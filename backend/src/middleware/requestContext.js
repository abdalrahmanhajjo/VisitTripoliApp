/**
 * Correlates logs and error responses with a stable request id (propagates X-Request-Id or generates one).
 */
const crypto = require('crypto');

const ID_RE = /^[a-zA-Z0-9_-]{8,128}$/;

function requestContext(req, res, next) {
  const headerId = req.get('x-request-id');
  const id =
    headerId && typeof headerId === 'string' && ID_RE.test(headerId.trim())
      ? headerId.trim()
      : crypto.randomUUID();
  req.requestId = id;
  res.setHeader('X-Request-Id', id);
  next();
}

module.exports = { requestContext };
