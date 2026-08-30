fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rr_discord_gate'
description 'Vérification Discord (rôle Citoyen) + NUI accès / sélection personnages'
version '1.0.0'
author 'RE ROLL'

shared_scripts {
    'config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/app.js',
}
