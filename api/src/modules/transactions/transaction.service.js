import { config } from '../../config/env.js';
import { getDb, transaction } from '../../db/database.js';
import { conflict, forbidden, notFound, unprocessable } from '../../utils/httpError.js';
import { nowIso, paymentReference, uniqueSuffixCode, uuid } from '../../utils/codes.js';
import { maskAccountNumber, maskEmail, maskPhone } from '../../utils/masking.js';
import { simulatorProvider } from '../payments/providers/simulator.provider.js';
import { xenditProvider } from '../payments/providers/xendit.provider.js';
import { transactionCreateSchema, transactionQuerySchema } from '../../validation/schemas.js';

function getPaymentProvider() {
  return config.paymentMode === 'xendit' ? xenditProvider : simulatorProvider;
}

export function serializeTransaction(row, currentUserId = null) {
  if (!row) return null;
  const isPayer = currentUserId && row.payer_id === currentUserId;
  const isPayee = currentUserId && row.payee_id === currentUserId;
  const isParticipant = isPayer || isPayee;

  let productImages = [];
  try {
    productImages = JSON.parse(row.product_image_urls || '[]');
  } catch {
    productImages = [];
  }

  return {
    id: row.id,
    reference: row.reference,
    idempotency_key: row.idempotency_key,
    type: row.type,
    payer_id: row.payer_id,
    payee_id: row.payee_id,
    product_id: row.product_id,
    trade_id: row.trade_id,
    base_amount: Number(row.base_amount),
    unique_code: Number(row.unique_code),
    total_amount: Number(row.total_amount),
    status: row.status,
    payment_channel: row.payment_channel,
    payment_provider: row.payment_provider,
    provider_payment_id: row.provider_payment_id,
    qr_string: row.qr_string,
    va_number: isParticipant ? row.va_number : maskAccountNumber(row.va_number),
    transaction_date: row.transaction_date,
    expires_at: row.expires_at,
    paid_at: row.paid_at,
    created_at: row.created_at,
    updated_at: row.updated_at,
    payer: {
      id: row.payer_id,
      name: row.payer_name,
      email: isParticipant ? row.payer_email : maskEmail(row.payer_email),
      phone: isParticipant ? row.payer_phone : maskPhone(row.payer_phone),
    },
    payee: {
      id: row.payee_id,
      name: row.payee_name,
      email: isParticipant ? row.payee_email : maskEmail(row.payee_email),
      phone: isParticipant ? row.payee_phone : maskPhone(row.payee_phone),
    },
    product: row.product_id
      ? {
          id: row.product_id,
          name: row.product_name,
          brand: row.product_brand,
          size_us: Number(row.product_size_us),
          price: Number(row.product_price),
          condition: row.product_condition,
          image_urls: productImages,
        }
      : null,
  };
}

const TX_SELECT_SQL = `
  SELECT 
    tx.*,
    u_payer.name as payer_name, u_payer.email as payer_email, u_payer.phone as payer_phone,
    u_payee.name as payee_name, u_payee.email as payee_email, u_payee.phone as payee_phone,
    p.name as product_name, p.brand as product_brand, p.size_us as product_size_us,
    p.price as product_price, p.condition as product_condition, p.image_urls as product_image_urls
  FROM transactions tx
  JOIN users u_payer ON tx.payer_id = u_payer.id
  JOIN users u_payee ON tx.payee_id = u_payee.id
  LEFT JOIN products p ON tx.product_id = p.id
`;

export async function getTransactionById(txId, currentUserId = null) {
  const db = getDb();
  const row = db.prepare(`${TX_SELECT_SQL} WHERE tx.id = ?`).get(txId);
  if (!row) throw notFound('Transaksi');
  return serializeTransaction(row, currentUserId);
}

export async function getTransactionByReference(ref, currentUserId = null) {
  const db = getDb();
  const row = db.prepare(`${TX_SELECT_SQL} WHERE tx.reference = ?`).get(ref);
  if (!row) throw notFound('Transaksi');
  return serializeTransaction(row, currentUserId);
}

export async function listTransactions(user, rawQuery = {}) {
  const query = transactionQuerySchema.parse(rawQuery);
  const db = getDb();

  const conditions = ['(tx.payer_id = ? OR tx.payee_id = ?)'];
  const params = [user.id, user.id];

  if (query.status) {
    conditions.push('tx.status = ?');
    params.push(query.status);
  }
  if (query.from) {
    conditions.push('tx.transaction_date >= ?');
    params.push(query.from);
  }
  if (query.to) {
    conditions.push('tx.transaction_date <= ?');
    params.push(query.to);
  }

  const sql = `${TX_SELECT_SQL} WHERE ${conditions.join(' AND ')} ORDER BY tx.created_at DESC`;
  const rows = db.prepare(sql).all(...params);
  return rows.map((r) => serializeTransaction(r, user.id));
}

export async function createTransaction(user, rawInput, { key } = {}) {
  const input = transactionCreateSchema.parse(rawInput);
  const db = getDb();
  const provider = getPaymentProvider();

  const txId = input.id ?? uuid();
  const existing = db.prepare('SELECT id FROM transactions WHERE id = ?').get(txId);
  if (existing) {
    return getTransactionById(txId, user.id);
  }

  let type = 'PURCHASE';
  let payeeId = null;
  let baseAmount = 0;
  let productId = null;
  let tradeId = null;

  if (input.product_id) {
    const product = db
      .prepare('SELECT * FROM products WHERE id = ? AND deleted_at IS NULL')
      .get(input.product_id);
    if (!product) throw notFound('Produk');
    if (product.owner_id === user.id) {
      throw unprocessable('INVALID_ORDER', 'Tidak bisa membeli produk milik sendiri.');
    }
    if (!product.is_for_sale) {
      throw unprocessable('NOT_FOR_SALE', 'Produk ini tidak untuk dijual.');
    }
    if (product.status !== 'AVAILABLE') {
      throw conflict('PRODUCT_UNAVAILABLE', 'Produk sedang dalam proses transaksi lain atau sudah terjual.');
    }
    type = 'PURCHASE';
    payeeId = product.owner_id;
    baseAmount = product.price;
    productId = product.id;
  } else if (input.trade_id) {
    const trade = db.prepare('SELECT * FROM trades WHERE id = ?').get(input.trade_id);
    if (!trade) throw notFound('Penawaran tukar (trade)');
    if (trade.status !== 'ACCEPTED') {
      throw unprocessable('TRADE_NOT_ACCEPTED', 'Transaksi selisih hanya untuk trade yang telah disetujui (ACCEPTED).');
    }

    const cashAdj = trade.cash_adjustment;
    if (cashAdj === 0) {
      throw unprocessable('NO_CASH_DIFF', 'Trade ini tidak memiliki selisih tunai.');
    }

    if (cashAdj > 0) {
      // Sender pays receiver
      if (user.id !== trade.sender_id) {
        throw forbidden('Hanya penawar (sender) yang harus membayar selisih tunai trade ini.');
      }
      payeeId = trade.receiver_id;
      baseAmount = cashAdj;
    } else {
      // Receiver pays sender
      if (user.id !== trade.receiver_id) {
        throw forbidden('Hanya penerima (receiver) yang harus membayar selisih tunai trade ini.');
      }
      payeeId = trade.sender_id;
      baseAmount = Math.abs(cashAdj);
    }

    type = 'TRADE_CASH_DIFF';
    tradeId = trade.id;
  }

  // Generate unique 3-digit verification code avoiding collisions
  let uniqueCode = uniqueSuffixCode();
  let totalAmount = baseAmount + uniqueCode;
  let attempts = 0;
  while (
    db
      .prepare("SELECT 1 FROM transactions WHERE total_amount = ? AND status = 'PENDING_PAYMENT'")
      .get(totalAmount)
  ) {
    uniqueCode = uniqueSuffixCode();
    totalAmount = baseAmount + uniqueCode;
    attempts += 1;
    if (attempts > 50) {
      throw conflict('TOO_MANY_PENDING', 'Sistem sedang sibuk memproses transaksi. Coba lagi dalam 1 menit.');
    }
  }

  const reference = paymentReference();
  const now = nowIso();
  const txDate = input.client_created_at ?? now;
  const expiresAt = new Date(Date.now() + config.paymentExpiryMinutes * 60 * 1000).toISOString();

  // Call payment provider (Xendit or Simulator)
  const paymentResult = await provider.createPayment({
    channel: input.payment_channel,
    reference,
    amount: totalAmount,
    expiresAt,
    customerName: user.name,
  });

  return transaction(() => {
    // If buying a product, reserve it immediately
    if (productId) {
      db.prepare("UPDATE products SET status = 'RESERVED', updated_at = ? WHERE id = ?").run(now, productId);
    }

    db.prepare(
      `INSERT INTO transactions (
        id, reference, idempotency_key, type, payer_id, payee_id,
        product_id, trade_id, base_amount, unique_code, total_amount,
        status, payment_channel, payment_provider, provider_payment_id,
        qr_string, va_number, transaction_date, expires_at, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'PENDING_PAYMENT', ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    ).run(
      txId,
      reference,
      key ?? reference,
      type,
      user.id,
      payeeId,
      productId,
      tradeId,
      baseAmount,
      uniqueCode,
      totalAmount,
      input.payment_channel,
      provider.name,
      paymentResult.providerPaymentId,
      paymentResult.qrString,
      paymentResult.vaNumber,
      txDate,
      expiresAt,
      now,
      now,
    );

    return getTransactionById(txId, user.id);
  });
}

/**
 * Settlement engine: Called either by Xendit Webhook or Simulator Pay Endpoint.
 * Executes ownership transfer and state transitions atomically.
 */
export async function settleTransaction({ reference, paidAmount, providerPaymentId, source = 'webhook' }) {
  const db = getDb();
  return transaction(() => {
    const tx = db.prepare('SELECT * FROM transactions WHERE reference = ?').get(reference);
    if (!tx) throw notFound('Transaksi');

    if (tx.status === 'PAID') {
      // Idempotent: already paid
      return { success: true, status: 'PAID', already_paid: true, transaction: serializeTransaction(tx) };
    }

    if (tx.status !== 'PENDING_PAYMENT') {
      throw conflict('INVALID_TX_STATUS', `Transaksi berstatus ${tx.status}, tidak dapat diselesaikan.`);
    }

    // Verify paid amount matches expected total amount (prevent underpayment)
    if (paidAmount !== undefined && Number(paidAmount) !== Number(tx.total_amount)) {
      throw unprocessable(
        'AMOUNT_MISMATCH',
        `Nominal bayar (${paidAmount}) tidak sesuai dengan tagihan (${tx.total_amount}).`,
      );
    }

    const now = nowIso();

    // 1. Mark transaction as PAID
    db.prepare(
      `UPDATE transactions SET 
        status = 'PAID', paid_at = ?, provider_payment_id = COALESCE(?, provider_payment_id), updated_at = ?
       WHERE id = ?`,
    ).run(now, providerPaymentId ?? null, now, tx.id);

    // 2. Transfer ownership according to transaction type
    if (tx.type === 'PURCHASE' && tx.product_id) {
      db.prepare(
        `UPDATE products SET 
          owner_id = ?, status = 'AVAILABLE', is_sold = 1, updated_at = ?
         WHERE id = ?`,
      ).run(tx.payer_id, now, tx.product_id);
    } else if (tx.type === 'TRADE_CASH_DIFF' && tx.trade_id) {
      const trade = db.prepare('SELECT * FROM trades WHERE id = ?').get(tx.trade_id);
      if (trade) {
        // Swap sneaker ownerships and complete the trade
        db.prepare("UPDATE products SET owner_id = ?, status = 'AVAILABLE', updated_at = ? WHERE id = ?").run(
          trade.receiver_id,
          now,
          trade.offered_product_id,
        );
        db.prepare("UPDATE products SET owner_id = ?, status = 'AVAILABLE', updated_at = ? WHERE id = ?").run(
          trade.sender_id,
          now,
          trade.target_product_id,
        );
        db.prepare("UPDATE trades SET status = 'COMPLETED', updated_at = ? WHERE id = ?").run(now, trade.id);
      }
    }

    const updatedTx = getTransactionById(tx.id);
    return { success: true, status: 'PAID', already_paid: false, transaction: updatedTx };
  });
}
