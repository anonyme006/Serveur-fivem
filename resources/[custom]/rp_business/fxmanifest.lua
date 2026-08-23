fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rp_business'
description 'API entreprises — comptes, stock, employés, historique'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'locales/fr.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/api.lua',
}

dependencies {
    'ox_lib',
    'oxmysql',
    'qbx_core',
    'rp_core',
}
