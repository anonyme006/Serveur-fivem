'use strict';

const { SlashCommandBuilder } = require('discord.js');
const fivem = require('../services/fivem');
const { successEmbed, errorEmbed } = require('../services/embeds');
const { requireLevel, LEVEL } = require('../utils/permissions');

module.exports = {
  data: new SlashCommandBuilder()
    .setName('kick')
    .setDescription('Expulse un joueur du serveur FiveM')
    .addIntegerOption((o) => o.setName('id').setDescription('ID serveur du joueur').setRequired(true))
    .addStringOption((o) => o.setName('raison').setDescription('Raison du kick').setRequired(true)),
  check: requireLevel(LEVEL.moderator),
  async execute(interaction) {
    await interaction.deferReply({ ephemeral: true });
    const id = interaction.options.getInteger('id', true);
    const reason = interaction.options.getString('raison', true);
    try {
      const res = await fivem.kick({
        id,
        reason,
        staff: interaction.user.tag,
        staffId: interaction.user.id,
      });
      await interaction.editReply({
        embeds: [successEmbed(`Joueur **${res.name || id}** kick.\nRaison : ${reason}`)],
      });
    } catch (e) {
      await interaction.editReply({ embeds: [errorEmbed(e.message)] });
    }
  },
};
