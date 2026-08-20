fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'kx_mechanic'
author 'KX Development'
description 'Advanced professional mechanic system for Qbox'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/utils.lua',
}

client_scripts {
    'client/main.lua',
    'client/vehicle.lua',
    'client/zones.lua',
    'client/mechanic.lua',
    'client/menus.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/database.lua',
    'server/main.lua',
    'server/mechanic.lua',
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/app.js',
}

dependencies {
    'ox_lib',
    'ox_target',
    'ox_inventory',
    'oxmysql',
    'qbx_core',
}