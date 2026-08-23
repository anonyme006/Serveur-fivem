fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rp_garages'
description 'Garages NUI FR optionnels (désactivez qbx_garages si utilisé)'
version '1.0.0'

ui_page 'web/index.html'

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
}

files {
    'web/index.html',
    'web/css/style.css',
    'web/js/app.js',
}

dependencies {
    'ox_lib',
    'oxmysql',
    'qbx_core',
    'rp_core',
}
