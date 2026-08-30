fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'vibe_discord'
author 'Vibe RP'
description 'Bridge Discord ↔ FiveM (gestion IG + logs Discord)'
version '1.0.0'

shared_scripts {
    'config/config.lua',
}

server_scripts {
    'server/players.lua',
    'server/actions.lua',
    'server/logs.lua',
    'server/http.lua',
    'server/main.lua',
}

client_scripts {
    'client/main.lua',
}

dependencies {
    '/server:7290',
}

