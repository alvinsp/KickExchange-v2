import jwt from 'jsonwebtoken';
import { config } from '../config/env.js';
import { getDb } from '../db/database.js';
import { HttpError } from '../utils/httpError.js';

export function signToken(userId) {
  return jwt.sign({ sub: userId }, config.jwtSecret, {
    algorithm: 'HS256',
    expiresIn: config.jwtExpiresIn,
  });
}

export function requireAuth(req, _res, next) {
  const header = req.get('authorization') ?? '';
  const [scheme, token] = header.split(' ');
  if (scheme !== 'Bearer' || !token) {
    return next(new HttpError(401, 'UNAUTHENTICATED', 'Silakan login terlebih dahulu.'));
  }
  let payload;
  try {
    payload = jwt.verify(token, config.jwtSecret, { algorithms: ['HS256'] });
  } catch (err) {
    const code = err?.name === 'TokenExpiredError' ? 'TOKEN_EXPIRED' : 'INVALID_TOKEN';
    return next(new HttpError(401, code, 'Sesi tidak valid atau sudah berakhir. Silakan login ulang.'));
  }
  const user = getDb()
    .prepare('SELECT id, name, email, phone, created_at FROM users WHERE id = ?')
    .get(payload.sub);
  if (!user) return next(new HttpError(401, 'INVALID_TOKEN', 'Akun tidak ditemukan.'));
  req.user = { ...user };
  return next();
}
