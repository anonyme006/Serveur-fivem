fx_version 'cerulean'
game 'gta5'

name 'esx_hud'
author 'Serveur-fivem'
description 'HUD ESX minimaliste — barres santé/faim/soif + speedometer circulaire'
version '1.0.0'

lua54 'yes'

shared_script 'config.lua'

client_script 'client/main.lua'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
}

dependencies {
    'es_extended',
}
