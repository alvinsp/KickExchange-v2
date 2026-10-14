import { Router } from 'express';
import { requireAuth } from '../../middlewares/auth.js';
import { operationRoute } from '../operations.js';
import { getTradeById, listTrades } from './trade.service.js';

const router = Router();

// List user's trades: ?type=all | incoming | outgoing
router.get('/', requireAuth, async (req, res, next) => {
  try {
    const trades = await listTrades(req.user, req.query.type);
    res.json({ trades });
  } catch (err) {
    next(err);
  }
});

// Single trade detail
router.get('/:id', requireAuth, async (req, res, next) => {
  try {
    const trade = await getTradeById(req.params.id, req.user.id);
    res.json({ trade });
  } catch (err) {
    next(err);
  }
});

// Create trade offer (with Idempotency key)
router.post(
  '/',
  requireAuth,
  operationRoute('TRADE_CREATE', (req) => req.body),
);

// Apply trade action: accept, reject, cancel (with Idempotency key)
router.post(
  '/:id/action',
  requireAuth,
  operationRoute('TRADE_ACTION', (req) => ({ ...req.body, id: req.params.id })),
);

export default router;
