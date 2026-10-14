import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import rateLimit from 'express-rate-limit';
import { config } from './config/env.js';
import { notFoundHandler, errorHandler } from './middlewares/errorHandler.js';

import authRoutes from './modules/auth/auth.routes.js';
import productRoutes from './modules/products/product.routes.js';
import tradeRoutes from './modules/trades/trade.routes.js';
import transactionRoutes from './modules/transactions/transaction.routes.js';
import paymentRoutes from './modules/payments/payment.routes.js';
import syncRoutes from './modules/sync/sync.routes.js';

export function createApp() {
  const app = express();

  app.use(helmet());
  app.use(
    cors({
      origin: config.corsOrigins.includes('*') ? true : config.corsOrigins,
      methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
      allowedHeaders: ['Content-Type', 'Authorization', 'X-Idempotency-Key', 'x-callback-token'],
      exposedHeaders: ['Idempotent-Replayed'],
    }),
  );

  app.use(express.json({ limit: '1mb' }));

  if (config.rateLimitEnabled) {
    app.use(
      rateLimit({
        windowMs: 60 * 1000,
        limit: 120,
        standardHeaders: 'draft-7',
        legacyHeaders: false,
        message: {
          error: {
            code: 'RATE_LIMIT_EXCEEDED',
            message: 'Terlalu banyak permintaan. Silakan tunggu beberapa saat.',
          },
        },
      }),
    );
  }

  // Health check endpoint
  app.get('/health', (req, res) => {
    res.json({
      status: 'UP',
      timestamp: new Date().toISOString(),
      service: 'KickExchange v2 API',
      payment_mode: config.paymentMode,
    });
  });

  // API v1 Routing
  const apiV1 = express.Router();
  apiV1.use('/auth', authRoutes);
  apiV1.use('/products', productRoutes);
  apiV1.use('/trades', tradeRoutes);
  apiV1.use('/transactions', transactionRoutes);
  apiV1.use('/payments', paymentRoutes);
  apiV1.use('/sync', syncRoutes);

  app.use('/api/v1', apiV1);

  // 404 & Error Handling
  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
}
