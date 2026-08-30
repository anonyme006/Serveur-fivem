fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'serenity_loadingscreen'
author 'Serenity V RP'
description 'Loading screen Serenity V RP'
version '1.0.0'

loadscreen 'html/index.html'
loadscreen_cursor 'yes'
loadscreen_manual_shutdown 'yes'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/config.js',
    'html/logo.jpg',
}

client_script 'client.lua'
