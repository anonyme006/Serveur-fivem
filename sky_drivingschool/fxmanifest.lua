fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'sky_drivingschool'
author 'Sky Development'
description 'American DMV Driving School for Qbox — theory, practical exams, licenses & points'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'locales/*.lua',
    'shared/*.lua',
}

client_scripts {
    'client/main.lua',
    'client/interactions.lua',
    'client/nui.lua',
    'client/theory.lua',
    'client/practical.lua',
    'client/license_card.lua',
    'client/admin.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/bridge.lua',
    'server/database.lua',
    'server/anticheat.lua',
    'server/license_adapter.lua',
    'server/payment.lua',
    'server/points.lua',
    'server/theory.lua',
    'server/practical.lua',
    'server/admin.lua',
    'server/main.lua',
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/app.js',
    'web/assets/*',
    'data/*.json',
}

dependencies {
    'ox_lib',
    'oxmysql',
}

provide 'sky_drivingschool'
