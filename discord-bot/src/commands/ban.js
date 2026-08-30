'use strict';

const { SlashCommandBuilder } = require('discord.js');
const fivem = require('../services/fivem');
const { successEmbed, errorEmbed } = require('../services/embeds');
const { requireLevel, LEVEL } = require('../utils/permissions');

module.exports = {
  data: new SlashCommandBuilder()
    .setName('ban')
    .setDescription('Bannit un joueur du serveur FiveM')
    .addIntegerOption((o) => o.setName('id').setDescription('ID serveur (en ligne)').setRequired(false))
    .addStringOption((o) => o.setName('license').setDescription('License Rockstar (hors ligne)').setRequired(false))
    .addStringOption((o) => o.setName('raison').setDescription('Raison').setRequired(true))
    .addIntegerOption((o) =>
      o.setName('heures').setDescription('Durée en heures (0 = permanent)').setRequired(false)
    ),
  check: requireLevel(LEVEL.moderator),
  async execute(interaction) {
    await interaction.deferReply({ ephemeral: true });
    const id = interaction.options.getInteger('id');
    const license = interaction.options.getString('license');
    const reason = interaction.options.getString('raison', true);
    const hours = interaction.options.getInteger('heures') ?? 0;

    if (!id && !license) {
      await interaction.editReply({ embeds: [errorEmbed('Indique un `id` en ligne ou une `license`.')] });
      return;
    }

    try {
      const res = await fivem.ban({
        id,
        license,
        reason,
        hours,
        staff: interaction.user.tag,
        staffId: interaction.user.id,
      });
      const dur = hours > 0 ? `${hours}h` : 'permanent';
      await interaction.editReply({
        embeds: [successEmbed(`Ban **${res.name || license || id}** (${dur}).\nRaison : ${reason}`)],
      });
    } catch (e) {
      await interaction.editReply({ embeds: [errorEmbed(e.message)] });
    }
  },
};
