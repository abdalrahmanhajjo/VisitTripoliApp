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
  const privateKey = process.env.IMAGEKIT_PRIVATE_KEY;
  if (!privateKey) {
    throw new Error('IMAGEKIT_PRIVATE_KEY is required for media uploads');
  }
  _client = new ImageKit({
    privateKey,
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
  const uploadFile = await ImageKit.toFile(buffer, fileName);
  const uploadFn =
    (imagekit && typeof imagekit.upload === 'function')
      ? imagekit.upload.bind(imagekit)
      : (imagekit?.files && typeof imagekit.files.upload === 'function')
          ? imagekit.files.upload.bind(imagekit.files)
          : null;
  if (!uploadFn) {
    throw new Error('ImageKit upload API is unavailable');
  }
  const result = await uploadFn({
    file: uploadFile,
    fileName,
    folder,
    useUniqueFileName: true,
    isPrivateFile,
  });
  const url = result?.url || result?.data?.url || null;
  if (!url) {
    throw new Error('ImageKit upload succeeded but URL is missing');
  }
  return url;
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
  return !!process.env.IMAGEKIT_PRIVATE_KEY;
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
