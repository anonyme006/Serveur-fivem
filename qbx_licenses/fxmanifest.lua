fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'qbx_licenses'
author 'Serenity V RP'
description 'Permis à points — voiture, moto, bateau, avion + retrait police'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'locales/fr.lua',
    'shared/*.lua',
}

client_scripts {
    'client/main.lua',
    'client/police.lua',
    'client/card.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/police.lua',
    'server/card.lua',
    'bridge/qbx_idcard.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
}

dependencies {
    'ox_lib',
    'oxmysql',
    'qbx_core',
}
