import bcrypt from 'bcryptjs';
import { getDb } from './database.js';
import { nowIso, uuid } from '../utils/codes.js';

export async function seedDatabase() {
  const db = getDb();

  const userCount = db.prepare('SELECT COUNT(*) as c FROM users').get().c;
  if (userCount > 0) {
    console.log('[seed] Database already contains data. Skipping seed.');
    return;
  }

  console.log('[seed] Seeding database with initial users and sneakers...');
  const hash = await bcrypt.hash('password123', 10);
  const now = nowIso();

  const users = [
    {
      id: uuid(),
      name: 'Alvin Suwarno Putra',
      email: 'alvin@example.com',
      phone: '081234567890',
      password_hash: hash,
      created_at: now,
    },
    {
      id: uuid(),
      name: 'Budi Sneakerhead',
      email: 'budi@example.com',
      phone: '081398765432',
      password_hash: hash,
      created_at: now,
    },
    {
      id: uuid(),
      name: 'Reza Collector',
      email: 'reza@example.com',
      phone: '085712348765',
      password_hash: hash,
      created_at: now,
    },
  ];

  const insertUser = db.prepare(
    'INSERT INTO users (id, name, email, phone, password_hash, created_at) VALUES (?, ?, ?, ?, ?, ?)',
  );
  for (const u of users) {
    insertUser.run(u.id, u.name, u.email, u.phone, u.password_hash, u.created_at);
  }

  const products = [
    {
      id: uuid(),
      owner_id: users[0].id,
      name: 'Air Jordan 1 Retro High OG Chicago Lost & Found',
      brand: 'Nike',
      size_us: 9.5,
      price: 3850000,
      condition: 'BNIB',
      description: 'Brand new in box, complete with extra laces and receipt. Ready to trade or sell.',
      image_urls: JSON.stringify([
        'https://images.unsplash.com/photo-1552346154-21d32810aba3?w=800',
        'https://images.unsplash.com/photo-1584735935682-2f2b69dff9d2?w=800',
      ]),
      is_for_sale: 1,
      is_for_trade: 1,
    },
    {
      id: uuid(),
      owner_id: users[1].id,
      name: 'Yeezy Boost 350 V2 Zebra',
      brand: 'Adidas',
      size_us: 10.0,
      price: 4200000,
      condition: 'BNIB',
      description: 'OG all, tags still attached. Open for trade with Travis Scott Dunks or cash.',
      image_urls: JSON.stringify([
        'https://images.unsplash.com/photo-1587563871167-1ee9c731aefb?w=800',
      ]),
      is_for_sale: 1,
      is_for_trade: 1,
    },
    {
      id: uuid(),
      owner_id: users[1].id,
      name: 'Dunk Low Retro White Black Panda',
      brand: 'Nike',
      size_us: 9.5,
      price: 1750000,
      condition: 'BNIB',
      description: 'Classic daily beater or collection. Fast sale preferred.',
      image_urls: JSON.stringify([
        'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?w=800',
      ]),
      is_for_sale: 1,
      is_for_trade: 0,
    },
    {
      id: uuid(),
      owner_id: users[2].id,
      name: 'New Balance 990v5 Made in USA Grey',
      brand: 'New Balance',
      size_us: 9.0,
      price: 2450000,
      condition: 'USED_VERY_GOOD',
      description: 'Worn twice casually, immaculate condition 9.5/10. Full box included.',
      image_urls: JSON.stringify([
        'https://images.unsplash.com/photo-1539185441755-769473a23570?w=800',
      ]),
      is_for_sale: 1,
      is_for_trade: 1,
    },
    {
      id: uuid(),
      owner_id: users[2].id,
      name: 'Salomon XT-6 Black Phantom',
      brand: 'Salomon',
      size_us: 10.5,
      price: 2950000,
      condition: 'BNIB',
      description: 'Outdoor trail and gorpcore staple. Quicklace system intact.',
      image_urls: JSON.stringify([
        'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800',
      ]),
      is_for_sale: 1,
      is_for_trade: 1,
    },
  ];

  const insertProduct = db.prepare(
    `INSERT INTO products (
      id, owner_id, name, brand, size_us, price, condition, description,
      image_urls, is_for_sale, is_for_trade, status, created_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'AVAILABLE', ?, ?)`,
  );

  for (const p of products) {
    insertProduct.run(
      p.id,
      p.owner_id,
      p.name,
      p.brand,
      p.size_us,
      p.price,
      p.condition,
      p.description,
      p.image_urls,
      p.is_for_sale,
      p.is_for_trade,
      now,
      now,
    );
  }

  console.log(`[seed] Done! Seeded ${users.length} users and ${products.length} sneaker products.`);
}

if (process.argv[1]?.endsWith('seed.js')) {
  seedDatabase()
    .then(() => process.exit(0))
    .catch((err) => {
      console.error(err);
      process.exit(1);
    });
}
