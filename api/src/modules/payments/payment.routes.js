import { Router } from 'express';
import { config } from '../../config/env.js';
import { getDb } from '../../db/database.js';
import { HttpError, forbidden, unprocessable } from '../../utils/httpError.js';
import { nowIso, safeEqual } from '../../utils/codes.js';
import { settleTransaction } from '../transactions/transaction.service.js';

const router = Router();

// Xendit Webhook Endpoint: receives callbacks for QRIS and Bank VA payments
router.post('/webhook/xendit', async (req, res, next) => {
  try {
    const callbackToken = req.get('x-callback-token') ?? '';
    if (!config.xendit.callbackToken || !safeEqual(callbackToken, config.xendit.callbackToken)) {
      throw forbidden('Token callback tidak valid.');
    }

    const payload = req.body;
    let reference = null;
    let paidAmount = undefined;
    let providerPaymentId = null;
    let eventKey = null;

    if (payload?.event === 'qr.payment') {
      // QRIS Paid event
      if (payload?.data?.status !== 'SUCCEEDED') {
        return res.json({ status: 'IGNORED', message: `Status QRIS ${payload?.data?.status}` });
      }
      reference = payload.data.reference_id;
      paidAmount = payload.data.amount;
      providerPaymentId = payload.data.id;
      eventKey = `qr_${providerPaymentId}`;
    } else if (payload?.external_id) {
      // Virtual Account Paid event
      reference = payload.external_id;
      paidAmount = payload.amount;
      providerPaymentId = payload.id || payload.payment_id;
      eventKey = `va_${providerPaymentId || reference}`;
    } else {
      throw unprocessable('UNRECOGNIZED_WEBHOOK', 'Format payload webhook tidak dikenali.');
    }

    // Record webhook event to prevent duplicate processing
    const db = getDb();
    const existing = db.prepare('SELECT outcome FROM webhook_events WHERE event_key = ?').get(eventKey);
    if (existing) {
      return res.json({ status: 'ALREADY_PROCESSED', outcome: existing.outcome });
    }

    const result = await settleTransaction({
      reference,
      paidAmount,
      providerPaymentId,
      source: 'xendit_webhook',
    });

    db.prepare(
      `INSERT INTO webhook_events (event_key, source, reference, payload, outcome, received_at)
       VALUES (?, 'xendit', ?, ?, ?, ?)`,
    ).run(eventKey, reference, JSON.stringify(payload), result.status, nowIso());

    res.json({ status: 'SUCCESS', transaction_status: result.status });
  } catch (err) {
    next(err);
  }
});

// Simulator Pay Endpoint: simulates scanning QR or paying VA at ATM/m-banking
router.post('/simulator/:reference/pay', async (req, res, next) => {
  try {
    const { reference } = req.params;
    const result = await settleTransaction({
      reference,
      source: 'simulator',
    });
    res.json({
      message: 'Pembayaran simulator berhasil diverifikasi.',
      result,
    });
  } catch (err) {
    next(err);
  }
});

export default router;
