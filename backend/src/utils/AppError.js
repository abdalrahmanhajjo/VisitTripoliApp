/**
 * Operational HTTP errors — passed to Express error middleware for consistent JSON.
 */
class AppError extends Error {
  /**
   * @param {number} statusCode HTTP status
   * @param {string} message Safe client message
   * @param {{ cause?: unknown }} [opts]
   */
  constructor(statusCode, message, opts = {}) {
    super(message);
    this.name = 'AppError';
    this.statusCode = statusCode;
    this.isOperational = true;
    /** @type {string | null} Optional stable machine-readable code for clients (e.g. VALIDATION_ERROR). */
    this.code = opts.code != null ? String(opts.code) : null;
    if (opts.cause) this.cause = opts.cause;
    Error.captureStackTrace?.(this, this.constructor);
  }
}

module.exports = { AppError };
