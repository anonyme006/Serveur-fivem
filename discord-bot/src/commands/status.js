'use strict';

const { SlashCommandBuilder } = require('discord.js');
const fivem = require('../services/fivem');
const { errorEmbed, statusEmbed } = require('../services/embeds');
const { requireLevel, LEVEL } = require('../utils/permissions');

module.exports = {
  data: new SlashCommandBuilder()
    .setName('status')
    .setDescription('Affiche le statut du serveur FiveM'),
  check: requireLevel(LEVEL.staff),
  async execute(interaction) {
    await interaction.deferReply();
    try {
      const data = await fivem.getStatus();
      await interaction.editReply({ embeds: [statusEmbed(data)] });
    } catch (e) {
      await interaction.editReply({ embeds: [errorEmbed(`Serveur injoignable : ${e.message}`)] });
    }
  },
};
