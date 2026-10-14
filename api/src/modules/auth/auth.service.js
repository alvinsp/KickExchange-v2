import bcrypt from 'bcryptjs';
import { getDb } from '../../db/database.js';
import { signToken } from '../../middlewares/auth.js';
import { HttpError, conflict } from '../../utils/httpError.js';
import { nowIso, uuid } from '../../utils/codes.js';
import { maskEmail, maskPhone } from '../../utils/masking.js';
import { loginSchema, registerSchema } from '../../validation/schemas.js';

// Pre-computed hash so "unknown email" and "wrong password" take the same time.
const DUMMY_HASH = bcrypt.hashSync('dummy-password-for-timing', 10);

export function serializeSelf(user) {
  return {
    id: user.id,
    name: user.name,
    email: user.email,
    phone: user.phone ?? null,
    email_masked: maskEmail(user.email),
    phone_masked: maskPhone(user.phone),
    created_at: user.created_at,
  };
}

export async function register(rawInput) {
  const input = registerSchema.parse(rawInput);
  const db = getDb();
  if (db.prepare('SELECT 1 FROM users WHERE email = ?').get(input.email)) {
    throw conflict('EMAIL_TAKEN', 'Email sudah terdaftar.');
  }
  const user = {
    id: uuid(),
    name: input.name,
    email: input.email,
    phone: input.phone ?? null,
    created_at: nowIso(),
  };
  const hash = await bcrypt.hash(input.password, 12);
  db.prepare(
    'INSERT INTO users (id, name, email, phone, password_hash, created_at) VALUES (?, ?, ?, ?, ?, ?)',
  ).run(user.id, user.name, user.email, user.phone, hash, user.created_at);

  return { token: signToken(user.id), user: serializeSelf(user) };
}

export async function login(rawInput) {
  const input = loginSchema.parse(rawInput);
  const row = getDb().prepare('SELECT * FROM users WHERE email = ?').get(input.email);
  const ok = await bcrypt.compare(input.password, row?.password_hash ?? DUMMY_HASH);
  if (!row || !ok) {
    // Same message for both cases -> no account enumeration.
    throw new HttpError(401, 'INVALID_CREDENTIALS', 'Email atau password salah.');
  }
  return { token: signToken(row.id), user: serializeSelf(row) };
}
