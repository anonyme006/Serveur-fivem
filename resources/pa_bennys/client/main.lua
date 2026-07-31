local ESX = exports['es_extended']:getSharedObject()

local PlayerData = {}
local onDuty = not Config.RequireDuty
local activeAlert, missionBlip, missionVehicle, missionPed, currentMission = nil, nil, 0, 0, nil

local function notify(msg, nType)
    lib.notify({ title = Config.CompanyName, description = msg, type = nType or 'inform' })
end

local function isMech()
    local job = PlayerData.job
    if not job or not Config.Jobs[job.name] then return false end
    if Config.RequireDuty and not onDuty then return false end
    return true
end

local function getVeh(dist)
    dist = dist or 5.0
    if cache.vehicle and cache.vehicle ~= 0 then return cache.vehicle end
    return GetClosestVehicle(GetEntityCoords(cache.ped), dist, 0, 71)
end

local function vehState(veh)
    if veh == 0 then return nil end
    local burst = {}
    for i = 0, 7 do burst[i] = IsVehicleTyreBurst(veh, i, false) end
    return {
        engine = GetVehicleEngineHealth(veh),
        body = GetVehicleBodyHealth(veh),
        tank = GetVehiclePetrolTankHealth(veh),
        burst = burst,
        dirty = GetVehicleDirtLevel(veh),
    }
end

local function fmtHp(v) return math.floor(math.max(0, math.min(100, v / 10.0))) end

local function progress(opts)
    return lib.progressCircle({
        duration = opts.duration,
        label = opts.label,
        position = 'bottom',
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = opts.anim,
    })
end

local function needsFix(state, t)
    if t == 'engine' then return state.engine < 900.0
    elseif t == 'body' then return state.body < 900.0
    elseif t == 'tank' then return state.tank < 900.0
    elseif t == 'clean' then return state.dirty > 0.5
    elseif t == 'tires' then
        for _, b in pairs(state.burst) do if b then return true end end
    end
    return false
end

local function applyFix(veh, t)
    if veh == 0 then return end
    if t == 'engine' then
        SetVehicleEngineHealth(veh, 1000.0)
        SetVehicleUndriveable(veh, false)
    elseif t == 'body' then
        SetVehicleBodyHealth(veh, 1000.0)
        SetVehicleDeformationFixed(veh)
    elseif t == 'tank' then
        SetVehiclePetrolTankHealth(veh, 1000.0)
    elseif t == 'tires' then
        for i = 0, 7 do
            if IsVehicleTyreBurst(veh, i, false) then SetVehicleTyreFixed(veh, i) end
        end
    elseif t == 'clean' then
        SetVehicleDirtLevel(veh, 0.0)
        WashDecalsFromVehicle(veh, 1.0)
    else
        SetVehicleFixed(veh)
        SetVehicleDeformationFixed(veh)
        SetVehicleEngineHealth(veh, 1000.0)
        SetVehicleBodyHealth(veh, 1000.0)
        SetVehiclePetrolTankHealth(veh, 1000.0)
        SetVehicleUndriveable(veh, false)
        for i = 0, 7 do SetVehicleTyreFixed(veh, i) end
        SetVehicleDirtLevel(veh, 0.0)
    end
end

local function clearBlip()
    if missionBlip and DoesBlipExist(missionBlip) then RemoveBlip(missionBlip) end
    missionBlip = nil
end

local function setBlip(coords, route)
    clearBlip()
    missionBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(missionBlip, Config.Bipeur.blipSprite)
    SetBlipColour(missionBlip, Config.Bipeur.blipColor)
    SetBlipScale(missionBlip, 1.0)
    SetBlipFlashes(missionBlip, true)
    if route then SetBlipRoute(missionBlip, true) end
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName("Dépannage Benny's")
    EndTextCommandSetBlipName(missionBlip)
end

local function nuiBipeur(data, show)
    SendNUIMessage({
        action = show and 'show' or 'hide',
        company = Config.CompanyName,
        code = data and data.code or '',
        message = data and data.message or '',
        payout = data and data.payout and ('~%d$'):format(data.payout) or '',
    })
end

local function setHood(veh, open)
    if veh == 0 then return end
    if open then SetVehicleDoorOpen(veh, 4, false, false)
    else SetVehicleDoorShut(veh, 4, false) end
end

local function runRepair(fixType, cfg, veh)
    veh = veh or getVeh(Config.Repair.maxDistance)
    if veh == 0 then notify('Aucun véhicule à proximité.', 'error'); return end

    local openHood = Config.Repair.openHoodFor[fixType]
    if openHood then setHood(veh, true) end
    local ok = progress({ duration = cfg.duration, label = cfg.label, anim = cfg.anim })
    if openHood then setHood(veh, false) end
    if not ok then ClearPedTasks(cache.ped); return end

    ClearPedTasks(cache.ped)
    TriggerServerEvent('pa_bennys:server:repair', NetworkGetNetworkIdFromEntity(veh), fixType)
end

local function openRepairMenu(veh, state)
    veh = veh or getVeh()
    state = state or vehState(veh)
    if veh == 0 then return end

    local options = {}
    local repairs = {
        { type = 'engine', cfg = Config.Repair.engine, price = Config.Prices.engine, icon = 'engine' },
        { type = 'body', cfg = Config.Repair.body, price = Config.Prices.body, icon = 'car-burst' },
        { type = 'tank', cfg = Config.Repair.tank, price = Config.Prices.tank, icon = 'gas-pump' },
        { type = 'tires', cfg = Config.Repair.tires, price = Config.Prices.tires, icon = 'circle' },
        { type = 'clean', cfg = Config.Repair.clean, price = Config.Prices.clean, icon = 'soap' },
        { type = 'full', cfg = Config.Repair.full, price = Config.Prices.full, icon = 'screwdriver-wrench' },
    }

    for _, r in ipairs(repairs) do
        local req = r.type == 'full' or needsFix(state, r.type)
        options[#options + 1] = {
            title = r.cfg.label,
            description = req and ('%d$'):format(r.price) or 'OK',
            icon = r.icon,
            disabled = not req,
            onSelect = function() runRepair(r.type, r.cfg, veh) end,
        }
    end

    lib.registerContext({ id = 'pa_bennys_repair', title = 'Réparations', menu = 'pa_bennys_main', options = options })
    lib.showContext('pa_bennys_repair')
end

local function runDiagnostic(veh)
    veh = veh or getVeh()
    if veh == 0 then notify('Aucun véhicule.', 'error'); return end
    if not progress({ duration = Config.Repair.diagnosticDuration, label = 'Diagnostic...', anim = Config.Repair.engine.anim }) then
        ClearPedTasks(cache.ped)
        return
    end
    ClearPedTasks(cache.ped)

    local s = vehState(veh)
    lib.registerContext({
        id = 'pa_bennys_diag',
        title = 'Diagnostic',
        menu = 'pa_bennys_main',
        options = {
            { title = ('Moteur : %d%%'):format(fmtHp(s.engine)), disabled = true },
            { title = ('Carrosserie : %d%%'):format(fmtHp(s.body)), disabled = true },
            { title = ('Réservoir : %d%%'):format(fmtHp(s.tank)), disabled = true },
            { title = 'Pneus', description = needsFix(s, 'tires') and 'Crevés' or 'OK', disabled = true },
            { title = 'Réparations', icon = 'wrench', onSelect = function() openRepairMenu(veh, s) end },
        },
    })
    lib.showContext('pa_bennys_diag')
end

local function openBipeur()
    if not isMech() then notify('Service requis.', 'error'); return end

    local opts = {{ title = 'Statut', description = activeAlert and activeAlert.label or 'Aucun appel', disabled = true }}
    if activeAlert and not activeAlert.accepted then
        opts[#opts + 1] = { title = 'Accepter', icon = 'check', onSelect = function()
            TriggerServerEvent('pa_bennys:server:acceptMission', activeAlert.id)
        end }
        opts[#opts + 1] = { title = 'Refuser', icon = 'xmark', onSelect = function()
            activeAlert = nil; nuiBipeur(nil, false); clearBlip()
        end }
    elseif activeAlert and activeAlert.accepted then
        opts[#opts + 1] = { title = 'GPS', icon = 'location-dot', onSelect = function()
            setBlip(activeAlert.coords, true)
        end }
        opts[#opts + 1] = { title = 'Abandonner', icon = 'ban', onSelect = function()
            TriggerServerEvent('pa_bennys:server:cancelMission', activeAlert.id)
        end }
    else
        opts[#opts + 1] = { title = 'En attente...', disabled = true }
    end

    lib.registerContext({ id = 'pa_bennys_bipeur', title = 'Bipeur', options = opts })
    lib.showContext('pa_bennys_bipeur')
end

local function toggleDuty()
    if not PlayerData.job or not Config.Jobs[PlayerData.job.name] then
        notify("Tu n'es pas employé Benny's.", 'error')
        return
    end
    onDuty = not onDuty
    TriggerServerEvent('pa_bennys:server:setDuty', onDuty)
    notify(onDuty and 'Prise de service — bipeur actif.' or 'Fin de service.', onDuty and 'success' or 'inform')
end

local function openMainMenu()
    if not isMech() then notify('Service requis. Utilise /bennys duty si besoin.', 'error'); return end
    lib.registerContext({
        id = 'pa_bennys_main',
        title = Config.CompanyName,
        options = {
            { title = 'Diagnostic', icon = 'stethoscope', onSelect = runDiagnostic },
            { title = 'Réparations', icon = 'wrench', onSelect = function() openRepairMenu() end },
            { title = 'Bipeur', icon = 'pager', onSelect = openBipeur },
            {
                title = Config.RequireDuty and (onDuty and 'Fin de service' or 'Prise de service') or 'Service actif',
                icon = 'user-clock',
                onSelect = toggleDuty,
                disabled = not Config.RequireDuty,
            },
        },
    })
    lib.showContext('pa_bennys_main')
end

local function applyCustomMod(veh, modType, modData)
    if modType == 'neon' then
        SetVehicleNeonLightsColour(veh, modData.r, modData.g, modData.b)
        for n = 0, 3 do SetVehicleNeonLightEnabled(veh, n, true) end
    elseif modType == 'color' then
        SetVehicleColours(veh, modData.primary, modData.secondary)
    elseif modType == 'tint' then
        SetVehicleWindowTint(veh, modData.index)
    elseif modType == 'wheels' then
        SetVehicleWheelType(veh, modData.wheelType)
        if modData.modIndex then SetVehicleMod(veh, 23, modData.modIndex, false) end
    end
end

local function confirmCustom(veh, modType, modData, label)
    if lib.alertDialog({
        header = "Benny's Custom",
        content = ('Valider : %s ?'):format(label or modType),
        centered = true,
        cancel = true,
    }) ~= 'confirm' then return end

    applyCustomMod(veh, modType, modData)
    TriggerServerEvent('pa_bennys:server:custom', NetworkGetNetworkIdFromEntity(veh), modType, modData)
end

local function openCustomMenu()
    if not isMech() then notify('Service requis.', 'error'); return end
    local veh = getVeh(6.0)
    if veh == 0 then return end

    lib.registerContext({
        id = 'pa_bennys_custom',
        title = 'Custom',
        options = {
            { title = 'Néons', icon = 'lightbulb', onSelect = function()
                local opts = {}
                for _, c in ipairs(Config.CustomMods.neonColors) do
                    opts[#opts + 1] = {
                        title = c.label,
                        onSelect = function()
                            confirmCustom(veh, 'neon', { r = c.r, g = c.g, b = c.b }, ('Néons %s'):format(c.label))
                        end,
                    }
                end
                lib.registerContext({ id = 'pa_bennys_neon', title = 'Néons', menu = 'pa_bennys_custom', options = opts })
                lib.showContext('pa_bennys_neon')
            end },
            { title = 'Couleur', icon = 'palette', onSelect = function()
                local cols = {
                    { l = 'Noir', p = 0 }, { l = 'Blanc', p = 111 }, { l = 'Rouge', p = 27 },
                    { l = 'Bleu', p = 64 }, { l = 'Rose néon', p = 135 },
                }
                local opts = {}
                for _, c in ipairs(cols) do
                    opts[#opts + 1] = {
                        title = c.l,
                        onSelect = function()
                            local _, s = GetVehicleColours(veh)
                            confirmCustom(veh, 'color', { primary = c.p, secondary = s }, ('Couleur %s'):format(c.l))
                        end,
                    }
                end
                lib.registerContext({ id = 'pa_bennys_color', title = 'Couleurs', menu = 'pa_bennys_custom', options = opts })
                lib.showContext('pa_bennys_color')
            end },
            { title = 'Vitres teintées', icon = 'window-maximize', onSelect = function()
                local opts = {}
                for _, t in ipairs(Config.CustomMods.windowTints) do
                    opts[#opts + 1] = {
                        title = t.label,
                        onSelect = function()
                            confirmCustom(veh, 'tint', { index = t.index }, ('Vitres %s'):format(t.label))
                        end,
                    }
                end
                lib.registerContext({ id = 'pa_bennys_tint', title = 'Vitres', menu = 'pa_bennys_custom', options = opts })
                lib.showContext('pa_bennys_tint')
            end },
            { title = 'Jantes', icon = 'circle', onSelect = function()
                local opts = {}
                for _, w in ipairs(Config.CustomMods.wheelTypes) do
                    opts[#opts + 1] = {
                        title = w.label,
                        onSelect = function()
                            local n = GetNumVehicleMods(veh, 23)
                            local modIndex = n > 0 and math.random(0, n - 1) or 0
                            confirmCustom(veh, 'wheels', { wheelType = w.type, modIndex = modIndex }, ('Jantes %s'):format(w.label))
                        end,
                    }
                end
                lib.registerContext({ id = 'pa_bennys_wheels', title = 'Jantes', menu = 'pa_bennys_custom', options = opts })
                lib.showContext('pa_bennys_wheels')
            end },
        },
    })
    lib.showContext('pa_bennys_custom')
end

local function cleanupMission()
    if missionVehicle ~= 0 and DoesEntityExist(missionVehicle) then DeleteEntity(missionVehicle) end
    if missionPed ~= 0 and DoesEntityExist(missionPed) then DeleteEntity(missionPed) end
    missionVehicle, missionPed = 0, 0
end

local function missionRepair(veh, mType)
    veh = veh or getVeh(8.0)
    if veh == 0 then notify('Approche le véhicule.', 'error'); return false end

    local cfg = (mType == 'flat' and Config.Repair.tires)
        or ((mType == 'engine' or mType == 'battery') and Config.Repair.engine)
        or (mType == 'accident' and Config.Repair.body)
        or Config.Repair.full

    local openHood = mType == 'engine' or mType == 'battery'
    if openHood then setHood(veh, true) end
    local ok = progress({ duration = cfg.duration, label = cfg.label, anim = cfg.anim })
    if openHood then setHood(veh, false) end
    if not ok then ClearPedTasks(cache.ped); return false end

    ClearPedTasks(cache.ped)
    return true
end

RegisterNetEvent('esx:playerLoaded', function(xPlayer) PlayerData = xPlayer end)
RegisterNetEvent('esx:setJob', function(job) PlayerData.job = job end)

CreateThread(function()
    while not ESX.IsPlayerLoaded() do Wait(200) end
    PlayerData = ESX.GetPlayerData()
end)

RegisterNetEvent('pa_bennys:client:applyFix', function(netId, fixType)
    local veh = NetworkGetEntityFromNetworkId(netId)
    if veh ~= 0 then applyFix(veh, fixType) end
end)

RegisterNetEvent('pa_bennys:client:syncCustom', function(netId, modType, modData)
    local veh = NetworkGetEntityFromNetworkId(netId)
    if veh ~= 0 and modType and modData then applyCustomMod(veh, modType, modData) end
end)

RegisterNetEvent('pa_bennys:client:openMenu', openMainMenu)
RegisterNetEvent('pa_bennys:client:openBipeur', openBipeur)

RegisterNetEvent('pa_bennys:client:bipeur', function(data)
    if not isMech() then return end
    activeAlert = data
    if Config.Bipeur.sound then
        SendNUIMessage({ action = 'beep' })
        PlaySoundFrontend(-1, 'Text_Arrive_Tone', 'Phone_SoundSet_Default', true)
    end
    nuiBipeur(data, true)
    notify(data.message, 'inform')
    setBlip(data.coords, false)
    SetTimeout(Config.Bipeur.blipTime * 1000, function()
        if activeAlert and activeAlert.id == data.id then clearBlip() end
    end)
end)

RegisterNetEvent('pa_bennys:client:missionAccepted', function(data)
    activeAlert = data
    nuiBipeur(nil, false)
    setBlip(data.coords, true)
    cleanupMission()

    local loc, model = data.coords, joaat(data.vehicleModel or 'blista')
    lib.requestModel(model)
    missionVehicle = CreateVehicle(model, loc.x, loc.y, loc.z, loc.w or 0.0, true, false)
    SetEntityAsMissionEntity(missionVehicle, true, true)
    SetVehicleOnGroundProperly(missionVehicle)
    SetVehicleEngineOn(missionVehicle, false, true, true)

    if data.damage then
        if data.damage.engine then SetVehicleEngineHealth(missionVehicle, data.damage.engine) end
        if data.damage.body then SetVehicleBodyHealth(missionVehicle, data.damage.body) end
    end
    if data.burstTires then
        SetVehicleTyreBurst(missionVehicle, 0, true, 1000.0)
        SetVehicleTyreBurst(missionVehicle, 1, true, 1000.0)
    end
    if data.missionType == 'engine' or data.missionType == 'battery' then
        SetVehicleUndriveable(missionVehicle, true)
    end

    lib.requestModel(joaat('a_m_y_business_01'))
    missionPed = CreatePed(4, joaat('a_m_y_business_01'), loc.x + 2.0, loc.y + 1.0, loc.z, 0.0, true, false)
    TaskStartScenarioInPlace(missionPed, 'WORLD_HUMAN_STAND_MOBILE', 0, true)
    currentMission = data

    exports.ox_target:addLocalEntity(missionVehicle, {{
        name = 'pa_bennys_mission',
        icon = 'fa-solid fa-wrench',
        label = 'Intervenir',
        canInteract = function()
            return isMech() and currentMission and currentMission.id == data.id
        end,
        onSelect = function()
            if missionRepair(missionVehicle, currentMission.missionType) then
                TriggerServerEvent('pa_bennys:server:completeMission', currentMission.id)
            end
        end,
    }})

    notify('Mission acceptée — rends-toi sur place.', 'success')
end)

RegisterNetEvent('pa_bennys:client:missionComplete', function()
    if missionPed ~= 0 and DoesEntityExist(missionPed) then
        TaskWanderStandard(missionPed, 10.0, 10)
        SetTimeout(15000, function()
            if DoesEntityExist(missionPed) then DeleteEntity(missionPed) end
        end)
    end
    if missionVehicle ~= 0 and DoesEntityExist(missionVehicle) then
        SetVehicleFixed(missionVehicle)
        SetVehicleEngineOn(missionVehicle, true, true, false)
        SetTimeout(20000, function()
            if DoesEntityExist(missionVehicle) then DeleteEntity(missionVehicle) end
        end)
    end
    currentMission = nil
end)

RegisterNetEvent('pa_bennys:client:missionEnded', function()
    activeAlert = nil
    nuiBipeur(nil, false)
    clearBlip()
    cleanupMission()
    currentMission = nil
end)

RegisterNetEvent('pa_bennys:client:spawnVehicle', function(model)
    local s, hash = Config.Garage.spawn, joaat(model)
    lib.requestModel(hash)
    local veh = CreateVehicle(hash, s.x, s.y, s.z, s.w, true, false)
    SetPedIntoVehicle(cache.ped, veh, -1)
    SetVehicleNumberPlateText(veh, 'BENNYS')
    SetModelAsNoLongerNeeded(hash)
    notify('Véhicule sorti.', 'success')
end)

RegisterCommand('bennys', function(_, args)
    if args[1] == 'duty' then toggleDuty() else openMainMenu() end
end, false)

RegisterCommand('mecano', function(_, args)
    if args[1] == 'duty' then toggleDuty() else openMainMenu() end
end, false)

RegisterCommand(Config.Bipeur.command, openBipeur, false)
RegisterKeyMapping(Config.Bipeur.command, "Bipeur Benny's", 'keyboard', Config.Bipeur.keybind)

RegisterNUICallback('accept', function(_, cb)
    if activeAlert and not activeAlert.accepted then
        TriggerServerEvent('pa_bennys:server:acceptMission', activeAlert.id)
    end
    cb('ok')
end)

RegisterNUICallback('decline', function(_, cb)
    activeAlert = nil
    nuiBipeur(nil, false)
    clearBlip()
    cb('ok')
end)

RegisterNUICallback('close', function(_, cb)
    nuiBipeur(nil, false)
    cb('ok')
end)

CreateThread(function()
    exports.ox_target:addGlobalVehicle({
        {
            name = 'pa_bennys_road_diag',
            icon = 'fa-solid fa-stethoscope',
            label = "Diagnostic (Benny's)",
            distance = Config.Repair.maxDistance,
            canInteract = isMech,
            onSelect = function(data) runDiagnostic(data.entity) end,
        },
        {
            name = 'pa_bennys_road_repair',
            icon = 'fa-solid fa-wrench',
            label = "Réparer (Benny's)",
            distance = Config.Repair.maxDistance,
            canInteract = isMech,
            onSelect = function(data) openRepairMenu(data.entity) end,
        },
    })
end)

CreateThread(function()
    for i, z in ipairs(Config.Workshop.zones) do
        exports.ox_target:addSphereZone({
            coords = z.coords,
            radius = z.radius,
            options = {
                { name = 'pa_bennys_ws_' .. i, icon = 'fa-solid fa-wrench', label = z.label, canInteract = isMech, onSelect = openMainMenu },
                { name = 'pa_bennys_diag_' .. i, icon = 'fa-solid fa-stethoscope', label = 'Diagnostic', canInteract = isMech, onSelect = runDiagnostic },
            },
        })
    end

    local w = Config.Workshop
    local blip = AddBlipForCoord(w.zones[1].coords.x, w.zones[1].coords.y, w.zones[1].coords.z)
    SetBlipSprite(blip, w.blip.sprite)
    SetBlipColour(blip, w.blip.color)
    SetBlipScale(blip, w.blip.scale)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(w.blip.label)
    EndTextCommandSetBlipName(blip)
end)

CreateThread(function()
    local c = Config.CustomShop
    exports.ox_target:addSphereZone({
        coords = c.coords,
        radius = c.radius,
        options = {{
            name = 'pa_bennys_custom',
            icon = 'fa-solid fa-spray-can',
            label = "Benny's Custom",
            canInteract = isMech,
            onSelect = openCustomMenu,
        }},
    })

    local blip = AddBlipForCoord(c.coords.x, c.coords.y, c.coords.z)
    SetBlipSprite(blip, c.blip.sprite)
    SetBlipColour(blip, c.blip.color)
    SetBlipScale(blip, c.blip.scale)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(c.blip.label)
    EndTextCommandSetBlipName(blip)
end)

CreateThread(function()
    local g = Config.Garage
    exports.ox_target:addSphereZone({
        coords = g.coords,
        radius = 2.0,
        options = {{
            name = 'pa_bennys_garage',
            icon = 'fa-solid fa-truck-pickup',
            label = "Garage Benny's",
            canInteract = isMech,
            onSelect = function()
                local opts = {}
                for _, v in ipairs(g.vehicles) do
                    opts[#opts + 1] = {
                        title = v.label,
                        onSelect = function()
                            TriggerServerEvent('pa_bennys:server:spawnVehicle', v.model)
                        end,
                    }
                end
                lib.registerContext({ id = 'pa_bennys_garage_m', title = 'Véhicules', options = opts })
                lib.showContext('pa_bennys_garage_m')
            end,
        }},
    })
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then cleanupMission() end
end)

exports('OpenMenu', openMainMenu)
exports('OpenBipeur', openBipeur)
