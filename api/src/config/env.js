import crypto from 'node:crypto';

// Load ./.env if present (Node >= 21.7). Real environment variables always win.
try {
  process.loadEnvFile();
} catch {
  /* no .env file - rely on process environment */
}

const env = process.env.NODE_ENV ?? 'development';

function resolveJwtSecret() {
  const secret = process.env.JWT_SECRET;
  if (secret && secret.length >= 32) return secret;
  if (env === 'production') {
    throw new Error('JWT_SECRET wajib diisi (minimal 32 karakter) pada mode production.');
  }
  // Dev/test fallback: random per-process secret (tokens invalid after restart).
  console.warn('[config] JWT_SECRET tidak di-set / terlalu pendek. Memakai secret acak sementara.');
  return crypto.randomBytes(48).toString('hex');
}

const xenditSecretKey = process.env.XENDIT_SECRET_KEY?.trim() ?? '';
const xenditCallbackToken = process.env.XENDIT_CALLBACK_TOKEN?.trim() ?? '';

if (xenditSecretKey && !xenditCallbackToken) {
  throw new Error(
    'XENDIT_CALLBACK_TOKEN wajib diisi jika XENDIT_SECRET_KEY di-set, agar webhook pembayaran tidak bisa dipalsukan.',
  );
}

export const config = Object.freeze({
  env,
  isTest: env === 'test',
  port: Number(process.env.PORT ?? 3000),
  dbPath: process.env.DB_PATH ?? './data/kickexchange.db',
  jwtSecret: resolveJwtSecret(),
  jwtExpiresIn: process.env.JWT_EXPIRES_IN ?? '12h',
  paymentExpiryMinutes: Number(process.env.PAYMENT_EXPIRY_MINUTES ?? 15),
  corsOrigins: (process.env.CORS_ORIGINS ?? '*')
    .split(',')
    .map((o) => o.trim())
    .filter(Boolean),
  rateLimitEnabled: process.env.RATE_LIMIT_ENABLED !== 'false',
  // "xendit" when a secret key is configured, otherwise a local simulator.
  paymentMode: xenditSecretKey ? 'xendit' : 'simulator',
  xendit: Object.freeze({
    secretKey: xenditSecretKey,
    callbackToken: xenditCallbackToken,
    baseUrl: process.env.XENDIT_BASE_URL ?? 'https://api.xendit.co',
  }),
});
