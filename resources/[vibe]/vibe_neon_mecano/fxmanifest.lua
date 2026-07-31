fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'vibe_neon_mecano'
description 'Neon Mechanic — réparations réalistes, custom, bipeur et missions dépannage'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/utils.lua',
    'client/repair.lua',
    'client/custom.lua',
    'client/bipeur.lua',
    'client/missions.lua',
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
    'server/missions.lua',
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
