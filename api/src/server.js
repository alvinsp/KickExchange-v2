import { config } from './config/env.js';
import { createApp } from './app.js';
import { getDb, closeDb } from './db/database.js';
import { seedDatabase } from './db/seed.js';
import { releaseStaleKeys } from './middlewares/idempotency.js';

async function bootstrap() {
  console.log('--------------------------------------------------');
  console.log(`👟 KickExchange v2 API starting [env: ${config.env}]`);
  console.log(`💳 Payment Mode: ${config.paymentMode.toUpperCase()}`);
  console.log(`📁 Database Path: ${config.dbPath}`);
  console.log('--------------------------------------------------');

  // Initialize DB and clear stale keys
  getDb();
  releaseStaleKeys();

  // Seed sample products and users if fresh database
  await seedDatabase();

  const app = createApp();
  const server = app.listen(config.port, '0.0.0.0', () => {
    console.log(`🚀 KickExchange API listening on http://0.0.0.0:${config.port}`);
    console.log(`🔍 Health check: http://localhost:${config.port}/health`);
  });

  const shutdown = (signal) => {
    console.log(`\n[server] Received ${signal}. Closing gracefully...`);
    server.close(() => {
      closeDb();
      console.log('[server] Database closed and server terminated.');
      process.exit(0);
    });
  };

  process.on('SIGINT', () => shutdown('SIGINT'));
  process.on('SIGTERM', () => shutdown('SIGTERM'));
}

bootstrap().catch((err) => {
  console.error('[server] Fatal error during bootstrap:', err);
  process.exit(1);
});
