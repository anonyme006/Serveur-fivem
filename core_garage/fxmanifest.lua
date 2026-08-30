fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'core_garage'
author 'VIBE'
description 'Garage premium ESX Legacy — public, personnel, entreprise, métier, fourrière, bateau, avion, hélico'
version '1.1.0'

shared_scripts {
    '@es_extended/imports.lua',
    '@ox_lib/init.lua',
    'config.lua',
    'locales/*.lua',
    'shared/utils.lua',
}

client_scripts {
    '@menuv/menuv.lua',
    'client/main.lua',
    'client/spawn.lua',
    'client/nui.lua',
    'client/admin.lua',
    'client/menuv.lua',
    'client/garage.lua',
    'client/store.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/database.lua',
    'server/security.lua',
    'server/main.lua',
    'server/garage.lua',
    'server/store.lua',
    'server/spawn.lua',
    'server/impound.lua',
    'server/company.lua',
    'server/admin.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/assets/*',
}

dependencies {
    'es_extended',
    'oxmysql',
    'ox_lib',
    'ox_target',
    'menuv',
}
