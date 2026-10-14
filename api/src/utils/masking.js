// PII masking helpers (UU PDP). Never expose another user's raw contact data.

export function maskEmail(email) {
  if (!email || !email.includes('@')) return email ?? null;
  const [name, domain] = email.split('@');
  const visible = name.length <= 2 ? name.slice(0, 1) : name.slice(0, 2);
  return `${visible}***@${domain}`;
}

export function maskPhone(phone) {
  if (!phone) return null;
  const digits = phone.replace(/\D/g, '');
  if (digits.length < 8) return '****';
  return `${digits.slice(0, 4)}-****-${digits.slice(-4)}`;
}

/** 8808123456789 -> 8808 **** 6789 */
export function maskAccountNumber(acc) {
  if (!acc) return null;
  if (acc.length < 8) return '****';
  return `${acc.slice(0, 4)} **** ${acc.slice(-4)}`;
}
