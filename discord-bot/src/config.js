'use strict';

const fs = require('fs');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

const configPath = path.join(__dirname, '..', 'config.json');
let fileConfig = {};

if (fs.existsSync(configPath)) {
  fileConfig = JSON.parse(fs.readFileSync(configPath, 'utf8'));
} else {
  const example = path.join(__dirname, '..', 'config.example.json');
  if (fs.existsSync(example)) {
    fileConfig = JSON.parse(fs.readFileSync(example, 'utf8'));
  }
}

const required = ['DISCORD_TOKEN', 'DISCORD_CLIENT_ID', 'BRIDGE_SECRET', 'FIVEM_BRIDGE_URL'];
for (const key of required) {
  if (!process.env[key]) {
    console.warn(`[config] Variable manquante: ${key}`);
  }
}

module.exports = {
  token: process.env.DISCORD_TOKEN || '',
  clientId: process.env.DISCORD_CLIENT_ID || '',
  guildId: process.env.DISCORD_GUILD_ID || '',
  bridgeSecret: process.env.BRIDGE_SECRET || '',
  fivemUrl: (process.env.FIVEM_BRIDGE_URL || 'http://127.0.0.1:30120/vibe_discord').replace(/\/$/, ''),
  botName: process.env.BOT_NAME || 'Vibe RP',
  roles: fileConfig.roles || { admin: [], moderator: [], staff: [] },
  channels: fileConfig.channels || {},
  statusIntervalMs: fileConfig.statusIntervalMs || 60000,
  embedColor: fileConfig.embedColor || 0x597f7e,
};
