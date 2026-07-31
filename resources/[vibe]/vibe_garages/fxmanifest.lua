fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'vibe_garages'
description 'Garages simplifiés (stub Ox + Qbox)'
version '0.1.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts { 'client/main.lua' }
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

dependencies { 'ox_lib', 'ox_target', 'qbx_core', 'vibe_api' }
