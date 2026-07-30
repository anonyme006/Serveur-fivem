fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'core_creator'
author 'Core Creator'
description 'Admin in-game creator for shops, blips, farms, jobs, garages, gangs, apartments, robberies and vehicle keys'
version '1.0.0'

shared_scripts {
    'config.lua',
    'shared/utils.lua',
    'shared/locales.lua',
    'shared/bridge.lua',
    'shared/validator.lua',
}

client_scripts {
    'client/main.lua',
    'client/nui.lua',
    'client/placement.lua',
    'client/preview.lua',
    'client/creator.lua',
    'client/modules/*.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/database.lua',
    'server/permissions.lua',
    'server/logger.lua',
    'server/validator.lua',
    'server/main.lua',
    'server/importexport.lua',
    'server/modules/*.lua',
}

ui_page 'web/dist/index.html'

files {
    'web/dist/index.html',
    'web/dist/assets/*',
    'locales/*.json',
}

dependencies {
    'oxmysql',
}

-- Optional soft dependencies (auto-detected):
-- es_extended | qb-core | qbx_core
-- ox_lib | ox_inventory | ox_target | qb-target
