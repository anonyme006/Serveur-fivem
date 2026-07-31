local activeAlert = nil
local missionBlip = nil

local function clearBlip()
    if missionBlip and DoesBlipExist(missionBlip) then
        RemoveBlip(missionBlip)
    end
    missionBlip = nil
end

local function setMissionBlip(coords, route)
    clearBlip()
    missionBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(missionBlip, Config.Bipeur.blipSprite)
    SetBlipColour(missionBlip, Config.Bipeur.blipColor)
    SetBlipScale(missionBlip, 1.0)
    SetBlipFlashes(missionBlip, true)
    if route then SetBlipRoute(missionBlip, true) end
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Dépannage Neon')
    EndTextCommandSetBlipName(missionBlip)
end

local function playBipeurSound()
    if not Config.Bipeur.sound then return end
    SendNUIMessage({ action = 'beep' })
    PlaySoundFrontend(-1, 'Text_Arrive_Tone', 'Phone_SoundSet_Default', true)
end

local function showBipeurNui(data, show)
    SendNUIMessage({
        action = show and 'show' or 'hide',
        company = Config.CompanyName,
        code = data and data.code or '',
        message = data and data.message or '',
        from = data and data.from or '',
        payout = data and data.payout and ('~%d$'):format(data.payout) or '',
    })
end

RegisterNetEvent('vibe_neon_mecano:client:bipeur', function(data)
    if not Neon.IsMechanic() then return end
    activeAlert = data
    playBipeurSound()
    showBipeurNui(data, true)
    Neon.Notify('Bipeur', data.message, 'inform')
    setMissionBlip(data.coords, false)
    SetTimeout(Config.Bipeur.blipTime * 1000, function()
        if activeAlert and activeAlert.id == data.id then
            clearBlip()
        end
    end)
end)

RegisterNetEvent('vibe_neon_mecano:client:missionAccepted', function(data)
    activeAlert = data
    showBipeurNui(nil, false)
    setMissionBlip(data.coords, true)
    TriggerEvent('vibe_neon_mecano:client:startMission', data)
    Neon.Notify('Mission acceptée', 'Rends-toi sur les lieux du dépannage.', 'success')
end)

RegisterNetEvent('vibe_neon_mecano:client:missionEnded', function()
    activeAlert = nil
    showBipeurNui(nil, false)
    clearBlip()
end)

RegisterNetEvent('vibe_neon_mecano:client:openBipeur', function()
    if not Neon.IsMechanic() then
        Neon.Notify(nil, 'Service requis.', 'error')
        return
    end

    local options = {
        {
            title = 'Statut bipeur',
            description = activeAlert and ('Appel en cours : %s'):format(activeAlert.label or activeAlert.code) or 'Aucun appel actif',
            icon = 'pager',
            disabled = true,
        },
    }

    if activeAlert and not activeAlert.accepted then
        options[#options + 1] = {
            title = 'Accepter l\'appel',
            icon = 'check',
            onSelect = function()
                TriggerServerEvent('vibe_neon_mecano:server:acceptMission', activeAlert.id)
            end,
        }
        options[#options + 1] = {
            title = 'Refuser',
            icon = 'xmark',
            onSelect = function()
                TriggerServerEvent('vibe_neon_mecano:server:declineMission', activeAlert.id)
                activeAlert = nil
                showBipeurNui(nil, false)
                clearBlip()
            end,
        }
    elseif activeAlert and activeAlert.accepted then
        options[#options + 1] = {
            title = 'GPS vers l\'intervention',
            icon = 'location-dot',
            onSelect = function()
                setMissionBlip(activeAlert.coords, true)
            end,
        }
        options[#options + 1] = {
            title = 'Abandonner la mission',
            icon = 'ban',
            onSelect = function()
                TriggerServerEvent('vibe_neon_mecano:server:cancelMission', activeAlert.id)
            end,
        }
    else
        options[#options + 1] = {
            title = 'En attente d\'appels...',
            description = 'Reste en service pour recevoir des missions',
            icon = 'hourglass',
            disabled = true,
        }
    end

    lib.registerContext({ id = 'neon_bipeur', title = 'Bipeur Neon Mechanic', options = options })
    lib.showContext('neon_bipeur')
end)

RegisterCommand(Config.Bipeur.command, function()
    TriggerEvent('vibe_neon_mecano:client:openBipeur')
end, false)

RegisterKeyMapping(Config.Bipeur.command, 'Ouvrir le bipeur Neon Mechanic', 'keyboard', Config.Bipeur.keybind)

RegisterNUICallback('accept', function(_, cb)
    if activeAlert and not activeAlert.accepted then
        TriggerServerEvent('vibe_neon_mecano:server:acceptMission', activeAlert.id)
    end
    cb('ok')
end)

RegisterNUICallback('decline', function(_, cb)
    if activeAlert then
        TriggerServerEvent('vibe_neon_mecano:server:declineMission', activeAlert.id)
        activeAlert = nil
        showBipeurNui(nil, false)
        clearBlip()
    end
    cb('ok')
end)

RegisterNUICallback('close', function(_, cb)
    showBipeurNui(nil, false)
    cb('ok')
end)

exports('GetActiveAlert', function()
    return activeAlert
end)

exports('ClearMissionBlip', clearBlip)
