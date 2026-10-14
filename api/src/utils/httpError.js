export class HttpError extends Error {
  /**
   * @param {number} status HTTP status code
   * @param {string} code   Stable machine-readable error code (consumed by the Flutter app)
   * @param {string} message Human readable message (Bahasa Indonesia)
   * @param {object} [details]
   */
  constructor(status, code, message, details) {
    super(message);
    this.name = 'HttpError';
    this.status = status;
    this.code = code;
    this.details = details;
  }
}

export const notFound = (what = 'Data') => new HttpError(404, 'NOT_FOUND', `${what} tidak ditemukan.`);
export const forbidden = (msg = 'Kamu tidak memiliki akses ke resource ini.') =>
  new HttpError(403, 'FORBIDDEN', msg);
export const conflict = (code, msg, details) => new HttpError(409, code, msg, details);
export const unprocessable = (code, msg, details) => new HttpError(422, code, msg, details);
