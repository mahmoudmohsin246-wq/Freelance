// Supabase Edge Function: send-push
//
// Purpose: deliver a real device push notification (via Firebase Cloud
// Messaging) for a notification that was already written to Firestore by
// the Flutter app, WITHOUT needing Firebase Cloud Functions / the Blaze
// plan. Everything here talks to Google's REST APIs directly using a
// Firebase service account (which is free to create on the Spark plan).
//
// Flow (called by the app right after it writes
// users/{userId}/notifications/{notificationId}):
//   1. Verify the caller's Firebase ID token (proves they're a real,
//      logged-in user of this Firebase project — not just anyone on the
//      internet).
//   2. Mint a short-lived Google OAuth2 access token from the service
//      account (scopes: Firestore + FCM).
//   3. Read the notification doc + the target user's fcmTokens from
//      Firestore via its REST API (this is authoritative — we never trust
//      title/body from the client directly, only the doc that Firestore's
//      own security rules already gated).
//   4. Send the push via the FCM HTTP v1 API to every token.
//   5. Delete any token FCM reports as unregistered/invalid.
//
// Deploy with: supabase functions deploy send-push --no-verify-jwt
// (--no-verify-jwt because we verify the FIREBASE id token ourselves
// below, not a Supabase-issued one.)
//
// Required secret (set once):
//   supabase secrets set FIREBASE_SERVICE_ACCOUNT='<contents of the
//   service-account JSON file downloaded from Firebase Console>'

import { importPKCS8, importX509, SignJWT, jwtVerify, decodeProtectedHeader } from 'npm:jose@5';

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
  });
}

interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
}

function loadServiceAccount(): ServiceAccount {
  const raw = Deno.env.get('FIREBASE_SERVICE_ACCOUNT');
  if (!raw) throw new Error('FIREBASE_SERVICE_ACCOUNT secret is not set');
  return JSON.parse(raw) as ServiceAccount;
}

/** Verifies a Firebase Auth ID token was really issued by this Firebase project. */
async function verifyFirebaseIdToken(idToken: string, projectId: string): Promise<string> {
  const { kid } = decodeProtectedHeader(idToken);
  if (!kid) throw new Error('ID token missing kid');

  const certsRes = await fetch(
    'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com',
  );
  const certs: Record<string, string> = await certsRes.json();
  const pem = certs[kid];
  if (!pem) throw new Error('No matching certificate for token kid');

  const publicKey = await importX509(pem, 'RS256');
  const { payload } = await jwtVerify(idToken, publicKey, {
    issuer: `https://securetoken.google.com/${projectId}`,
    audience: projectId,
  });

  const uid = payload.sub;
  if (!uid) throw new Error('ID token missing sub');
  return uid;
}

/** Exchanges the service account for a short-lived Google OAuth2 access token. */
async function getGoogleAccessToken(sa: ServiceAccount, scopes: string[]): Promise<string> {
  const privateKey = await importPKCS8(sa.private_key, 'RS256');
  const now = Math.floor(Date.now() / 1000);

  const assertion = await new SignJWT({ scope: scopes.join(' ') })
    .setProtectedHeader({ alg: 'RS256', typ: 'JWT' })
    .setIssuer(sa.client_email)
    .setSubject(sa.client_email)
    .setAudience('https://oauth2.googleapis.com/token')
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(privateKey);

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  });

  if (!res.ok) {
    throw new Error(`Failed to mint Google access token: ${res.status} ${await res.text()}`);
  }
  const data = await res.json();
  return data.access_token as string;
}

function fsValue(fields: Record<string, any> | undefined, key: string): string {
  const v = fields?.[key];
  if (!v) return '';
  return v.stringValue ?? '';
}

async function getNotificationDoc(
  projectId: string,
  accessToken: string,
  userId: string,
  notificationId: string,
) {
  const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/users/${userId}/notifications/${notificationId}`;
  const res = await fetch(url, { headers: { Authorization: `Bearer ${accessToken}` } });
  if (!res.ok) return null;
  const doc = await res.json();
  return {
    title: fsValue(doc.fields, 'title'),
    body: fsValue(doc.fields, 'message'),
    type: fsValue(doc.fields, 'type') || 'general',
  };
}

async function getUserTokens(
  projectId: string,
  accessToken: string,
  userId: string,
): Promise<string[]> {
  const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/users/${userId}/fcmTokens?pageSize=200`;
  const res = await fetch(url, { headers: { Authorization: `Bearer ${accessToken}` } });
  if (!res.ok) return [];
  const data = await res.json();
  const docs = data.documents ?? [];
  return docs.map((d: any) => (d.name as string).split('/').pop() as string);
}

async function deleteToken(
  projectId: string,
  accessToken: string,
  userId: string,
  token: string,
) {
  const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/users/${userId}/fcmTokens/${token}`;
  await fetch(url, { method: 'DELETE', headers: { Authorization: `Bearer ${accessToken}` } });
}

async function sendFcm(
  projectId: string,
  accessToken: string,
  token: string,
  title: string,
  body: string,
  data: Record<string, string>,
): Promise<{ ok: boolean; unregistered: boolean }> {
  const url = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;
  const res = await fetch(url, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      message: {
        token,
        notification: { title, body },
        data,
        android: { notification: { channel_id: 'high_importance_channel' } },
        apns: { payload: { aps: { sound: 'default' } } },
      },
    }),
  });

  if (res.ok) return { ok: true, unregistered: false };

  const errText = await res.text();
  const unregistered =
    res.status === 404 ||
    errText.includes('UNREGISTERED') ||
    errText.includes('INVALID_ARGUMENT');
  console.error('FCM send failed', token, res.status, errText);
  return { ok: false, unregistered };
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS_HEADERS });
  if (req.method !== 'POST') return jsonResponse({ error: 'Method not allowed' }, 405);

  try {
    const { idToken, userId, notificationId } = await req.json();
    if (!idToken || !userId || !notificationId) {
      return jsonResponse({ error: 'idToken, userId and notificationId are required' }, 400);
    }

    const sa = loadServiceAccount();

    // 1. Make sure this call really comes from a signed-in user of our
    //    Firebase project (blocks random internet callers from burning
    //    our FCM/Firestore quota).
    await verifyFirebaseIdToken(idToken, sa.project_id);

    // 2. Server-level Google access token (Firestore read/delete + FCM send).
    const accessToken = await getGoogleAccessToken(sa, [
      'https://www.googleapis.com/auth/datastore',
      'https://www.googleapis.com/auth/firebase.messaging',
    ]);

    // 3. Read the (already rule-gated) notification content — never trust
    //    title/body straight from the client.
    const notif = await getNotificationDoc(sa.project_id, accessToken, userId, notificationId);
    if (!notif || (!notif.title && !notif.body)) {
      return jsonResponse({ sent: 0, total: 0, note: 'notification doc not found or empty' });
    }

    const tokens = await getUserTokens(sa.project_id, accessToken, userId);
    if (tokens.length === 0) {
      return jsonResponse({ sent: 0, total: 0, note: 'user has no registered devices' });
    }

    let sent = 0;
    for (const token of tokens) {
      const result = await sendFcm(sa.project_id, accessToken, token, notif.title, notif.body, {
        notificationId,
        type: notif.type,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      });
      if (result.ok) sent++;
      else if (result.unregistered) {
        await deleteToken(sa.project_id, accessToken, userId, token);
      }
    }

    return jsonResponse({ sent, total: tokens.length });
  } catch (err) {
    console.error('send-push error:', err);
    return jsonResponse({ error: String(err) }, 500);
  }
});
