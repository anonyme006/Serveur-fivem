local dead = false

local function isEms()
    local job = exports.vibe_api:GetJob()
    return job and Config.Jobs[job.name] and job.onduty
end

local function closestPlayer(maxDist)
    local coords = GetEntityCoords(cache.ped)
    local closest, dist
    for _, pid in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(pid)
        if ped ~= cache.ped then
            local d = #(coords - GetEntityCoords(ped))
            if d < (maxDist or 3.0) and (not dist or d < dist) then
                closest, dist = GetPlayerServerId(pid), d
            end
        end
    end
    return closest
end

RegisterCommand('ems', function()
    if not isEms() then
        exports.vibe_api:Notify('EMS', 'Service EMS requis.', 'error')
        return
    end
    local target = closestPlayer(3.0)
    if not target then
        exports.vibe_api:Notify('EMS', 'Aucun patient.', 'error')
        return
    end
    lib.registerContext({
        id = 'vibe_ems',
        title = ('EMS — ID %s'):format(target),
        options = {
            {
                title = 'Reanimer',
                icon = 'heart-pulse',
                onSelect = function()
                    if lib.progressCircle({
                        duration = Config.ReviveDuration,
                        label = 'Reanimation...',
                        position = 'bottom',
                        canCancel = true,
                        disable = { move = true, combat = true },
                        anim = { dict = 'mini@cpr@char_a@cpr_str', clip = 'cpr_pumpchest' },
                    }) then
                        TriggerServerEvent('vibe_medicextract:server:revive', target)
                    end
                end,
            },
            {
                title = 'Soigner',
                icon = 'kit-medical',
                onSelect = function()
                    if lib.progressCircle({
                        duration = Config.HealDuration,
                        label = 'Soins...',
                        position = 'bottom',
                        canCancel = true,
                        disable = { move = true, combat = true },
                    }) then
                        TriggerServerEvent('vibe_medicextract:server:heal', target)
                    end
                end,
            },
            {
                title = 'Extraire vers hopital',
                icon = 'truck-medical',
                onSelect = function()
                    TriggerServerEvent('vibe_medicextract:server:extract', target)
                end,
            },
        },
    })
    lib.showContext('vibe_ems')
end, false)
RegisterKeyMapping('ems', 'Menu EMS', 'keyboard', 'F7')

AddEventHandler('gameEventTriggered', function(name, args)
    if name ~= 'CEventNetworkEntityDamage' then return end
    local victim = args[1]
    if victim ~= cache.ped then return end
    if IsEntityDead(cache.ped) or GetEntityHealth(cache.ped) <= 0 then
        if not dead then
            dead = true
            exports.vibe_api:Notify('EMS', 'Tu es inconscient. Attends les secours.', 'error')
        end
    end
end)

RegisterNetEvent('vibe_medicextract:client:revive', function()
    dead = false
    local coords = GetEntityCoords(cache.ped)
    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, GetEntityHeading(cache.ped), true, false)
    SetEntityHealth(cache.ped, 150)
    ClearPedBloodDamage(cache.ped)
    exports.vibe_api:Notify('EMS', 'Tu as ete reanime.', 'success')
end)

RegisterNetEvent('vibe_medicextract:client:heal', function()
    SetEntityHealth(cache.ped, GetEntityMaxHealth(cache.ped))
    exports.vibe_api:Notify('EMS', 'Tu as ete soigne.', 'success')
end)

RegisterNetEvent('vibe_medicextract:client:extract', function()
    DoScreenFadeOut(500)
    Wait(600)
    SetEntityCoords(cache.ped, Config.Hospital.x, Config.Hospital.y, Config.Hospital.z, false, false, false, false)
    TriggerEvent('vibe_medicextract:client:revive')
    DoScreenFadeIn(800)
end)
