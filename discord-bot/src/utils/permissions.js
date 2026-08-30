'use strict';

const config = require('../config');

const LEVEL = {
  admin: 3,
  moderator: 2,
  staff: 1,
};

function memberLevel(member) {
  if (!member) return 0;
  const ids = member.roles.cache;
  if (config.roles.admin?.some((id) => ids.has(id))) return LEVEL.admin;
  if (config.roles.moderator?.some((id) => ids.has(id))) return LEVEL.moderator;
  if (config.roles.staff?.some((id) => ids.has(id))) return LEVEL.staff;
  if (member.permissions.has('Administrator')) return LEVEL.admin;
  return 0;
}

function requireLevel(minLevel) {
  return (interaction) => {
    const level = memberLevel(interaction.member);
    if (level < minLevel) {
      return { ok: false, message: 'Tu n\'as pas la permission pour cette commande.' };
    }
    return { ok: true, level };
  };
}

module.exports = { LEVEL, memberLevel, requireLevel };
