/**
 * SMS OTP service (Twilio).
 * When not configured, logs OTP to console for development.
 */
let twilioClient = null;

function initTwilio() {
  const sid = process.env.TWILIO_ACCOUNT_SID;
  const token = process.env.TWILIO_AUTH_TOKEN;
  const from = process.env.TWILIO_PHONE_NUMBER;
  if (sid && token && from) {
    try {
      twilioClient = require('twilio')(sid, token);
      return { client: twilioClient, from };
    } catch (_) {}
  }
  return null;
}

const twilioConfig = initTwilio();

async function sendOtp(phone, code) {
  if (twilioConfig) {
    await twilioConfig.client.messages.create({
      body: `Your Visit Tripoli verification code: ${code}`,
      from: twilioConfig.from,
      to: phone,
    });
    return true;
  }
  console.log('\n--- SMS OTP (no Twilio) ---');
  console.log(`To: ${phone}`);
  console.log(`Code: ${code}`);
  console.log('--- Set TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, TWILIO_PHONE_NUMBER for production ---\n');
  return true;
}

module.exports = { sendOtp };
