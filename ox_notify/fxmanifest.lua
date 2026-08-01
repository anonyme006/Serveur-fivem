fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'ox_notify'
author 'Serveur-fivem'
description 'Notifications style ox_lib — barre gauche + progress bas (look photo)'
version '1.0.0'

shared_script 'config.lua'

client_scripts {
    'client/main.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
}

exports {
    'Notify',
    'Alert',
}
