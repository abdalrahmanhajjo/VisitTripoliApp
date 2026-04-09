/**
 * ImageKit media storage adapter.
 * Keeps legacy export names to avoid route-level refactors.
 */
const ImageKit = require('@imagekit/nodejs');
const crypto = require('crypto');
const path = require('path');

const BUCKET = 'feed-images';
const AVATARS_BUCKET = 'avatars';
const VIDEOS_BUCKET = 'feed-videos';

let _client = null;

function getClient() {
  if (_client) return _client;
  const publicKey = process.env.IMAGEKIT_PUBLIC_KEY;
  const privateKey = process.env.IMAGEKIT_PRIVATE_KEY;
  const urlEndpoint = process.env.IMAGEKIT_URL_ENDPOINT;
  if (!publicKey || !privateKey || !urlEndpoint) {
    throw new Error('IMAGEKIT_PUBLIC_KEY, IMAGEKIT_PRIVATE_KEY and IMAGEKIT_URL_ENDPOINT are required for media uploads');
  }
  _client = new ImageKit({
    publicKey,
    privateKey,
    urlEndpoint,
  });
  return _client;
}

function getExtension(mimetype, originalname, fallback = '.jpg') {
  if (originalname) {
    const ext = path.extname(originalname.toLowerCase());
    if (ext) return ext;
  }
  const map = {
    'image/jpeg': '.jpg',
    'image/png': '.png',
    'image/gif': '.gif',
    'image/webp': '.webp',
    'video/mp4': '.mp4',
    'video/webm': '.webm',
    'video/quicktime': '.mov',
    'video/x-msvideo': '.avi',
  };
  return map[mimetype] || fallback;
}

function getFolder(subFolder) {
  const root = (process.env.IMAGEKIT_FOLDER || '/tripoli-explorer').trim();
  const normalizedRoot = root.startsWith('/') ? root : `/${root}`;
  const cleanSub = String(subFolder || '').replace(/^\/+/, '');
  return `${normalizedRoot}/${cleanSub}`;
}

async function uploadToImageKit({ buffer, fileName, folder, isPrivateFile = false }) {
  const imagekit = getClient();
  const result = await imagekit.upload({
    file: buffer,
    fileName,
    folder,
    useUniqueFileName: true,
    isPrivateFile,
  });
  return result.url;
}

async function uploadFeedImage(buffer, file) {
  const ext = getExtension(file?.mimetype, file?.originalname, '.jpg');
  const fileName = `${crypto.randomBytes(16).toString('hex')}${ext}`;
  return uploadToImageKit({
    buffer,
    fileName,
    folder: getFolder(BUCKET),
  });
}

async function uploadFeedVideo(buffer, file) {
  const ext = getExtension(file?.mimetype, file?.originalname, '.mp4');
  const fileName = `${crypto.randomBytes(16).toString('hex')}${ext}`;
  return uploadToImageKit({
    buffer,
    fileName,
    folder: getFolder(VIDEOS_BUCKET),
  });
}

async function uploadProfileAvatar(buffer, file, userId) {
  const ext = getExtension(file?.mimetype, file?.originalname, '.jpg');
  const fileName = `${crypto.randomBytes(12).toString('hex')}${ext}`;
  return uploadToImageKit({
    buffer,
    fileName,
    folder: getFolder(`${AVATARS_BUCKET}/${userId}`),
  });
}

function isConfigured() {
  return !!(
    process.env.IMAGEKIT_PUBLIC_KEY
    && process.env.IMAGEKIT_PRIVATE_KEY
    && process.env.IMAGEKIT_URL_ENDPOINT
  );
}

module.exports = {
  uploadFeedImage,
  uploadFeedVideo,
  uploadProfileAvatar,
  isConfigured,
  BUCKET,
  AVATARS_BUCKET,
  VIDEOS_BUCKET,
};
