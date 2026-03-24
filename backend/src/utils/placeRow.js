/** Shared place JSON shape for /api/places and /api/user/saved-places */

function resolveImageUrls(images, baseUrl) {
  if (!Array.isArray(images)) return [];
  const base = (baseUrl || process.env.UPLOADS_BASE_URL || '').replace(/\/$/, '');
  return images.filter(Boolean).map((url) => {
    if (!url || typeof url !== 'string') return null;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (url.startsWith('/') && base) return `${base}${url}`;
    return url;
  }).filter(Boolean);
}

function safeParseJson(val, fallback = []) {
  if (Array.isArray(val)) return val;
  if (typeof val !== 'string') return fallback;
  try {
    return JSON.parse(val);
  } catch {
    return fallback;
  }
}

function rowToPlace(row, baseUrl) {
  let images = safeParseJson(row.images, []);
  images = resolveImageUrls(images, baseUrl);
  const result = {
    id: row.id,
    name: row.name,
    description: row.description || '',
    location: row.location || '',
    latitude: row.latitude ?? null,
    longitude: row.longitude ?? null,
    images,
    category: row.category || '',
    categoryId: row.category_id,
    duration: row.duration,
    price: row.price,
    bestTime: row.best_time,
    rating: row.rating,
    reviewCount: row.review_count,
    hours: row.hours,
    tags: row.tags,
    searchName: row.search_name,
  };
  if (row.latitude != null && row.longitude != null) {
    result.coordinates = { lat: row.latitude, lng: row.longitude };
  }
  if (images.length === 1) result.image = images[0];
  return result;
}

function getUploadsBaseUrl(req) {
  if (process.env.UPLOADS_BASE_URL) return process.env.UPLOADS_BASE_URL;
  const proto = req.get('x-forwarded-proto') || (req.secure ? 'https' : 'http');
  const host = req.get('x-forwarded-host') || req.get('host') || `localhost:${process.env.PORT || 3000}`;
  if (process.env.UPLOADS_PATH) return `${proto}://${host}`;
  const uploadsPort = process.env.UPLOADS_PORT || process.env.WEBTRIPOLI_PORT || '3001';
  const hostOnly = host.includes(':') ? host.split(':')[0] : host;
  return `${proto}://${hostOnly}:${uploadsPort}`;
}

module.exports = { resolveImageUrls, safeParseJson, rowToPlace, getUploadsBaseUrl };
