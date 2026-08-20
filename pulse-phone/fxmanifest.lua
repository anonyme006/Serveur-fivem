fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pulse-phone'
author 'Pulse Collective'
description 'Téléphone RP original pour Qbox — Services, appels, messages, banque'
version '0.1.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
    'shared/utils.lua',
    'locales/*.lua',
}

client_scripts {
    'client/main.lua',
    'client/phone.lua',
    'client/calls.lua',
    'client/notifications.lua',
    'client/services.lua',
    'client/exports.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/database.lua',
    'server/players.lua',
    'server/contacts.lua',
    'server/messages.lua',
    'server/calls.lua',
    'server/companies.lua',
    'server/services.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/assets/**/*',
    'html/sounds/**/*',
}

dependencies {
    'qbx_core',
    'ox_lib',
    'ox_inventory',
    'oxmysql',
    'pma-voice',
}

provides {
    'pulse-phone',
}
