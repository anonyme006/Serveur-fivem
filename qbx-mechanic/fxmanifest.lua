fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'qbx-mechanic'
author 'Qbox Mechanic'
description 'Professional mechanic system for Qbox — repairs, diagnostics, tuning, billing, stock & management'
version '0.1.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/utils.lua',
}

client_scripts {
    '@qbx_core/modules/playerdata.lua',
    'client/utils.lua',
    'client/main.lua',
    'client/zones.lua',
    'client/vehicle.lua',
    'client/repair.lua',
    'client/customization.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/database.lua',
    'server/callbacks.lua',
    'server/main.lua',
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/preview.html',
    'web/style.css',
    'web/preview.css',
    'web/app.js',
    'web/preview-boot.js',
    'web/assets/.gitkeep',
}

dependencies {
    'ox_lib',
    'ox_target',
    'oxmysql',
    'qbx_core',
}

provide 'qbx-mechanic'
