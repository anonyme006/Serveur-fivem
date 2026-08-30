'use strict';

const http = require('http');
const config = require('../config');
const { logEmbed } = require('./embeds');
const { log, error } = require('../utils/logger');

const CHANNEL_MAP = {
  connect: 'logs_connect',
  disconnect: 'logs_connect',
  chat: 'logs_chat',
  death: 'logs_death',
  staff: 'logs_staff',
  economy: 'logs_economy',
  report: 'logs_reports',
  announce: 'logs_staff',
};

/**
 * Petit serveur HTTP pour recevoir les logs poussés par FiveM.
 * POST /log  { type, fields, color? }
 */
function startLogServer(client, port = 3847) {
  const server = http.createServer(async (req, res) => {
    const send = (code, obj) => {
      res.writeHead(code, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify(obj));
    };

    if (req.method === 'GET' && req.url === '/health') {
      send(200, { ok: true });
      return;
    }

    if (req.method !== 'POST' || !req.url?.startsWith('/log')) {
      send(404, { error: 'not_found' });
      return;
    }

    const secret = req.headers['x-bridge-secret'];
    if (!secret || secret !== config.bridgeSecret) {
      send(401, { error: 'unauthorized' });
      return;
    }

    let body = '';
    req.on('data', (c) => {
      body += c;
      if (body.length > 1_000_000) req.destroy();
    });
    req.on('end', async () => {
      try {
        const payload = JSON.parse(body || '{}');
        const type = payload.type || 'staff';
        const channelKey = CHANNEL_MAP[type] || 'logs_staff';
        const channelId = config.channels[channelKey];
        if (!channelId || channelId.startsWith('CHANNEL_')) {
          send(200, { ok: true, skipped: true });
          return;
        }
        const channel = await client.channels.fetch(channelId).catch(() => null);
        if (!channel) {
          send(200, { ok: true, skipped: 'channel' });
          return;
        }
        await channel.send({ embeds: [logEmbed(type, payload.fields || {}, payload.color)] });
        send(200, { ok: true });
      } catch (e) {
        error('log ingest', e);
        send(500, { error: e.message });
      }
    });
  });

  server.listen(port, '0.0.0.0', () => {
    log(`Récepteur de logs Discord sur :${port}`);
  });

  return server;
}

module.exports = { startLogServer };
