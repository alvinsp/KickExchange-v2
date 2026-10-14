import { Router } from 'express';
import { requireAuth } from '../../middlewares/auth.js';
import { operationRoute } from '../operations.js';
import { getProductById, listProducts } from './product.service.js';

const router = Router();

// Optional auth helper: if token is supplied, attach req.user, else continue anonymously
function optionalAuth(req, res, next) {
  const header = req.get('authorization') ?? '';
  if (!header.startsWith('Bearer ')) return next();
  return requireAuth(req, res, next);
}

// Public product catalog list with search & filter
router.get('/', optionalAuth, async (req, res, next) => {
  try {
    const result = await listProducts(req.query, req.user?.id);
    res.json(result);
  } catch (err) {
    next(err);
  }
});

// Single product detail
router.get('/:id', optionalAuth, async (req, res, next) => {
  try {
    const product = await getProductById(req.params.id, req.user?.id);
    res.json({ product });
  } catch (err) {
    next(err);
  }
});

// Create product listing (Supports Idempotency Key)
router.post(
  '/',
  requireAuth,
  operationRoute('PRODUCT_CREATE', (req) => req.body),
);

// Update product listing (Optimistic Locking & Idempotency)
router.put(
  '/:id',
  requireAuth,
  operationRoute('PRODUCT_UPDATE', (req) => ({ ...req.body, id: req.params.id })),
);

// Delete product listing
router.delete(
  '/:id',
  requireAuth,
  operationRoute('PRODUCT_DELETE', (req) => ({ id: req.params.id })),
);

export default router;
