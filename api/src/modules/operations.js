import { HttpError } from '../utils/httpError.js';
import { runIdempotent } from '../middlewares/idempotency.js';
import * as products from './products/product.service.js';
import * as trades from './trades/trade.service.js';
import * as transactions from './transactions/transaction.service.js';

// Every state-changing operation, addressable both by REST routes and by the
// offline sync batch. Because both paths share the same scope name and payload
// shape, a request that timed out online and is later replayed by the sync
// queue hits the same idempotency record and is NOT executed twice.
export const OPERATIONS = {
  PRODUCT_CREATE: { status: 201, exec: (user, input) => products.createProduct(user, input) },
  PRODUCT_UPDATE: { status: 200, exec: (user, input) => products.updateProduct(user, input) },
  PRODUCT_DELETE: { status: 200, exec: (user, input) => products.deleteProduct(user, input) },
  TRADE_CREATE: { status: 201, exec: (user, input) => trades.createTrade(user, input) },
  TRADE_ACTION: { status: 200, exec: (user, input) => trades.applyTradeAction(user, input) },
  TRANSACTION_CREATE: {
    status: 201,
    exec: (user, input, ctx) => transactions.createTransaction(user, input, ctx),
  },
};

/**
 * @param {{user:object, scope:keyof OPERATIONS, input:object, key?:string, requireKey?:boolean}} args
 * @returns {Promise<{status:number, body:any, replayed:boolean}>}
 */
export async function executeOperation({ user, scope, input, key, requireKey = false }) {
  const op = OPERATIONS[scope];
  if (!op) throw new HttpError(400, 'UNKNOWN_OPERATION', `Operasi ${scope} tidak dikenal.`);

  if (!key) {
    if (requireKey) {
      throw new HttpError(400, 'IDEMPOTENCY_KEY_REQUIRED', 'Header X-Idempotency-Key wajib diisi untuk operasi ini.');
    }
    const body = await op.exec(user, input, { key: null });
    return { status: op.status, body, replayed: false };
  }

  return runIdempotent({ userId: user.id, key, scope, payload: input }, async () => ({
    status: op.status,
    body: await op.exec(user, input, { key }),
  }));
}

/** Express adapter: builds the input from the request and sends the (possibly replayed) result. */
export function operationRoute(scope, buildInput, { requireKey = false } = {}) {
  return async (req, res) => {
    const result = await executeOperation({
      user: req.user,
      scope,
      input: buildInput(req),
      key: req.get('x-idempotency-key'),
      requireKey,
    });
    if (result.replayed) res.set('Idempotent-Replayed', 'true');
    res.status(result.status).json(result.body);
  };
}
