/**
 * Shared image upload for dashboard (places) and feed.
 * Uploads to ImageKit and returns public URL.
 */
const express = require('express');
const multer = require('multer');
const { authMiddleware } = require('../middleware/auth');
const { imageFileFilter, MAX_IMAGE_SIZE } = require('../middleware/secureUpload');
const { uploadFeedImage, isConfigured: mediaStorageConfigured } = require('../lib/supabaseStorage');

const router = express.Router();
const uploadImage = multer({
  storage: multer.memoryStorage(),
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
 * Returns: { url: "https://ik.imagekit.io/..." }
 */
router.post('/image', adminOrAuth, async (req, res) => {
  uploadImage.single('image')(req, res, async (err) => {
    if (err) {
      if (err.code === 'LIMIT_FILE_SIZE') return res.status(400).json({ error: 'File too large. Max 10MB.' });
      return res.status(400).json({ error: err.message || 'Invalid file' });
    }
    const file = req.file;
    if (!file) return res.status(400).json({ error: 'No image file provided' });
    try {
      if (!mediaStorageConfigured()) {
        return res.status(503).json({ error: 'Image upload requires ImageKit configuration' });
      }
      const url = await uploadFeedImage(file.buffer, file);
      return res.status(201).json({ url });
    } catch (e) {
      return res.status(500).json({ error: e.message || 'Failed to upload image' });
    }
  });
});

module.exports = router;
