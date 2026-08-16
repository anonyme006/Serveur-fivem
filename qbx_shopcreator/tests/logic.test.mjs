// Node unit tests for shared hour / sanitize logic mirrored from Lua.
// Run: node qbx_shopcreator/tests/logic.test.mjs

function isWithinHours(openHour, closeHour, hour, minute) {
  openHour = Number(openHour) || 0;
  closeHour = Number(closeHour) || 0;
  hour = Number(hour) || 0;
  minute = Number(minute) || 0;

  let openMin = Math.floor(openHour) * 60;
  let closeMin = Math.floor(closeHour) * 60;
  if (openHour === Math.floor(openHour)) openMin = openHour * 60;
  if (closeHour === Math.floor(closeHour)) closeMin = closeHour * 60;

  const now = hour * 60 + minute;
  if (openMin === closeMin) return true;
  if (openMin < closeMin) return now >= openMin && now < closeMin;
  return now >= openMin || now < closeMin;
}

function sanitizeItemName(item) {
  if (typeof item !== 'string') return null;
  item = item.toLowerCase().trim();
  if (!item || !/^[\w]+$/.test(item) || item.length > 64) return null;
  return item;
}

function clampInt(value, min, max) {
  const n = Number(value);
  if (!Number.isFinite(n)) return null;
  const i = Math.floor(n);
  if (i < min || i > max) return null;
  return i;
}

let failed = 0;
function assert(cond, msg) {
  if (!cond) {
    failed += 1;
    console.error('FAIL:', msg);
  } else {
    console.log('OK:', msg);
  }
}

assert(isWithinHours(8, 22, 12, 0) === true, 'midday open');
assert(isWithinHours(8, 22, 7, 59) === false, 'before open');
assert(isWithinHours(8, 22, 22, 0) === false, 'at close exclusive');
assert(isWithinHours(22, 6, 23, 0) === true, 'overnight late');
assert(isWithinHours(22, 6, 3, 0) === true, 'overnight early');
assert(isWithinHours(22, 6, 12, 0) === false, 'overnight midday closed');
assert(isWithinHours(0, 0, 15, 0) === true, '24h when equal');
assert(sanitizeItemName('Bread') === 'bread', 'sanitize item');
assert(sanitizeItemName('bad name') === null, 'reject spaces');
assert(sanitizeItemName('../hack') === null, 'reject path');
assert(clampInt('3', 1, 50) === 3, 'clamp ok');
assert(clampInt(-1, 1, 50) === null, 'clamp negative');
assert(clampInt(3.9, 1, 50) === 3, 'clamp floor');

if (failed > 0) {
  console.error(`\n${failed} test(s) failed`);
  process.exit(1);
}
console.log('\nAll logic tests passed');
