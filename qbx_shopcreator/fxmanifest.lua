fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'qbx_shopcreator'
author 'Serveur-fivem'
description 'Shop Creator & Business Management — native Qbox / ox suite'
version '1.0.0'

ui_page 'web/dist/index.html'

files {
    'web/dist/index.html',
    'web/dist/assets/*',
}

shared_scripts {
    '@ox_lib/init.lua',
    'config/shared.lua',
    'shared/*.lua',
    'locales/*.lua',
}

client_scripts {
    'client/*.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'config/server.lua',
    'server/*.lua',
}

dependencies {
    'ox_lib',
    'ox_target',
    'ox_inventory',
    'oxmysql',
    'qbx_core',
}