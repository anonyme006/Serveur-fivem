'use strict';

const { SlashCommandBuilder } = require('discord.js');
const fivem = require('../services/fivem');
const { playersEmbed, errorEmbed } = require('../services/embeds');
const { requireLevel, LEVEL } = require('../utils/permissions');

module.exports = {
  data: new SlashCommandBuilder()
    .setName('players')
    .setDescription('Liste les joueurs connectés sur le serveur FiveM'),
  check: requireLevel(LEVEL.staff),
  async execute(interaction) {
    await interaction.deferReply({ ephemeral: true });
    try {
      const data = await fivem.getPlayers();
      await interaction.editReply({ embeds: [playersEmbed(data.players || [])] });
    } catch (e) {
      await interaction.editReply({ embeds: [errorEmbed(`Impossible de joindre FiveM : ${e.message}`)] });
    }
  },
};
