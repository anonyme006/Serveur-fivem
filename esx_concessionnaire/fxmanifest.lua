fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'esx_concessionnaire'
author 'VIBE'
description 'Concessionnaire véhicules ESX — UI Voiture / VIBE'
version '1.0.0'

shared_scripts {
    '@es_extended/imports.lua',
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

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/style.css',
    'html/js/app.js',
    'html/img/logo.svg',
}

dependencies {
    'es_extended',
    'oxmysql',
}
