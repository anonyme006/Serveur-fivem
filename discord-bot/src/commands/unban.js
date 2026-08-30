'use strict';

const { SlashCommandBuilder } = require('discord.js');
const fivem = require('../services/fivem');
const { successEmbed, errorEmbed } = require('../services/embeds');
const { requireLevel, LEVEL } = require('../utils/permissions');

module.exports = {
  data: new SlashCommandBuilder()
    .setName('unban')
    .setDescription('Retire un ban FiveM')
    .addStringOption((o) => o.setName('license').setDescription('License Rockstar').setRequired(true)),
  check: requireLevel(LEVEL.admin),
  async execute(interaction) {
    await interaction.deferReply({ ephemeral: true });
    const license = interaction.options.getString('license', true);
    try {
      await fivem.unban({
        license,
        staff: interaction.user.tag,
        staffId: interaction.user.id,
      });
      await interaction.editReply({ embeds: [successEmbed(`Unban de \`${license}\`.`)] });
    } catch (e) {
      await interaction.editReply({ embeds: [errorEmbed(e.message)] });
    }
  },
};
