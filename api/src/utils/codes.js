import crypto from 'node:crypto';

export const uuid = () => crypto.randomUUID();
export const nowIso = () => new Date().toISOString();

/** Cryptographically secure 3-digit code in [100, 999]. */
export const uniqueSuffixCode = () => crypto.randomInt(100, 1000);

/** Human-friendly, unique payment reference, e.g. KX-20261014-7F3A9C12. */
export function paymentReference(date = new Date()) {
  const ymd = date.toISOString().slice(0, 10).replaceAll('-', '');
  return `KX-${ymd}-${crypto.randomBytes(4).toString('hex').toUpperCase()}`;
}

/** Deterministic JSON (sorted keys) so identical payloads hash identically. */
export function stableStringify(value) {
  if (value === undefined) return 'null';
  if (value === null || typeof value !== 'object') return JSON.stringify(value);
  if (Array.isArray(value)) return `[${value.map(stableStringify).join(',')}]`;
  const keys = Object.keys(value)
    .filter((k) => value[k] !== undefined)
    .sort();
  return `{${keys.map((k) => `${JSON.stringify(k)}:${stableStringify(value[k])}`).join(',')}}`;
}

export const sha256 = (input) => crypto.createHash('sha256').update(input).digest('hex');

/** Constant-time string comparison (for webhook tokens). */
export function safeEqual(a, b) {
  const bufA = Buffer.from(String(a ?? ''));
  const bufB = Buffer.from(String(b ?? ''));
  if (bufA.length !== bufB.length) return false;
  return crypto.timingSafeEqual(bufA, bufB);
}
