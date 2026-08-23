fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rp_burgershot'
description 'Burger Shot — job légal profond (craft, caisse, service)'
version '2.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
}

dependencies {
    'ox_lib',
    'ox_inventory',
    'ox_target',
    'qbx_core',
    'rp_core',
    'rp_jobs',
}
