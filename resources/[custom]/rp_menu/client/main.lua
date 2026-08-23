local open = false

local function setOpen(state)
    open = state
    SetNuiFocus(state, state)
    if not state then
        SendNUIMessage({ action = 'close' })
    end
end

local function openMenu()
    if open then return end
    local player = lib.callback.await('rp_menu:getOverview', false)
    if not player then return end
    local licenses = {}
    if GetResourceState('rp_licenses') == 'started' then
        licenses = lib.callback.await('rp_licenses:getMine', false) or {}
    end
    setOpen(true)
    SendNUIMessage({
        action = 'open',
        brand = Config.Brand,
        player = player,
        licenses = licenses,
    })
end

RegisterNUICallback('close', function(_, cb)
    setOpen(false)
    cb(1)
end)

RegisterNUICallback('duty', function(_, cb)
    if GetResourceState('rp_jobs') == 'started' then
        lib.callback.await('rp_jobs:toggleDuty', false)
    end
    cb(1)
end)

RegisterNUICallback('business', function(_, cb)
    local player = lib.callback.await('rp_menu:getOverview', false)
    if player and player.job and GetResourceState('rp_business') == 'started' then
        local info = lib.callback.await('rp_business:getInfo', false, player.job.name)
        if info then
            lib.notify({
                title = info.label,
                description = ('Solde suivi : %s$'):format(info.balance),
                type = 'inform',
            })
        else
            lib.notify({ description = 'Pas d\'accès entreprise.', type = 'error' })
        end
    end
    cb(1)
end)

RegisterNUICallback('anims', function(_, cb)
    setOpen(false)
    if GetResourceState('scully_emotemenu') == 'started' then
        ExecuteCommand('emotemenu')
    else
        lib.notify({ description = 'Menu animations non démarré.', type = 'error' })
    end
    cb(1)
end)

RegisterNUICallback('invoices', function(_, cb)
    setOpen(false)
    ExecuteCommand('factures')
    cb(1)
end)

RegisterNUICallback('logout', function(_, cb)
    setOpen(false)
    local confirm = lib.alertDialog({
        header = 'Déconnexion',
        content = 'Revenir à la sélection de personnage ?',
        centered = true,
        cancel = true,
    })
    if confirm == 'confirm' then
        TriggerServerEvent('rp_menu:server:logout')
    end
    cb(1)
end)

lib.addKeybind({
    name = 'rp_player_menu',
    description = 'Menu personnage Cinéma LS',
    defaultKey = Config.OpenKey,
    onPressed = openMenu,
})

RegisterCommand('menu', openMenu, false)
