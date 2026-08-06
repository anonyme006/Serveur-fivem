--[[
    Boss / employee management — core_wholesaler
]]

Boss = {}

--- Vérifie droit boss
---@param player table
---@return boolean
function Boss.IsBoss(player)
    local job = player.PlayerData.job
    if job.name ~= Config.Job.name then return false end
    local grade = job.grade and job.grade.level or 0
    if grade >= Config.Permissions.bossMenu then return true end
    -- Check grade config boss flag
    local gcfg = Config.Job.grades[grade]
    return gcfg and gcfg.boss == true
end

--- CA / bénéfices
---@return table
function Boss.GetFinance()
    local revenue = MySQL.scalar.await([[
        SELECT COALESCE(SUM(total), 0) FROM wholesaler_orders
        WHERE status IN ('withdrawn', 'delivered', 'available', 'prepared', 'pending')
    ]]) or 0

    local exportRevenue = MySQL.scalar.await([[
        SELECT COALESCE(SUM(reward), 0) FROM wholesaler_exports WHERE status = 'completed'
    ]]) or 0

    local deliveryCosts = MySQL.scalar.await([[
        SELECT COALESCE(SUM(delivery_reward), 0) FROM wholesaler_orders WHERE status = 'delivered'
    ]]) or 0

    local totalRevenue = revenue + exportRevenue
    local profit = totalRevenue - deliveryCosts

    return {
        revenue = totalRevenue,
        profit = profit,
        orderRevenue = revenue,
        exportRevenue = exportRevenue,
        deliveryCosts = deliveryCosts,
    }
end

--- Entreprises clientes
---@return table[]
function Boss.GetCompanies()
    return MySQL.query.await(
        'SELECT * FROM wholesaler_companies ORDER BY total_spent DESC'
    ) or {}
end

--- Employés enregistrés
---@return table[]
function Boss.GetEmployees()
    return MySQL.query.await(
        'SELECT * FROM wholesaler_employees WHERE active = 1 ORDER BY grade DESC, name ASC'
    ) or {}
end

--- Recruter un joueur proche
---@param source number
---@param targetId number
---@param grade integer|nil
---@return boolean, string|nil
function Boss.Hire(source, targetId, grade)
    local boss = Payment.GetPlayer(source)
    local target = Payment.GetPlayer(targetId)
    if not boss or not target then return false, 'error' end
    if not Boss.IsBoss(boss) then return false, 'no_permission' end

    grade = math.floor(tonumber(grade) or 0)
    if not Config.Job.grades[grade] then grade = 0 end

    target.Functions.SetJob(Config.Job.name, grade)

    local name = Payment.GetName(target)
    MySQL.insert.await([[
        INSERT INTO wholesaler_employees (citizenid, name, grade, hired_by, active)
        VALUES (?, ?, ?, ?, 1)
        ON DUPLICATE KEY UPDATE name = VALUES(name), grade = VALUES(grade), hired_by = VALUES(hired_by), active = 1, hired_at = NOW()
    ]], {
        target.PlayerData.citizenid,
        name,
        grade,
        boss.PlayerData.citizenid,
    })

    DB.LogHistory({
        citizenid = boss.PlayerData.citizenid,
        company = Config.Job.name,
        action = 'employee_hired',
        details = { target = target.PlayerData.citizenid, grade = grade },
    })

    return true
end

--- Licencier
---@param source number
---@param citizenid string
---@return boolean, string|nil
function Boss.Fire(source, citizenid)
    local boss = Payment.GetPlayer(source)
    if not boss then return false, 'error' end
    if not Boss.IsBoss(boss) then return false, 'no_permission' end
    if citizenid == boss.PlayerData.citizenid then return false, 'error' end

    MySQL.update.await(
        'UPDATE wholesaler_employees SET active = 0 WHERE citizenid = ?',
        { citizenid }
    )

    -- Si en ligne, retire le job
    local targetSrc = Orders.GetSourceByCitizenId(citizenid)
    if targetSrc then
        local target = Payment.GetPlayer(targetSrc)
        if target and target.PlayerData.job.name == Config.Job.name then
            target.Functions.SetJob('unemployed', 0)
        end
    end

    DB.LogHistory({
        citizenid = boss.PlayerData.citizenid,
        company = Config.Job.name,
        action = 'employee_fired',
        details = { target = citizenid },
    })

    return true
end

--- Modifier le grade d'un employé
---@param source number
---@param citizenid string
---@param grade integer
---@return boolean, string|nil
function Boss.SetGrade(source, citizenid, grade)
    local boss = Payment.GetPlayer(source)
    if not boss then return false, 'error' end
    if not Boss.IsBoss(boss) then return false, 'no_permission' end

    grade = math.floor(tonumber(grade) or 0)
    if not Config.Job.grades[grade] then return false, 'error' end

    MySQL.update.await(
        'UPDATE wholesaler_employees SET grade = ? WHERE citizenid = ? AND active = 1',
        { grade, citizenid }
    )

    local targetSrc = Orders.GetSourceByCitizenId(citizenid)
    if targetSrc then
        local target = Payment.GetPlayer(targetSrc)
        if target and target.PlayerData.job.name == Config.Job.name then
            target.Functions.SetJob(Config.Job.name, grade)
        end
    end

    return true
end
