if Config.Modules and Config.Modules.core == false then return end

if not Config.Offroad or not Config.Offroad.enabled then return end

local cfg = Config.Offroad
local lastLabel = nil
local lastNotify = 0
local affected = false
local whitelistHashes = {}
local softHashes = {}

CreateThread(function()
    for _, name in ipairs(cfg.whitelist or {}) do
        local hash = type(name) == 'number' and name or joaat(name)
        whitelistHashes[hash] = true
    end
    for name, mult in pairs(cfg.softMultiplier or {}) do
        local hash = type(name) == 'number' and name or joaat(name)
        softHashes[hash] = tonumber(mult) or 1.0
    end
end)

local function resetVehicle(veh)
    if not veh or veh == 0 or not DoesEntityExist(veh) then return end
    SetVehicleEngineTorqueMultiplier(veh, 1.0)
    SetVehicleReduceGrip(veh, false)
    -- 0.0 = vitesse max native
    SetVehicleMaxSpeed(veh, 0.0)
    affected = false
end

local function majoritySurface(veh)
    local counts = {}
    local bestId, bestCount = nil, 0

    for wheel = 0, 3 do
        local mat = GetVehicleWheelSurfaceMaterial(veh, wheel)
        if mat and mat ~= 0 then
            counts[mat] = (counts[mat] or 0) + 1
            if counts[mat] > bestCount then
                bestCount = counts[mat]
                bestId = mat
            end
        end
    end

    return bestId
end

local function isExempt(veh)
    local class = GetVehicleClass(veh)
    local model = GetEntityModel(veh)

    if whitelistHashes[model] then
        return true, 0.0
    end

    -- Classes non terrestres / motos / vélos
    if cfg.exemptClasses and cfg.exemptClasses[class] then
        if class == 9 then
            -- Off-road : pas exempt, mais pénalité allégée (relief 0–1)
            return false, cfg.offroadClassMultiplier or 0.85
        end
        return true, 0.0
    end

    -- relief 0 = pénalité pleine (softMultiplier appliqué à part)
    return false, 0.0
end

local function applySurface(veh, surface, relief)
    relief = tonumber(relief) or 0.0
    if relief < 0.0 then relief = 0.0 end
    if relief > 1.0 then relief = 1.0 end

    -- relief 1.0 ≈ aucune perte, 0.0 = traction configurée
    local traction = (surface.traction or 1.0)
    traction = traction + (1.0 - traction) * relief

    local soft = softHashes[GetEntityModel(veh)]
    if soft and soft < 1.0 then
        traction = traction * soft
    end

    if traction < 0.15 then traction = 0.15 end
    if traction > 1.0 then traction = 1.0 end

    SetVehicleEngineTorqueMultiplier(veh, traction)

    if surface.grip and traction < 0.60 and relief < 0.9 then
        SetVehicleReduceGrip(veh, true)
    else
        SetVehicleReduceGrip(veh, false)
    end

    if surface.maxKmh then
        local cap = surface.maxKmh + (surface.maxKmh * relief * 0.4)
        SetVehicleMaxSpeed(veh, (cap / 3.6) + 0.0)
    else
        SetVehicleMaxSpeed(veh, 0.0)
    end

    affected = true
end

CreateThread(function()
    while true do
        local sleep = 500
        local ped = PlayerPedId()

        if IsPedInAnyVehicle(ped, false) then
            local veh = GetVehiclePedIsIn(ped, false)
            if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
                sleep = cfg.interval or 150

                local exempt, classMult = isExempt(veh)
                if exempt then
                    if affected then
                        resetVehicle(veh)
                        lastLabel = nil
                    end
                else
                    local matId = majoritySurface(veh)
                    local surface = matId and cfg.surfaces and cfg.surfaces[matId]

                    if surface then
                        applySurface(veh, surface, classMult or 0.0)

                        if cfg.notify and surface.label and surface.label ~= lastLabel then
                            local now = GetGameTimer()
                            if now - lastNotify > 8000 then
                                lastNotify = now
                                lastLabel = surface.label
                                Core.Notify(Core.Locale('offroad_slow', surface.label), 'warning')
                            else
                                lastLabel = surface.label
                            end
                        end
                    else
                        if affected then
                            resetVehicle(veh)
                            lastLabel = nil
                        end
                    end
                end
            elseif affected then
                -- passager / plus conducteur : ne pas laisser l'état coincé si on reprend
                affected = false
                lastLabel = nil
            end
        else
            if affected then
                -- sortie véhicule : reset si entité encore valide
                local veh = GetVehiclePedIsIn(ped, true)
                if veh ~= 0 and DoesEntityExist(veh) then
                    resetVehicle(veh)
                end
                affected = false
                lastLabel = nil
            end
            sleep = 800
        end

        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        resetVehicle(GetVehiclePedIsIn(ped, false))
    end
end)
