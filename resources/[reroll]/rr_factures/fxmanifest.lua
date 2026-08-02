fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rr_factures'
description 'Factures joueur → joueur (stub)'
version '0.1.0'

shared_scripts { '@ox_lib/init.lua', 'config.lua' }
client_scripts { 'client/main.lua' }
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/main.lua' }
dependencies { 'ox_lib', 'oxmysql', 'qbx_core', 'rr_api' }
