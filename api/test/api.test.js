import test from 'node:test';
import assert from 'node:assert/strict';
import { createApp } from '../src/app.js';
import { getDb, closeDb } from '../src/db/database.js';
import { seedDatabase } from '../src/db/seed.js';

let app;
let server;
let baseUrl;

test.before(async () => {
  process.env.NODE_ENV = 'test';
  process.env.DB_PATH = ':memory:';
  process.env.RATE_LIMIT_ENABLED = 'false';
  process.env.JWT_SECRET = 'test-secret-key-that-has-at-least-32-chars-long!';

  const db = getDb();
  db.exec('DELETE FROM transactions; DELETE FROM trades; DELETE FROM products; DELETE FROM users; DELETE FROM idempotency_keys; DELETE FROM webhook_events;');
  await seedDatabase();

  app = createApp();
  await new Promise((resolve) => {
    server = app.listen(0, '127.0.0.1', () => {
      const port = server.address().port;
      baseUrl = `http://127.0.0.1:${port}`;
      resolve();
    });
  });
});

test.after(async () => {
  await new Promise((resolve) => server.close(resolve));
  closeDb();
});

test('1. Health check endpoint returns status UP and simulator mode', async () => {
  const res = await fetch(`${baseUrl}/health`);
  assert.equal(res.status, 200);
  const data = await res.json();
  assert.equal(data.status, 'UP');
  assert.equal(data.payment_mode, 'simulator');
});

test('2. Auth flow: register new user and login', async () => {
  // Register
  const regRes = await fetch(`${baseUrl}/api/v1/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      name: 'Tester Sneaker',
      email: 'tester@kickexchange.com',
      phone: '081299998888',
      password: 'password123',
    }),
  });
  assert.equal(regRes.status, 201);
  const regData = await regRes.json();
  assert.ok(regData.token);
  assert.equal(regData.user.email, 'tester@kickexchange.com');

  // Login
  const loginRes = await fetch(`${baseUrl}/api/v1/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email: 'tester@kickexchange.com',
      password: 'password123',
    }),
  });
  assert.equal(loginRes.status, 200);
  const loginData = await loginRes.json();
  assert.ok(loginData.token);
});

test('3. Product listing and search', async () => {
  const res = await fetch(`${baseUrl}/api/v1/products?q=Jordan`);
  assert.equal(res.status, 200);
  const data = await res.json();
  assert.ok(data.items.length >= 1);
  assert.ok(data.items[0].name.includes('Jordan'));
});

test('4. Idempotent product creation', async () => {
  // Login as seeded user Alvin
  const loginRes = await fetch(`${baseUrl}/api/v1/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'alvin@example.com', password: 'password123' }),
  });
  const { token } = await loginRes.json();

  const idempotencyKey = 'IDEM-PROD-TEST-1001';
  const productPayload = {
    name: 'Nike SB Dunk Low Pro',
    brand: 'Nike',
    size_us: 10.0,
    price: 2100000,
    condition: 'BNIB',
    description: 'Fresh SB Dunks for skate and street.',
    image_urls: ['https://example.com/dunk1.jpg'],
    is_for_sale: true,
    is_for_trade: true,
  };

  // First request: Creates product
  const res1 = await fetch(`${baseUrl}/api/v1/products`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
      'X-Idempotency-Key': idempotencyKey,
    },
    body: JSON.stringify(productPayload),
  });
  assert.equal(res1.status, 201);
  const prod1 = await res1.json();
  assert.equal(prod1.name, 'Nike SB Dunk Low Pro');

  // Second request: Replay with same key -> Returns 201 and Idempotent-Replayed header
  const res2 = await fetch(`${baseUrl}/api/v1/products`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
      'X-Idempotency-Key': idempotencyKey,
    },
    body: JSON.stringify(productPayload),
  });
  assert.equal(res2.status, 201);
  assert.equal(res2.headers.get('idempotent-replayed'), 'true');
  const prod2 = await res2.json();
  assert.equal(prod2.id, prod1.id);
});

test('5. Transaction checkout with 3-digit code & Simulator payment settlement', async () => {
  // Login as Buyer (Reza)
  const buyerRes = await fetch(`${baseUrl}/api/v1/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'reza@example.com', password: 'password123' }),
  });
  const { token: buyerToken, user: buyerUser } = await buyerRes.json();

  // Find a product owned by Budi or Alvin
  const prodRes = await fetch(`${baseUrl}/api/v1/products?q=Zebra`);
  const { items } = await prodRes.json();
  const product = items[0];
  assert.ok(product);

  const txKey = 'IDEM-TX-TEST-2002';
  const checkoutRes = await fetch(`${baseUrl}/api/v1/transactions`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${buyerToken}`,
      'Content-Type': 'application/json',
      'X-Idempotency-Key': txKey,
    },
    body: JSON.stringify({
      product_id: product.id,
      payment_channel: 'QRIS',
    }),
  });
  assert.equal(checkoutRes.status, 201);
  const tx = await checkoutRes.json();

  // Verify extraction of 3-digit unique code and exact total
  assert.ok(tx.unique_code >= 100 && tx.unique_code <= 999);
  assert.equal(tx.total_amount, tx.base_amount + tx.unique_code);
  assert.equal(tx.status, 'PENDING_PAYMENT');
  assert.ok(tx.qr_string.startsWith('000201')); // Valid EMVCo QR string

  // Pay via Simulator
  const payRes = await fetch(`${baseUrl}/api/v1/payments/simulator/${tx.reference}/pay`, {
    method: 'POST',
  });
  assert.equal(payRes.status, 200);
  const payData = await payRes.json();
  assert.equal(payData.result.status, 'PAID');

  // Verify sneaker ownership is transferred to buyer
  const updatedProdRes = await fetch(`${baseUrl}/api/v1/products/${product.id}`);
  const { product: updatedProd } = await updatedProdRes.json();
  assert.equal(updatedProd.owner_id, buyerUser.id);
});

test('6. Batch offline sync engine', async () => {
  const loginRes = await fetch(`${baseUrl}/api/v1/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'alvin@example.com', password: 'password123' }),
  });
  const { token } = await loginRes.json();

  const syncPayload = {
    operations: [
      {
        idempotency_key: 'SYNC-OFFLINE-001',
        type: 'PRODUCT_CREATE',
        payload: {
          name: 'Converse Chuck 70 High Vintage',
          brand: 'Converse',
          size_us: 9.0,
          price: 999000,
          condition: 'BNIB',
          description: 'Offline created item.',
          image_urls: ['https://example.com/chuck.jpg'],
          is_for_sale: true,
          is_for_trade: false,
        },
      },
    ],
  };

  const syncRes = await fetch(`${baseUrl}/api/v1/sync/batch`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(syncPayload),
  });

  assert.equal(syncRes.status, 200);
  const syncData = await syncRes.json();
  assert.equal(syncData.processed, 1);
  assert.equal(syncData.results[0].status, 201);
});
