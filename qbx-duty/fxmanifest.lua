fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'qbx-duty'
author 'VIBE'
description 'Système global de prise de service et blips dynamiques pour toutes les entreprises Qbox'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/jobs.lua',
}

client_scripts {
    'client/main.lua',
    'client/duty.lua',
    'client/blips.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/players.lua',
    'server/duty.lua',
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/app.js',
}

dependencies {
    'qbx_core',
    'ox_lib',
    'ox_target',
    'oxmysql',
}
