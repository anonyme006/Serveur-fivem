fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'vibe_neon_mecano'
description 'Neon Mechanic — tout-en-un (réparations, custom, bipeur, dépannage)'
version '1.1.0'

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
    'ox_lib',
    'ox_target',
    'qbx_core',
    'vibe_api',
}
