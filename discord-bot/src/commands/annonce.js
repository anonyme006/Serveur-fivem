'use strict';

const { SlashCommandBuilder } = require('discord.js');
const fivem = require('../services/fivem');
const { successEmbed, errorEmbed } = require('../services/embeds');
const { requireLevel, LEVEL } = require('../utils/permissions');

module.exports = {
  data: new SlashCommandBuilder()
    .setName('annonce')
    .setDescription('Annonce IG (tous les joueurs)')
    .addStringOption((o) => o.setName('message').setDescription('Texte de l\'annonce').setRequired(true)),
  check: requireLevel(LEVEL.moderator),
  async execute(interaction) {
    await interaction.deferReply();
    const message = interaction.options.getString('message', true);
    try {
      await fivem.announce({
        message,
        staff: interaction.user.tag,
        staffId: interaction.user.id,
      });
      await interaction.editReply({
        embeds: [successEmbed(`Annonce envoyée IG :\n> ${message}`)],
      });
    } catch (e) {
      await interaction.editReply({ embeds: [errorEmbed(e.message)] });
    }
  },
};
