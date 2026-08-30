'use strict';

const fs = require('fs');
const path = require('path');
const {
  Client,
  Collection,
  GatewayIntentBits,
  Partials,
  Events,
} = require('discord.js');
const config = require('./config');
const { startLogServer } = require('./services/logServer');
const { startStatusUpdater } = require('./services/statusUpdater');
const { errorEmbed } = require('./services/embeds');
const { log, error } = require('./utils/logger');

const client = new Client({
  intents: [GatewayIntentBits.Guilds, GatewayIntentBits.GuildMembers],
  partials: [Partials.Channel],
});

client.commands = new Collection();

const commandsDir = path.join(__dirname, 'commands');
for (const file of fs.readdirSync(commandsDir).filter((f) => f.endsWith('.js'))) {
  const cmd = require(path.join(commandsDir, file));
  if (cmd?.data?.name) client.commands.set(cmd.data.name, cmd);
}

client.once(Events.ClientReady, (c) => {
  log(`Connecté en tant que ${c.user.tag}`);
  startLogServer(client, Number(process.env.LOG_PORT || 3847));
  startStatusUpdater(client);
});

client.on(Events.InteractionCreate, async (interaction) => {
  if (!interaction.isChatInputCommand()) return;
  const command = client.commands.get(interaction.commandName);
  if (!command) return;

  try {
    if (command.check) {
      const gate = command.check(interaction);
      if (!gate.ok) {
        await interaction.reply({ embeds: [errorEmbed(gate.message)], ephemeral: true });
        return;
      }
    }
    await command.execute(interaction);
  } catch (e) {
    error(`commande /${interaction.commandName}`, e);
    const payload = { embeds: [errorEmbed('Erreur interne du bot.')], ephemeral: true };
    if (interaction.deferred || interaction.replied) {
      await interaction.followUp(payload).catch(() => {});
    } else {
      await interaction.reply(payload).catch(() => {});
    }
  }
});

if (!config.token) {
  console.error('DISCORD_TOKEN manquant. Copie .env.example → .env');
  process.exit(1);
}

client.login(config.token);
