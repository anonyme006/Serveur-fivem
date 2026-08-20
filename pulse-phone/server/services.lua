--[[
    Pulse Phone — Demandes de service (priorité)
    Acceptation atomique pour éviter le double-accept.
]]

Pulse = Pulse or {}
Pulse.Services = {}

local requestCooldown = {}

local function getOnlineEmployees(jobName, minGrade)
    local list = {}
    local players = exports.qbx_core:GetQBPlayers()
    if not players then return list end
    for src, player in pairs(players) do
        local job = player.PlayerData and player.PlayerData.job
        if job and job.name == jobName and job.onduty then
            local grade = job.grade and job.grade.level or 0
            if grade >= (minGrade or 0) then
                list[#list + 1] = src
            end
        end
    end
    return list
end

local function findSourceByCitizenId(citizenid)
    local players = exports.qbx_core:GetQBPlayers()
    if not players then return nil end
    for src, player in pairs(players) do
        if player.PlayerData.citizenid == citizenid then
            return src
        end
    end
    return nil
end

---@param source number
---@param data table
---@return table
function Pulse.Services.CreateRequest(source, data)
    local citizenid = Pulse.Server.GetCitizenId(source)
    if not citizenid or type(data) ~= 'table' then
        return { ok = false }
    end

    local now = os.time()
    if requestCooldown[source] and now - requestCooldown[source] < (Config.Cooldowns.serviceRequest / 1000) then
        return { ok = false, error = 'cooldown' }
    end
    requestCooldown[source] = now

    local company = Config.Companies[data.companyId]
    if not company then return { ok = false, error = 'unknown_company' } end

    local user = Pulse.Database.GetUser(citizenid)
    if not user then return { ok = false } end

    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    local description = type(data.description) == 'string' and data.description:sub(1, 500) or ''
    if description == '' then return { ok = false, error = 'invalid' } end

    local serviceType = type(data.serviceType) == 'string' and data.serviceType:sub(1, 80) or 'general'
    local locationLabel = type(data.locationLabel) == 'string' and data.locationLabel:sub(1, 120) or nil
    local clientName = Pulse.Players.GetFullName(source)
    local companyId = company.id or data.companyId

    local id = MySQL.insert.await([[
        INSERT INTO phone_service_requests
            (company_id, citizenid, client_name, client_number, service_type, description, pos_x, pos_y, pos_z, location_label, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending')
    ]], {
        companyId,
        citizenid,
        clientName,
        user.phone_number,
        serviceType,
        description,
        coords.x, coords.y, coords.z,
        locationLabel,
    })

    local payload = {
        id = id,
        companyId = companyId,
        clientName = clientName,
        clientNumber = user.phone_number,
        serviceType = serviceType,
        description = description,
        locationLabel = locationLabel,
        position = { x = coords.x, y = coords.y, z = coords.z },
        status = 'pending',
    }

    for _, empSrc in ipairs(getOnlineEmployees(company.job, company.minGrade)) do
        TriggerClientEvent('pulse-phone:client:notify', empSrc, {
            type = 'service',
            title = 'SERVICE',
            body = L('new_service_request'),
            sound = 'company',
            payload = payload,
        })
        TriggerClientEvent('pulse-phone:client:serviceRequest', empSrc, payload)
    end

    return { ok = true, request = payload }
end

lib.callback.register('pulse-phone:server:createServiceRequest', function(source, data)
    return Pulse.Services.CreateRequest(source, data)
end)

lib.callback.register('pulse-phone:server:acceptServiceRequest', function(source, requestId)
    local citizenid = Pulse.Server.GetCitizenId(source)
    requestId = tonumber(requestId)
    if not citizenid or not requestId then return { ok = false } end

    local row = MySQL.single.await('SELECT * FROM phone_service_requests WHERE id = ? LIMIT 1', { requestId })
    if not row or row.status ~= 'pending' then
        return { ok = false, error = 'unavailable' }
    end

    local company = Config.Companies[row.company_id]
    if not company or not Pulse.Players.HasJob(source, company.job, company.minGrade) then
        return { ok = false, error = 'forbidden' }
    end

    local affected = MySQL.update.await([[
        UPDATE phone_service_requests
        SET status = 'accepted', accepted_by = ?, accepted_at = NOW()
        WHERE id = ? AND status = 'pending'
    ]], { citizenid, requestId })

    if not affected or affected < 1 then
        return { ok = false, error = 'already_taken' }
    end

    local employeeName = Pulse.Players.GetFullName(source)
    local clientSrc = findSourceByCitizenId(row.citizenid)
    local result = {
        id = requestId,
        status = 'accepted',
        employeeName = employeeName,
        acceptedBy = citizenid,
        companyId = row.company_id,
        position = { x = row.pos_x, y = row.pos_y, z = row.pos_z },
    }

    if clientSrc then
        TriggerClientEvent('pulse-phone:client:notify', clientSrc, {
            type = 'service',
            title = L('service_accepted'),
            body = employeeName,
            payload = result,
        })
        TriggerClientEvent('pulse-phone:client:serviceUpdate', clientSrc, result)
    end

    return { ok = true, request = result }
end)

lib.callback.register('pulse-phone:server:refuseServiceRequest', function(source, requestId)
    local citizenid = Pulse.Server.GetCitizenId(source)
    requestId = tonumber(requestId)
    if not citizenid or not requestId then return { ok = false } end

    local row = MySQL.single.await('SELECT * FROM phone_service_requests WHERE id = ? LIMIT 1', { requestId })
    if not row or row.status ~= 'pending' then return { ok = false } end

    local company = Config.Companies[row.company_id]
    if not company or not Pulse.Players.HasJob(source, company.job, company.minGrade) then
        return { ok = false, error = 'forbidden' }
    end

    MySQL.update.await(
        'UPDATE phone_service_requests SET status = ? WHERE id = ? AND status = ?',
        { 'refused', requestId, 'pending' }
    )
    return { ok = true }
end)

exports('CreateServiceRequest', function(src, data)
    return Pulse.Services.CreateRequest(src, data)
end)
