fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pa_bennys'
description "Benny's ESX — réparations, custom, bipeur, missions dépannage"
version '1.0.0'
author 'PA Scripts'

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

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'sql/install.sql',
}

dependencies {
    'es_extended',
    'ox_lib',
    'ox_target',
}
