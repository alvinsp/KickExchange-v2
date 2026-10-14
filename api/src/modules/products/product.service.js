import { getDb } from '../../db/database.js';
import { conflict, forbidden, notFound } from '../../utils/httpError.js';
import { nowIso, uuid } from '../../utils/codes.js';
import { maskEmail, maskPhone } from '../../utils/masking.js';
import {
  productCreateSchema,
  productDeleteSchema,
  productQuerySchema,
  productUpdateSchema,
} from '../../validation/schemas.js';

export function serializeProduct(row, currentUserId = null) {
  if (!row) return null;
  const isOwner = currentUserId && row.owner_id === currentUserId;
  let imageUrls = [];
  try {
    imageUrls = JSON.parse(row.image_urls || '[]');
  } catch {
    imageUrls = [];
  }

  return {
    id: row.id,
    owner_id: row.owner_id,
    name: row.name,
    brand: row.brand,
    size_us: Number(row.size_us),
    price: Number(row.price),
    condition: row.condition,
    description: row.description || '',
    image_urls: imageUrls,
    is_for_sale: Boolean(row.is_for_sale),
    is_for_trade: Boolean(row.is_for_trade),
    status: row.status,
    created_at: row.created_at,
    updated_at: row.updated_at,
    owner: {
      id: row.owner_id,
      name: row.owner_name,
      email: isOwner ? row.owner_email : maskEmail(row.owner_email),
      phone: isOwner ? row.owner_phone : maskPhone(row.owner_phone),
    },
  };
}

export async function listProducts(rawQuery, currentUserId = null) {
  const query = productQuerySchema.parse(rawQuery);
  const db = getDb();

  const conditions = ['p.deleted_at IS NULL'];
  const params = [];

  if (query.owner === 'me') {
    if (!currentUserId) throw forbidden('Silakan login untuk melihat produk Anda.');
    conditions.push('p.owner_id = ?');
    params.push(currentUserId);
  } else {
    // Only show available sneakers on public market
    conditions.push("p.status = 'AVAILABLE'");
  }

  if (query.brand) {
    conditions.push('LOWER(p.brand) = LOWER(?)');
    params.push(query.brand);
  }

  if (query.mode === 'sale') {
    conditions.push('p.is_for_sale = 1');
  } else if (query.mode === 'trade') {
    conditions.push('p.is_for_trade = 1');
  }

  if (query.q) {
    conditions.push('(LOWER(p.name) LIKE ? OR LOWER(p.brand) LIKE ?)');
    const term = `%${query.q.toLowerCase()}%`;
    params.push(term, term);
  }

  const whereClause = conditions.join(' AND ');

  const totalRow = db
    .prepare(`SELECT COUNT(*) as count FROM products p WHERE ${whereClause}`)
    .get(...params);
  const total = Number(totalRow.count);

  const offset = (query.page - 1) * query.limit;
  const sql = `
    SELECT p.*, u.name as owner_name, u.email as owner_email, u.phone as owner_phone
    FROM products p
    JOIN users u ON p.owner_id = u.id
    WHERE ${whereClause}
    ORDER BY p.created_at DESC
    LIMIT ? OFFSET ?
  `;

  const rows = db.prepare(sql).all(...params, query.limit, offset);
  const items = rows.map((row) => serializeProduct(row, currentUserId));

  return {
    items,
    pagination: {
      page: query.page,
      limit: query.limit,
      total,
      total_pages: Math.ceil(total / query.limit) || 1,
    },
  };
}

export async function getProductById(id, currentUserId = null) {
  const db = getDb();
  const sql = `
    SELECT p.*, u.name as owner_name, u.email as owner_email, u.phone as owner_phone
    FROM products p
    JOIN users u ON p.owner_id = u.id
    WHERE p.id = ? AND p.deleted_at IS NULL
  `;
  const row = db.prepare(sql).get(id);
  if (!row) throw notFound('Produk');
  return serializeProduct(row, currentUserId);
}

export async function createProduct(user, rawInput) {
  const input = productCreateSchema.parse(rawInput);
  const db = getDb();

  const productId = input.id ?? uuid();
  const now = nowIso();

  // If this ID already exists, avoid duplicate constraint violation (e.g. offline sync replay)
  const existing = db.prepare('SELECT id FROM products WHERE id = ?').get(productId);
  if (existing) {
    return getProductById(productId, user.id);
  }

  db.prepare(
    `INSERT INTO products (
      id, owner_id, name, brand, size_us, price, condition,
      description, image_urls, is_for_sale, is_for_trade, status,
      created_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'AVAILABLE', ?, ?)`,
  ).run(
    productId,
    user.id,
    input.name,
    input.brand,
    input.size_us,
    input.price,
    input.condition,
    input.description,
    JSON.stringify(input.image_urls),
    input.is_for_sale ? 1 : 0,
    input.is_for_trade ? 1 : 0,
    now,
    now,
  );

  return getProductById(productId, user.id);
}

export async function updateProduct(user, rawInput) {
  const input = productUpdateSchema.parse(rawInput);
  const db = getDb();

  const existing = db
    .prepare('SELECT * FROM products WHERE id = ? AND deleted_at IS NULL')
    .get(input.id);
  if (!existing) throw notFound('Produk');

  if (existing.owner_id !== user.id) {
    throw forbidden('Anda bukan pemilik produk ini.');
  }

  // Optimistic concurrency check (vital for offline edits)
  if (existing.updated_at !== input.base_updated_at) {
    throw conflict(
      'VERSION_CONFLICT',
      'Produk telah diubah di server sejak terakhir kali Anda menyimpannya. Silakan perbarui data terlebih dahulu.',
      {
        server_updated_at: existing.updated_at,
        client_base_updated_at: input.base_updated_at,
      },
    );
  }

  const updates = [];
  const params = [];

  if (input.name !== undefined) {
    updates.push('name = ?');
    params.push(input.name);
  }
  if (input.brand !== undefined) {
    updates.push('brand = ?');
    params.push(input.brand);
  }
  if (input.size_us !== undefined) {
    updates.push('size_us = ?');
    params.push(input.size_us);
  }
  if (input.price !== undefined) {
    updates.push('price = ?');
    params.push(input.price);
  }
  if (input.condition !== undefined) {
    updates.push('condition = ?');
    params.push(input.condition);
  }
  if (input.description !== undefined) {
    updates.push('description = ?');
    params.push(input.description);
  }
  if (input.image_urls !== undefined) {
    updates.push('image_urls = ?');
    params.push(JSON.stringify(input.image_urls));
  }
  if (input.is_for_sale !== undefined) {
    updates.push('is_for_sale = ?');
    params.push(input.is_for_sale ? 1 : 0);
  }
  if (input.is_for_trade !== undefined) {
    updates.push('is_for_trade = ?');
    params.push(input.is_for_trade ? 1 : 0);
  }

  const now = nowIso();
  updates.push('updated_at = ?');
  params.push(now);

  params.push(input.id);
  db.prepare(`UPDATE products SET ${updates.join(', ')} WHERE id = ?`).run(...params);

  return getProductById(input.id, user.id);
}

export async function deleteProduct(user, rawInput) {
  const input = productDeleteSchema.parse(rawInput);
  const db = getDb();

  const existing = db
    .prepare('SELECT * FROM products WHERE id = ? AND deleted_at IS NULL')
    .get(input.id);
  if (!existing) throw notFound('Produk');

  if (existing.owner_id !== user.id) {
    throw forbidden('Anda bukan pemilik produk ini.');
  }

  const now = nowIso();
  db.prepare('UPDATE products SET deleted_at = ?, updated_at = ? WHERE id = ?').run(
    now,
    now,
    input.id,
  );

  return { success: true, id: input.id, deleted_at: now };
}
