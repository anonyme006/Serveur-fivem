fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'sd-company-announcements'
author 'Serveur-fivem'
version '1.0.0'
description 'Application Annonces Entreprise pour SD-Phone (ESX Legacy)'

shared_scripts {
    '@es_extended/imports.lua',
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/client.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua',
}

files {
    'web/**/*',
}

-- ui_page is required so GetResourceMetadata can resolve the UI path for
-- sd-phone addCustomApp. Body stays visibility:hidden so the fullscreen
-- overlay never paints over the game.
ui_page 'web/index.html'

dependencies {
    'es_extended',
    'oxmysql',
    'ox_lib',
    'sd-phone',
}