fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'qbox-restaurants'
author 'Serveur FiveM'
description 'Système de restaurant multi-établissements — Horny\'s & Greasy Joe\'s'
version '2.1.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/utils.lua',
    'shared/products.lua',
    'shared/recipes.lua',
    'shared/locations.lua',
}

client_scripts {
    'client/main.lua',
    'client/target.lua',
    'client/tablet.lua',
    'client/crafting.lua',
    'client/sales.lua',
    'client/billing.lua',
    'client/employees.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/stock.lua',
    'server/crafting.lua',
    'server/sales.lua',
    'server/billing.lua',
    'server/employees.lua',
    'server/callbacks.lua',
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/app.js',
    'web/assets/*',
    'web/pages/*.html',
}

dependencies {
    'ox_lib',
    'oxmysql',
    'ox_inventory',
    'ox_target',
    'qbx_core',
}
