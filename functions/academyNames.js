const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { onCall } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

/**
 * Keeps a single public document (academyNames/list) in sync with the
 * distinct list of academy names taken from every user whose role is
 * 'admin'. This lets the registration screen show existing academies to
 * users who are NOT signed in yet, without opening read access to the
 * whole `users` collection (which stays locked to authenticated reads).
 */
exports.syncAcademyNames = onDocumentWritten('users/{userId}', async (event) => {
  const db = admin.firestore();

  const before = event.data?.before?.exists ? event.data.before.data() : null;
  const after = event.data?.after?.exists ? event.data.after.data() : null;

  const relevantBefore = before && before.role === 'admin' ? before.academyName : null;
  const relevantAfter = after && after.role === 'admin' ? after.academyName : null;
  if (relevantBefore === relevantAfter) return; // nothing academy-related changed

  const snap = await db.collection('users').where('role', '==', 'admin').get();
  const names = Array.from(
    new Set(
      snap.docs
        .map((doc) => (doc.data().academyName || '').trim())
        .filter((name) => name.length > 0)
    )
  ).sort((a, b) => a.localeCompare(b));

  await db.collection('academyNames').doc('list').set({
    names,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
});

/**
 * One-time backfill for academy names that already existed before this
 * function was deployed (the trigger above only fires on NEW writes).
 * Call this once after deploying, then you can delete it.
 */
exports.backfillAcademyNamesOnce = onCall(async () => {
  const db = admin.firestore();
  const snap = await db.collection('users').where('role', '==', 'admin').get();
  const names = Array.from(
    new Set(
      snap.docs
        .map((doc) => (doc.data().academyName || '').trim())
        .filter((name) => name.length > 0)
    )
  ).sort((a, b) => a.localeCompare(b));

  await db.collection('academyNames').doc('list').set({
    names,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { count: names.length, names };
});
