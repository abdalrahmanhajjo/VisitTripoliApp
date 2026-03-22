/**
 * Get request language for DB-stored translations: ?lang= or Accept-Language.
 * Returns 'en', 'ar', or 'fr'. Used to select from *_translations tables.
 */
function getRequestLang(req) {
  const q = req.query && req.query.lang;
  if (q && typeof q === 'string') {
    const code = q.trim().toLowerCase().split('-')[0];
    if (code && code.length === 2) return code;
  }
  const accept = req.get('accept-language');
  if (accept && typeof accept === 'string') {
    const first = accept.split(',')[0].trim().toLowerCase().split('-')[0];
    if (first && first.length === 2) return first;
  }
  return 'en';
}

module.exports = { getRequestLang };
