local cuffed = false
local escorted = false
local escorting = nil

local function getClosestPlayer(maxDist)
    local coords = GetEntityCoords(cache.ped)
    local closest, closestDist
    for _, playerId in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(playerId)
        if ped ~= cache.ped then
            local dist = #(coords - GetEntityCoords(ped))
            if dist < (maxDist or 3.0) and (not closestDist or dist < closestDist) then
                closest = GetPlayerServerId(playerId)
                closestDist = dist
            end
        end
    end
    return closest
end

local function openMenu()
    if not exports.vibe_api:IsPolice(true) then
        exports.vibe_api:Notify('FDO', 'Service requis.', 'error')
        return
    end
    local target = getClosestPlayer(Config.MaxCuffDistance)
    if not target then
        exports.vibe_api:Notify('FDO', 'Aucun citoyen à proximité.', 'error')
        return
    end

    lib.registerContext({
        id = 'vibe_fdo_menu',
        title = ('FDO — ID %s'):format(target),
        options = {
            {
                title = 'Menotter / Démenotter',
                icon = 'handcuffs',
                onSelect = function()
                    TriggerServerEvent('vibe_fdo:server:cuff', target)
                end,
            },
            {
                title = 'Escorter',
                icon = 'person-walking',
                onSelect = function()
                    TriggerServerEvent('vibe_fdo:server:escort', target)
                end,
            },
            {
                title = 'Fouiller',
                icon = 'magnifying-glass',
                onSelect = function()
                    TriggerServerEvent('vibe_fdo:server:search', target)
                end,
            },
            {
                title = 'Amende',
                icon = 'file-invoice-dollar',
                onSelect = function()
                    if GetResourceState('vibe_amende') == 'started' then
                        exports.vibe_amende:OpenFineMenu(target)
                    else
                        exports.vibe_api:Notify('FDO', 'vibe_amende manquant.', 'error')
                    end
                end,
            },
            {
                title = 'Prison (minutes)',
                icon = 'lock',
                onSelect = function()
                    local input = lib.inputDialog('Mise en prison', {
                        { type = 'number', label = 'Minutes', required = true, min = 1, max = 120 },
                        { type = 'input', label = 'Motif', required = true },
                    })
                    if input then
                        TriggerServerEvent('vibe_fdo:server:jail', target, tonumber(input[1]), input[2])
                    end
                end,
            },
        },
    })
    lib.showContext('vibe_fdo_menu')
end

RegisterCommand('fdo', openMenu, false)
RegisterKeyMapping('fdo', 'Menu FDO', 'keyboard', 'F6')

RegisterNetEvent('vibe_fdo:client:setCuffed', function(state)
    cuffed = state
    LocalPlayer.state:set('invBusy', state, true)
    if state then
        lib.requestAnimDict('mp_arresting')
        TaskPlayAnim(cache.ped, 'mp_arresting', 'idle', 8.0, -8.0, -1, 49, 0, false, false, false)
    else
        ClearPedTasks(cache.ped)
    end
end)

RegisterNetEvent('vibe_fdo:client:escort', function(officerSrc)
    escorted = officerSrc ~= nil
    CreateThread(function()
        while escorted do
            local officer = GetPlayerFromServerId(officerSrc)
            if officer == -1 then break end
            local oped = GetPlayerPed(officer)
            AttachEntityToEntity(cache.ped, oped, 11816, 0.35, 0.45, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
            Wait(500)
        end
        DetachEntity(cache.ped, true, false)
        escorted = false
    end)
end)

RegisterNetEvent('vibe_fdo:client:openSearch', function(targetId)
    exports.ox_inventory:openInventory('player', targetId)
end)

RegisterNetEvent('vibe_fdo:client:jail', function(minutes)
    local c = Config.Jail.coords
    SetEntityCoords(cache.ped, c.x, c.y, c.z, false, false, false, false)
    SetEntityHeading(cache.ped, c.w)
    exports.vibe_api:Notify('Prison', ('Tu es incarcéré pour %s min.'):format(minutes), 'error')
    CreateThread(function()
        local ends = GetGameTimer() + (minutes * 60000)
        while GetGameTimer() < ends do
            Wait(5000)
            local pos = GetEntityCoords(cache.ped)
            if #(pos - vec3(c.x, c.y, c.z)) > 80.0 then
                SetEntityCoords(cache.ped, c.x, c.y, c.z, false, false, false, false)
            end
        end
        local r = Config.Jail.release
        SetEntityCoords(cache.ped, r.x, r.y, r.z, false, false, false, false)
        TriggerServerEvent('vibe_fdo:server:release')
        exports.vibe_api:Notify('Prison', 'Tu es libre.', 'success')
    end)
end)

CreateThread(function()
    while true do
        if cuffed then
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 21, true)
            DisableControlAction(0, 22, true)
            DisableControlAction(0, 23, true)
            DisableControlAction(0, 75, true)
            if not IsEntityPlayingAnim(cache.ped, 'mp_arresting', 'idle', 3) then
                TaskPlayAnim(cache.ped, 'mp_arresting', 'idle', 8.0, -8.0, -1, 49, 0, false, false, false)
            end
            Wait(0)
        else
            Wait(400)
        end
    end
end)
