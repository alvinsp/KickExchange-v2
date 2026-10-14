// Server-side schema. Money is stored as INTEGER rupiah (never floating point).
export const SCHEMA_SQL = `
CREATE TABLE IF NOT EXISTS users (
  id            TEXT PRIMARY KEY,
  name          TEXT NOT NULL,
  email         TEXT NOT NULL UNIQUE,
  phone         TEXT,
  password_hash TEXT NOT NULL,
  created_at    TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS products (
  id           TEXT PRIMARY KEY,
  owner_id     TEXT NOT NULL REFERENCES users(id),
  name         TEXT NOT NULL,
  brand        TEXT NOT NULL,
  size_us      REAL NOT NULL,
  price        INTEGER NOT NULL CHECK (price > 0),
  condition    TEXT NOT NULL,
  description  TEXT NOT NULL DEFAULT '',
  image_urls   TEXT NOT NULL DEFAULT '[]',
  is_for_sale  INTEGER NOT NULL DEFAULT 1,
  is_for_trade INTEGER NOT NULL DEFAULT 1,
  is_sold      INTEGER NOT NULL DEFAULT 0,
  status       TEXT NOT NULL DEFAULT 'AVAILABLE', -- AVAILABLE | RESERVED | SOLD
  created_at   TEXT NOT NULL,
  updated_at   TEXT NOT NULL,
  deleted_at   TEXT
);
CREATE INDEX IF NOT EXISTS idx_products_owner ON products(owner_id);
CREATE INDEX IF NOT EXISTS idx_products_status ON products(status);

CREATE TABLE IF NOT EXISTS trades (
  id                 TEXT PRIMARY KEY,
  sender_id          TEXT NOT NULL REFERENCES users(id),
  receiver_id        TEXT NOT NULL REFERENCES users(id),
  offered_product_id TEXT NOT NULL REFERENCES products(id),
  target_product_id  TEXT NOT NULL REFERENCES products(id),
  cash_adjustment    INTEGER NOT NULL DEFAULT 0, -- >0 sender pays receiver, <0 receiver pays sender
  notes              TEXT NOT NULL DEFAULT '',
  status             TEXT NOT NULL, -- PENDING | ACCEPTED | REJECTED | CANCELLED | COMPLETED
  client_created_at  TEXT,
  created_at         TEXT NOT NULL,
  updated_at         TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_trades_sender ON trades(sender_id);
CREATE INDEX IF NOT EXISTS idx_trades_receiver ON trades(receiver_id);

CREATE TABLE IF NOT EXISTS transactions (
  id                  TEXT PRIMARY KEY,
  reference           TEXT NOT NULL UNIQUE, -- sent to Xendit as reference_id / external_id
  idempotency_key     TEXT NOT NULL,
  type                TEXT NOT NULL, -- PURCHASE | TRADE_CASH_DIFF
  payer_id            TEXT NOT NULL REFERENCES users(id),
  payee_id            TEXT NOT NULL REFERENCES users(id),
  product_id          TEXT REFERENCES products(id),
  trade_id            TEXT REFERENCES trades(id),
  base_amount         INTEGER NOT NULL CHECK (base_amount > 0),
  unique_code         INTEGER NOT NULL CHECK (unique_code BETWEEN 100 AND 999),
  total_amount        INTEGER NOT NULL,
  status              TEXT NOT NULL, -- PENDING_PAYMENT | PAID | EXPIRED | CANCELLED | FAILED
  payment_channel     TEXT NOT NULL, -- QRIS | BCA | BNI | BRI | MANDIRI
  payment_provider    TEXT NOT NULL, -- xendit | simulator
  provider_payment_id TEXT,
  qr_string           TEXT,
  va_number           TEXT,
  review_note         TEXT,
  transaction_date    TEXT NOT NULL,
  expires_at          TEXT NOT NULL,
  paid_at             TEXT,
  created_at          TEXT NOT NULL,
  updated_at          TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_tx_payer ON transactions(payer_id);
CREATE INDEX IF NOT EXISTS idx_tx_payee ON transactions(payee_id);
CREATE INDEX IF NOT EXISTS idx_tx_status ON transactions(status);
-- Two open bills can never share the same total -> the 3-digit code always identifies one bill.
CREATE UNIQUE INDEX IF NOT EXISTS idx_tx_open_total
  ON transactions(total_amount) WHERE status = 'PENDING_PAYMENT';

-- Every mutating request (direct or via offline sync) is recorded here.
-- A replayed key returns the stored response instead of executing again.
CREATE TABLE IF NOT EXISTS idempotency_keys (
  user_id       TEXT NOT NULL,
  key           TEXT NOT NULL,
  scope         TEXT NOT NULL,
  request_hash  TEXT NOT NULL,
  state         TEXT NOT NULL, -- IN_PROGRESS | DONE
  status_code   INTEGER,
  response_body TEXT,
  created_at    TEXT NOT NULL,
  PRIMARY KEY (user_id, key)
);

-- Payment-provider callbacks are processed exactly once.
CREATE TABLE IF NOT EXISTS webhook_events (
  event_key   TEXT PRIMARY KEY,
  source      TEXT NOT NULL,
  reference   TEXT,
  payload     TEXT NOT NULL,
  outcome     TEXT NOT NULL,
  received_at TEXT NOT NULL
);
`;
