import crypto from 'node:crypto';

// Local payment simulator - used when XENDIT_SECRET_KEY is empty.
// Produces EMVCo-formatted (QRIS-like) strings and VA numbers that look real
// but are NOT payable. Payment is confirmed through POST /api/v1/payments/simulator/:id/pay
// which goes through exactly the same settlement path as a real Xendit webhook.

const tlv = (id, value) => `${id}${String(value.length).padStart(2, '0')}${value}`;

/** CRC16/CCITT-FALSE as required by the EMVCo QR spec (tag 63). */
function crc16(payload) {
  let crc = 0xffff;
  for (const byte of Buffer.from(payload, 'utf8')) {
    crc ^= byte << 8;
    for (let i = 0; i < 8; i += 1) {
      crc = crc & 0x8000 ? ((crc << 1) ^ 0x1021) & 0xffff : (crc << 1) & 0xffff;
    }
  }
  return crc.toString(16).toUpperCase().padStart(4, '0');
}

function buildQrisString({ reference, amount }) {
  const body =
    tlv('00', '01') +
    tlv('01', '12') + // 12 = dynamic QR (single use, fixed amount)
    tlv('26', tlv('00', 'ID.CO.KICKEXCHANGE.SIM') + tlv('01', reference.slice(0, 25))) +
    tlv('52', '5661') + // MCC 5661 = shoe stores
    tlv('53', '360') + // IDR
    tlv('54', String(amount)) +
    tlv('58', 'ID') +
    tlv('59', 'KICKEXCHANGE SIMULATOR') +
    tlv('60', 'JAKARTA') +
    tlv('62', tlv('01', reference.slice(0, 25)));
  const withCrcTag = `${body}6304`;
  return withCrcTag + crc16(withCrcTag);
}

const VA_PREFIX = { BCA: '70012', BNI: '8808', BRI: '26215', MANDIRI: '88908' };

function buildVaNumber(bank) {
  const prefix = VA_PREFIX[bank] ?? '9999';
  let digits = '';
  while (prefix.length + digits.length < 16) digits += crypto.randomInt(0, 10);
  return prefix + digits;
}

export const simulatorProvider = {
  name: 'simulator',
  async createPayment({ channel, reference, amount }) {
    if (channel === 'QRIS') {
      return {
        providerPaymentId: `sim_qr_${crypto.randomUUID()}`,
        qrString: buildQrisString({ reference, amount }),
        vaNumber: null,
      };
    }
    return {
      providerPaymentId: `sim_va_${crypto.randomUUID()}`,
      qrString: null,
      vaNumber: buildVaNumber(channel),
    };
  },
};

export const _internals = { crc16, buildQrisString };
