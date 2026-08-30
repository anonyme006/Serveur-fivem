fx_version 'cerulean'
game 'gta5'

name 'qbx-taxi'
description 'San Andreas Taxi Corporation — Système taxi RP pour Qbox (MenuV)'
author 'San Andreas Taxi Corporation'
version '1.0.0'

lua54 'yes'
use_experimental_fxv2_oal 'yes'

ox_lib 'locale'

--- MenuV doit démarrer AVANT qbx-taxi (server.cfg : ensure menuv)
dependencies {
    'menuv',
    'ox_lib',
    'qbx_core',
    'oxmysql',
    'ox_target',
    'ox_inventory',
    'qbx-duty',
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

--- Scripts client / serveur ajoutés aux étapes suivantes :
--- Étape 2  : @menuv/menuv.lua + intégration MenuV
--- Étape 3+ : client/menu_*.lua, client/main.lua, server/*.lua, shared/utils.lua

files {
    'web/assets/logo.png',
}
