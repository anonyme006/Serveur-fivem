--[[
    Pulse Phone — Entreprises + gestion + duty + solde
]]

Pulse = Pulse or {}
Pulse.Companies = {
    runtime = {},
}

local dutyCooldown = {}

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

local function resourceStarted(name)
    return GetResourceState(name) == 'started'
end

---@param jobName string
---@return number
function Pulse.Companies.GetBalance(jobName)
    local provider = Config.CompanyBanking and Config.CompanyBanking.provider or 'auto'

    local function tryRenewed()
        if not resourceStarted('Renewed-Banking') then return nil end
        local ok, amount = pcall(function()
            return exports['Renewed-Banking']:getAccountMoney(jobName)
        end)
        if ok and type(amount) == 'number' then return amount end
        return nil
    end

    local function tryQbManagement()
        if not resourceStarted('qb-management') then return nil end
        local ok, amount = pcall(function()
            return exports['qb-management']:GetAccount(jobName)
        end)
        if ok and type(amount) == 'number' then return amount end
        return nil
    end

    local function tryQbxManagement()
        if not resourceStarted('qbx_management') then return nil end
        local ok, amount = pcall(function()
            return exports.qbx_management:GetAccount(jobName)
        end)
        if ok and type(amount) == 'number' then return amount end
        return nil
    end

    local function fromDb()
        local row = MySQL.single.await('SELECT balance FROM phone_companies WHERE job = ? OR id = ? LIMIT 1', { jobName, jobName })
        return row and tonumber(row.balance) or 0
    end

    if provider == 'renewed' then return tryRenewed() or 0 end
    if provider == 'qb-management' then return tryQbManagement() or 0 end
    if provider == 'qbx_management' then return tryQbxManagement() or 0 end
    if provider == 'phone_db' then return fromDb() end

    return tryRenewed() or tryQbxManagement() or tryQbManagement() or fromDb()
end

function Pulse.Companies.SyncFromConfig()
    for id, company in pairs(Config.Companies) do
        local coords = company.coords or {}
        MySQL.query.await([[
            INSERT INTO phone_companies
                (id, label, job, category, description, location, number, icon, icon_color, status, auto_status, pos_x, pos_y, pos_z)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'closed', ?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE
                label = VALUES(label),
                job = VALUES(job),
                category = VALUES(category),
                description = VALUES(description),
                location = VALUES(location),
                number = VALUES(number),
                icon = VALUES(icon),
                icon_color = VALUES(icon_color),
                auto_status = VALUES(auto_status),
                pos_x = VALUES(pos_x),
                pos_y = VALUES(pos_y),
                pos_z = VALUES(pos_z)
        ]], {
            company.id or id,
            company.label,
            company.job,
            company.category or 'service',
            company.description or '',
            company.location or '',
            company.number,
            company.icon or string.sub(company.label, 1, 3):upper(),
            company.iconColor or '#0D9488',
            company.autoStatus and 1 or 0,
            coords.x, coords.y, coords.z,
        })
    end
end

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
        location = data.location or '',
        number = tostring(data.number or ''),
        icon = data.icon,
        iconColor = data.iconColor,
        canCall = data.canCall ~= false,
        blip = data.blip,
        coords = data.coords,
        autoStatus = data.autoStatus ~= false,
    }
    Pulse.Companies.SyncFromConfig()
    return true
end

function Pulse.Companies.Get(companyId)
    return Config.Companies[companyId]
end

function Pulse.Companies.FindByJob(jobName)
    for id, company in pairs(Config.Companies) do
        if company.job == jobName then
            return id, company
        end
    end
    return nil, nil
end

function Pulse.Companies.GetPublicList()
    local list = {}
    for id, company in pairs(Config.Companies) do
        local online = countOnDuty(company.job)
        local status = company.autoStatus and computeAutoStatus(online) or 'closed'
        local row = MySQL.single.await(
            'SELECT logo, icon, icon_color, status, auto_status, location, pos_x, pos_y, pos_z FROM phone_companies WHERE id = ?',
            { id }
        )
        if row and row.auto_status == 0 then
            status = row.status
        elseif row then
            MySQL.update.await('UPDATE phone_companies SET status = ? WHERE id = ?', { status, id })
        end

        local coords = company.coords
        if row and row.pos_x then
            coords = { x = row.pos_x, y = row.pos_y, z = row.pos_z }
        end

        list[#list + 1] = {
            id = id,
            label = company.label,
            description = company.description,
            location = company.location or (row and row.location) or '',
            number = company.number,
            category = company.category,
            status = status,
            employeesOnline = online,
            logo = row and row.logo or nil,
            icon = company.icon or (row and row.icon) or 'CO',
            iconColor = company.iconColor or (row and row.icon_color) or '#0D9488',
            canCall = company.canCall ~= false,
            position = coords,
        }
    end
    table.sort(list, function(a, b) return a.label < b.label end)
    return list
end

---@param source number
---@return table|nil
function Pulse.Companies.GetPlayerCompanyContext(source)
    local player = Pulse.Server.GetPlayer(source)
    if not player then return nil end
    local job = player.PlayerData.job
    if not job then return nil end
    local companyId, company = Pulse.Companies.FindByJob(job.name)
    if not company then return nil end
    local grade = job.grade and job.grade.level or 0
    return {
        companyId = companyId,
        company = company,
        job = job,
        grade = grade,
        onDuty = job.onduty == true,
        isBoss = grade >= (company.manageGrade or 2) or job.isboss == true,
        isEmployee = true,
    }
end

---@param jobName string
---@return table[]
function Pulse.Companies.GetEmployees(jobName)
    local employees = {}
    local seen = {}

    local players = exports.qbx_core:GetQBPlayers()
    if players then
        for src, player in pairs(players) do
            local job = player.PlayerData.job
            if job and job.name == jobName then
                local cid = player.PlayerData.citizenid
                seen[cid] = true
                local charinfo = player.PlayerData.charinfo or {}
                employees[#employees + 1] = {
                    citizenid = cid,
                    name = (('%s %s'):format(charinfo.firstname or '', charinfo.lastname or '')):gsub('%s+$', ''),
                    grade = job.grade and job.grade.level or 0,
                    gradeLabel = job.grade and job.grade.name or tostring(job.grade and job.grade.level or 0),
                    onDuty = job.onduty == true,
                    online = true,
                    source = src,
                }
            end
        end
    end

    -- Employés hors ligne (table players Qbox)
    local rows = MySQL.query.await([[
        SELECT citizenid, charinfo, job
        FROM players
        WHERE JSON_UNQUOTE(JSON_EXTRACT(job, '$.name')) = ?
        LIMIT 80
    ]], { jobName }) or {}

    for _, row in ipairs(rows) do
        if not seen[row.citizenid] then
            local charinfo = type(row.charinfo) == 'string' and json.decode(row.charinfo) or row.charinfo or {}
            local job = type(row.job) == 'string' and json.decode(row.job) or row.job or {}
            local grade = job.grade and (job.grade.level or job.grade) or 0
            if type(grade) == 'table' then grade = grade.level or 0 end
            employees[#employees + 1] = {
                citizenid = row.citizenid,
                name = (('%s %s'):format(charinfo.firstname or 'Inconnu', charinfo.lastname or '')):gsub('%s+$', ''),
                grade = tonumber(grade) or 0,
                gradeLabel = (job.grade and job.grade.name) or tostring(grade),
                onDuty = false,
                online = false,
            }
        end
    end

    table.sort(employees, function(a, b)
        if a.grade ~= b.grade then return a.grade > b.grade end
        return a.name < b.name
    end)
    return employees
end

lib.callback.register('pulse-phone:server:getCompanies', function(_source)
    return Pulse.Companies.GetPublicList()
end)

lib.callback.register('pulse-phone:server:getCompany', function(_source, companyId)
    if type(companyId) ~= 'string' then return nil end
    for _, c in ipairs(Pulse.Companies.GetPublicList()) do
        if c.id == companyId then return c end
    end
    return nil
end)

lib.callback.register('pulse-phone:server:getServicesBootstrap', function(source)
    local ctx = Pulse.Companies.GetPlayerCompanyContext(source)
    return {
        companies = Pulse.Companies.GetPublicList(),
        me = ctx and {
            companyId = ctx.companyId,
            label = ctx.company.label,
            grade = ctx.grade,
            gradeLabel = ctx.job.grade and ctx.job.grade.name or tostring(ctx.grade),
            onDuty = ctx.onDuty,
            isBoss = ctx.isBoss,
            isEmployee = true,
        } or { isEmployee = false, isBoss = false, onDuty = false },
    }
end)

lib.callback.register('pulse-phone:server:toggleDuty', function(source)
    local now = os.time()
    if dutyCooldown[source] and now - dutyCooldown[source] < ((Config.Cooldowns.toggleDuty or 1500) / 1000) then
        return { ok = false, error = 'cooldown' }
    end
    dutyCooldown[source] = now

    local player = Pulse.Server.GetPlayer(source)
    if not player then return { ok = false } end
    local job = player.PlayerData.job
    if not job then return { ok = false } end

    local companyId, company = Pulse.Companies.FindByJob(job.name)
    if not company then return { ok = false, error = 'no_company' } end

    local newDuty = not job.onduty
    local ok = pcall(function()
        player.Functions.SetJobDuty(newDuty)
    end)
    if not ok then
        -- fallback qbx export
        pcall(function()
            exports.qbx_core:SetJobDuty(source, newDuty)
        end)
    end

    local citizenid = player.PlayerData.citizenid
    MySQL.query.await([[
        INSERT INTO phone_company_employees (company_id, citizenid, grade, on_duty, last_seen)
        VALUES (?, ?, ?, ?, NOW())
        ON DUPLICATE KEY UPDATE on_duty = VALUES(on_duty), grade = VALUES(grade), last_seen = NOW()
    ]], { companyId, citizenid, job.grade and job.grade.level or 0, newDuty and 1 or 0 })

    TriggerClientEvent('pulse-phone:client:notify', source, {
        type = 'service',
        title = company.label,
        body = newDuty and L('duty_on') or L('duty_off'),
        sound = 'notification',
    })

    return { ok = true, onDuty = newDuty }
end)

lib.callback.register('pulse-phone:server:getCompanyManagement', function(source)
    local ctx = Pulse.Companies.GetPlayerCompanyContext(source)
    if not ctx or not ctx.isEmployee then
        return { ok = false, error = 'forbidden' }
    end

    local balance = nil
    local employees = nil
    if ctx.isBoss then
        balance = Pulse.Companies.GetBalance(ctx.company.job)
        employees = Pulse.Companies.GetEmployees(ctx.company.job)
    else
        -- employé non-patron : liste réduite (online only) sans solde
        employees = {}
        for _, emp in ipairs(Pulse.Companies.GetEmployees(ctx.company.job)) do
            if emp.online then
                employees[#employees + 1] = {
                    name = emp.name,
                    grade = emp.grade,
                    gradeLabel = emp.gradeLabel,
                    onDuty = emp.onDuty,
                    online = true,
                }
            end
        end
    end

    local row = MySQL.single.await('SELECT status FROM phone_companies WHERE id = ?', { ctx.companyId })

    return {
        ok = true,
        companyId = ctx.companyId,
        label = ctx.company.label,
        isBoss = ctx.isBoss,
        onDuty = ctx.onDuty,
        grade = ctx.grade,
        gradeLabel = ctx.job.grade and ctx.job.grade.name or tostring(ctx.grade),
        balance = balance,
        status = row and row.status or 'closed',
        employees = employees or {},
        pendingRequests = MySQL.scalar.await(
            'SELECT COUNT(*) FROM phone_service_requests WHERE company_id = ? AND status = ?',
            { ctx.companyId, 'pending' }
        ) or 0,
    }
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
