if not Config.Network or not Config.Network.enabled then return end

local antennas = {} -- id -> { id, owner, label, coords, heading, range }

local function syncAll(target)
    TriggerClientEvent('qbx_rp_core:network:sync', target or -1, antennas, Config.Network.staticAntennas or {})
end

local function loadAntennas()
    antennas = {}
    local rows = MySQL.query.await('SELECT * FROM qbx_rp_core_antennas') or {}
    for _, row in ipairs(rows) do
        local coords = Core.DecodeJson(row.coords)
        antennas[row.id] = {
            id = row.id,
            owner = row.owner,
            label = row.label or ('Antenne #%s'):format(row.id),
            coords = coords,
            heading = tonumber(row.heading) or 0.0,
            range = tonumber(row.range_m) or Config.Network.range or 180.0,
            static = false,
        }
    end
    syncAll(-1)
    print(('^2[qbx_rp_core]^0 %d antenne(s) réseau chargée(s)'):format(#rows))
end

MySQL.ready(function()
    SetTimeout(2500, loadAntennas)
end)

local function countOwned(identifier)
    local n = 0
    for _, a in pairs(antennas) do
        if a.owner == identifier then n = n + 1 end
    end
    return n
end

local function removeItem(src)
    local item = Config.Network.antennaItem or 'phone_antenna'
    if GetResourceState('ox_inventory') ~= 'started' then return false end
    return exports.ox_inventory:RemoveItem(src, item, 1) and true or false
end

local function giveItem(src)
    local item = Config.Network.antennaItem or 'phone_antenna'
    if GetResourceState('ox_inventory') ~= 'started' then return false end
    return exports.ox_inventory:AddItem(src, item, 1) and true or false
end

local function hasItem(src)
    local item = Config.Network.antennaItem or 'phone_antenna'
    if GetResourceState('ox_inventory') ~= 'started' then return false end
    local count = exports.ox_inventory:Search(src, 'count', item) or 0
    return (tonumber(count) or 0) > 0
end

--- Signal pour un joueur (serveur)
---@return number strength 0–100, number|nil antennaId
function Core.GetSignalStrength(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return 0, nil end
    local coords = GetEntityCoords(ped)
    local best, bestId = 0, nil
    local maxRange = Config.Network.range or 180.0
    local goodRange = Config.Network.goodRange or 90.0

    local function consider(id, data)
        if not data.coords or not data.coords.x then return end
        local c = data.coords
        local dist = #(coords - vec3(c.x, c.y, c.z))
        local range = tonumber(data.range) or maxRange
        if dist > range then return end
        local strength
        if dist <= goodRange then
            strength = 100 - math.floor((dist / goodRange) * 30)
        else
            strength = 70 - math.floor(((dist - goodRange) / math.max(1.0, range - goodRange)) * 70)
        end
        if strength < 1 then strength = 1 end
        if strength > best then
            best = strength
            bestId = id
        end
    end

    for id, data in pairs(antennas) do
        consider(id, data)
    end
    for i, data in ipairs(Config.Network.staticAntennas or {}) do
        consider('static_' .. i, {
            coords = { x = data.coords.x, y = data.coords.y, z = data.coords.z },
            range = data.range or maxRange,
        })
    end

    return best, bestId
end

exports('GetSignalStrength', function(src)
    return Core.GetSignalStrength(src)
end)

exports('HasNetworkSignal', function(src)
    local s = Core.GetSignalStrength(src)
    return s > 0
end)

lib.callback.register('qbx_rp_core:network:getSignal', function(source)
    local strength, antennaId = Core.GetSignalStrength(source)
    return { strength = strength, antennaId = antennaId, hasSignal = strength > 0 }
end)

lib.callback.register('qbx_rp_core:network:getAntennas', function()
    return antennas, Config.Network.staticAntennas or {}
end)

lib.callback.register('qbx_rp_core:network:deploy', function(source, coords, heading)
    local player = Core.GetPlayer(source)
    if not player then return false, 'cover_busy' end
    if type(coords) ~= 'table' or not coords.x then return false, 'cover_busy' end

    if not hasItem(source) then
        return false, 'network_no_item'
    end

    local max = tonumber(Config.Network.maxPerPlayer) or 0
    if max > 0 and countOwned(Core.GetCitizenId(player)) >= max then
        return false, 'network_max', max
    end

    if not removeItem(source) then
        return false, 'network_no_item'
    end

    local range = Config.Network.range or 180.0
    local insertId = MySQL.insert.await(
        'INSERT INTO qbx_rp_core_antennas (owner, label, coords, heading, range_m) VALUES (?, ?, ?, ?, ?)',
        {
            Core.GetCitizenId(player),
            ('Antenne %s'):format(GetPlayerName(source) or ''),
            json.encode({ x = coords.x, y = coords.y, z = coords.z }),
            tonumber(heading) or 0.0,
            range,
        }
    )

    antennas[insertId] = {
        id = insertId,
        owner = Core.GetCitizenId(player),
        label = ('Antenne #%s'):format(insertId),
        coords = { x = coords.x, y = coords.y, z = coords.z },
        heading = tonumber(heading) or 0.0,
        range = range,
        static = false,
    }

    MySQL.update.await('UPDATE qbx_rp_core_antennas SET label = ? WHERE id = ?', {
        ('Antenne #%s'):format(insertId), insertId
    })
    antennas[insertId].label = ('Antenne #%s'):format(insertId)

    syncAll(-1)

    if Core.Log then
        Core.Log('system', '📡 Antenne déployée', ('ID `%s` — portée %sm'):format(insertId, range), {
            color = 'success',
            src = source,
            fields = {
                { name = 'Coords', value = ('`%.1f, %.1f, %.1f`'):format(coords.x, coords.y, coords.z), inline = false },
            },
        })
    end

    return true, 'network_deployed', insertId
end)

lib.callback.register('qbx_rp_core:network:remove', function(source, antennaId)
    local player = Core.GetPlayer(source)
    if not player then return false, 'cover_busy' end

    antennaId = tonumber(antennaId)
    local entry = antennaId and antennas[antennaId]
    if not entry then return false, 'network_not_found' end

    local allowed = entry.owner == Core.GetCitizenId(player)
    if not allowed and Config.Network.removeJobs then
        local job = Core.GetJob(player)
        if job and job.name then
            local minGrade = Config.Network.removeJobs[job.name]
            if minGrade ~= nil and Core.GetJobGrade(player) >= minGrade then
                allowed = true
            end
        end
    end
    if not allowed then return false, 'network_not_yours' end

    MySQL.update.await('DELETE FROM qbx_rp_core_antennas WHERE id = ?', { antennaId })
    antennas[antennaId] = nil
    giveItem(source)
    syncAll(-1)

    if Core.Log then
        Core.Log('system', '📡 Antenne retirée', ('ID `%s`'):format(antennaId), {
            color = 'warning',
            src = source,
        })
    end

    return true, 'network_removed'
end)

lib.callback.register('qbx_rp_core:network:canUsePhone', function(source, action)
    local strength = Core.GetSignalStrength(source)
    if strength <= 0 then
        return false, 'network_no_signal', action or 'phone'
    end
    return true, strength
end)

AddEventHandler('playerJoining', function()
    local src = source
    SetTimeout(5000, function()
        if GetPlayerName(src) then syncAll(src) end
    end)
end)

CreateThread(function()
    Wait(1500)
    local item = Config.Network.antennaItem or 'phone_antenna'
    Core.RegisterUsableItem(item, function(playerId)
        TriggerClientEvent('qbx_rp_core:network:tryDeploy', playerId)
    end)
end)

exports('GetAntennas', function()
    return antennas
end)
