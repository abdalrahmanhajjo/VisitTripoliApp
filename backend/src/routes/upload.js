/**
 * Shared image upload for dashboard (places) and feed.
 * Saves to uploads/images/ and returns URL so places form and feed use the same storage.
 */
const express = require('express');
const multer = require('multer');
const fs = require('fs');
const { authMiddleware } = require('../middleware/auth');
const adminAuth = require('../middleware/adminAuth');
const { getSecureStorage, imageFileFilter, MAX_IMAGE_SIZE, UPLOADS_IMAGES_DIR } = require('../middleware/secureUpload');

const router = express.Router();

if (!fs.existsSync(UPLOADS_IMAGES_DIR)) {
  fs.mkdirSync(UPLOADS_IMAGES_DIR, { recursive: true });
}

const storage = multer.diskStorage(getSecureStorage(UPLOADS_IMAGES_DIR));
const uploadImage = multer({
  storage,
  limits: { fileSize: MAX_IMAGE_SIZE },
  fileFilter: imageFileFilter,
});

/** Accept either admin key (dashboard) or JWT (business owner). */
function adminOrAuth(req, res, next) {
  const secret = process.env.ADMIN_SECRET;
  const key = req.headers['x-admin-key'];
  if (secret && key && key === secret) return next();
  authMiddleware(req, res, next);
}

/**
 * POST /api/upload/image
 * Auth: X-Admin-Key (admin) or Bearer JWT (business owner).
 * Body: multipart with field "image" (single file).
 * Returns: { url: "/uploads/images/xxx.jpg" }
 */
router.post('/image', adminOrAuth, (req, res) => {
  uploadImage.single('image')(req, res, (err) => {
    if (err) {
      if (err.code === 'LIMIT_FILE_SIZE') return res.status(400).json({ error: 'File too large. Max 10MB.' });
      return res.status(400).json({ error: err.message || 'Invalid file' });
    }
    const file = req.file;
    if (!file) return res.status(400).json({ error: 'No image file provided' });
    res.status(201).json({ url: `/uploads/images/${file.filename}` });
  });
});

module.exports = router;
