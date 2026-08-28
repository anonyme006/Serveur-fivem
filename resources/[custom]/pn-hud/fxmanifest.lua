fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pn-hud'
description 'HUD Qbox — interface générale légère et HUD véhicule moderne'
version '1.0.0'

ui_page 'web/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/fuel.lua',
    'client/seatbelt.lua',
    'client/vehicle.lua',
    'client/main.lua',
}

files {
    'web/index.html',
    'web/css/style.css',
    'web/css/vehicle.css',
    'web/js/app.js',
    'web/js/vehicle.js',
}

dependencies {
    'ox_lib',
    'qbx_core',
}
