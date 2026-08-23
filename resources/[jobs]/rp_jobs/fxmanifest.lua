fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rp_jobs'
description 'Enregistrement & configuration des métiers FR (Qbox CreateJobs)'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/jobs.lua',
    'locales/fr.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
}

dependencies {
    'ox_lib',
    'qbx_core',
    'rp_core',
}
