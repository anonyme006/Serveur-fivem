'use strict';

const { SlashCommandBuilder } = require('discord.js');
const fivem = require('../services/fivem');
const { successEmbed, errorEmbed } = require('../services/embeds');
const { requireLevel, LEVEL } = require('../utils/permissions');

module.exports = {
  data: new SlashCommandBuilder()
    .setName('setjob')
    .setDescription('Change le métier d\'un joueur')
    .addIntegerOption((o) => o.setName('id').setDescription('ID serveur').setRequired(true))
    .addStringOption((o) => o.setName('job').setDescription('Nom du job (ex: police)').setRequired(true))
    .addIntegerOption((o) => o.setName('grade').setDescription('Grade').setRequired(false)),
  check: requireLevel(LEVEL.admin),
  async execute(interaction) {
    await interaction.deferReply({ ephemeral: true });
    const id = interaction.options.getInteger('id', true);
    const job = interaction.options.getString('job', true);
    const grade = interaction.options.getInteger('grade') ?? 0;
    try {
      const res = await fivem.setJob({
        id,
        job,
        grade,
        staff: interaction.user.tag,
        staffId: interaction.user.id,
      });
      await interaction.editReply({
        embeds: [successEmbed(`**${res.name || id}** → job \`${job}\` grade ${grade}.`)],
      });
    } catch (e) {
      await interaction.editReply({ embeds: [errorEmbed(e.message)] });
    }
  },
};
