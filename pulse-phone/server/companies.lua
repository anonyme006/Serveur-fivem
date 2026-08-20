--[[
    Pulse Phone — Entreprises
]]

Pulse = Pulse or {}
Pulse.Companies = {
    runtime = {}, -- id -> { employeesOnline = n, status = ... }
}

local function countOnDuty(jobName)
    local count = 0
    local players = exports.qbx_core:GetQBPlayers()
    if not players then return 0 end
    for _, player in pairs(players) do
        local job = player.PlayerData and player.PlayerData.job
        if job and job.name == jobName and job.onduty then
            count = count + 1
        end
    end
    return count
end

local function computeAutoStatus(online)
    if online < Config.CompanyAutoStatus.closedBelow then
        return 'closed'
    end
    if online < Config.CompanyAutoStatus.openAt then
        return 'busy'
    end
    return 'open'
end

function Pulse.Companies.SyncFromConfig()
    for id, company in pairs(Config.Companies) do
        MySQL.query.await([[
            INSERT INTO phone_companies (id, label, job, category, description, number, status, auto_status)
            VALUES (?, ?, ?, ?, ?, ?, 'closed', ?)
            ON DUPLICATE KEY UPDATE
                label = VALUES(label),
                job = VALUES(job),
                category = VALUES(category),
                description = VALUES(description),
                number = VALUES(number),
                auto_status = VALUES(auto_status)
        ]], {
            company.id or id,
            company.label,
            company.job,
            company.category or 'service',
            company.description or '',
            company.number,
            company.autoStatus and 1 or 0,
        })
    end
end

---@param companyId string
---@param data table
function Pulse.Companies.Register(companyId, data)
    if type(companyId) ~= 'string' or type(data) ~= 'table' then return false end
    Config.Companies[companyId] = {
        id = companyId,
        label = data.label or companyId,
        job = data.job or companyId,
        minGrade = data.minGrade or 0,
        manageGrade = data.manageGrade or 2,
        category = data.category or 'service',
        description = data.description or '',
        number = tostring(data.number or ''),
        blip = data.blip,
        autoStatus = data.autoStatus ~= false,
    }
    Pulse.Companies.SyncFromConfig()
    return true
end

function Pulse.Companies.Get(companyId)
    return Config.Companies[companyId]
end

function Pulse.Companies.GetPublicList()
    local list = {}
    for id, company in pairs(Config.Companies) do
        local online = countOnDuty(company.job)
        local status = company.autoStatus and computeAutoStatus(online) or 'closed'
        local row = MySQL.single.await('SELECT logo, status, auto_status, pos_x, pos_y, pos_z FROM phone_companies WHERE id = ?', { id })
        if row and row.auto_status == 0 then
            status = row.status
        elseif row then
            MySQL.update.await('UPDATE phone_companies SET status = ? WHERE id = ?', { status, id })
        end

        list[#list + 1] = {
            id = id,
            label = company.label,
            description = company.description,
            number = company.number,
            category = company.category,
            status = status,
            employeesOnline = online,
            logo = row and row.logo or nil,
            position = row and row.pos_x and { x = row.pos_x, y = row.pos_y, z = row.pos_z } or nil,
        }
    end
    table.sort(list, function(a, b) return a.label < b.label end)
    return list
end

lib.callback.register('pulse-phone:server:getCompanies', function(_source)
    return Pulse.Companies.GetPublicList()
end)

lib.callback.register('pulse-phone:server:getCompany', function(_source, companyId)
    if type(companyId) ~= 'string' then return nil end
    local list = Pulse.Companies.GetPublicList()
    for _, c in ipairs(list) do
        if c.id == companyId then return c end
    end
    return nil
end)

lib.callback.register('pulse-phone:server:setCompanyStatus', function(source, companyId, status)
    local company = Config.Companies[companyId]
    if not company then return { ok = false, error = 'unknown' } end
    if not Pulse.Players.HasJob(source, company.job, company.manageGrade) then
        return { ok = false, error = 'forbidden' }
    end
    if status ~= 'open' and status ~= 'busy' and status ~= 'closed' then
        return { ok = false, error = 'invalid' }
    end
    MySQL.update.await(
        'UPDATE phone_companies SET status = ?, auto_status = 0 WHERE id = ?',
        { status, companyId }
    )
    return { ok = true, status = status }
end)

exports('RegisterCompany', function(companyId, data)
    return Pulse.Companies.Register(companyId, data)
end)

exports('GetCompany', function(companyId)
    return Pulse.Companies.Get(companyId)
end)
