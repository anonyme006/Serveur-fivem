local function isMech()
    local job = exports.vibe_api:GetJob()
    return job and Config.Jobs[job.name] and job.onduty
end

local function repair()
    local veh = cache.vehicle or GetClosestVehicle(GetEntityCoords(cache.ped), 4.0, 0, 71)
    if veh == 0 then
        exports.vibe_api:Notify('Mecano', 'Aucun vehicule.', 'error')
        return
    end
    if lib.progressCircle({
        duration = Config.RepairDuration,
        label = 'Reparation...',
        position = 'bottom',
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = 'mini@repair', clip = 'fixing_a_ped' },
    }) then
        TriggerServerEvent('vibe_mechanic:server:repair', NetworkGetNetworkIdFromEntity(veh))
    end
end

RegisterCommand('mecano', function()
    if not isMech() then
        exports.vibe_api:Notify('Mecano', 'Service mecano requis.', 'error')
        return
    end
    lib.registerContext({
        id = 'vibe_mech',
        title = 'Mecano',
        options = {
            { title = 'Reparer le vehicule', icon = 'wrench', onSelect = repair },
            {
                title = 'Nettoyer',
                icon = 'soap',
                onSelect = function()
                    local veh = cache.vehicle or GetClosestVehicle(GetEntityCoords(cache.ped), 4.0, 0, 71)
                    if veh ~= 0 then
                        SetVehicleDirtLevel(veh, 0.0)
                        WashDecalsFromVehicle(veh, 1.0)
                    end
                end,
            },
        },
    })
    lib.showContext('vibe_mech')
end, false)

CreateThread(function()
    for i, coords in ipairs(Config.Locations) do
        exports.ox_target:addSphereZone({
            coords = coords,
            radius = 2.0,
            options = {{
                name = 'vibe_mech_' .. i,
                icon = 'fa-solid fa-wrench',
                label = 'Atelier mecano',
                canInteract = isMech,
                onSelect = repair,
            }},
        })
    end
end)

RegisterNetEvent('vibe_mechanic:client:fixVehicle', function(netId)
    local veh = NetworkGetEntityFromNetworkId(netId)
    if veh == 0 then return end
    SetVehicleFixed(veh)
    SetVehicleDeformationFixed(veh)
    SetVehicleEngineHealth(veh, 1000.0)
    SetVehicleBodyHealth(veh, 1000.0)
    SetVehiclePetrolTankHealth(veh, 1000.0)
end)
