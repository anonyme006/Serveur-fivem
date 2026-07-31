fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'esx_core'
author 'VIBE'
description 'Core RP — persistance véhicules, fourrière reboot, clés, portefeuille, bâche, occasions, alertes'
version '1.0.0'

shared_scripts {
    '@es_extended/imports.lua',
    '@ox_lib/init.lua',
    'config.lua',
    'locales/fr.lua',
    'shared/utils.lua',
}

client_scripts {
    'client/alerts.lua',
    'client/map.lua',
    'client/damage.lua',
    'client/persistence.lua',
    'client/keys.lua',
    'client/bridge_keys.lua',
    'client/wallet.lua',
    'client/cover.lua',
    'client/used_parking.lua',
    'client/offroad.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/persistence.lua',
    'server/keys.lua',
    'server/bridge_keys.lua',
    'server/wallet.lua',
    'server/cover.lua',
    'server/used_parking.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
}

dependencies {
    'es_extended',
    'oxmysql',
    'ox_lib',
}
