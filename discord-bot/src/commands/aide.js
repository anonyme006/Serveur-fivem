'use strict';

const { SlashCommandBuilder } = require('discord.js');
const { baseEmbed } = require('../services/embeds');
const { requireLevel, LEVEL } = require('../utils/permissions');

module.exports = {
  data: new SlashCommandBuilder()
    .setName('aide')
    .setDescription('Liste des commandes du bot FiveM'),
  check: requireLevel(LEVEL.staff),
  async execute(interaction) {
    const embed = baseEmbed('Commandes Discord ↔ FiveM').setDescription(
      [
        '**Staff**',
        '`/players` — joueurs en ligne',
        '`/status` — statut serveur',
        '`/warn` — avertissement IG',
        '`/revive` `/heal` — réanimer / soigner',
        '',
        '**Modération**',
        '`/kick` `/ban` `/unban` — sanctions',
        '`/annonce` — annonce IG',
        '',
        '**Admin**',
        '`/giveitem` `/setjob` — économie / jobs',
        '`/whitelist add|remove|list` — whitelist',
        '',
        'Les actions IG (connexions, chat, morts, staff) sont aussi postées dans les salons de logs configurés.',
      ].join('\n')
    );
    await interaction.reply({ embeds: [embed], ephemeral: true });
  },
};
