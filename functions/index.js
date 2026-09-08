/**
 * Cloud Functions - إرسال إيميلات + رفع صور الحساب بطريقة آمنة
 */

const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { setGlobalOptions } = require('firebase-functions/v2');
const { defineSecret } = require('firebase-functions/params');
const admin = require('firebase-admin');
const sgMail = require('@sendgrid/mail');
const { createClient } = require('@supabase/supabase-js');

admin.initializeApp();
setGlobalOptions({ region: 'us-central1', maxInstances: 10 });

// Secret definitions
const SENDGRID_API_KEY = defineSecret('SENDGRID_API_KEY');
const SENDER_EMAIL = defineSecret('SENDER_EMAIL');
const SUPABASE_URL = defineSecret('SUPABASE_URL');
const SUPABASE_SERVICE_ROLE_KEY = defineSecret('SUPABASE_SERVICE_ROLE_KEY');

const APP_NAME = 'Academio';

function buildResetEmailHtml(link) {
  return `
  <div dir="rtl" style="font-family: Arial, sans-serif; max-width: 480px; margin: auto; padding: 24px; background:#f5f7fa; border-radius:12px;">
    <h2 style="color:#1a73e8;">إعادة تعيين كلمة المرور</h2>
    <p style="color:#333; font-size:15px; line-height:1.6;">
      وصلنا طلب لإعادة تعيين كلمة المرور الخاصة بحسابك في تطبيق ${APP_NAME}.
      لو انت اللي طلبت ده، دوس على الزرار تحت لتعيين كلمة مرور جديدة.
    </p>
    <a href="${link}" style="display:inline-block; background:#1a73e8; color:#fff; text-decoration:none; padding:12px 28px; border-radius:8px; font-weight:bold; margin:16px 0;">
      إعادة تعيين كلمة المرور
    </a>
    <p style="color:#777; font-size:13px;">
      لو انت مش طلبت ده، ممكن تتجاهل الإيميل ده بأمان وحسابك هيفضل زي ما هو.
    </p>
  </div>`;
}

function buildVerifyEmailHtml(link) {
  return `
  <div dir="rtl" style="font-family: Arial, sans-serif; max-width: 480px; margin: auto; padding: 24px; background:#f5f7fa; border-radius:12px;">
    <h2 style="color:#0f9d58;">تفعيل بريدك الإلكتروني</h2>
    <p style="color:#333; font-size:15px; line-height:1.6;">
      أهلاً بيك في تطبيق ${APP_NAME}! دوس على الزرار تحت عشان تفعّل حسابك.
    </p>
    <a href="${link}" style="display:inline-block; background:#0f9d58; color:#fff; text-decoration:none; padding:12px 28px; border-radius:8px; font-weight:bold; margin:16px 0;">
      تفعيل الحساب
    </a>
    <p style="color:#777; font-size:13px;">
      لو انت مش عملت الحساب ده، ممكن تتجاهل الإيميل ده.
    </p>
  </div>`;
}

async function sendViaSendGrid({ to, subject, html, apiKey, senderEmail }) {
  sgMail.setApiKey(apiKey);
  await sgMail.send({
    to,
    from: { email: senderEmail, name: APP_NAME },
    subject,
    html,
  });
}

exports.sendPasswordResetEmailCustom = onCall(
  { secrets: [SENDGRID_API_KEY, SENDER_EMAIL] },
  async (request) => {
    const email = (request.data && request.data.email || '').trim().toLowerCase();
    if (!email || !email.includes('@')) {
      throw new HttpsError('invalid-argument', 'enterValidEmail');
    }

    try {
      await admin.auth().getUserByEmail(email);
      const link = await admin.auth().generatePasswordResetLink(email);

      await sendViaSendGrid({
        to: email,
        subject: 'إعادة تعيين كلمة المرور - ' + APP_NAME,
        html: buildResetEmailHtml(link),
        apiKey: SENDGRID_API_KEY.value(),
        senderEmail: SENDER_EMAIL.value(),
      });

      return { success: true };
    } catch (err) {
      if (err.code === 'auth/user-not-found') {
        return { success: true };
      }
      console.error('sendPasswordResetEmailCustom error:', err);
      throw new HttpsError('internal', 'genericError');
    }
  }
);

exports.sendVerificationEmailCustom = onCall(
  { secrets: [SENDGRID_API_KEY, SENDER_EMAIL] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'يجب تسجيل الدخول أولاً');
    }

    try {
      const user = await admin.auth().getUser(request.auth.uid);
      if (user.emailVerified) {
        return { success: true, alreadyVerified: true };
      }

      const link = await admin.auth().generateEmailVerificationLink(user.email);

      await sendViaSendGrid({
        to: user.email,
        subject: 'تفعيل بريدك الإلكتروني - ' + APP_NAME,
        html: buildVerifyEmailHtml(link),
        apiKey: SENDGRID_API_KEY.value(),
        senderEmail: SENDER_EMAIL.value(),
      });

      return { success: true };
    } catch (err) {
      console.error('sendVerificationEmailCustom error:', err);
      throw new HttpsError('internal', 'genericError');
    }
  }
);

/**
 * دالة توليد رابط رفع صورة الحساب الشفافة والآمنة لـ Supabase Storage
 */
exports.generateAvatarUploadUrl = onCall(
  { secrets: [SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'يجب تسجيل الدخول أولاً');
    }

    const uid = request.auth.uid;
    const filePath = `users/${uid}/avatar.jpg`;

    const supabase = createClient(
      SUPABASE_URL.value(),
      SUPABASE_SERVICE_ROLE_KEY.value()
    );

    try {
      const { data: uploadData, error } = await supabase
        .storage
        .from('avatars')
        .createSignedUploadUrl(filePath);

      if (error) throw new Error(error.message);

      return {
        signedUrl: uploadData.signedUrl,
        path: filePath,
        baseUrl: SUPABASE_URL.value(),
      };
    } catch (err) {
      console.error('generateAvatarUploadUrl error:', err);
      throw new HttpsError('internal', err.message);
    }
  }
);

/**
 * دالة إرسال Push Notification (FCM) حقيقية عند إنشاء إشعار في Firestore
 *
 * الـ Manager (أو أي staff) بيكتب مستند إشعار جديد تحت:
 *   users/{userId}/notifications/{notificationId}
 * (سواء إشعار لمستخدم واحد أو جزء من broadcast لكل المستخدمين — الاثنين
 * بيتكتبوا كمستند منفصل تحت كل مستخدم، فنفس الـ trigger ده بيغطي الحالتين
 * من غير ما نحتاج function تانية مخصصة للـ broadcast).
 *
 * الفنكشن دي بتاخد الـ FCM tokens المسجلة للمستخدم صاحب المستند
 * (users/{userId}/fcmTokens/*) وتبعتلهم push notification حقيقي عن طريق
 * Firebase Admin SDK. أي token مرفوض/منتهي (unregistered) بيتشال من
 * Firestore تلقائيًا عشان محدش يفضل يحاول يبعتله تاني.
 */
exports.sendPushOnNotificationCreated = onDocumentCreated(
  'users/{userId}/notifications/{notificationId}',
  async (event) => {
    const { userId, notificationId } = event.params;
    const snap = event.data;
    if (!snap) {
      console.error('sendPushOnNotificationCreated: no snapshot data for', notificationId);
      return;
    }

    const notif = snap.data() || {};
    const title = (notif.title || '').toString().trim();
    const body = (notif.message || '').toString().trim();

    if (!title && !body) {
      console.warn('sendPushOnNotificationCreated: empty title/message, skipping', notificationId);
      return;
    }

    try {
      const tokensSnap = await admin
        .firestore()
        .collection('users')
        .doc(userId)
        .collection('fcmTokens')
        .get();

      if (tokensSnap.empty) {
        // Normal case: user has never opened the app on a device with
        // push permission granted, or is signed out everywhere.
        return;
      }

      const tokens = tokensSnap.docs.map((d) => d.id);

      const message = {
        notification: { title: title || APP_NAME, body },
        data: {
          notificationId,
          type: (notif.type || 'general').toString(),
          subscriptionId: (notif.subscriptionId || '').toString(),
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        android: {
          notification: {
            channelId: 'high_importance_channel',
          },
        },
        apns: {
          payload: {
            aps: { sound: 'default' },
          },
        },
        tokens,
      };

      const response = await admin.messaging().sendEachForMulticast(message);

      if (response.failureCount > 0) {
        const staleTokens = [];
        response.responses.forEach((r, idx) => {
          if (!r.success) {
            const code = r.error && r.error.code;
            console.error('FCM send failed for token', tokens[idx], code, r.error && r.error.message);
            if (
              code === 'messaging/registration-token-not-registered' ||
              code === 'messaging/invalid-registration-token'
            ) {
              staleTokens.push(tokens[idx]);
            }
          }
        });

        if (staleTokens.length > 0) {
          const batch = admin.firestore().batch();
          staleTokens.forEach((t) => {
            batch.delete(
              admin.firestore().collection('users').doc(userId).collection('fcmTokens').doc(t)
            );
          });
          await batch.commit();
        }
      }

      console.log(
        `sendPushOnNotificationCreated: sent ${response.successCount}/${tokens.length} for user ${userId}, notification ${notificationId}`
      );
    } catch (err) {
      console.error('sendPushOnNotificationCreated error:', err);
    }
  }
);