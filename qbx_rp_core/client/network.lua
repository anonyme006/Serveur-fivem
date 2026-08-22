if not Config.Network or not Config.Network.enabled then return end

local cfg = Config.Network
local deployed = {} -- id -> data
local staticList = {}
local props = {} -- id -> entity
local blips = {}
local signalStrength = 0
local phoneBlocked = true -- pas de réseau par défaut
local lastNotify = 0
local signalReady = false

local function loadModel(model)
    if not model or model == '' then return nil end
    local hash = type(model) == 'number' and model or joaat(model)
    if not IsModelInCdimage(hash) and not IsModelValid(hash) then return nil end
    RequestModel(hash)
    local t = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < t do Wait(10) end
    return HasModelLoaded(hash) and hash or nil
end

local function deleteAntennaProp(id)
    local ent = props[id]
    if ent and DoesEntityExist(ent) then DeleteEntity(ent) end
    props[id] = nil
    if blips[id] then
        RemoveBlip(blips[id])
        blips[id] = nil
    end
end

local function spawnAntenna(id, data, isStatic)
    deleteAntennaProp(id)
    local c = data.coords
    if not c then return end
    local x = c.x or c[1]
    local y = c.y or c[2]
    local z = c.z or c[3]
    if not x then return end

    local hash = loadModel(cfg.prop) or loadModel(cfg.fallbackProp)
    if hash then
        local obj = CreateObject(hash, x, y, z - 1.0, false, false, false)
        SetEntityHeading(obj, data.heading or 0.0)
        FreezeEntityPosition(obj, true)
        SetEntityInvincible(obj, true)
        SetModelAsNoLongerNeeded(hash)
        props[id] = obj
    end

    if cfg.blip and cfg.blip.enabled and not isStatic then
        local blip = AddBlipForCoord(x, y, z)
        SetBlipSprite(blip, cfg.blip.sprite or 459)
        SetBlipColour(blip, cfg.blip.color or 3)
        SetBlipScale(blip, cfg.blip.scale or 0.65)
        SetBlipAsShortRange(blip, cfg.blip.shortRange ~= false)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(data.label or 'Antenne')
        EndTextCommandSetBlipName(blip)
        blips[id] = blip
    end
end

local function syncAntennas(dynamic, static)
    deployed = dynamic or {}
    staticList = static or {}

    local keep = {}
    for id, data in pairs(deployed) do
        keep[id] = true
        spawnAntenna(id, data, false)
    end
    for id in pairs(props) do
        if type(id) == 'number' and not keep[id] then
            deleteAntennaProp(id)
        end
    end

    for i, data in ipairs(staticList) do
        local sid = 'static_' .. i
        spawnAntenna(sid, {
            coords = { x = data.coords.x, y = data.coords.y, z = data.coords.z },
            heading = data.heading or 0.0,
            label = data.label or 'Antenne',
            range = data.range,
        }, true)
    end
end

RegisterNetEvent('qbx_rp_core:network:sync', function(dynamic, static)
    syncAntennas(dynamic, static)
end)

local function calcLocalSignal()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local best = 0
    local maxRange = cfg.range or 180.0
    local goodRange = cfg.goodRange or 90.0

    local function consider(data)
        local c = data.coords
        if not c then return end
        local x, y, z = c.x or c[1], c.y or c[2], c.z or c[3]
        if not x then return end
        local dist = #(coords - vec3(x, y, z))
        local range = tonumber(data.range) or maxRange
        if dist > range then return end
        local strength
        if dist <= goodRange then
            strength = 100 - math.floor((dist / goodRange) * 30)
        else
            strength = 70 - math.floor(((dist - goodRange) / math.max(1.0, range - goodRange)) * 70)
        end
        if strength < 1 then strength = 1 end
        if strength > best then best = strength end
    end

    for _, data in pairs(deployed) do consider(data) end
    for _, data in ipairs(staticList) do
        consider({
            coords = { x = data.coords.x, y = data.coords.y, z = data.coords.z },
            range = data.range or maxRange,
        })
    end

    return best
end

--- Bridges téléphone
local function setPhoneNetwork(hasSignal)
    local phones = cfg.phones or {}

    if phones.npwd and GetResourceState('npwd') == 'started' then
        pcall(function()
            exports.npwd:setPhoneDisabled(not hasSignal)
        end)
    end

    if phones.lbphone then
        if GetResourceState('lb-phone') == 'started' then
            pcall(function()
                exports['lb-phone']:ToggleDisabled(not hasSignal)
            end)
            -- Fallback events utilisés par certaines builds
            TriggerEvent('lb-phone:SetAirplaneMode', not hasSignal)
        end
    end

    if phones.gksphone and GetResourceState('gksphone') == 'started' then
        pcall(function()
            exports['gksphone']:SetAirplaneMode(not hasSignal)
        end)
    end

    if phones.qsmartphone then
        for _, res in ipairs({ 'qs-smartphone-pro', 'qs-smartphone' }) do
            if GetResourceState(res) == 'started' then
                pcall(function()
                    exports[res]:SetCanOpenPhone(hasSignal)
                end)
                TriggerEvent(res .. ':setAirplaneMode', not hasSignal)
            end
        end
    end

    LocalPlayer.state.qbx_rp_core_signal = signalStrength
    LocalPlayer.state.qbx_rp_core_has_network = hasSignal
end

local function notifyNoSignal(action)
    if not (cfg.phones and cfg.phones.notifyOnBlock) then return end
    local now = GetGameTimer()
    if now - lastNotify < 4000 then return end
    lastNotify = now
    Core.Notify(Core.Locale('network_no_signal', action or 'téléphone'), 'error')
end

--- API client
exports('GetSignalStrength', function()
    return signalStrength
end)

exports('HasNetworkSignal', function()
    return signalStrength > 0
end)

--- Bloquer actions téléphone (appel / SMS / social)
--- Autres scripts : if not exports.qbx_rp_core:CanUsePhoneFeature('call') then return end
exports('CanUsePhoneFeature', function(feature)
    if signalStrength <= 0 then
        notifyNoSignal(feature or 'réseau')
        return false
    end
    return true
end)

-- Events génériques pour scripts téléphone custom
AddEventHandler('qbx_rp_core:network:tryCall', function(cb)
    local ok = signalStrength > 0
    if not ok then notifyNoSignal(Core.Locale('network_action_call')) end
    if cb then cb(ok) end
end)

AddEventHandler('qbx_rp_core:network:tryMessage', function(cb)
    local ok = signalStrength > 0
    if not ok then notifyNoSignal(Core.Locale('network_action_sms')) end
    if cb then cb(ok) end
end)

AddEventHandler('qbx_rp_core:network:trySocial', function(cb)
    local ok = signalStrength > 0
    if not ok then notifyNoSignal(Core.Locale('network_action_social')) end
    if cb then cb(ok) end
end)

-- Boucle signal + HUD
CreateThread(function()
    Wait(2000)
    local dyn, stat = lib.callback.await('qbx_rp_core:network:getAntennas', false)
    if dyn then syncAntennas(dyn, stat) end

    while true do
        signalStrength = calcLocalSignal()
        local hasSignal = signalStrength > 0

        if hasSignal ~= (not phoneBlocked) then
            phoneBlocked = not hasSignal
            setPhoneNetwork(hasSignal)
            if signalReady then
                if not hasSignal then
                    Core.Notify(Core.Locale('network_lost'), 'error')
                elseif signalStrength >= 50 then
                    Core.Notify(Core.Locale('network_ok'), 'success')
                else
                    Core.Notify(Core.Locale('network_weak'), 'warning')
                end
            end
        else
            setPhoneNetwork(hasSignal)
        end

        signalReady = true
        Wait(cfg.checkInterval or 1000)
    end
end)

-- HUD signal (coins)
CreateThread(function()
    while true do
        if cfg.showSignalHud then
            local bars = 0
            if signalStrength > 0 then bars = 1 end
            if signalStrength >= 30 then bars = 2 end
            if signalStrength >= 55 then bars = 3 end
            if signalStrength >= 80 then bars = 4 end

            local label = signalStrength <= 0 and Core.Locale('network_hud_none')
                or Core.Locale('network_hud_signal', bars, signalStrength)

            SetTextFont(4)
            SetTextScale(0.35, 0.35)
            SetTextColour(signalStrength <= 0 and 220 or 180, signalStrength <= 0 and 80 or 220, signalStrength <= 0 and 80 or 180, 220)
            SetTextOutline()
            SetTextEntry('STRING')
            AddTextComponentString(label)
            DrawText(0.86, 0.94)

            Wait(0)
        else
            Wait(1000)
        end
    end
end)

local function deployAntenna()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        return Core.Notify(Core.Locale('network_in_vehicle'), 'error')
    end

    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local forward = GetEntityForwardVector(ped)
    local place = coords + forward * 1.2

    local okProgress = true
    if lib.progressCircle then
        okProgress = lib.progressCircle({
            duration = cfg.deployProgress or 8000,
            label = Core.Locale('network_deploying'),
            position = 'bottom',
            useWhileDead = false,
            canCancel = true,
            disable = { move = true, car = true, combat = true },
            anim = { dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', clip = 'machinic_loop_mechandplayer' },
        })
    else
        Wait(cfg.deployProgress or 8000)
    end
    if not okProgress then return end

    local ok, msg, id = lib.callback.await('qbx_rp_core:network:deploy', false, {
        x = place.x, y = place.y, z = place.z,
    }, heading)

    if ok then
        Core.Notify(Core.Locale(msg or 'network_deployed'), 'success')
    else
        if msg == 'network_max' then
            Core.Notify(Core.Locale('network_max', id), 'error')
        else
            Core.Notify(Core.Locale(msg or 'cover_busy'), 'error')
        end
    end
end

RegisterNetEvent('qbx_rp_core:network:tryDeploy', function()
    deployAntenna()
end)

-- ox_inventory export
exports('usePhoneAntenna', function()
    deployAntenna()
end)

RegisterCommand('antenne', function()
    deployAntenna()
end, false)

RegisterCommand('retirerantenne', function()
    local ped = PlayerPedId()
    local pcoords = GetEntityCoords(ped)
    local nearest, dist, nearestId = nil, 3.5, nil

    for id, data in pairs(deployed) do
        local c = data.coords
        if c then
            local d = #(pcoords - vec3(c.x, c.y, c.z))
            if d < dist then
                dist = d
                nearest = data
                nearestId = id
            end
        end
    end

    if not nearest then
        return Core.Notify(Core.Locale('network_none_nearby'), 'error')
    end

    local okProgress = true
    if lib.progressCircle then
        okProgress = lib.progressCircle({
            duration = cfg.removeProgress or 6000,
            label = Core.Locale('network_removing'),
            position = 'bottom',
            useWhileDead = false,
            canCancel = true,
            disable = { move = true, car = true, combat = true },
            anim = { dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', clip = 'machinic_loop_mechandplayer' },
        })
    end
    if not okProgress then return end

    local ok, msg = lib.callback.await('qbx_rp_core:network:remove', false, nearestId)
    Core.Notify(Core.Locale(msg or (ok and 'network_removed' or 'cover_busy')), ok and 'success' or 'error')
end, false)

-- Interaction proche antennes
CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local pcoords = GetEntityCoords(ped)

        for id, data in pairs(deployed) do
            local c = data.coords
            if c then
                local d = #(pcoords - vec3(c.x, c.y, c.z))
                if d < 12.0 then
                    sleep = 0
                    if d < 2.5 then
                        BeginTextCommandDisplayHelp('STRING')
                        AddTextComponentSubstringPlayerName(Core.Locale('network_help_remove'))
                        EndTextCommandDisplayHelp(0, false, true, -1)
                        if IsControlJustReleased(0, 38) then
                            ExecuteCommand('retirerantenne')
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for id in pairs(props) do deleteAntennaProp(id) end
end)
