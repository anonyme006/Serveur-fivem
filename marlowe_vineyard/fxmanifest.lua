fx_version 'cerulean'
game 'gta5'

name 'marlowe_vineyard'
description 'Marlowe Vineyard — Job Qbox + MenuV'
author 'Marlowe Vineyard'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/utils.lua',
}

client_scripts {
    '@qbx_core/modules/playerdata.lua',
    '@menuv/menuv.lua',
    'client/menu.lua',
    'client/main.lua',
    'client/vineyard.lua',
    'client/production.lua',
    'client/deliveries.lua',
    'client/garage.lua',
    'client/clothing.lua',
    'client/boss.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/database.lua',
    'server/main.lua',
    'server/production.lua',
    'server/deliveries.lua',
    'server/employees.lua',
    'server/finances.lua',
}

files {
    'html/images/Marlowe_Vineyard.png',
}

dependencies {
    'menuv',
    'qbx_core',
    'ox_lib',
    'ox_target',
    'ox_inventory',
    'oxmysql',
}
