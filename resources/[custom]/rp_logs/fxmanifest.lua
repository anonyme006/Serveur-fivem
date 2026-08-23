fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rp_logs'
description 'Logs serveur + Discord webhooks'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/utils.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

dependencies {
    'oxmysql',
    'ox_lib',
    'rp_core',
}
