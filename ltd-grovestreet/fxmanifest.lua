fx_version 'cerulean'
game 'gta5'

name 'ltd-grovestreet'
description 'LTD Grove Street — Magasin complet (ESX/QBCore, ox_lib, ox_target, ox_inventory)'
author 'Cursor Agent'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua',
}

dependencies {
    'ox_lib',
    'ox_target',
    'ox_inventory',
    'oxmysql',
}
