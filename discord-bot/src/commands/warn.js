'use strict';

const { SlashCommandBuilder } = require('discord.js');
const fivem = require('../services/fivem');
const { successEmbed, errorEmbed } = require('../services/embeds');
const { requireLevel, LEVEL } = require('../utils/permissions');

module.exports = {
  data: new SlashCommandBuilder()
    .setName('warn')
    .setDescription('Envoie un avertissement IG à un joueur')
    .addIntegerOption((o) => o.setName('id').setDescription('ID serveur').setRequired(true))
    .addStringOption((o) => o.setName('raison').setDescription('Raison').setRequired(true)),
  check: requireLevel(LEVEL.staff),
  async execute(interaction) {
    await interaction.deferReply({ ephemeral: true });
    const id = interaction.options.getInteger('id', true);
    const reason = interaction.options.getString('raison', true);
    try {
      const res = await fivem.warn({
        id,
        reason,
        staff: interaction.user.tag,
        staffId: interaction.user.id,
      });
      await interaction.editReply({
        embeds: [successEmbed(`Warn envoyé à **${res.name || id}** : ${reason}`)],
      });
    } catch (e) {
      await interaction.editReply({ embeds: [errorEmbed(e.message)] });
    }
  },
};
