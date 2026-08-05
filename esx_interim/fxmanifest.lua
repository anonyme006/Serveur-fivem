fx_version 'cerulean'
game 'gta5'

name 'esx_interim'
description 'Pôle Emploi — Jobs intérim (plombier, éboueur, livreur, électricien, mineur/joaillerie)'
author 'Cursor Agent'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'locales/fr.lua',
}

client_scripts {
    'client/main.lua',
    'client/jobs.lua',
}

server_scripts {
    'server/main.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
}

dependencies {
    'es_extended',
    'ox_lib',
    'ox_target',
}

