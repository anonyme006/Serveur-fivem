fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'qbx_ressources'
author 'VIBE'
description 'Pack QBox unifié — core RP, duty/blips entreprises, corps endormis'
version '1.0.0'

-- Compat dépendances anciennes ressources
provide 'qbx_rp_core'
provide 'qbx-duty'
provide 'qbx_sleeping_bodies'

shared_scripts {
    '@ox_lib/init.lua',
    'config/init.lua',
    'config/core.lua',
    'config/duty.lua',
    'config/sleeping.lua',
    'locales/fr.lua',
    'shared/utils.lua',
    'shared/qbx.lua',
    'shared/duty_jobs.lua',
    'shared/sleeping_utils.lua',
}

client_scripts {
    -- Core RP
    'client/core/alerts.lua',
    'client/core/map.lua',
    'client/core/damage.lua',
    'client/core/persistence.lua',
    'client/core/keys.lua',
    'client/core/bridge_keys.lua',
    'client/core/key_item.lua',
    'client/core/keyshop.lua',
    'client/core/wallet.lua',
    'client/core/cover.lua',
    'client/core/used_parking.lua',
    'client/core/offroad.lua',
    'client/core/weather.lua',
    'client/core/network.lua',
    -- Duty
    'client/duty/main.lua',
    'client/duty/duty.lua',
    'client/duty/blips.lua',
    -- Sleeping bodies
    'client/sleeping/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/bootstrap.lua',
    -- Core RP
    'server/core/main.lua',
    'server/core/discord.lua',
    'server/core/discord_hooks.lua',
    'server/core/persistence.lua',
    'server/core/inventory_keys.lua',
    'server/core/keys.lua',
    'server/core/bridge_keys.lua',
    'server/core/keyshop.lua',
    'server/core/wallet.lua',
    'server/core/cover.lua',
    'server/core/used_parking.lua',
    'server/core/weather.lua',
    'server/core/network.lua',
    -- Duty
    'server/duty/players.lua',
    'server/duty/duty.lua',
    'server/duty/main.lua',
    -- Sleeping bodies
    'server/sleeping/main.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/duty_style.css',
    'html/duty_app.js',
    'sql/qbx_ressources.sql',
}

dependencies {
    'qbx_core',
    'oxmysql',
    'ox_lib',
    'ox_target',
}
