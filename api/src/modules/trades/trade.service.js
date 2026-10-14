import { getDb, transaction } from '../../db/database.js';
import { conflict, forbidden, notFound, unprocessable } from '../../utils/httpError.js';
import { nowIso, uuid } from '../../utils/codes.js';
import { maskEmail, maskPhone } from '../../utils/masking.js';
import { tradeActionSchema, tradeCreateSchema } from '../../validation/schemas.js';

export function serializeTrade(row, currentUserId = null) {
  if (!row) return null;
  const isSender = currentUserId && row.sender_id === currentUserId;
  const isReceiver = currentUserId && row.receiver_id === currentUserId;
  const isParticipant = isSender || isReceiver;

  let offeredImages = [];
  let targetImages = [];
  try {
    offeredImages = JSON.parse(row.offered_image_urls || '[]');
  } catch {
    offeredImages = [];
  }
  try {
    targetImages = JSON.parse(row.target_image_urls || '[]');
  } catch {
    targetImages = [];
  }

  return {
    id: row.id,
    sender_id: row.sender_id,
    receiver_id: row.receiver_id,
    offered_product_id: row.offered_product_id,
    target_product_id: row.target_product_id,
    cash_adjustment: Number(row.cash_adjustment),
    notes: row.notes || '',
    status: row.status,
    client_created_at: row.client_created_at,
    created_at: row.created_at,
    updated_at: row.updated_at,
    sender: {
      id: row.sender_id,
      name: row.sender_name,
      email: isParticipant ? row.sender_email : maskEmail(row.sender_email),
      phone: isParticipant ? row.sender_phone : maskPhone(row.sender_phone),
    },
    receiver: {
      id: row.receiver_id,
      name: row.receiver_name,
      email: isParticipant ? row.receiver_email : maskEmail(row.receiver_email),
      phone: isParticipant ? row.receiver_phone : maskPhone(row.receiver_phone),
    },
    offered_product: {
      id: row.offered_product_id,
      name: row.offered_name,
      brand: row.offered_brand,
      size_us: Number(row.offered_size_us),
      price: Number(row.offered_price),
      condition: row.offered_condition,
      image_urls: offeredImages,
    },
    target_product: {
      id: row.target_product_id,
      name: row.target_name,
      brand: row.target_brand,
      size_us: Number(row.target_size_us),
      price: Number(row.target_price),
      condition: row.target_condition,
      image_urls: targetImages,
    },
  };
}

const TRADE_SELECT_SQL = `
  SELECT 
    t.*,
    u_send.name as sender_name, u_send.email as sender_email, u_send.phone as sender_phone,
    u_recv.name as receiver_name, u_recv.email as receiver_email, u_recv.phone as receiver_phone,
    p_off.name as offered_name, p_off.brand as offered_brand, p_off.size_us as offered_size_us,
    p_off.price as offered_price, p_off.condition as offered_condition, p_off.image_urls as offered_image_urls,
    p_tar.name as target_name, p_tar.brand as target_brand, p_tar.size_us as target_size_us,
    p_tar.price as target_price, p_tar.condition as target_condition, p_tar.image_urls as target_image_urls
  FROM trades t
  JOIN users u_send ON t.sender_id = u_send.id
  JOIN users u_recv ON t.receiver_id = u_recv.id
  JOIN products p_off ON t.offered_product_id = p_off.id
  JOIN products p_tar ON t.target_product_id = p_tar.id
`;

export async function getTradeById(tradeId, currentUserId = null) {
  const db = getDb();
  const row = db.prepare(`${TRADE_SELECT_SQL} WHERE t.id = ?`).get(tradeId);
  if (!row) throw notFound('Penawaran tukar (trade)');
  return serializeTrade(row, currentUserId);
}

export async function listTrades(user, type = 'all') {
  const db = getDb();
  const conditions = [];
  const params = [];

  if (type === 'incoming') {
    conditions.push('t.receiver_id = ?');
    params.push(user.id);
  } else if (type === 'outgoing') {
    conditions.push('t.sender_id = ?');
    params.push(user.id);
  } else {
    conditions.push('(t.sender_id = ? OR t.receiver_id = ?)');
    params.push(user.id, user.id);
  }

  const sql = `${TRADE_SELECT_SQL} WHERE ${conditions.join(' AND ')} ORDER BY t.created_at DESC`;
  const rows = db.prepare(sql).all(...params);
  return rows.map((r) => serializeTrade(r, user.id));
}

export async function createTrade(user, rawInput) {
  const input = tradeCreateSchema.parse(rawInput);
  const db = getDb();

  return transaction(() => {
    const tradeId = input.id ?? uuid();

    // Check idempotency / already existing record
    const existing = db.prepare('SELECT id FROM trades WHERE id = ?').get(tradeId);
    if (existing) {
      return getTradeById(tradeId, user.id);
    }

    const offered = db
      .prepare('SELECT * FROM products WHERE id = ? AND deleted_at IS NULL')
      .get(input.offered_product_id);
    if (!offered) throw notFound('Sepatu yang Anda tawarkan');

    const target = db
      .prepare('SELECT * FROM products WHERE id = ? AND deleted_at IS NULL')
      .get(input.target_product_id);
    if (!target) throw notFound('Sepatu yang ingin ditukar');

    if (offered.owner_id !== user.id) {
      throw forbidden('Sepatu yang ditawarkan harus milik Anda sendiri.');
    }
    if (target.owner_id === user.id) {
      throw unprocessable('INVALID_TRADE', 'Tidak bisa menukar dengan sepatu milik Anda sendiri.');
    }
    if (!offered.is_for_trade) {
      throw unprocessable('NOT_FOR_TRADE', 'Sepatu Anda belum diaktifkan opsi tukarnya.');
    }
    if (!target.is_for_trade) {
      throw unprocessable('NOT_FOR_TRADE', 'Sepatu target tidak tersedia untuk barter.');
    }
    if (offered.status !== 'AVAILABLE') {
      throw conflict('PRODUCT_UNAVAILABLE', 'Sepatu yang Anda tawarkan sedang dalam transaksi lain.');
    }
    if (target.status !== 'AVAILABLE') {
      throw conflict('PRODUCT_UNAVAILABLE', 'Sepatu target sedang tidak tersedia.');
    }

    const now = nowIso();
    db.prepare(
      `INSERT INTO trades (
        id, sender_id, receiver_id, offered_product_id, target_product_id,
        cash_adjustment, notes, status, client_created_at, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, 'PENDING', ?, ?, ?)`,
    ).run(
      tradeId,
      user.id,
      target.owner_id,
      input.offered_product_id,
      input.target_product_id,
      input.cash_adjustment,
      input.notes,
      input.client_created_at ?? now,
      now,
      now,
    );

    return getTradeById(tradeId, user.id);
  });
}

export async function applyTradeAction(user, rawInput) {
  const input = tradeActionSchema.parse(rawInput);
  const db = getDb();

  return transaction(() => {
    const trade = db.prepare('SELECT * FROM trades WHERE id = ?').get(input.id);
    if (!trade) throw notFound('Penawaran tukar (trade)');

    if (trade.status !== 'PENDING') {
      throw conflict('TRADE_NOT_PENDING', `Penawaran sudah berstatus ${trade.status}.`);
    }

    const now = nowIso();

    if (input.action === 'cancel') {
      if (trade.sender_id !== user.id) {
        throw forbidden('Hanya pengirim yang dapat membatalkan penawaran ini.');
      }
      db.prepare("UPDATE trades SET status = 'CANCELLED', updated_at = ? WHERE id = ?").run(
        now,
        input.id,
      );
    } else if (input.action === 'reject') {
      if (trade.receiver_id !== user.id) {
        throw forbidden('Hanya penerima yang dapat menolak penawaran ini.');
      }
      db.prepare("UPDATE trades SET status = 'REJECTED', updated_at = ? WHERE id = ?").run(
        now,
        input.id,
      );
    } else if (input.action === 'accept') {
      if (trade.receiver_id !== user.id) {
        throw forbidden('Hanya penerima yang dapat menerima penawaran ini.');
      }

      // Check availability of both sneakers
      const offered = db.prepare('SELECT status FROM products WHERE id = ?').get(trade.offered_product_id);
      const target = db.prepare('SELECT status FROM products WHERE id = ?').get(trade.target_product_id);

      if (offered?.status !== 'AVAILABLE' || target?.status !== 'AVAILABLE') {
        throw conflict(
          'PRODUCTS_NO_LONGER_AVAILABLE',
          'Salah satu sepatu sudah tidak tersedia atau sedang dalam proses transaksi lain.',
        );
      }

      // If cash_adjustment == 0, direct barter swap (status COMPLETED and swap owners)
      if (trade.cash_adjustment === 0) {
        db.prepare("UPDATE products SET owner_id = ?, updated_at = ? WHERE id = ?").run(
          trade.receiver_id,
          now,
          trade.offered_product_id,
        );
        db.prepare("UPDATE products SET owner_id = ?, updated_at = ? WHERE id = ?").run(
          trade.sender_id,
          now,
          trade.target_product_id,
        );
        db.prepare("UPDATE trades SET status = 'COMPLETED', updated_at = ? WHERE id = ?").run(
          now,
          input.id,
        );
      } else {
        // If cash adjustment is needed, mark ACCEPTED and reserve both products until cash diff is paid
        db.prepare("UPDATE products SET status = 'RESERVED', updated_at = ? WHERE id IN (?, ?)").run(
          now,
          trade.offered_product_id,
          trade.target_product_id,
        );
        db.prepare("UPDATE trades SET status = 'ACCEPTED', updated_at = ? WHERE id = ?").run(
          now,
          input.id,
        );
      }
    }

    return getTradeById(input.id, user.id);
  });
}
