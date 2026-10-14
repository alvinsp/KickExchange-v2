import { Router } from 'express';
import { requireAuth } from '../../middlewares/auth.js';
import { executeOperation } from '../operations.js';
import { syncBatchSchema } from '../../validation/schemas.js';
import { HttpError } from '../../utils/httpError.js';

const router = Router();

// Batch Offline Sync Endpoint
router.post('/batch', requireAuth, async (req, res, next) => {
  try {
    const input = syncBatchSchema.parse(req.body);
    const results = [];

    for (const op of input.operations) {
      try {
        const result = await executeOperation({
          user: req.user,
          scope: op.type,
          input: op.payload,
          key: op.idempotency_key,
          requireKey: true,
        });

        results.push({
          idempotency_key: op.idempotency_key,
          type: op.type,
          status: result.status,
          replayed: result.replayed,
          data: result.body,
        });
      } catch (err) {
        if (err instanceof HttpError) {
          results.push({
            idempotency_key: op.idempotency_key,
            type: op.type,
            status: err.status,
            error: {
              code: err.code,
              message: err.message,
              details: err.details,
            },
          });
        } else {
          console.error(`[sync-error] operation ${op.type} failed:`, err);
          results.push({
            idempotency_key: op.idempotency_key,
            type: op.type,
            status: 500,
            error: {
              code: 'INTERNAL_ERROR',
              message: 'Gagal memproses item antrean sinkronisasi.',
            },
          });
        }
      }
    }

    res.json({
      total: input.operations.length,
      processed: results.length,
      results,
    });
  } catch (err) {
    next(err);
  }
});

export default router;
