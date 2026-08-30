'use strict';

const { SlashCommandBuilder } = require('discord.js');
const fivem = require('../services/fivem');
const { successEmbed, errorEmbed } = require('../services/embeds');
const { requireLevel, LEVEL } = require('../utils/permissions');

module.exports = {
  data: new SlashCommandBuilder()
    .setName('heal')
    .setDescription('Soigne un joueur IG')
    .addIntegerOption((o) => o.setName('id').setDescription('ID serveur').setRequired(true)),
  check: requireLevel(LEVEL.staff),
  async execute(interaction) {
    await interaction.deferReply({ ephemeral: true });
    const id = interaction.options.getInteger('id', true);
    try {
      const res = await fivem.heal({
        id,
        staff: interaction.user.tag,
        staffId: interaction.user.id,
      });
      await interaction.editReply({ embeds: [successEmbed(`**${res.name || id}** soigné.`)] });
    } catch (e) {
      await interaction.editReply({ embeds: [errorEmbed(e.message)] });
    }
  },
};
