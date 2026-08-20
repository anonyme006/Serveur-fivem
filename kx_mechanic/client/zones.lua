KX = KX or {}

local liftEntities = {}

local function createBlip()
    if not Config.Blips.enabled then return end
    local blip = AddBlipForCoord(Config.Blips.coords.x, Config.Blips.coords.y, Config.Blips.coords.z)
    SetBlipSprite(blip, Config.Blips.sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, Config.Blips.scale)
    SetBlipColour(blip, Config.Blips.color)
    SetBlipAsShortRange(blip, Config.Blips.shortRange)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(Config.Blips.label)
    EndTextCommandSetBlipName(blip)
end

local function registerZones()
    local duty = Config.Locations.duty
    exports.ox_target:addBoxZone({
        coords = duty.coords,
        size = duty.size,
        rotation = duty.rotation,
        debug = Config.Debug,
        options = {
            {
                name = 'kx_mechanic_duty',
                icon = 'fa-solid fa-user-clock',
                label = 'Prise / fin de service',
                canInteract = function()
                    return KX.IsMechanic
                end,
                onSelect = function()
                    lib.callback.await('kx_mechanic:server:toggleDuty', false)
                    Wait(200)
                    local job = lib.callback.await('kx_mechanic:server:getPlayerJob', false)
                    if job then
                        KX.OnDuty = job.onduty == true
                        KX.Grade = job.grade or 0
                        KX.IsMechanic = job.name == Config.Job
                    end
                end,
            },
        },
    })

    local boss = Config.Locations.boss
    exports.ox_target:addBoxZone({
        coords = boss.coords,
        size = boss.size,
        rotation = boss.rotation,
        debug = Config.Debug,
        options = {
            {
                name = 'kx_mechanic_boss',
                icon = 'fa-solid fa-briefcase',
                label = 'Gestion entreprise',
                canInteract = function()
                    return KX.HasPerm('management')
                end,
                onSelect = function()
                    KX.OpenMechanicMenu('management')
                end,
            },
        },
    })

    local stash = Config.Locations.stash
    exports.ox_target:addBoxZone({
        coords = stash.coords,
        size = stash.size,
        rotation = stash.rotation,
        debug = Config.Debug,
        options = {
            {
                name = 'kx_mechanic_stash',
                icon = 'fa-solid fa-boxes-stacked',
                label = 'Ouvrir stockage',
                canInteract = function()
                    return KX.HasPerm('stock')
                end,
                onSelect = function()
                    exports.ox_inventory:openInventory('stash', stash.id)
                end,
            },
        },
    })

    local craft = Config.Locations.craft
    exports.ox_target:addBoxZone({
        coords = craft.coords,
        size = craft.size,
        rotation = craft.rotation,
        debug = Config.Debug,
        options = {
            {
                name = 'kx_mechanic_craft',
                icon = 'fa-solid fa-screwdriver-wrench',
                label = 'Utiliser établi',
                canInteract = function()
                    return KX.CanWork()
                end,
                onSelect = function()
                    KX.OpenMechanicMenu('repair')
                end,
            },
        },
    })

    local tools = Config.Locations.tools
    exports.ox_target:addBoxZone({
        coords = tools.coords,
        size = tools.size,
        rotation = tools.rotation,
        debug = Config.Debug,
        options = {
            {
                name = 'kx_mechanic_tools',
                icon = 'fa-solid fa-wrench',
                label = 'Utiliser outils',
                canInteract = function()
                    return KX.CanWork()
                end,
                onSelect = function()
                    KX.OpenMechanicMenu('maintenance')
                end,
            },
        },
    })
end

local function getLiftConfig(liftId)
    for i = 1, #Config.Lifts do
        if Config.Lifts[i].id == liftId then
            return Config.Lifts[i]
        end
    end
    return nil
end

local function findVehicleNearLift(lift)
    local vehicles = GetGamePool('CVehicle')
    local closest, closestDist
    for i = 1, #vehicles do
        local vehicle = vehicles[i]
        local dist = #(GetEntityCoords(vehicle) - lift.coords)
        if dist <= lift.radius and (not closestDist or dist < closestDist) then
            closest = vehicle
            closestDist = dist
        end
    end
    return closest
end

local function animateLift(vehicle, lift, raise)
    if not vehicle or vehicle == 0 then return end
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    SetNetworkIdCanMigrate(netId, false)
    NetworkRequestControlOfEntity(vehicle)

    local timeout = 0
    while not NetworkHasControlOfEntity(vehicle) and timeout < 50 do
        NetworkRequestControlOfEntity(vehicle)
        Wait(50)
        timeout = timeout + 1
    end

    FreezeEntityPosition(vehicle, true)
    local coords = GetEntityCoords(vehicle)
    local targetZ = raise and (lift.coords.z + lift.raiseHeight) or lift.coords.z
    local duration = raise and lift.raiseDuration or lift.lowerDuration
    local steps = math.max(math.floor(duration / 20), 1)
    local startZ = coords.z
    local delta = (targetZ - startZ) / steps

    for i = 1, steps do
        local z = startZ + (delta * i)
        SetEntityCoordsNoOffset(vehicle, coords.x, coords.y, z, false, false, false)
        Wait(20)
    end

    SetEntityCoordsNoOffset(vehicle, lift.coords.x, lift.coords.y, targetZ, false, false, false)
    SetEntityHeading(vehicle, lift.heading)
    FreezeEntityPosition(vehicle, true)
end

function KX.LiftAction(liftId, action)
    if not KX.HasPerm('lift') then
        KX.Notify('Vous devez être mécanicien.', 'error')
        return
    end

    local lift = getLiftConfig(liftId)
    if not lift then return end

    local vehicle
    local netId
    local plate

    if action == 'attach' then
        vehicle = findVehicleNearLift(lift)
        if not vehicle then
            KX.Notify('Aucun véhicule à proximité du pont.', 'error')
            return
        end
        netId = NetworkGetNetworkIdFromEntity(vehicle)
        plate = KX.GetVehiclePlate(vehicle)
        SetEntityCoordsNoOffset(vehicle, lift.coords.x, lift.coords.y, lift.coords.z, false, false, false)
        SetEntityHeading(vehicle, lift.heading)
        FreezeEntityPosition(vehicle, true)
    elseif action == 'raise' or action == 'lower' or action == 'detach' then
        local states = GlobalState.kx_mechanic_lifts or {}
        local state = states[liftId]
        if state and state.netId then
            vehicle = NetworkGetEntityFromNetworkId(state.netId)
            netId = state.netId
            plate = state.plate
        end
    end

    local result = lib.callback.await('kx_mechanic:server:liftAction', false, liftId, action, netId, plate)
    if not result or not result.ok then
        KX.Notify(result and result.message or 'Action impossible.', 'error')
        return
    end

    if action == 'raise' and vehicle and vehicle ~= 0 then
        animateLift(vehicle, lift, true)
        KX.Notify('Véhicule monté sur le pont.', 'success')
    elseif action == 'lower' and vehicle and vehicle ~= 0 then
        animateLift(vehicle, lift, false)
        KX.Notify('Véhicule descendu.', 'success')
    elseif action == 'attach' then
        KX.Notify('Véhicule verrouillé sur le pont.', 'success')
    elseif action == 'detach' and vehicle and vehicle ~= 0 then
        FreezeEntityPosition(vehicle, false)
        SetNetworkIdCanMigrate(netId, true)
        KX.Notify('Véhicule libéré.', 'success')
    end
end

RegisterNetEvent('kx_mechanic:client:syncLift', function(liftId, state)
    liftEntities[liftId] = state
    if state and state.netId and state.raised then
        local vehicle = NetworkGetEntityFromNetworkId(state.netId)
        local lift = getLiftConfig(liftId)
        if vehicle and vehicle ~= 0 and lift then
            FreezeEntityPosition(vehicle, true)
            SetEntityCoordsNoOffset(vehicle, lift.coords.x, lift.coords.y, lift.coords.z + lift.raiseHeight, false, false, false)
        end
    elseif state and state.netId and not state.raised and not state.locked then
        local vehicle = NetworkGetEntityFromNetworkId(state.netId)
        if vehicle and vehicle ~= 0 then
            FreezeEntityPosition(vehicle, false)
        end
    end
end)

local function registerLifts()
    if not Config.EnableLifts then return end

    for i = 1, #Config.Lifts do
        local lift = Config.Lifts[i]
        exports.ox_target:addSphereZone({
            coords = lift.coords,
            radius = lift.radius,
            debug = Config.Debug,
            options = {
                {
                    name = 'kx_lift_attach_' .. lift.id,
                    icon = 'fa-solid fa-car',
                    label = 'Monter le véhicule',
                    canInteract = function()
                        return KX.HasPerm('lift')
                    end,
                    onSelect = function()
                        KX.LiftAction(lift.id, 'attach')
                    end,
                },
                {
                    name = 'kx_lift_raise_' .. lift.id,
                    icon = 'fa-solid fa-arrow-up',
                    label = 'Élever le pont',
                    canInteract = function()
                        return KX.HasPerm('lift')
                    end,
                    onSelect = function()
                        KX.LiftAction(lift.id, 'raise')
                    end,
                },
                {
                    name = 'kx_lift_lower_' .. lift.id,
                    icon = 'fa-solid fa-arrow-down',
                    label = 'Descendre le véhicule',
                    canInteract = function()
                        return KX.HasPerm('lift')
                    end,
                    onSelect = function()
                        KX.LiftAction(lift.id, 'lower')
                    end,
                },
                {
                    name = 'kx_lift_work_' .. lift.id,
                    icon = 'fa-solid fa-wrench',
                    label = 'Travailler sur le véhicule',
                    canInteract = function()
                        return KX.CanWork()
                    end,
                    onSelect = function()
                        local states = GlobalState.kx_mechanic_lifts or {}
                        local state = states[lift.id]
                        if state and state.netId then
                            local vehicle = NetworkGetEntityFromNetworkId(state.netId)
                            if vehicle and vehicle ~= 0 then
                                KX.CurrentVehicle = vehicle
                                KX.OpenMechanicMenu('repair')
                                return
                            end
                        end
                        KX.Notify('Aucun véhicule sur le pont.', 'error')
                    end,
                },
                {
                    name = 'kx_lift_detach_' .. lift.id,
                    icon = 'fa-solid fa-unlock',
                    label = 'Libérer le véhicule',
                    canInteract = function()
                        return KX.HasPerm('lift')
                    end,
                    onSelect = function()
                        KX.LiftAction(lift.id, 'detach')
                    end,
                },
            },
        })
    end
end

local function registerVehicleTargets()
    exports.ox_target:addGlobalVehicle({
        {
            name = 'kx_veh_diagnose',
            icon = 'fa-solid fa-stethoscope',
            label = 'Diagnostiquer',
            distance = Config.MaxRepairDistance,
            canInteract = function()
                return KX.HasPerm('diagnose')
            end,
            onSelect = function(data)
                KX.CurrentVehicle = data.entity
                KX.StartDiagnose(data.entity)
            end,
        },
        {
            name = 'kx_veh_repair',
            icon = 'fa-solid fa-wrench',
            label = 'Réparer',
            distance = Config.MaxRepairDistance,
            canInteract = function()
                return KX.HasPerm('repair')
            end,
            onSelect = function(data)
                KX.CurrentVehicle = data.entity
                KX.OpenMechanicMenu('repair')
            end,
        },
        {
            name = 'kx_veh_tires',
            icon = 'fa-solid fa-circle',
            label = 'Pneus',
            distance = Config.MaxRepairDistance,
            canInteract = function()
                return KX.HasPerm('tires')
            end,
            onSelect = function(data)
                KX.CurrentVehicle = data.entity
                KX.OpenMechanicMenu('tires')
            end,
        },
        {
            name = 'kx_veh_body',
            icon = 'fa-solid fa-car',
            label = 'Carrosserie',
            distance = Config.MaxRepairDistance,
            canInteract = function()
                return KX.HasPerm('body')
            end,
            onSelect = function(data)
                KX.CurrentVehicle = data.entity
                KX.OpenMechanicMenu('body')
            end,
        },
        {
            name = 'kx_veh_perf',
            icon = 'fa-solid fa-gauge-high',
            label = 'Performance',
            distance = Config.MaxRepairDistance,
            canInteract = function()
                return KX.HasPerm('performance') and Config.EnablePerformance
            end,
            onSelect = function(data)
                KX.CurrentVehicle = data.entity
                KX.OpenMechanicMenu('performance')
            end,
        },
        {
            name = 'kx_veh_maint',
            icon = 'fa-solid fa-oil-can',
            label = 'Entretien',
            distance = Config.MaxRepairDistance,
            canInteract = function()
                return KX.HasPerm('maintenance') and Config.EnableMaintenance
            end,
            onSelect = function(data)
                KX.CurrentVehicle = data.entity
                KX.OpenMechanicMenu('maintenance')
            end,
        },
    })
end

CreateThread(function()
    createBlip()
    registerZones()
    registerLifts()
    registerVehicleTargets()
end)