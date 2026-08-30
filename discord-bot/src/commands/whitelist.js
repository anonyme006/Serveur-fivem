'use strict';

const { SlashCommandBuilder } = require('discord.js');
const fivem = require('../services/fivem');
const { successEmbed, errorEmbed, baseEmbed } = require('../services/embeds');
const { requireLevel, LEVEL } = require('../utils/permissions');

module.exports = {
  data: new SlashCommandBuilder()
    .setName('whitelist')
    .setDescription('Gère la whitelist du serveur')
    .addSubcommand((s) =>
      s
        .setName('add')
        .setDescription('Ajoute une license à la whitelist')
        .addStringOption((o) => o.setName('license').setDescription('license:xxxx').setRequired(true))
        .addStringOption((o) => o.setName('note').setDescription('Note (pseudo Discord…)').setRequired(false))
    )
    .addSubcommand((s) =>
      s
        .setName('remove')
        .setDescription('Retire une license')
        .addStringOption((o) => o.setName('license').setDescription('license:xxxx').setRequired(true))
    )
    .addSubcommand((s) => s.setName('list').setDescription('Liste la whitelist')),
  check: requireLevel(LEVEL.admin),
  async execute(interaction) {
    await interaction.deferReply({ ephemeral: true });
    const sub = interaction.options.getSubcommand();
    try {
      if (sub === 'add') {
        const license = interaction.options.getString('license', true);
        const note = interaction.options.getString('note') || interaction.user.tag;
        await fivem.whitelistAdd({
          license,
          note,
          staff: interaction.user.tag,
          staffId: interaction.user.id,
        });
        await interaction.editReply({ embeds: [successEmbed(`Whitelist + \`${license}\``)] });
        return;
      }
      if (sub === 'remove') {
        const license = interaction.options.getString('license', true);
        await fivem.whitelistRemove({
          license,
          staff: interaction.user.tag,
          staffId: interaction.user.id,
        });
        await interaction.editReply({ embeds: [successEmbed(`Whitelist − \`${license}\``)] });
        return;
      }
      const data = await fivem.whitelistList();
      const entries = data.entries || [];
      const text =
        entries.length === 0
          ? '_Whitelist vide_'
          : entries
              .slice(0, 40)
              .map((e) => `• \`${e.license}\` — ${e.note || '—'}`)
              .join('\n');
      await interaction.editReply({
        embeds: [baseEmbed(`Whitelist (${entries.length})`).setDescription(text)],
      });
    } catch (e) {
      await interaction.editReply({ embeds: [errorEmbed(e.message)] });
    }
  },
};
