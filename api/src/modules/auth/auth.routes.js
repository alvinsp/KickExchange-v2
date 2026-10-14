import { Router } from 'express';
import rateLimit from 'express-rate-limit';
import { config } from '../../config/env.js';
import { requireAuth } from '../../middlewares/auth.js';
import { login, register, serializeSelf } from './auth.service.js';

const router = Router();

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 20,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  skip: () => !config.rateLimitEnabled,
  message: { error: { code: 'TOO_MANY_REQUESTS', message: 'Terlalu banyak percobaan. Coba lagi dalam 15 menit.' } },
});

router.post('/register', authLimiter, async (req, res) => {
  res.status(201).json(await register(req.body));
});

router.post('/login', authLimiter, async (req, res) => {
  res.json(await login(req.body));
});

router.get('/me', requireAuth, (req, res) => {
  res.json({ user: serializeSelf(req.user) });
});

export default router;
