fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rr_spawnselector'
description 'Sélecteur de spawn (stub Qbox)'
version '0.1.0'

shared_scripts {
    '@ox_lib/init.lua',
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

dependencies {
    'ox_lib',
    'qbx_core',
    'rr_api',
}
