import { config } from '../../../config/env.js';
import { HttpError } from '../../../utils/httpError.js';

// Thin Xendit REST client (no SDK). Docs:
//  - QRIS:  POST /qr_codes                 (header api-version: 2022-07-31)
//  - VA:    POST /callback_virtual_accounts (fixed, closed amount, single use)
// Auth: HTTP Basic with the secret key as username and an empty password.

async function xenditPost(path, body, extraHeaders = {}) {
  const auth = Buffer.from(`${config.xendit.secretKey}:`).toString('base64');
  let res;
  try {
    res = await fetch(`${config.xendit.baseUrl}${path}`, {
      method: 'POST',
      headers: {
        Authorization: `Basic ${auth}`,
        'Content-Type': 'application/json',
        ...extraHeaders,
      },
      body: JSON.stringify(body),
      signal: AbortSignal.timeout(15_000),
    });
  } catch (err) {
    throw new HttpError(502, 'PAYMENT_PROVIDER_UNREACHABLE', 'Gateway pembayaran tidak dapat dihubungi. Coba lagi.', {
      reason: err?.name,
    });
  }
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    console.error('[xendit] error', res.status, data);
    throw new HttpError(502, 'PAYMENT_PROVIDER_ERROR', 'Gateway pembayaran menolak permintaan. Coba lagi nanti.', {
      provider_code: data?.error_code,
    });
  }
  return data;
}

/** Xendit only accepts alphabetic names for VA display. */
const vaDisplayName = (name) => {
  const clean = String(name ?? '')
    .replace(/[^A-Za-z ]/g, '')
    .trim();
  return clean.length >= 3 ? clean.slice(0, 50) : 'KickExchange Customer';
};

export const xenditProvider = {
  name: 'xendit',
  async createPayment({ channel, reference, amount, expiresAt, customerName }) {
    if (channel === 'QRIS') {
      const qr = await xenditPost(
        '/qr_codes',
        {
          reference_id: reference,
          type: 'DYNAMIC',
          currency: 'IDR',
          amount,
          expires_at: expiresAt,
        },
        { 'api-version': '2022-07-31', 'idempotency-key': reference },
      );
      return { providerPaymentId: qr.id, qrString: qr.qr_string, vaNumber: null };
    }

    const va = await xenditPost(
      '/callback_virtual_accounts',
      {
        external_id: reference,
        bank_code: channel,
        name: vaDisplayName(customerName),
        is_closed: true,
        expected_amount: amount,
        is_single_use: true,
        expiration_date: expiresAt,
      },
      { 'x-idempotency-key': reference },
    );
    return { providerPaymentId: va.id, qrString: null, vaNumber: va.account_number };
  },
};
