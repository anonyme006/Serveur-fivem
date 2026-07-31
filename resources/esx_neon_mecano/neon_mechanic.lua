--[[
    Neon Mechanic — ESX (fichier unique)
    Réparations réalistes, custom, bipeur, missions dépannage

    Dépendances :
      • es_extended
      • ox_lib, ox_target
      • esx_addonaccount (recommandé) ou esx_society / Renewed-Banking

    Installation :
      ensure es_extended
      ensure esx_addonaccount
      ensure esx_neon_mecano

    Compte société : society_mechanic (addon_account_data)
]]

-- =============================================================================
-- CONFIG
-- =============================================================================

Config = {
    CompanyName = 'Neon Mechanic',
    SocietyAccount = 'society_mechanic',
    Jobs = { mechanic = true, bennys = true },
    RequireDuty = false,

    Workshop = {
        blip = { sprite = 446, color = 3, scale = 0.85, label = 'Neon Mechanic — Atelier' },
        zones = {
            { coords = vec3(-337.0, -136.5, 39.0), radius = 8.0, label = 'LS Customs — Atelier' },
            { coords = vec3(-211.0, -1324.0, 30.9), radius = 8.0, label = 'Benny\'s — Atelier' },
        },
    },

    CustomShop = {
        blip = { sprite = 72, color = 27, scale = 0.85, label = 'Neon Mechanic — Custom' },
        coords = vec3(-205.5, -1308.5, 31.3),
        radius = 6.0,
    },

    Garage = {
        coords = vec3(-194.0, -1290.0, 31.3),
        spawn = vec4(-188.0, -1295.0, 31.3, 270.0),
        vehicles = {
            { model = 'flatbed', label = 'Dépanneuse Flatbed' },
            { model = 'towtruck2', label = 'Dépanneuse lourde' },
            { model = 'slamvan3', label = 'Van intervention' },
        },
    },

    Repair = {
        diagnosticDuration = 5000,
        maxDistance = 5.0,
        openHoodFor = { engine = true, tank = true, full = true },
        engine = { duration = 12000, label = 'Réparation moteur', anim = { dict = 'mini@repair', clip = 'fixing_a_ped' } },
        body = { duration = 10000, label = 'Carrosserie', anim = { dict = 'mini@repair', clip = 'fixing_a_ped' } },
        tank = { duration = 8000, label = 'Réservoir', anim = { dict = 'mini@repair', clip = 'fixing_a_ped' } },
        tires = { duration = 6000, label = 'Changement pneus', anim = { dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', clip = 'machinic_loop_mechandplayer' } },
        clean = { duration = 4000, label = 'Nettoyage', anim = { dict = 'timetable@floyd@clean_kitchen@base', clip = 'base' } },
        full = { duration = 18000, label = 'Révision complète', anim = { dict = 'mini@repair', clip = 'fixing_a_ped' } },
    },

    Prices = {
        engine = 450, body = 380, tank = 280, tires = 220, clean = 80, full = 950,
        customNeon = 350, customColor = 200, customWheels = 400, customTint = 150,
    },
    EmployeeCut = 0.15,

    CustomMods = {
        neonColors = {
            { label = 'Blanc', r = 222, g = 222, b = 255 }, { label = 'Bleu', r = 2, g = 21, b = 255 },
            { label = 'Bleu électrique', r = 3, g = 83, b = 255 }, { label = 'Vert menthe', r = 0, g = 255, b = 140 },
            { label = 'Vert lime', r = 94, g = 255, b = 1 }, { label = 'Jaune', r = 255, g = 255, b = 0 },
            { label = 'Orange', r = 255, g = 62, b = 0 }, { label = 'Rouge', r = 255, g = 1, b = 1 },
            { label = 'Rose', r = 255, g = 5, b = 190 }, { label = 'Violet', r = 153, g = 0, b = 153 },
        },
        windowTints = {
            { label = 'Aucune', index = 0 }, { label = 'Légère', index = 3 },
            { label = 'Fumée', index = 2 }, { label = 'Noir', index = 1 },
        },
        wheelTypes = {
            { label = 'Sport', type = 0 }, { label = 'Muscle', type = 1 }, { label = 'Lowrider', type = 2 },
            { label = 'SUV', type = 3 }, { label = 'Offroad', type = 4 }, { label = 'Tuner', type = 5 },
        },
    },

    Bipeur = { command = 'bipeur', keybind = 'F6', sound = true, blipSprite = 446, blipColor = 5, blipTime = 120 },

    Missions = {
        enabled = true,
        interval = { min = 120, max = 300 },
        maxActive = 3,
        payout = { min = 600, max = 1200 },
        societyShare = 0.70,
        employeeBonus = { min = 150, max = 350 },
        completeRadius = 12.0,
        types = {
            { id = 'engine', label = 'Panne moteur', message = 'Véhicule en panne moteur — intervention requise', damage = { engine = 150.0, body = 600.0 } },
            { id = 'flat', label = 'Crevaison', message = 'Crevaison signalée — changement de pneu', burstTires = true, damage = { engine = 900.0, body = 850.0 } },
            { id = 'accident', label = 'Accident léger', message = 'Accident de la route — véhicule immobilisé', damage = { engine = 400.0, body = 350.0 } },
            { id = 'battery', label = 'Batterie à plat', message = 'Démarrage impossible — batterie déchargée', damage = { engine = 200.0, body = 950.0 } },
        },
        vehicles = { 'blista', 'asea', 'primo', 'fugitive', 'stanier', 'ingot', 'surge', 'premier' },
        locations = {
            vec4(120.0, -1030.0, 29.3, 0.0), vec4(-515.0, -260.0, 35.5, 90.0), vec4(825.0, -1035.0, 26.5, 180.0),
            vec4(-1100.0, -1500.0, 4.5, 270.0), vec4(2550.0, 385.0, 108.5, 0.0), vec4(-3040.0, 590.0, 7.5, 90.0),
            vec4(1700.0, 3580.0, 35.5, 180.0), vec4(-220.0, 6200.0, 31.5, 45.0), vec4(170.0, -1700.0, 29.3, 270.0),
            vec4(-700.0, -920.0, 19.0, 0.0), vec4(1135.0, 2650.0, 38.0, 90.0), vec4(-1480.0, -660.0, 28.5, 180.0),
        },
    },
}

-- =============================================================================
-- ESX HELPERS (partagés)
-- =============================================================================

local ESX = exports['es_extended']:getSharedObject()

local function notifyPlayer(src, msg, nType)
    if src and src > 0 then
        TriggerClientEvent('ox_lib:notify', src, {
            title = Config.CompanyName,
            description = msg,
            type = nType or 'inform',
        })
    else
        lib.notify({ title = Config.CompanyName, description = msg, type = nType or 'inform' })
    end
end

-- =============================================================================
-- SERVEUR
-- =============================================================================

if IsDuplicityVersion() then
    local activeMissions, assignedMissions, missionSeq = {}, {}, 0
    local onDutyPlayers = {}

    local function getJobName(src)
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer then return nil end
        return xPlayer.getJob().name
    end

    local function isMechanic(src)
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer then return false end
        local job = xPlayer.getJob()
        if not job or not Config.Jobs[job.name] then return false end
        if Config.RequireDuty and not onDutyPlayers[src] then return false end
        return true
    end

    local function addSocietyMoney(amount)
        amount = math.floor(tonumber(amount) or 0)
        if amount <= 0 then return end

        if GetResourceState('Renewed-Banking') == 'started' then
            exports['Renewed-Banking']:addAccountMoney(Config.SocietyAccount, amount)
            return
        end

        TriggerEvent('esx_addonaccount:getSharedAccount', Config.SocietyAccount, function(account)
            if account then account.addMoney(amount) end
        end)
    end

    local function addPlayerMoney(src, amount)
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer then xPlayer.addAccountMoney('bank', amount) end
    end

    local function distCheck(src, coords, maxDist)
        local ped = GetPlayerPed(src)
        if ped == 0 then return false end
        local p = GetEntityCoords(ped)
        return #(p - vector3(coords.x, coords.y, coords.z)) <= (maxDist or 5.0)
    end

    local function mechanicsOnDuty()
        local list = {}
        for _, src in ipairs(GetPlayers()) do
            src = tonumber(src)
            if isMechanic(src) then list[#list + 1] = src end
        end
        return list
    end

    local function broadcastBipeur(mission, targets)
        for _, src in ipairs(targets or mechanicsOnDuty()) do
            if not assignedMissions[src] then
                TriggerClientEvent('esx_neon_mecano:client:bipeur', src, mission)
            end
        end
    end

    local function createMission()
        if not Config.Missions.enabled then return end
        local active = 0
        for _, m in pairs(activeMissions) do if not m.completed then active = active + 1 end end
        if active >= Config.Missions.maxActive or #mechanicsOnDuty() == 0 then return end

        missionSeq = missionSeq + 1
        local mType = Config.Missions.types[math.random(#Config.Missions.types)]
        local loc = Config.Missions.locations[math.random(#Config.Missions.locations)]
        local mission = {
            id = missionSeq, code = 'DEP-' .. missionSeq, label = mType.label, message = mType.message,
            missionType = mType.id, coords = { x = loc.x, y = loc.y, z = loc.z, w = loc.w },
            vehicleModel = Config.Missions.vehicles[math.random(#Config.Missions.vehicles)],
            damage = mType.damage, burstTires = mType.burstTires,
            payout = math.random(Config.Missions.payout.min, Config.Missions.payout.max),
            accepted = false, completed = false, assignedTo = nil,
        }
        activeMissions[mission.id] = mission
        broadcastBipeur(mission)
    end

    RegisterNetEvent('esx_neon_mecano:server:setDuty', function(state)
        local src = source
        if not Config.Jobs[getJobName(src) or ''] then return end
        onDutyPlayers[src] = state and true or nil
    end)

    CreateThread(function()
        while true do
            Wait(math.random(Config.Missions.interval.min, Config.Missions.interval.max) * 1000)
            createMission()
        end
    end)

    RegisterNetEvent('esx_neon_mecano:server:repair', function(netId, fixType)
        local src = source
        if not isMechanic(src) then return end
        fixType = tostring(fixType or 'full')
        local price = Config.Prices[fixType] or 0
        TriggerClientEvent('esx_neon_mecano:client:applyFix', -1, netId, fixType)
        if price > 0 then
            addSocietyMoney(math.floor(price * (1.0 - Config.EmployeeCut)))
            addPlayerMoney(src, math.floor(price * Config.EmployeeCut))
        end
        notifyPlayer(src, 'Intervention terminée.', 'success')
    end)

    RegisterNetEvent('esx_neon_mecano:server:custom', function(netId, modType, modData)
        local src = source
        if not isMechanic(src) then return end
        modType = tostring(modType or 'neon')
        local prices = { neon = Config.Prices.customNeon, color = Config.Prices.customColor, tint = Config.Prices.customTint, wheels = Config.Prices.customWheels }
        local price = prices[modType] or Config.Prices.customNeon
        addSocietyMoney(math.floor(price * (1.0 - Config.EmployeeCut)))
        addPlayerMoney(src, math.floor(price * Config.EmployeeCut))
        TriggerClientEvent('esx_neon_mecano:client:syncCustom', -1, netId, modType, modData or {})
        notifyPlayer(src, 'Custom enregistré.', 'success')
    end)

    RegisterNetEvent('esx_neon_mecano:server:spawnVehicle', function(model)
        local src = source
        if not isMechanic(src) then return end
        TriggerClientEvent('esx_neon_mecano:client:spawnVehicle', src, tostring(model or 'flatbed'):sub(1, 32))
    end)

    RegisterNetEvent('esx_neon_mecano:server:acceptMission', function(missionId)
        local src = source
        if not isMechanic(src) or assignedMissions[src] then
            notifyPlayer(src, assignedMissions[src] and 'Mission déjà en cours.' or 'Accès refusé.', 'error')
            return
        end
        missionId = tonumber(missionId)
        local mission = activeMissions[missionId]
        if not mission or mission.completed or mission.assignedTo then
            notifyPlayer(src, 'Mission indisponible.', 'error')
            return
        end
        mission.accepted, mission.assignedTo = true, src
        assignedMissions[src] = missionId
        TriggerClientEvent('esx_neon_mecano:client:missionAccepted', src, mission)
        for _, id in ipairs(GetPlayers()) do
            id = tonumber(id)
            if id ~= src then TriggerClientEvent('esx_neon_mecano:client:missionEnded', id) end
        end
    end)

    RegisterNetEvent('esx_neon_mecano:server:cancelMission', function(missionId)
        local src = source
        missionId = tonumber(missionId)
        local mission = activeMissions[missionId]
        if not mission or mission.assignedTo ~= src then return end
        mission.assignedTo, mission.accepted = nil, false
        assignedMissions[src] = nil
        TriggerClientEvent('esx_neon_mecano:client:missionEnded', src)
        broadcastBipeur(mission)
    end)

    RegisterNetEvent('esx_neon_mecano:server:completeMission', function(missionId)
        local src = source
        if assignedMissions[src] ~= tonumber(missionId) then return end
        local mission = activeMissions[tonumber(missionId)]
        if not mission or mission.completed then return end
        if not distCheck(src, mission.coords, Config.Missions.completeRadius) then
            notifyPlayer(src, 'Trop loin du véhicule.', 'error')
            return
        end
        mission.completed = true
        assignedMissions[src] = nil
        local society = math.floor(mission.payout * Config.Missions.societyShare)
        local bonus = math.random(Config.Missions.employeeBonus.min, Config.Missions.employeeBonus.max)
        addSocietyMoney(society)
        addPlayerMoney(src, bonus)
        TriggerClientEvent('esx_neon_mecano:client:missionComplete', src)
        TriggerClientEvent('esx_neon_mecano:client:missionEnded', src)
        notifyPlayer(src, ('Dépannage OK — %d$ société, %d$ bonus.'):format(society, bonus), 'success')
        SetTimeout(60000, function() activeMissions[mission.id] = nil end)
    end)

    AddEventHandler('playerDropped', function()
        local src, mid = source, assignedMissions[source]
        onDutyPlayers[src] = nil
        if not mid then return end
        local mission = activeMissions[mid]
        if mission then mission.assignedTo, mission.accepted = nil, false; broadcastBipeur(mission) end
        assignedMissions[src] = nil
    end)

    exports('CreateMission', createMission)

-- =============================================================================
-- CLIENT
-- =============================================================================

else
    local PlayerData = {}
    local onDuty = not Config.RequireDuty
    local activeAlert, missionBlip, missionVehicle, missionPed, currentMission = nil, nil, 0, 0, nil

    local function notify(msg, nType) notifyPlayer(nil, msg, nType) end

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
        return { engine = GetVehicleEngineHealth(veh), body = GetVehicleBodyHealth(veh), tank = GetVehiclePetrolTankHealth(veh), burst = burst, dirty = GetVehicleDirtLevel(veh) }
    end

    local function fmtHp(v) return math.floor(math.max(0, math.min(100, v / 10.0))) end

    local function progress(opts)
        return lib.progressCircle({ duration = opts.duration, label = opts.label, position = 'bottom', canCancel = true, disable = { move = true, car = true, combat = true }, anim = opts.anim })
    end

    local function needsFix(state, t)
        if t == 'engine' then return state.engine < 900.0 elseif t == 'body' then return state.body < 900.0
        elseif t == 'tank' then return state.tank < 900.0 elseif t == 'clean' then return state.dirty > 0.5
        elseif t == 'tires' then for _, b in pairs(state.burst) do if b then return true end end end
        return false
    end

    local function applyFix(veh, t)
        if veh == 0 then return end
        if t == 'engine' then SetVehicleEngineHealth(veh, 1000.0); SetVehicleUndriveable(veh, false)
        elseif t == 'body' then SetVehicleBodyHealth(veh, 1000.0); SetVehicleDeformationFixed(veh)
        elseif t == 'tank' then SetVehiclePetrolTankHealth(veh, 1000.0)
        elseif t == 'tires' then for i = 0, 7 do if IsVehicleTyreBurst(veh, i, false) then SetVehicleTyreFixed(veh, i) end end
        elseif t == 'clean' then SetVehicleDirtLevel(veh, 0.0); WashDecalsFromVehicle(veh, 1.0)
        else SetVehicleFixed(veh); SetVehicleDeformationFixed(veh); SetVehicleEngineHealth(veh, 1000.0)
            SetVehicleBodyHealth(veh, 1000.0); SetVehiclePetrolTankHealth(veh, 1000.0); SetVehicleUndriveable(veh, false)
            for i = 0, 7 do SetVehicleTyreFixed(veh, i) end; SetVehicleDirtLevel(veh, 0.0) end
    end

    local function clearBlip()
        if missionBlip and DoesBlipExist(missionBlip) then RemoveBlip(missionBlip) end
        missionBlip = nil
    end

    local function setBlip(coords, route)
        clearBlip()
        missionBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(missionBlip, Config.Bipeur.blipSprite); SetBlipColour(missionBlip, Config.Bipeur.blipColor)
        SetBlipScale(missionBlip, 1.0); SetBlipFlashes(missionBlip, true)
        if route then SetBlipRoute(missionBlip, true) end
        BeginTextCommandSetBlipName('STRING'); AddTextComponentSubstringPlayerName('Dépannage Neon'); EndTextCommandSetBlipName(missionBlip)
    end

    local function nuiBipeur(data, show)
        SendNUIMessage({ action = show and 'show' or 'hide', company = Config.CompanyName, code = data and data.code or '',
            message = data and data.message or '', payout = data and data.payout and ('~%d$'):format(data.payout) or '' })
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
        TriggerServerEvent('esx_neon_mecano:server:repair', NetworkGetNetworkIdFromEntity(veh), fixType)
    end

    local function openRepairMenu(veh, state)
        veh = veh or getVeh(); state = state or vehState(veh)
        if veh == 0 then return end
        local options, repairs = {}, {
            { type = 'engine', cfg = Config.Repair.engine, price = Config.Prices.engine, icon = 'engine' },
            { type = 'body', cfg = Config.Repair.body, price = Config.Prices.body, icon = 'car-burst' },
            { type = 'tank', cfg = Config.Repair.tank, price = Config.Prices.tank, icon = 'gas-pump' },
            { type = 'tires', cfg = Config.Repair.tires, price = Config.Prices.tires, icon = 'circle' },
            { type = 'clean', cfg = Config.Repair.clean, price = Config.Prices.clean, icon = 'soap' },
            { type = 'full', cfg = Config.Repair.full, price = Config.Prices.full, icon = 'screwdriver-wrench' },
        }
        for _, r in ipairs(repairs) do
            local req = r.type == 'full' or needsFix(state, r.type)
            options[#options + 1] = { title = r.cfg.label, description = req and ('%d$'):format(r.price) or 'OK', icon = r.icon, disabled = not req,
                onSelect = function() runRepair(r.type, r.cfg, veh) end }
        end
        lib.registerContext({ id = 'neon_repair', title = 'Réparations', menu = 'neon_main', options = options })
        lib.showContext('neon_repair')
    end

    local function runDiagnostic(veh)
        veh = veh or getVeh()
        if veh == 0 then notify('Aucun véhicule.', 'error'); return end
        if not progress({ duration = Config.Repair.diagnosticDuration, label = 'Diagnostic...', anim = Config.Repair.engine.anim }) then ClearPedTasks(cache.ped); return end
        ClearPedTasks(cache.ped)
        local s = vehState(veh)
        lib.registerContext({ id = 'neon_diag', title = 'Diagnostic', menu = 'neon_main', options = {
            { title = ('Moteur : %d%%'):format(fmtHp(s.engine)), disabled = true },
            { title = ('Carrosserie : %d%%'):format(fmtHp(s.body)), disabled = true },
            { title = ('Réservoir : %d%%'):format(fmtHp(s.tank)), disabled = true },
            { title = 'Pneus', description = needsFix(s, 'tires') and 'Crevés' or 'OK', disabled = true },
            { title = 'Réparations', icon = 'wrench', onSelect = function() openRepairMenu(veh, s) end },
        }})
        lib.showContext('neon_diag')
    end

    local function openBipeur()
        if not isMech() then notify('Service requis.', 'error'); return end
        local opts = {{ title = 'Statut', description = activeAlert and activeAlert.label or 'Aucun appel', disabled = true }}
        if activeAlert and not activeAlert.accepted then
            opts[#opts+1] = { title = 'Accepter', icon = 'check', onSelect = function() TriggerServerEvent('esx_neon_mecano:server:acceptMission', activeAlert.id) end }
            opts[#opts+1] = { title = 'Refuser', icon = 'xmark', onSelect = function() activeAlert = nil; nuiBipeur(nil, false); clearBlip() end }
        elseif activeAlert and activeAlert.accepted then
            opts[#opts+1] = { title = 'GPS', icon = 'location-dot', onSelect = function() setBlip(activeAlert.coords, true) end }
            opts[#opts+1] = { title = 'Abandonner', icon = 'ban', onSelect = function() TriggerServerEvent('esx_neon_mecano:server:cancelMission', activeAlert.id) end }
        else
            opts[#opts+1] = { title = 'En attente...', disabled = true }
        end
        lib.registerContext({ id = 'neon_bipeur', title = 'Bipeur', options = opts }); lib.showContext('neon_bipeur')
    end

    local function toggleDuty()
        if not PlayerData.job or not Config.Jobs[PlayerData.job.name] then
            notify('Tu n\'es pas mécano.', 'error'); return
        end
        onDuty = not onDuty
        TriggerServerEvent('esx_neon_mecano:server:setDuty', onDuty)
        notify(onDuty and 'Prise de service — bipeur actif.' or 'Fin de service.', onDuty and 'success' or 'inform')
    end

    local function openMainMenu()
        if not isMech() then notify('Service requis. Utilise /neonmecano duty si besoin.', 'error'); return end
        lib.registerContext({ id = 'neon_main', title = Config.CompanyName, options = {
            { title = 'Diagnostic', icon = 'stethoscope', onSelect = runDiagnostic },
            { title = 'Réparations', icon = 'wrench', onSelect = function() openRepairMenu() end },
            { title = 'Bipeur', icon = 'pager', onSelect = openBipeur },
            { title = Config.RequireDuty and (onDuty and 'Fin de service' or 'Prise de service') or 'Service actif', icon = 'user-clock', onSelect = toggleDuty, disabled = not Config.RequireDuty },
        }})
        lib.showContext('neon_main')
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
        if lib.alertDialog({ header = 'Custom Neon', content = ('Valider : %s ?'):format(label or modType), centered = true, cancel = true }) ~= 'confirm' then return end
        applyCustomMod(veh, modType, modData)
        TriggerServerEvent('esx_neon_mecano:server:custom', NetworkGetNetworkIdFromEntity(veh), modType, modData)
    end

    local function openCustomMenu()
        if not isMech() then notify('Service requis.', 'error'); return end
        local veh = getVeh(6.0); if veh == 0 then return end
        lib.registerContext({ id = 'neon_custom', title = 'Custom', options = {
            { title = 'Néons', icon = 'lightbulb', onSelect = function()
                local opts = {}
                for _, c in ipairs(Config.CustomMods.neonColors) do
                    opts[#opts+1] = { title = c.label, onSelect = function()
                        confirmCustom(veh, 'neon', { r = c.r, g = c.g, b = c.b }, ('Néons %s'):format(c.label))
                    end }
                end
                lib.registerContext({ id = 'neon_neon', title = 'Néons', menu = 'neon_custom', options = opts }); lib.showContext('neon_neon')
            end },
            { title = 'Couleur', icon = 'palette', onSelect = function()
                local cols = {{ l = 'Noir', p = 0 }, { l = 'Blanc', p = 111 }, { l = 'Rouge', p = 27 }, { l = 'Bleu', p = 64 }, { l = 'Rose néon', p = 135 }}
                local opts = {}
                for _, c in ipairs(cols) do opts[#opts+1] = { title = c.l, onSelect = function()
                    local _, s = GetVehicleColours(veh)
                    confirmCustom(veh, 'color', { primary = c.p, secondary = s }, ('Couleur %s'):format(c.l))
                end } end
                lib.registerContext({ id = 'neon_color', title = 'Couleurs', menu = 'neon_custom', options = opts }); lib.showContext('neon_color')
            end },
            { title = 'Vitres teintées', icon = 'window-maximize', onSelect = function()
                local opts = {}
                for _, t in ipairs(Config.CustomMods.windowTints) do opts[#opts+1] = { title = t.label, onSelect = function()
                    confirmCustom(veh, 'tint', { index = t.index }, ('Vitres %s'):format(t.label))
                end } end
                lib.registerContext({ id = 'neon_tint', title = 'Vitres', menu = 'neon_custom', options = opts }); lib.showContext('neon_tint')
            end },
            { title = 'Jantes', icon = 'circle', onSelect = function()
                local opts = {}
                for _, w in ipairs(Config.CustomMods.wheelTypes) do opts[#opts+1] = { title = w.label, onSelect = function()
                    local n = GetNumVehicleMods(veh, 23)
                    local modIndex = n > 0 and math.random(0, n - 1) or 0
                    confirmCustom(veh, 'wheels', { wheelType = w.type, modIndex = modIndex }, ('Jantes %s'):format(w.label))
                end } end
                lib.registerContext({ id = 'neon_wheels', title = 'Jantes', menu = 'neon_custom', options = opts }); lib.showContext('neon_wheels')
            end },
        }})
        lib.showContext('neon_custom')
    end

    local function cleanupMission()
        if missionVehicle ~= 0 and DoesEntityExist(missionVehicle) then DeleteEntity(missionVehicle) end
        if missionPed ~= 0 and DoesEntityExist(missionPed) then DeleteEntity(missionPed) end
        missionVehicle, missionPed = 0, 0
    end

    local function missionRepair(veh, mType)
        veh = veh or getVeh(8.0); if veh == 0 then notify('Approche le véhicule.', 'error'); return false end
        local cfg = (mType == 'flat' and Config.Repair.tires) or ((mType == 'engine' or mType == 'battery') and Config.Repair.engine)
            or (mType == 'accident' and Config.Repair.body) or Config.Repair.full
        local openHood = mType == 'engine' or mType == 'battery'
        if openHood then setHood(veh, true) end
        local ok = progress({ duration = cfg.duration, label = cfg.label, anim = cfg.anim })
        if openHood then setHood(veh, false) end
        if not ok then ClearPedTasks(cache.ped); return false end
        ClearPedTasks(cache.ped); return true
    end

    RegisterNetEvent('esx:playerLoaded', function(xPlayer) PlayerData = xPlayer end)
    RegisterNetEvent('esx:setJob', function(job) PlayerData.job = job end)

    CreateThread(function()
        while not ESX.IsPlayerLoaded() do Wait(200) end
        PlayerData = ESX.GetPlayerData()
    end)

    RegisterNetEvent('esx_neon_mecano:client:applyFix', function(netId, fixType)
        local veh = NetworkGetEntityFromNetworkId(netId); if veh ~= 0 then applyFix(veh, fixType) end
    end)
    RegisterNetEvent('esx_neon_mecano:client:syncCustom', function(netId, modType, modData)
        local veh = NetworkGetEntityFromNetworkId(netId)
        if veh ~= 0 and modType and modData then applyCustomMod(veh, modType, modData) end
    end)
    RegisterNetEvent('esx_neon_mecano:client:openMenu', openMainMenu)
    RegisterNetEvent('esx_neon_mecano:client:openBipeur', openBipeur)

    RegisterNetEvent('esx_neon_mecano:client:bipeur', function(data)
        if not isMech() then return end
        activeAlert = data
        if Config.Bipeur.sound then SendNUIMessage({ action = 'beep' }); PlaySoundFrontend(-1, 'Text_Arrive_Tone', 'Phone_SoundSet_Default', true) end
        nuiBipeur(data, true); notify(data.message, 'inform'); setBlip(data.coords, false)
        SetTimeout(Config.Bipeur.blipTime * 1000, function() if activeAlert and activeAlert.id == data.id then clearBlip() end end)
    end)

    RegisterNetEvent('esx_neon_mecano:client:missionAccepted', function(data)
        activeAlert = data; nuiBipeur(nil, false); setBlip(data.coords, true); cleanupMission()
        local loc, model = data.coords, joaat(data.vehicleModel or 'blista')
        lib.requestModel(model)
        missionVehicle = CreateVehicle(model, loc.x, loc.y, loc.z, loc.w or 0.0, true, false)
        SetEntityAsMissionEntity(missionVehicle, true, true); SetVehicleOnGroundProperly(missionVehicle)
        SetVehicleEngineOn(missionVehicle, false, true, true)
        if data.damage then
            if data.damage.engine then SetVehicleEngineHealth(missionVehicle, data.damage.engine) end
            if data.damage.body then SetVehicleBodyHealth(missionVehicle, data.damage.body) end
        end
        if data.burstTires then SetVehicleTyreBurst(missionVehicle, 0, true, 1000.0); SetVehicleTyreBurst(missionVehicle, 1, true, 1000.0) end
        if data.missionType == 'engine' or data.missionType == 'battery' then SetVehicleUndriveable(missionVehicle, true) end
        lib.requestModel(joaat('a_m_y_business_01'))
        missionPed = CreatePed(4, joaat('a_m_y_business_01'), loc.x + 2.0, loc.y + 1.0, loc.z, 0.0, true, false)
        TaskStartScenarioInPlace(missionPed, 'WORLD_HUMAN_STAND_MOBILE', 0, true)
        currentMission = data
        exports.ox_target:addLocalEntity(missionVehicle, {{
            name = 'neon_mission', icon = 'fa-solid fa-wrench', label = 'Intervenir',
            canInteract = function() return isMech() and currentMission and currentMission.id == data.id end,
            onSelect = function()
                if missionRepair(missionVehicle, currentMission.missionType) then
                    TriggerServerEvent('esx_neon_mecano:server:completeMission', currentMission.id)
                end
            end,
        }})
        notify('Mission acceptée — rends-toi sur place.', 'success')
    end)

    RegisterNetEvent('esx_neon_mecano:client:missionComplete', function()
        if missionPed ~= 0 and DoesEntityExist(missionPed) then TaskWanderStandard(missionPed, 10.0, 10); SetTimeout(15000, function() if DoesEntityExist(missionPed) then DeleteEntity(missionPed) end end) end
        if missionVehicle ~= 0 and DoesEntityExist(missionVehicle) then SetVehicleFixed(missionVehicle); SetVehicleEngineOn(missionVehicle, true, true, false)
            SetTimeout(20000, function() if DoesEntityExist(missionVehicle) then DeleteEntity(missionVehicle) end end) end
        currentMission = nil
    end)

    RegisterNetEvent('esx_neon_mecano:client:missionEnded', function()
        activeAlert = nil; nuiBipeur(nil, false); clearBlip(); cleanupMission(); currentMission = nil
    end)

    RegisterNetEvent('esx_neon_mecano:client:spawnVehicle', function(model)
        local s, hash = Config.Garage.spawn, joaat(model)
        lib.requestModel(hash)
        local veh = CreateVehicle(hash, s.x, s.y, s.z, s.w, true, false)
        SetPedIntoVehicle(cache.ped, veh, -1); SetVehicleNumberPlateText(veh, 'NEON'); SetModelAsNoLongerNeeded(hash)
        notify('Véhicule sorti.', 'success')
    end)

    RegisterCommand('neonmecano', function(_, args)
        if args[1] == 'duty' then toggleDuty() else openMainMenu() end
    end, false)
    RegisterCommand('mecano', function(_, args)
        if args[1] == 'duty' then toggleDuty() else openMainMenu() end
    end, false)
    RegisterCommand(Config.Bipeur.command, openBipeur, false)
    RegisterKeyMapping(Config.Bipeur.command, 'Bipeur Neon Mechanic', 'keyboard', Config.Bipeur.keybind)

    RegisterNUICallback('accept', function(_, cb) if activeAlert and not activeAlert.accepted then TriggerServerEvent('esx_neon_mecano:server:acceptMission', activeAlert.id) end; cb('ok') end)
    RegisterNUICallback('decline', function(_, cb) activeAlert = nil; nuiBipeur(nil, false); clearBlip(); cb('ok') end)
    RegisterNUICallback('close', function(_, cb) nuiBipeur(nil, false); cb('ok') end)

    CreateThread(function()
        exports.ox_target:addGlobalVehicle({
            { name = 'neon_road_diag', icon = 'fa-solid fa-stethoscope', label = 'Diagnostic (Neon)', distance = Config.Repair.maxDistance,
              canInteract = isMech, onSelect = function(data) runDiagnostic(data.entity) end },
            { name = 'neon_road_repair', icon = 'fa-solid fa-wrench', label = 'Réparer (Neon)', distance = Config.Repair.maxDistance,
              canInteract = isMech, onSelect = function(data) openRepairMenu(data.entity) end },
        })
    end)

    CreateThread(function()
        for i, z in ipairs(Config.Workshop.zones) do
            exports.ox_target:addSphereZone({ coords = z.coords, radius = z.radius, options = {
                { name = 'neon_ws_' .. i, icon = 'fa-solid fa-wrench', label = z.label, canInteract = isMech, onSelect = openMainMenu },
                { name = 'neon_diag_' .. i, icon = 'fa-solid fa-stethoscope', label = 'Diagnostic', canInteract = isMech, onSelect = runDiagnostic },
            }})
        end
        local w = Config.Workshop
        local blip = AddBlipForCoord(w.zones[1].coords.x, w.zones[1].coords.y, w.zones[1].coords.z)
        SetBlipSprite(blip, w.blip.sprite); SetBlipColour(blip, w.blip.color); SetBlipScale(blip, w.blip.scale); SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING'); AddTextComponentSubstringPlayerName(w.blip.label); EndTextCommandSetBlipName(blip)
    end)

    CreateThread(function()
        local c = Config.CustomShop
        exports.ox_target:addSphereZone({ coords = c.coords, radius = c.radius, options = {{
            name = 'neon_custom', icon = 'fa-solid fa-spray-can', label = 'Custom Neon', canInteract = isMech, onSelect = openCustomMenu,
        }}})
        local blip = AddBlipForCoord(c.coords.x, c.coords.y, c.coords.z)
        SetBlipSprite(blip, c.blip.sprite); SetBlipColour(blip, c.blip.color); SetBlipScale(blip, c.blip.scale); SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING'); AddTextComponentSubstringPlayerName(c.blip.label); EndTextCommandSetBlipName(blip)
    end)

    CreateThread(function()
        local g = Config.Garage
        exports.ox_target:addSphereZone({ coords = g.coords, radius = 2.0, options = {{
            name = 'neon_garage', icon = 'fa-solid fa-truck-pickup', label = 'Garage Neon', canInteract = isMech,
            onSelect = function()
                local opts = {}
                for _, v in ipairs(g.vehicles) do opts[#opts+1] = { title = v.label, onSelect = function() TriggerServerEvent('esx_neon_mecano:server:spawnVehicle', v.model) end } end
                lib.registerContext({ id = 'neon_garage_m', title = 'Véhicules', options = opts }); lib.showContext('neon_garage_m')
            end,
        }}})
    end)

    AddEventHandler('onResourceStop', function(res) if res == GetCurrentResourceName() then cleanupMission() end end)
end
