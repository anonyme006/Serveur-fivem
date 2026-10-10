/// HMAC helpers for server-to-server auth (never expose to clients)
const crypto = require('crypto');

function hmacSha256Hex(secret, payload) {
  return crypto.createHmac('sha256', secret).update(payload).digest('hex');
}

function sha256Hex(value) {
  return crypto.createHash('sha256').update(value).digest('hex');
}

function randomToken(bytes = 32) {
  return crypto.randomBytes(bytes).toString('hex');
}

exports('hmacSha256Hex', (secret, payload) => hmacSha256Hex(String(secret), String(payload)));
exports('sha256Hex', (value) => sha256Hex(String(value)));
exports('randomToken', (bytes) => randomToken(Number(bytes) || 32));
