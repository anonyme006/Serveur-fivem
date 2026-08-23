fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rp_core'
author 'Serveur-fivem'
description 'Noyau custom FR — bridge Qbox, config centrale, notify, sécurité'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/utils.lua',
    'locales/*.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/bridge.lua',
    'server/security.lua',
}

dependencies {
    'ox_lib',
    'oxmysql',
    'qbx_core',
}

provides {
    'rp_core',
}
