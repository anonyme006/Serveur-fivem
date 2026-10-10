fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'qbx_player_portal'
author 'Serenity V'
description 'Synchronisation serveur Qbox ↔ portail joueur HTTPS'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/crypto.js',
    'modules/database.lua',
    'modules/qbx.lua',
    'modules/sync.lua',
    'server.lua',
}

dependencies {
    'oxmysql',
    'ox_lib',
    'qbx_core',
}
