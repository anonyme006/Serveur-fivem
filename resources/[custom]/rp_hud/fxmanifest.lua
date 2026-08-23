fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rp_hud'
description 'HUD moderne optionnel (désactivez qbx_hud si utilisé)'
version '1.0.0'

ui_page 'web/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
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
