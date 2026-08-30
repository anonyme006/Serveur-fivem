'use strict';

const fivem = require('./fivem');
const { statusEmbed } = require('./embeds');
const config = require('../config');
const { log, error } = require('../utils/logger');

let messageId = null;
let timer = null;

async function updatePresence(client, data) {
  const count = data?.count ?? data?.players?.length ?? 0;
  const max = data?.max ?? '?';
  try {
    await client.user.setPresence({
      activities: [{ name: `${count}/${max} joueurs`, type: 3 }],
      status: 'online',
    });
  } catch (e) {
    error('presence', e.message);
  }
}

async function updateStatusChannel(client, data) {
  const channelId = config.channels.status;
  if (!channelId || String(channelId).startsWith('CHANNEL_')) return;

  const channel = await client.channels.fetch(channelId).catch(() => null);
  if (!channel?.isTextBased()) return;

  const embed = statusEmbed(data);
  try {
    if (messageId) {
      const msg = await channel.messages.fetch(messageId).catch(() => null);
      if (msg) {
        await msg.edit({ embeds: [embed] });
        return;
      }
    }
    const sent = await channel.send({ embeds: [embed] });
    messageId = sent.id;
  } catch (e) {
    error('status channel', e.message);
  }
}

function startStatusUpdater(client) {
  const tick = async () => {
    try {
      const data = await fivem.getStatus();
      await updatePresence(client, data);
      await updateStatusChannel(client, data);
    } catch (e) {
      await updatePresence(client, { count: 0, max: '?' });
      // silencieux si serveur off
    }
  };

  tick();
  timer = setInterval(tick, config.statusIntervalMs);
  log('Status updater démarré');
  return () => clearInterval(timer);
}

module.exports = { startStatusUpdater };
