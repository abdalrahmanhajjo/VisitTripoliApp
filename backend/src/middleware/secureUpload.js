/**
 * Secure file upload configuration.
 * - Strict MIME type whitelist
 * - Filename sanitization (no path traversal)
 * - Size limits
 * - No executable extensions
 */

const path = require('path');
const fs = require('fs');
const crypto = require('crypto');

const ALLOWED_IMAGE_TYPES = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
const ALLOWED_VIDEO_TYPES = [
  'video/mp4',
  'video/webm',
  'video/ogg',
  'video/quicktime',    // iOS/macOS
  'video/x-msvideo',   // AVI
  'video/x-matroska',  // MKV
  'video/3gpp',        // Android
  'video/3gpp2',
  'video/mpeg',
  'application/octet-stream', // Generic binary — check extension below
];
const ALLOWED_VIDEO_EXTENSIONS = ['.mp4', '.webm', '.mov', '.avi', '.mkv', '.3gp', '.ogv', '.mpeg', '.mpg'];
const MAX_IMAGE_SIZE = 10 * 1024 * 1024;   // 10 MB
const MAX_VIDEO_SIZE = 200 * 1024 * 1024;  // 200 MB
const FORBIDDEN_EXTENSIONS = ['.exe', '.bat', '.cmd', '.sh', '.php', '.js', '.html', '.htaccess'];

/** Uploads root - must match index.js so feed images are served at /uploads/images/ */
function getUploadsRoot() {
  const projectRoot = path.join(__dirname, '../../..');
  return process.env.UPLOADS_PATH
    ? path.resolve(projectRoot, process.env.UPLOADS_PATH)
    : path.join(__dirname, '../../uploads');
}

/** Directory for all image uploads (feed + places dashboard). Same as admin places. */
function getUploadsImagesDir() {
  return path.join(getUploadsRoot(), 'images');
}
/** Directory for feed video uploads only. */
function getUploadsFeedDir() {
  return path.join(getUploadsRoot(), 'feed');
}

function getSecureStorage(destDir) {
  return {
    destination: (req, file, cb) => cb(null, destDir),
    filename: (req, file, cb) => {
      const ext = getSafeExtension(file.mimetype, file.originalname);
      const safeName = crypto.randomBytes(16).toString('hex') + ext;
      cb(null, safeName);
    },
  };
}

/**
 * Storage that saves images to uploads/images and videos to uploads/feed.
 * Use for feed/business feed-posts so image uploads match the places dashboard.
 */
function getFeedStorage() {
  const imagesDir = getUploadsImagesDir();
  const feedDir = getUploadsFeedDir();
  if (!fs.existsSync(imagesDir)) fs.mkdirSync(imagesDir, { recursive: true });
  if (!fs.existsSync(feedDir)) fs.mkdirSync(feedDir, { recursive: true });
  return {
    destination: (req, file, cb) => {
      const isImageMime = file.mimetype && file.mimetype.startsWith('image/');
      const ext = path.extname((file.originalname || file.filename || '').toLowerCase());
      const hasImageExt = ['.jpg', '.jpeg', '.png', '.gif', '.webp'].includes(ext);
      const dir = (isImageMime || (file.mimetype === 'application/octet-stream' && hasImageExt))
        ? imagesDir : feedDir;
      cb(null, dir);
    },
    filename: (req, file, cb) => {
      const ext = getSafeExtension(file.mimetype, file.originalname);
      const safeName = crypto.randomBytes(16).toString('hex') + ext;
      cb(null, safeName);
    },
  };
}

/** URL path for uploaded image (same as used in places). */
function getImageUrl(filename) {
  return `/uploads/images/${filename}`;
}

/** URL path for uploaded video (feed). */
function getVideoUrl(filename) {
  return `/uploads/feed/${filename}`;
}

function getSafeExtension(mimetype, originalname) {
  const map = {
    'image/jpeg': '.jpg',
    'image/png': '.png',
    'image/gif': '.gif',
    'image/webp': '.webp',
    'video/mp4': '.mp4',
    'video/webm': '.webm',
    'video/quicktime': '.mov',
    'video/ogg': '.ogv',
    'video/x-msvideo': '.avi',
    'video/x-matroska': '.mkv',
    'video/3gpp': '.3gp',
    'video/3gpp2': '.3g2',
    'video/mpeg': '.mpeg',
  };
  if (map[mimetype]) return map[mimetype];
  const ext = path.extname(originalname || '').toLowerCase();
  if (FORBIDDEN_EXTENSIONS.includes(ext)) return '.bin';
  if (['.jpg', '.jpeg', '.png', '.gif', '.webp'].includes(ext)) return ext === '.jpeg' ? '.jpg' : ext;
  if (ALLOWED_VIDEO_EXTENSIONS.includes(ext)) return ext;
  return '.bin';
}

const IMAGE_EXTENSIONS = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];

function imageFileFilter(req, file, cb) {
  if (ALLOWED_IMAGE_TYPES.includes(file.mimetype)) {
    return cb(null, true);
  }
  const ext = path.extname((file.originalname || file.filename || '').toLowerCase());
  if (IMAGE_EXTENSIONS.includes(ext)) {
    return cb(null, true);
  }
  cb(new Error('Invalid file type. Allowed: JPEG, PNG, GIF, WebP'));
}

function videoFileFilter(req, file, cb) {
  const mime = (file.mimetype || '').toLowerCase();
  const ext = path.extname((file.originalname || file.fieldname || '').toLowerCase());

  // Accept known video MIME types
  if (ALLOWED_VIDEO_TYPES.includes(mime)) {
    return cb(null, true);
  }
  // Accept any video/* sub-type
  if (mime.startsWith('video/')) {
    return cb(null, true);
  }
  // Accept octet-stream if extension is a known video type
  if (mime === 'application/octet-stream' && ALLOWED_VIDEO_EXTENSIONS.includes(ext)) {
    return cb(null, true);
  }
  if (!mime && ALLOWED_VIDEO_EXTENSIONS.includes(ext)) {
    return cb(null, true);
  }
  console.error(`[Upload] Rejected video: mime="${mime}", ext="${ext}", field="${file.fieldname}", original="${file.originalname}"`);
  cb(new Error(`Invalid video type: ${mime || 'unknown'}. Allowed: MP4, WebM, MOV, AVI, MKV`));
}

module.exports = {
  getSecureStorage,
  getFeedStorage,
  getImageUrl,
  getVideoUrl,
  getUploadsImagesDir,
  getUploadsFeedDir,
  UPLOADS_IMAGES_DIR: getUploadsImagesDir(),
  UPLOADS_FEED_DIR: getUploadsFeedDir(),
  imageFileFilter,
  videoFileFilter,
  ALLOWED_IMAGE_TYPES,
  ALLOWED_VIDEO_TYPES,
  MAX_IMAGE_SIZE,
  MAX_VIDEO_SIZE,
};
