'use strict';

const { EmbedBuilder } = require('discord.js');
const config = require('../config');

function baseEmbed(title) {
  return new EmbedBuilder()
    .setColor(config.embedColor)
    .setTitle(title)
    .setTimestamp()
    .setFooter({ text: config.botName });
}

function statusEmbed(data) {
  const players = data.players || [];
  const list =
    players.length === 0
      ? '_Aucun joueur connecté_'
      : players
          .slice(0, 25)
          .map((p) => `\`[${p.id}]\` **${p.name}** — ${p.job || 'civil'}`)
          .join('\n') + (players.length > 25 ? `\n_… et ${players.length - 25} autres_` : '');

  return baseEmbed(`📊 Statut — ${config.botName}`)
    .setDescription(
      [
        `**Joueurs :** ${data.count ?? players.length}/${data.max ?? '?'}`,
        `**Uptime :** ${data.uptime || 'n/a'}`,
        `**Framework :** ${data.framework || 'qbx'}`,
        '',
        list,
      ].join('\n')
    );
}

function playersEmbed(players) {
  const embed = baseEmbed(`👥 Joueurs en ligne (${players.length})`);
  if (!players.length) {
    embed.setDescription('_Serveur vide_');
    return embed;
  }
  const chunks = [];
  let buf = '';
  for (const p of players) {
    const line = `\`[${p.id}]\` **${escapeMd(p.name)}** | ${p.discord || 'pas de discord'} | ${p.job || '?'}\n`;
    if (buf.length + line.length > 900) {
      chunks.push(buf);
      buf = line;
    } else {
      buf += line;
    }
  }
  if (buf) chunks.push(buf);
  chunks.slice(0, 4).forEach((c, i) => embed.addFields({ name: i === 0 ? 'Liste' : '…', value: c }));
  return embed;
}

function logEmbed(type, fields, color) {
  const titles = {
    connect: '🟢 Connexion',
    disconnect: '🔴 Déconnexion',
    chat: '💬 Chat IG',
    death: '💀 Mort',
    staff: '🛡️ Action staff',
    economy: '💰 Économie',
    report: '📣 Report',
    announce: '📢 Annonce',
  };
  const embed = baseEmbed(titles[type] || type);
  if (color) embed.setColor(color);
  for (const [name, value] of Object.entries(fields)) {
    if (value === undefined || value === null || value === '') continue;
    embed.addFields({ name, value: String(value).slice(0, 1024), inline: String(value).length < 40 });
  }
  return embed;
}

function successEmbed(message) {
  return baseEmbed('✅ Succès').setDescription(message).setColor(0x3ba55d);
}

function errorEmbed(message) {
  return baseEmbed('❌ Erreur').setDescription(message).setColor(0xed4245);
}

function escapeMd(s) {
  return String(s || '').replace(/([_*`~|\\])/g, '\\$1');
}

module.exports = {
  baseEmbed,
  statusEmbed,
  playersEmbed,
  logEmbed,
  successEmbed,
  errorEmbed,
  escapeMd,
};
