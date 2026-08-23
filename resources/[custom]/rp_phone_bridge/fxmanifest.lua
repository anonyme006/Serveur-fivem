fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rp_phone_bridge'
description 'Pont téléphone — NPWD / LB Phone / sd-phone'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

client_scripts {
    'client/main.lua',
}

dependencies {
    'ox_lib',
    'oxmysql',
    'qbx_core',
    'rp_core',
}
