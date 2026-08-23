local function openCharacterMenu()
    local data = lib.callback.await('rp_menu:getOverview', false)
    if not data then return end

    lib.registerContext({
        id = 'rp_menu_character',
        title = L('identity'),
        menu = 'rp_menu_main',
        options = {
            { title = data.name, description = 'CitizenID : ' .. data.citizenid, icon = 'id-card' },
            { title = 'Naissance', description = tostring(data.birthdate), icon = 'cake-candles' },
            { title = 'Nationalité', description = tostring(data.nationality), icon = 'flag' },
            { title = 'Téléphone', description = tostring(data.phone), icon = 'phone' },
            {
                title = L('licenses'),
                icon = 'passport',
                onSelect = function()
                    if GetResourceState('rp_licenses') ~= 'started' then return end
                    local licenses = lib.callback.await('rp_licenses:getMine', false) or {}
                    local opts = {}
                    for _, lic in ipairs(licenses) do
                        opts[#opts + 1] = {
                            title = lic.label,
                            description = lic.owned and 'Possédé' or 'Non possédé',
                            icon = lic.owned and 'check' or 'xmark',
                        }
                    end
                    lib.registerContext({ id = 'rp_menu_licenses', title = L('licenses'), menu = 'rp_menu_character', options = opts })
                    lib.showContext('rp_menu_licenses')
                end,
            },
            {
                title = L('info'),
                description = ('Cash %s$ | Banque %s$'):format(data.cash, data.bank),
                icon = 'wallet',
            },
        }
    })
    lib.showContext('rp_menu_character')
end

local function openJobMenu()
    local data = lib.callback.await('rp_menu:getOverview', false)
    if not data or not data.job then return end
    local job = data.job
    lib.registerContext({
        id = 'rp_menu_job',
        title = L('job'),
        menu = 'rp_menu_main',
        options = {
            {
                title = job.label or job.name,
                description = ('Grade : %s | Service : %s'):format(
                    job.grade and job.grade.name or '?',
                    job.onduty and 'Oui' or 'Non'
                ),
                icon = 'briefcase',
            },
            {
                title = L('duty'),
                icon = 'toggle-on',
                onSelect = function()
                    if GetResourceState('rp_jobs') == 'started' then
                        lib.callback.await('rp_jobs:toggleDuty', false)
                    end
                end,
            },
            {
                title = L('business'),
                icon = 'building',
                onSelect = function()
                    if GetResourceState('rp_business') ~= 'started' then return end
                    local info = lib.callback.await('rp_business:getInfo', false, job.name)
                    if not info then
                        lib.notify({ description = 'Pas d\'accès entreprise.', type = 'error' })
                        return
                    end
                    lib.notify({
                        title = info.label,
                        description = ('Solde suivi : %s$ | Boss : %s'):format(info.balance, info.isBoss and 'Oui' or 'Non'),
                        type = 'inform',
                    })
                end,
            },
        }
    })
    lib.showContext('rp_menu_job')
end

local function openMain()
    lib.registerContext({
        id = 'rp_menu_main',
        title = L('menu_title'),
        options = {
            {
                title = 'PERSONNAGE',
                description = L('identity') .. ' / ' .. L('licenses'),
                icon = 'user',
                onSelect = openCharacterMenu,
            },
            {
                title = 'VÉHICULE',
                description = L('vehicle') .. ' / ' .. L('keys'),
                icon = 'car',
                onSelect = function()
                    lib.notify({ description = 'Utilisez qbx_vehiclekeys / garages pour la gestion.', type = 'inform' })
                end,
            },
            {
                title = 'TRAVAIL',
                description = L('job') .. ' / ' .. L('duty'),
                icon = 'briefcase',
                onSelect = openJobMenu,
            },
            {
                title = 'ANIMATIONS',
                description = L('anims') .. ' / ' .. L('walks'),
                icon = 'person-walking',
                onSelect = function()
                    if GetResourceState('scully_emotemenu') == 'started' then
                        ExecuteCommand('emotemenu')
                    else
                        lib.notify({ description = 'Menu animations (scully_emotemenu) non démarré.', type = 'error' })
                    end
                end,
            },
            {
                title = 'DIVERS',
                icon = 'gear',
                onSelect = function()
                    lib.registerContext({
                        id = 'rp_menu_misc',
                        title = 'Divers',
                        menu = 'rp_menu_main',
                        options = {
                            {
                                title = L('help'),
                                description = 'Discord / règles — config serveur',
                                icon = 'circle-question',
                            },
                            {
                                title = 'Factures',
                                icon = 'file-invoice-dollar',
                                onSelect = function() ExecuteCommand('factures') end,
                            },
                            {
                                title = L('logout'),
                                icon = 'right-from-bracket',
                                onSelect = function()
                                    local confirm = lib.alertDialog({
                                        header = 'Déconnexion',
                                        content = 'Revenir à la sélection de personnage ?',
                                        centered = true,
                                        cancel = true,
                                    })
                                    if confirm == 'confirm' then
                                        TriggerServerEvent('rp_menu:server:logout')
                                    end
                                end,
                            },
                        }
                    })
                    lib.showContext('rp_menu_misc')
                end,
            },
        }
    })
    lib.showContext('rp_menu_main')
end

lib.addKeybind({
    name = 'rp_player_menu',
    description = 'Ouvrir le menu joueur',
    defaultKey = Config.OpenKey,
    onPressed = function()
        openMain()
    end,
})

RegisterCommand('menu', openMain, false)
