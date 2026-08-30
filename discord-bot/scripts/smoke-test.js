'use strict';

/**
 * Test d'intégration local : mock de l'API FiveM + appels du client bot.
 * Usage: node scripts/smoke-test.js
 */
const http = require('http');
const path = require('path');

process.env.BRIDGE_SECRET = 'test-secret-smoke';
process.env.FIVEM_BRIDGE_URL = 'http://127.0.0.1:39120/vibe_discord';
process.env.DISCORD_TOKEN = 'fake';
process.env.DISCORD_CLIENT_ID = 'fake';

const SECRET = process.env.BRIDGE_SECRET;
const players = [
  { id: 1, name: 'Jean_Dupont', character: 'Jean Dupont', job: 'Police (Officer)', license: 'license:abc', discord: '111' },
  { id: 2, name: 'Marie_Martin', character: 'Marie Martin', job: 'civil', license: 'license:def', discord: '222' },
];

const server = http.createServer((req, res) => {
  const secret = req.headers['x-bridge-secret'];
  const send = (code, obj) => {
    res.writeHead(code, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(obj));
  };
  if (secret !== SECRET) return send(401, { error: 'unauthorized' });

  const url = new URL(req.url, 'http://127.0.0.1');
  let p = url.pathname.replace(/^\/+/, '');
  if (p.startsWith('vibe_discord/')) p = p.slice('vibe_discord/'.length);

  let body = '';
  req.on('data', (c) => (body += c));
  req.on('end', () => {
    const data = body ? JSON.parse(body) : {};
    if (p === 'status' || p === 'players') {
      return send(200, { ok: true, count: players.length, max: 48, uptime: '1h 2m', framework: 'qbx', players });
    }
    if (p === 'kick') return send(200, { ok: true, name: players.find((x) => x.id === data.id)?.name || '?', id: data.id });
    if (p === 'announce') return send(200, { ok: true, message: data.message });
    if (p === 'whitelist') return send(200, { ok: true, entries: [{ license: 'license:abc', note: 'test' }] });
    send(404, { error: 'unknown', path: p });
  });
});

async function main() {
  await new Promise((r) => server.listen(39120, '127.0.0.1', r));
  // charge après env
  const fivem = require(path.join(__dirname, '..', 'src', 'services', 'fivem'));
  const { statusEmbed, playersEmbed } = require(path.join(__dirname, '..', 'src', 'services', 'embeds'));

  const status = await fivem.getStatus();
  console.log('STATUS:', status.count + '/' + status.max, status.framework);

  const list = await fivem.getPlayers();
  console.log('PLAYERS:', list.players.map((p) => `[${p.id}] ${p.name}`).join(', '));

  const kick = await fivem.kick({ id: 1, reason: 'test', staff: 'Smoke#0001' });
  console.log('KICK:', kick.name);

  const ann = await fivem.announce({ message: 'Maintenance 5 min', staff: 'Smoke' });
  console.log('ANNOUNCE:', ann.ok);

  const wl = await fivem.whitelistList();
  console.log('WL:', wl.entries.length, 'entrée(s)');

  const embed = statusEmbed(status);
  console.log('EMBED title:', embed.data.title);
  console.log('EMBED desc lines:', (embed.data.description || '').split('\n').length);

  const pembed = playersEmbed(list.players);
  console.log('PLAYERS embed fields:', (pembed.data.fields || []).length);

  console.log('\n✅ smoke-test OK');
  server.close();
}

main().catch((e) => {
  console.error('❌', e);
  server.close();
  process.exit(1);
});
