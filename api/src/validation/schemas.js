import { z } from 'zod';

// Strict input validation: unknown fields are rejected (.strict()),
// HTML brackets & control characters are refused to block stored-XSS payloads.
const SINGLE_LINE = /^[^<>\u0000-\u001F\u007F]*$/;
const MULTI_LINE = /^[^<>\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]*$/;
const NO_MARKUP = 'Tidak boleh mengandung karakter < > atau karakter kontrol.';

const text = (min, max) => z.string().trim().min(min).max(max).regex(SINGLE_LINE, NO_MARKUP);
const id = z.uuid({ message: 'Format ID tidak valid (UUID).' });
const isoDate = z
  .string()
  .refine((s) => !Number.isNaN(Date.parse(s)) && /(Z|[+-]\d\d:\d\d)$/.test(s), {
    message: 'Harus berupa tanggal ISO-8601 dengan zona waktu (contoh: 2026-10-14T06:00:00Z).',
  });

export const PAYMENT_CHANNELS = ['QRIS', 'BCA', 'BNI', 'BRI', 'MANDIRI'];
export const SHOE_CONDITIONS = ['BNIB', 'BNWD', 'USED_VERY_GOOD', 'USED_GOOD'];
export const MAX_PRICE = 1_000_000_000;

// ---------- Auth ----------
export const registerSchema = z
  .object({
    name: text(2, 60),
    email: z.string().trim().toLowerCase().max(254).pipe(z.email({ message: 'Email tidak valid.' })),
    phone: z
      .string()
      .trim()
      .regex(/^(\+62|0)8\d{8,12}$/, 'Nomor HP harus format Indonesia, contoh 081234567890.')
      .optional(),
    password: z
      .string()
      .min(8, 'Password minimal 8 karakter.')
      .max(72, 'Password maksimal 72 karakter.')
      .regex(/[A-Za-z]/, 'Password harus mengandung huruf.')
      .regex(/\d/, 'Password harus mengandung angka.'),
  })
  .strict();

export const loginSchema = z
  .object({
    email: z.string().trim().toLowerCase().max(254),
    password: z.string().min(1).max(72),
  })
  .strict();

// ---------- Products ----------
const productFields = {
  name: text(3, 80),
  brand: text(2, 40),
  size_us: z
    .number()
    .min(3)
    .max(18)
    .refine((n) => Number.isInteger(n * 2), 'Ukuran harus kelipatan 0.5.'),
  price: z.number().int('Harga harus bilangan bulat rupiah.').min(10_000).max(MAX_PRICE),
  condition: z.enum(SHOE_CONDITIONS),
  description: z.string().trim().max(1000).regex(MULTI_LINE, NO_MARKUP),
  image_urls: z.array(z.url({ protocol: /^https$/, message: 'URL gambar harus https.' })).max(6),
  is_for_sale: z.boolean(),
  is_for_trade: z.boolean(),
};

export const productCreateSchema = z
  .object({
    id: id.optional(),
    ...productFields,
    description: productFields.description.default(''),
    image_urls: productFields.image_urls.default([]),
    is_for_sale: productFields.is_for_sale.default(true),
    is_for_trade: productFields.is_for_trade.default(true),
  })
  .strict()
  .refine((p) => p.is_for_sale || p.is_for_trade, {
    message: 'Produk harus bisa dijual dan/atau ditukar.',
    path: ['is_for_sale'],
  });

export const productUpdateSchema = z
  .object({
    id,
    base_updated_at: isoDate, // version the client edited from -> optimistic concurrency
    name: productFields.name.optional(),
    brand: productFields.brand.optional(),
    size_us: productFields.size_us.optional(),
    price: productFields.price.optional(),
    condition: productFields.condition.optional(),
    description: productFields.description.optional(),
    image_urls: productFields.image_urls.optional(),
    is_for_sale: productFields.is_for_sale.optional(),
    is_for_trade: productFields.is_for_trade.optional(),
  })
  .strict();

export const productDeleteSchema = z.object({ id }).strict();

export const productQuerySchema = z.object({
  q: z.string().trim().max(60).regex(SINGLE_LINE, NO_MARKUP).optional(),
  brand: z.string().trim().max(40).regex(SINGLE_LINE, NO_MARKUP).optional(),
  mode: z.enum(['sale', 'trade']).optional(),
  owner: z.enum(['me']).optional(),
  page: z.coerce.number().int().min(1).max(1000).default(1),
  limit: z.coerce.number().int().min(1).max(50).default(20),
});

// ---------- Trades ----------
export const tradeCreateSchema = z
  .object({
    id: id.optional(),
    offered_product_id: id,
    target_product_id: id,
    cash_adjustment: z.number().int().min(-MAX_PRICE).max(MAX_PRICE).default(0),
    notes: z.string().trim().max(300).regex(MULTI_LINE, NO_MARKUP).default(''),
    client_created_at: isoDate.optional(),
  })
  .strict()
  .refine((t) => t.offered_product_id !== t.target_product_id, {
    message: 'Sepatu yang ditawarkan dan yang diminta tidak boleh sama.',
    path: ['target_product_id'],
  });

export const tradeActionSchema = z
  .object({ id, action: z.enum(['accept', 'reject', 'cancel']) })
  .strict();

// ---------- Transactions ----------
export const transactionCreateSchema = z
  .object({
    id: id.optional(),
    product_id: id.optional(),
    trade_id: id.optional(),
    payment_channel: z.enum(PAYMENT_CHANNELS),
    client_created_at: isoDate.optional(), // when the user pressed "Bayar" (may be offline)
  })
  .strict()
  .refine((t) => Boolean(t.product_id) !== Boolean(t.trade_id), {
    message: 'Isi salah satu: product_id (beli) atau trade_id (selisih trade).',
    path: ['product_id'],
  });

export const transactionQuerySchema = z.object({
  status: z.enum(['PENDING_PAYMENT', 'PAID', 'EXPIRED', 'CANCELLED', 'FAILED']).optional(),
  from: isoDate.optional(),
  to: isoDate.optional(),
});

// ---------- Sync ----------
export const SYNC_OPERATION_TYPES = [
  'PRODUCT_CREATE',
  'PRODUCT_UPDATE',
  'PRODUCT_DELETE',
  'TRADE_CREATE',
  'TRADE_ACTION',
  'TRANSACTION_CREATE',
];

export const syncBatchSchema = z
  .object({
    operations: z
      .array(
        z
          .object({
            idempotency_key: z.string().min(8).max(128),
            type: z.enum(SYNC_OPERATION_TYPES),
            payload: z.record(z.string(), z.unknown()),
          })
          .strict(),
      )
      .min(1)
      .max(50),
  })
  .strict();
