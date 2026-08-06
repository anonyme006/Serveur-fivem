fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'core_wholesaler'
author 'Core Scripts'
description 'Grossiste centralisé pour entreprises — Qbox / ox_lib / ox_target / ox_inventory / oxmysql'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'locales/*.lua',
    'shared/*.lua',
}

client_scripts {
    'client/*.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua',
}

dependencies {
    'ox_lib',
    'ox_target',
    'ox_inventory',
    'oxmysql',
    'qbx_core',
}
