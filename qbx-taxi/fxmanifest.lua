fx_version 'cerulean'
game 'gta5'

name 'qbx-taxi'
description 'San Andreas Taxi Corporation — Entreprise taxi immersive pour Qbox'
author 'San Andreas Taxi Corporation'
version '1.0.0'

lua54 'yes'
use_experimental_fxv2_oal 'yes'

ox_lib 'locale'

dependencies {
    'ox_lib',
    'qbx_core',
    'oxmysql',
    'ox_target',
    'ox_inventory',
    'qbx-duty',
}

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
    'config.lua',
    'shared/utils.lua',
}

client_scripts {
    '@qbx_core/modules/playerdata.lua',
    'client/utils.lua',
    'client/main.lua',
    'client/duty.lua',
    'client/dispatch.lua',
    'client/rides.lua',
    'client/vehicle.lua',
    'client/garage.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/database.lua',
    'server/callbacks.lua',
    'server/billing.lua',
    'server/rides.lua',
    'server/main.lua',
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/app.js',
    'web/assets/logo.png',
}
