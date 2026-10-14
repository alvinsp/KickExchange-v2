import { z } from 'zod';
import { HttpError } from '../utils/httpError.js';

export function notFoundHandler(req, _res, next) {
  next(new HttpError(404, 'ROUTE_NOT_FOUND', `Endpoint ${req.method} ${req.path} tidak ditemukan.`));
}

// eslint-disable-next-line no-unused-vars
export function errorHandler(err, req, res, _next) {
  if (err instanceof z.ZodError) {
    return res.status(400).json({
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Input tidak valid.',
        details: err.issues.map((i) => ({ field: i.path.join('.'), message: i.message })),
      },
    });
  }
  if (err instanceof HttpError) {
    return res.status(err.status).json({
      error: { code: err.code, message: err.message, ...(err.details ? { details: err.details } : {}) },
    });
  }
  if (err?.type === 'entity.parse.failed') {
    return res.status(400).json({ error: { code: 'MALFORMED_JSON', message: 'Body JSON tidak valid.' } });
  }
  if (err?.type === 'entity.too.large') {
    return res.status(413).json({ error: { code: 'PAYLOAD_TOO_LARGE', message: 'Ukuran request terlalu besar.' } });
  }

  // Unknown error: log server-side, never leak internals to the client.
  console.error(`[error] ${req.method} ${req.originalUrl}`, err);
  return res.status(500).json({ error: { code: 'INTERNAL_ERROR', message: 'Terjadi kesalahan pada server.' } });
}
