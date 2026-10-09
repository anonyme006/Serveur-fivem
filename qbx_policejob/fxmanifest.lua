fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'qbx_policejob'
author 'Serveur RP'
description 'Métier Police Qbox — ressource all-in-one (ox_lib / ox_target / ox_inventory)'
version '0.1.0'

-- PHASE 1 : architecture, configuration, bridge Qbox.
-- Les scripts des phases suivantes seront ajoutés progressivement au fxmanifest.

dependencies {
    'ox_lib',
    'oxmysql',
    'qbx_core',
    'ox_target',
    'ox_inventory',
}

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
    'config/config.lua',
    'config/departments.lua',
    'config/weapons.lua',
    'config/vehicles.lua',
    'config/uniforms.lua',
    'config/objects.lua',
    'config/prison.lua',
    'config/fines.lua',
    'shared/locales.lua',
    'shared/utils.lua',
    'shared/permissions.lua',
}

client_scripts {
    '@qbx_core/modules/playerdata.lua',
    'client/main.lua',
    'client/licenses.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/database.lua',
    'server/security.lua',
    'server/departments.lua',
    'server/licenses.lua',
    'server/main.lua',
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/app.js',
}

provide 'qbx_policejob'
