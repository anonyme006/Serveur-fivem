fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'esx_neon_mecano'
description 'Neon Mechanic ESX — réparations, custom, bipeur, dépannage (fichier unique)'
version '2.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'neon_mechanic.lua',
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
