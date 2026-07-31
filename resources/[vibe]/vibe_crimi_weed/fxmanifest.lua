fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'vibe_crimi_weed'
description 'Circuit weed basique (stub — à équilibrer)'
version '0.1.0'

shared_scripts { '@ox_lib/init.lua', 'config.lua' }
client_scripts { 'client/main.lua' }
server_scripts { 'server/main.lua' }
dependencies { 'ox_lib', 'ox_target', 'ox_inventory', 'qbx_core' }
