fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rp_menu'
description 'Menu joueur NUI cinéma / streamer'
version '2.0.0'

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
    'server/main.lua',
}

files {
    'web/index.html',
    'web/css/style.css',
    'web/js/app.js',
}

dependencies {
    'ox_lib',
    'qbx_core',
    'rp_core',
}
