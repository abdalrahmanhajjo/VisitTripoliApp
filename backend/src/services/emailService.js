/**
 * Secure password reset email service.
 * Uses SMTP config from app (saved to file) or .env; falls back to console log for development.
 */
const nodemailer = require('nodemailer');
const { getSmtpConfig } = require('../config/smtpConfig');

const RESET_LINK_EXPIRY_MINUTES = 15;
const APP_NAME = process.env.APP_NAME || 'Visit Tripoli';

function createTransporter() {
  const c = getSmtpConfig();
  const host = c.host;
  const port = parseInt(c.port || '587', 10);
  const user = c.user;
  const pass = c.pass;
  const secure = process.env.SMTP_SECURE === 'true';

  if (!host || !user || !pass) {
    return null;
  }

  const options = {
    host,
    port,
    secure,
    auth: { user, pass },
  };
  // Gmail: ensure TLS works on port 587
  if (host.includes('gmail') && port === 587) {
    options.secure = false;
    options.requireTLS = true;
  }
  return nodemailer.createTransport(options);
}

/**
 * Send password reset code (6 digits) via email.
 * User enters code in the app to reset password.
 */
async function sendPasswordResetCode(email, code) {
  const transporter = createTransporter();

  if (!transporter) {
    console.log('\n--- Password Reset (no SMTP configured) ---');
    console.log(`To: ${email}`);
    console.log(`Your reset code: ${code} (valid ${RESET_LINK_EXPIRY_MINUTES} min)`);
    console.log('--- Set SMTP_HOST, SMTP_USER, SMTP_PASS in .env for production ---\n');
    return true;
  }

  const mailOptions = {
    from: `"${APP_NAME}" <${process.env.SMTP_FROM || getSmtpConfig().user}>`,
    to: email,
    subject: `Reset your ${APP_NAME} password`,
    html: `
      <!DOCTYPE html>
      <html>
      <head><meta charset="utf-8"></head>
      <body style="font-family: system-ui, sans-serif; line-height: 1.6; color: #1C1917; max-width: 480px; margin: 0 auto;">
        <h2 style="color: #0F766E;">Reset your password</h2>
        <p>You requested a password reset for your ${APP_NAME} account.</p>
        <p>Enter this code in the app to choose a new password:</p>
        <p style="font-size: 28px; font-weight: 700; letter-spacing: 0.2em; color: #0F766E; margin: 24px 0;">${code}</p>
        <p style="font-size: 14px; color: #57534E;">This code expires in ${RESET_LINK_EXPIRY_MINUTES} minutes. If you didn't request this, ignore this email.</p>
        <hr style="border: none; border-top: 1px solid #E7E5E4; margin: 24px 0;">
        <p style="font-size: 12px; color: #A8A29E;">${APP_NAME}</p>
      </body>
      </html>
    `,
    text: `Reset your ${APP_NAME} password\n\nYour code: ${code}\n\nEnter this in the app. Expires in ${RESET_LINK_EXPIRY_MINUTES} minutes.`,
  };

  try {
    await transporter.sendMail(mailOptions);
    return true;
  } catch (err) {
    console.error('Failed to send password reset email:', err.message || err);
    throw err;
  }
}

const VERIFICATION_LINK_EXPIRY_MINUTES = 24;

/**
 * Send email verification code (6 digits). User enters in app.
 */
async function sendVerificationCode(email, code) {
  const transporter = createTransporter();

  if (!transporter) {
    console.log('\n--- Email Verification (no SMTP) ---');
    console.log(`To: ${email}`);
    console.log(`Your verification code: ${code}`);
    console.log('---\n');
    return true;
  }

  const mailOptions = {
    from: `"${APP_NAME}" <${process.env.SMTP_FROM || getSmtpConfig().user}>`,
    to: email,
    subject: `Verify your ${APP_NAME} email`,
    html: `
      <!DOCTYPE html>
      <html>
      <head><meta charset="utf-8"></head>
      <body style="font-family: system-ui, sans-serif; line-height: 1.6; color: #1C1917; max-width: 480px; margin: 0 auto;">
        <h2 style="color: #0F766E;">Verify your email</h2>
        <p>Thanks for signing up for ${APP_NAME}.</p>
        <p>Enter this code in the app to verify your email:</p>
        <p style="font-size: 28px; font-weight: 700; letter-spacing: 0.2em; color: #0F766E; margin: 24px 0;">${code}</p>
        <p style="font-size: 14px; color: #57534E;">This code expires in ${VERIFICATION_LINK_EXPIRY_MINUTES} hours. If you didn't sign up, ignore this email.</p>
        <hr style="border: none; border-top: 1px solid #E7E5E4; margin: 24px 0;">
        <p style="font-size: 12px; color: #A8A29E;">${APP_NAME}</p>
      </body>
      </html>
    `,
    text: `Verify your ${APP_NAME} email\n\nYour code: ${code}\n\nEnter in the app. Expires in ${VERIFICATION_LINK_EXPIRY_MINUTES} hours.`,
  };

  try {
    await transporter.sendMail(mailOptions);
    return true;
  } catch (err) {
    console.error('Failed to send verification email:', err.message || err);
    throw err;
  }
}

function isSmtpConfigured() {
  return require('../config/smtpConfig').isConfigured();
}

module.exports = {
  sendPasswordResetCode,
  sendVerificationCode,
  isSmtpConfigured,
  RESET_LINK_EXPIRY_MINUTES,
  VERIFICATION_LINK_EXPIRY_MINUTES,
};
