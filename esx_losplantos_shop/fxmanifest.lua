fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'esx_losplantos_shop'
author 'Los Plantos'
description 'Menu magasin list-style Los Plantos pour ESX'
version '1.0.0'

shared_scripts {
    '@es_extended/imports.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/assets/*',
    'html/img/*',
}

dependencies {
    'es_extended',
}
