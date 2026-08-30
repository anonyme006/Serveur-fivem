'use strict';

const config = require('../config');

/**
 * Appelle l'API HTTP exposée par la ressource FiveM vibe_discord.
 */
async function fivemRequest(method, route, body = null) {
  const url = `${config.fivemUrl}${route.startsWith('/') ? route : `/${route}`}`;
  const headers = {
    'Content-Type': 'application/json',
    'X-Bridge-Secret': config.bridgeSecret,
  };

  const opts = { method, headers };
  if (body && method !== 'GET') {
    opts.body = JSON.stringify(body);
  }

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 12000);
  opts.signal = controller.signal;

  try {
    const res = await fetch(url, opts);
    const text = await res.text();
    let data;
    try {
      data = text ? JSON.parse(text) : {};
    } catch {
      data = { raw: text };
    }
    if (!res.ok) {
      const err = new Error(data.error || data.message || `HTTP ${res.status}`);
      err.status = res.status;
      err.data = data;
      throw err;
    }
    return data;
  } finally {
    clearTimeout(timer);
  }
}

module.exports = {
  getStatus: () => fivemRequest('GET', '/status'),
  getPlayers: () => fivemRequest('GET', '/players'),
  kick: (payload) => fivemRequest('POST', '/kick', payload),
  ban: (payload) => fivemRequest('POST', '/ban', payload),
  unban: (payload) => fivemRequest('POST', '/unban', payload),
  warn: (payload) => fivemRequest('POST', '/warn', payload),
  announce: (payload) => fivemRequest('POST', '/announce', payload),
  revive: (payload) => fivemRequest('POST', '/revive', payload),
  heal: (payload) => fivemRequest('POST', '/heal', payload),
  giveItem: (payload) => fivemRequest('POST', '/giveitem', payload),
  setJob: (payload) => fivemRequest('POST', '/setjob', payload),
  teleport: (payload) => fivemRequest('POST', '/teleport', payload),
  whitelistAdd: (payload) => fivemRequest('POST', '/whitelist/add', payload),
  whitelistRemove: (payload) => fivemRequest('POST', '/whitelist/remove', payload),
  whitelistList: () => fivemRequest('GET', '/whitelist'),
  screenshot: (payload) => fivemRequest('POST', '/screenshot', payload),
};
