import { getDb } from '../db/database.js';
import { HttpError, conflict, unprocessable } from '../utils/httpError.js';
import { nowIso, sha256, stableStringify } from '../utils/codes.js';

const KEY_PATTERN = /^[A-Za-z0-9_.:-]{8,128}$/;

// 4xx results are deterministic for the same payload, so they are stored and replayed.
// 401/403/429 depend on session/rate state and 5xx are transient -> not stored, retry allowed.
const NON_REPLAYABLE = new Set([401, 403, 429]);

export function assertValidKey(key) {
  if (!KEY_PATTERN.test(key ?? '')) {
    throw new HttpError(
      400,
      'INVALID_IDEMPOTENCY_KEY',
      'Idempotency key wajib diisi (8-128 karakter: huruf, angka, - _ . :).',
    );
  }
}

/** Removes keys left IN_PROGRESS by a crashed process so clients can retry. */
export function releaseStaleKeys() {
  getDb().prepare("DELETE FROM idempotency_keys WHERE state = 'IN_PROGRESS'").run();
}

/**
 * Executes `handler` at most once per (user, key).
 *  - same key + same payload  -> stored response is returned (replayed = true), nothing re-executes
 *  - same key + other payload -> 422 IDEMPOTENCY_KEY_REUSED
 *  - same key still running   -> 409 REQUEST_IN_PROGRESS
 *
 * @returns {Promise<{status:number, body:any, replayed:boolean}>}
 */
export async function runIdempotent({ userId, key, scope, payload }, handler) {
  assertValidKey(key);
  const db = getDb();
  const requestHash = sha256(`${scope}|${stableStringify(payload)}`);

  const existing = db
    .prepare('SELECT * FROM idempotency_keys WHERE user_id = ? AND key = ?')
    .get(userId, key);

  if (existing) {
    if (existing.scope !== scope || existing.request_hash !== requestHash) {
      throw unprocessable(
        'IDEMPOTENCY_KEY_REUSED',
        'Kode unik transaksi ini sudah dipakai untuk permintaan yang berbeda.',
      );
    }
    if (existing.state === 'IN_PROGRESS') {
      throw conflict('REQUEST_IN_PROGRESS', 'Permintaan dengan kode ini sedang diproses. Coba lagi sebentar.');
    }
    return { status: existing.status_code, body: JSON.parse(existing.response_body), replayed: true };
  }

  // No await between SELECT and INSERT -> atomic on Node's single thread; PK guards anyway.
  db.prepare(
    `INSERT INTO idempotency_keys (user_id, key, scope, request_hash, state, created_at)
     VALUES (?, ?, ?, ?, 'IN_PROGRESS', ?)`,
  ).run(userId, key, scope, requestHash, nowIso());

  const store = (status, body) =>
    db
      .prepare(
        `UPDATE idempotency_keys SET state = 'DONE', status_code = ?, response_body = ?
         WHERE user_id = ? AND key = ?`,
      )
      .run(status, JSON.stringify(body), userId, key);

  try {
    const { status, body } = await handler();
    store(status, body);
    return { status, body, replayed: false };
  } catch (err) {
    const replayable =
      err instanceof HttpError && err.status >= 400 && err.status < 500 && !NON_REPLAYABLE.has(err.status);
    if (replayable) {
      store(err.status, {
        error: { code: err.code, message: err.message, ...(err.details ? { details: err.details } : {}) },
      });
    } else {
      db.prepare('DELETE FROM idempotency_keys WHERE user_id = ? AND key = ?').run(userId, key);
    }
    throw err;
  }
}
