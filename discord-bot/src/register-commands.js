'use strict';

/**
 * Enregistre les slash commands auprès de Discord.
 * Usage: npm run register
 */
const fs = require('fs');
const path = require('path');
const { REST, Routes } = require('discord.js');
const config = require('./config');

const commands = [];
const dir = path.join(__dirname, 'commands');
for (const file of fs.readdirSync(dir).filter((f) => f.endsWith('.js'))) {
  const cmd = require(path.join(dir, file));
  if (cmd?.data) commands.push(cmd.data.toJSON());
}

async function main() {
  if (!config.token || !config.clientId) {
    console.error('DISCORD_TOKEN / DISCORD_CLIENT_ID requis');
    process.exit(1);
  }
  const rest = new REST({ version: '10' }).setToken(config.token);
  console.log(`Enregistrement de ${commands.length} commandes…`);
  if (config.guildId) {
    await rest.put(Routes.applicationGuildCommands(config.clientId, config.guildId), {
      body: commands,
    });
    console.log(`OK (guild ${config.guildId})`);
  } else {
    await rest.put(Routes.applicationCommands(config.clientId), { body: commands });
    console.log('OK (global — peut prendre jusqu\'à 1h)');
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
