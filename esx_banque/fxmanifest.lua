fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'esx_banque'
author 'VIBE'
description 'Banque & DAB ESX — comptes personnels et entreprise'
version '1.0.0'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/assets/*.svg',
}

shared_scripts {
    '@es_extended/imports.lua',
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
}

dependencies {
    'es_extended',
    'oxmysql',
    'ox_lib',
}
