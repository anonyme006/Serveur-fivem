fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'qbx_druglabs'
author 'Qbox Community'
description 'Advanced possessable drug laboratory system for Qbox'
version '1.0.0'

ox_lib 'locale'

shared_scripts {
    '@ox_lib/init.lua',
    'config/shared.lua',
    'config/labs.lua',
    'config/recipes.lua',
    'shared/constants.lua',
    'shared/utils.lua',
}

client_scripts {
    'bridge/notifications.lua',
    'bridge/interaction.lua',
    'client/main.lua',
    'client/targets.lua',
    'client/interiors.lua',
    'client/production.lua',
    'client/plants.lua',
    'client/police.lua',
    'client/admin.lua',
    'client/nui.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'config/server.lua',
    'bridge/player.lua',
    'bridge/inventory.lua',
    'bridge/gangs.lua',
    'bridge/dispatch.lua',
    'bridge/notifications.lua',
    'server/logs.lua',
    'server/rate_limit.lua',
    'server/repository.lua',
    'server/access.lua',
    'server/ownership.lua',
    'server/rentals.lua',
    'server/buckets.lua',
    'server/stash.lua',
    'server/production.lua',
    'server/plants.lua',
    'server/police.lua',
    'server/admin.lua',
    'server/callbacks.lua',
    'server/main.lua',
}

ui_page 'web/dist/index.html'

files {
    'locales/*.json',
    'web/dist/index.html',
    'web/dist/assets/*',
}

dependencies {
    'ox_lib',
    'oxmysql',
    'ox_inventory',
    'ox_target',
    'qbx_core',
}
