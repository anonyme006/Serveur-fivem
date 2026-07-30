fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'ox_inventory_ui'
author 'VIBE'
description 'Thème inventaire style ox_inventory — Utiliser vert, Fermer rouge'
version '1.0.0'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/preview.html',
}

client_scripts {
    'client/main.lua',
}

dependencies {
    'ox_inventory',
}
