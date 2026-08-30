'use strict';

const { SlashCommandBuilder } = require('discord.js');
const fivem = require('../services/fivem');
const { successEmbed, errorEmbed } = require('../services/embeds');
const { requireLevel, LEVEL } = require('../utils/permissions');

module.exports = {
  data: new SlashCommandBuilder()
    .setName('giveitem')
    .setDescription('Donne un item à un joueur (ox_inventory)')
    .addIntegerOption((o) => o.setName('id').setDescription('ID serveur').setRequired(true))
    .addStringOption((o) => o.setName('item').setDescription('Nom de l\'item').setRequired(true))
    .addIntegerOption((o) => o.setName('quantite').setDescription('Quantité').setRequired(false)),
  check: requireLevel(LEVEL.admin),
  async execute(interaction) {
    await interaction.deferReply({ ephemeral: true });
    const id = interaction.options.getInteger('id', true);
    const item = interaction.options.getString('item', true);
    const count = interaction.options.getInteger('quantite') ?? 1;
    try {
      const res = await fivem.giveItem({
        id,
        item,
        count,
        staff: interaction.user.tag,
        staffId: interaction.user.id,
      });
      await interaction.editReply({
        embeds: [successEmbed(`Donné **x${count} ${item}** à **${res.name || id}**.`)],
      });
    } catch (e) {
      await interaction.editReply({ embeds: [errorEmbed(e.message)] });
    }
  },
};
