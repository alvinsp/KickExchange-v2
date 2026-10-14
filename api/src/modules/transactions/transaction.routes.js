import { Router } from 'express';
import { requireAuth } from '../../middlewares/auth.js';
import { operationRoute } from '../operations.js';
import { getTransactionById, listTransactions } from './transaction.service.js';

const router = Router();

// List user transactions
router.get('/', requireAuth, async (req, res, next) => {
  try {
    const transactions = await listTransactions(req.user, req.query);
    res.json({ transactions });
  } catch (err) {
    next(err);
  }
});

// Single transaction detail
router.get('/:id', requireAuth, async (req, res, next) => {
  try {
    const transaction = await getTransactionById(req.params.id, req.user.id);
    res.json({ transaction });
  } catch (err) {
    next(err);
  }
});

// Create checkout order with Idempotency Key required
router.post(
  '/',
  requireAuth,
  operationRoute(
    'TRANSACTION_CREATE',
    (req) => req.body,
    { requireKey: true },
  ),
);

export default router;
