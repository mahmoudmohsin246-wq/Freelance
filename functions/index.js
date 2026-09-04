/**
 * Cloud Functions - إرسال إيميلات + رفع صور الحساب بطريقة آمنة
 */

const { onCall, HttpsError } = require('firebase-functions/v2/https');
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

const APP_NAME = 'أكاديمية رياضية';

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