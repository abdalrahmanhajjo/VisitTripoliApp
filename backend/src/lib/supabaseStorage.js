/**
 * Supabase Storage for feed images.
 * Uploads to the feed-Images bucket and returns public URLs.
 */

const { createClient } = require('@supabase/supabase-js');
const crypto = require('crypto');
const path = require('path');

const BUCKET = 'feed-images';
const AVATARS_BUCKET = 'avatars';
const VIDEOS_BUCKET = 'feed-videos';

let _client = null;
let _bucketEnsured = false;
let _avatarsBucketEnsured = false;
let _videosBucketEnsured = false;

function getClient() {
  if (_client) return _client;
  const url = process.env.SUPABASE_URL;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url || !key) {
    throw new Error('SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are required for feed image uploads');
  }
  _client = createClient(url, key);
  return _client;
}

async function ensureBucket() {
  if (_bucketEnsured) return;
  const supabase = getClient();
  const { error } = await supabase.storage.createBucket(BUCKET, {
    public: true,
    allowedMimeTypes: ['image/jpeg', 'image/png', 'image/gif', 'image/webp'],
    fileSizeLimit: '10MB',
  });
  if (error && !String(error.message || '').toLowerCase().includes('already exists')) {
    console.warn('[Supabase Storage] Could not create bucket:', error.message);
  }
  _bucketEnsured = true;
}

async function ensureAvatarsBucket() {
  if (_avatarsBucketEnsured) return;
  const supabase = getClient();
  const { error } = await supabase.storage.createBucket(AVATARS_BUCKET, {
    public: true,
    allowedMimeTypes: ['image/jpeg', 'image/png', 'image/gif', 'image/webp'],
    fileSizeLimit: '2MB',
  });
  if (error && !String(error.message || '').toLowerCase().includes('already exists')) {
    console.warn('[Supabase Storage] Could not create avatars bucket:', error.message);
  }
  _avatarsBucketEnsured = true;
}

async function ensureVideosBucket() {
  if (_videosBucketEnsured) return;
  const supabase = getClient();
  const { error } = await supabase.storage.createBucket(VIDEOS_BUCKET, {
    public: true,
    allowedMimeTypes: ['video/mp4', 'video/webm', 'video/ogg', 'video/quicktime', 'video/x-msvideo'],
    fileSizeLimit: '100MB',
  });
  if (error && !String(error.message || '').toLowerCase().includes('already exists')) {
    console.warn('[Supabase Storage] Could not create videos bucket:', error.message);
  }
  _videosBucketEnsured = true;
}

function getExtension(mimetype, originalname) {
  const map = {
    'image/jpeg': '.jpg',
    'image/png': '.png',
    'image/gif': '.gif',
    'image/webp': '.webp',
  };
  if (map[mimetype]) return map[mimetype];
  const ext = path.extname((originalname || '').toLowerCase());
  if (['.jpg', '.jpeg', '.png', '.gif', '.webp'].includes(ext)) return ext === '.jpeg' ? '.jpg' : ext;
  return '.jpg';
}

function getContentType(mimetype, originalname) {
  if (mimetype && mimetype.startsWith('image/')) return mimetype;
  const ext = path.extname((originalname || '').toLowerCase());
  const map = { '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.png': 'image/png', '.gif': 'image/gif', '.webp': 'image/webp' };
  return map[ext] || 'image/jpeg';
}

/**
 * Upload image buffer to Supabase Storage.
 * @param {Buffer} buffer - File buffer
 * @param {object} file - Multer file object { mimetype, originalname }
 * @returns {Promise<string>} Public URL
 */
async function uploadFeedImage(buffer, file) {
  await ensureBucket();
  const ext = getExtension(file.mimetype, file.originalname);
  const name = crypto.randomBytes(16).toString('hex') + ext;
  const supabase = getClient();
  const contentType = getContentType(file.mimetype, file.originalname);
  const { data, error } = await supabase.storage
    .from(BUCKET)
    .upload(name, buffer, {
      contentType,
      upsert: false,
    });
  if (error) throw error;
  const { data: urlData } = supabase.storage.from(BUCKET).getPublicUrl(data.path);
  return urlData.publicUrl;
}

/**
 * Upload video buffer to Supabase Storage (feed-videos bucket).
 * @param {Buffer} buffer - File buffer
 * @param {object} file - Multer file object { mimetype, originalname }
 * @returns {Promise<string>} Public URL
 */
async function uploadFeedVideo(buffer, file) {
  await ensureVideosBucket();
  const ext = path.extname((file.originalname || '').toLowerCase()) || '.mp4';
  const name = crypto.randomBytes(16).toString('hex') + ext;
  const supabase = getClient();
  const contentType = file.mimetype || 'video/mp4';
  const { data, error } = await supabase.storage
    .from(VIDEOS_BUCKET)
    .upload(name, buffer, {
      contentType,
      upsert: false,
    });
  if (error) throw error;
  const { data: urlData } = supabase.storage.from(VIDEOS_BUCKET).getPublicUrl(data.path);
  return urlData.publicUrl;
}

/**
 * Upload profile avatar to Supabase avatars bucket.
 * Path: avatars/{userId}/{uuid}.jpg - user-scoped for security.
 * @param {Buffer} buffer - File buffer
 * @param {object} file - Multer file object { mimetype, originalname }
 * @param {string} userId - User UUID (for path isolation)
 * @returns {Promise<string>} Public URL
 */
async function uploadProfileAvatar(buffer, file, userId) {
  await ensureAvatarsBucket();
  const ext = getExtension(file.mimetype, file.originalname);
  const name = crypto.randomBytes(12).toString('hex') + ext;
  const storagePath = `${userId}/${name}`;
  const supabase = getClient();
  const contentType = getContentType(file.mimetype, file.originalname);
  const { error } = await supabase.storage
    .from(AVATARS_BUCKET)
    .upload(storagePath, buffer, {
      contentType,
      upsert: true,
    });
  if (error) throw error;
  const { data: urlData } = supabase.storage.from(AVATARS_BUCKET).getPublicUrl(storagePath);
  return urlData.publicUrl;
}

function isConfigured() {
  return !!(process.env.SUPABASE_URL && process.env.SUPABASE_SERVICE_ROLE_KEY);
}

module.exports = { uploadFeedImage, uploadFeedVideo, uploadProfileAvatar, isConfigured, BUCKET, AVATARS_BUCKET, VIDEOS_BUCKET };
