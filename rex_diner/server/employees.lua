---@param source number
---@return boolean
---@return string|table
function RexDiner.ToggleService(source)
    local ok, err, ctx = RexDiner.Authorize(source, 'service', false)
    if not ok then return false, err end

    local player = RexDiner.GetPlayer(source)
    if not player then return false, 'Joueur invalide.' end

    local active = RexDiner.ServiceCache[source]
    if active then
        local duration = math.max(0, os.time() - (active.startedAt or os.time()))
        MySQL.update.await([[
            UPDATE rex_diner_service
            SET ended_at = CURRENT_TIMESTAMP, duration_seconds = ?
            WHERE identifier = ? AND restaurant = ? AND ended_at IS NULL
        ]], { duration, ctx.citizenid, ctx.restaurantKey })

        MySQL.update.await([[
            UPDATE rex_diner_employees
            SET total_service_seconds = total_service_seconds + ?
            WHERE restaurant = ? AND identifier = ?
        ]], { duration, ctx.restaurantKey, ctx.citizenid })

        RexDiner.ServiceCache[source] = nil
        player.Functions.SetJobDuty(false)
        RexDiner.Notify(source, 'Service', 'Vous êtes hors service.', 'inform')
        return true, { onDuty = false, duration = duration }
    end

    RexDiner.EnsureEmployeeRow(ctx.restaurantKey, ctx.citizenid, ctx.name, ctx.grade)
    MySQL.insert.await([[
        INSERT INTO rex_diner_service (restaurant, identifier, name)
        VALUES (?, ?, ?)
    ]], { ctx.restaurantKey, ctx.citizenid, ctx.name })

    RexDiner.ServiceCache[source] = {
        restaurant = ctx.restaurantKey,
        startedAt = os.time(),
    }
    player.Functions.SetJobDuty(true)
    RexDiner.Notify(source, 'Service', 'Vous êtes en service.', 'success')
    return true, { onDuty = true }
end

---@param citizenid string
---@param restaurantKey string
---@return table
function RexDiner.GetServiceStats(citizenid, restaurantKey)
    local today = MySQL.single.await([[
        SELECT COALESCE(SUM(duration_seconds),0) AS total
        FROM rex_diner_service
        WHERE restaurant = ? AND identifier = ? AND DATE(started_at) = CURDATE()
    ]], { restaurantKey, citizenid })

    local week = MySQL.single.await([[
        SELECT COALESCE(SUM(duration_seconds),0) AS total
        FROM rex_diner_service
        WHERE restaurant = ? AND identifier = ? AND started_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
    ]], { restaurantKey, citizenid })

    local active = MySQL.single.await([[
        SELECT started_at FROM rex_diner_service
        WHERE restaurant = ? AND identifier = ? AND ended_at IS NULL
        ORDER BY started_at DESC LIMIT 1
    ]], { restaurantKey, citizenid })

    local todaySec = tonumber(today and today.total) or 0
    local weekSec = tonumber(week and week.total) or 0

    if active and active.started_at then
        -- add live session approximate seconds from MySQL timestamp is awkward; use cache if present
        for src, cache in pairs(RexDiner.ServiceCache) do
            if cache.restaurant == restaurantKey then
                local cid = RexDiner.GetCitizenId(src)
                if cid == citizenid then
                    local live = os.time() - (cache.startedAt or os.time())
                    todaySec = todaySec + live
                    weekSec = weekSec + live
                    break
                end
            end
        end
    end

    return {
        today = todaySec,
        week = weekSec,
        onDuty = active ~= nil,
    }
end

---@param restaurantKey string
---@return table[]
function RexDiner.GetEmployees(restaurantKey)
    local rows = MySQL.query.await([[
        SELECT * FROM rex_diner_employees WHERE restaurant = ? ORDER BY grade DESC, name ASC
    ]], { restaurantKey }) or {}

    local online = {}
    local restaurant = GetRestaurant(restaurantKey)
    for src, player in pairs(RexDiner.GetOnlinePlayers()) do
        if player and player.PlayerData then
            local job = player.PlayerData.job
            if job and restaurant and job.name == restaurant.job then
                online[player.PlayerData.citizenid] = {
                    source = src,
                    onDuty = job.onduty == true or RexDiner.ServiceCache[src] ~= nil,
                    grade = job.grade and job.grade.level or 0,
                    name = RexDiner.GetCharName(src),
                }
            end
        end
    end

    local list = {}
    local seen = {}
    for i = 1, #rows do
        local row = rows[i]
        local live = online[row.identifier]
        seen[row.identifier] = true
        list[#list + 1] = {
            identifier = row.identifier,
            name = (live and live.name) or row.name,
            grade = live and live.grade or row.grade,
            gradeLabel = GetGradeLabel(live and live.grade or row.grade),
            commission = math.floor((GetCommissionRate(live and live.grade or row.grade) or 0) * 100),
            online = live ~= nil,
            onDuty = live and live.onDuty or false,
            totalSales = tonumber(row.total_sales) or 0,
            totalCommission = tonumber(row.total_commission) or 0,
            serviceSeconds = tonumber(row.total_service_seconds) or 0,
        }
    end

    for cid, live in pairs(online) do
        if not seen[cid] then
            list[#list + 1] = {
                identifier = cid,
                name = live.name,
                grade = live.grade,
                gradeLabel = GetGradeLabel(live.grade),
                commission = math.floor((GetCommissionRate(live.grade) or 0) * 100),
                online = true,
                onDuty = live.onDuty,
                totalSales = 0,
                totalCommission = 0,
                serviceSeconds = 0,
            }
        end
    end

    return list
end

---@param source number
---@param targetId number
---@param grade number
---@return boolean
---@return string
function RexDiner.HireEmployee(source, targetId, grade)
    if not Config.EnableEmployeeManagement then
        return false, 'Gestion employés désactivée.'
    end
    if not RexDiner.CheckCooldown(source, 'hire') then
        return false, 'Patientez.'
    end

    local ok, err, ctx = RexDiner.Authorize(source, 'employees')
    if not ok then return false, err end

    targetId = tonumber(targetId)
    grade = math.floor(tonumber(grade) or 0)
    if grade < 0 then grade = 0 end
    if grade > 3 and ctx.grade < 4 then
        return false, 'Vous ne pouvez pas recruter à ce grade.'
    end
    if grade >= ctx.grade and ctx.grade < 4 then
        return false, 'Impossible de recruter à un grade supérieur ou égal.'
    end
    if not targetId or not GetPlayerPed(targetId) then
        return false, 'Cible invalide.'
    end

    local target = RexDiner.GetPlayer(targetId)
    if not target then return false, 'Joueur introuvable.' end

    local restaurant = ctx.restaurant
    target.Functions.SetJob(restaurant.job, grade)

    local targetCid = RexDiner.GetCitizenId(targetId)
    local targetName = RexDiner.GetCharName(targetId)
    RexDiner.EnsureEmployeeRow(ctx.restaurantKey, targetCid, targetName, grade)

    RexDiner.Notify(source, 'Employés', ('%s recruté(e) (%s).'):format(targetName, GetGradeLabel(grade)), 'success')
    RexDiner.Notify(targetId, 'Emploi', ('Vous avez été recruté(e) chez %s.'):format(restaurant.label), 'success')
    return true, 'Employé recruté.'
end

---@param source number
---@param targetCitizenId string
---@return boolean
---@return string
function RexDiner.FireEmployee(source, targetCitizenId)
    if not Config.EnableEmployeeManagement then
        return false, 'Gestion employés désactivée.'
    end

    local ok, err, ctx = RexDiner.Authorize(source, 'employees')
    if not ok then return false, err end

    if type(targetCitizenId) ~= 'string' or targetCitizenId == '' then
        return false, 'Identifiant invalide.'
    end
    if targetCitizenId == ctx.citizenid then
        return false, 'Vous ne pouvez pas vous licencier.'
    end

    local emp = MySQL.single.await(
        'SELECT * FROM rex_diner_employees WHERE restaurant = ? AND identifier = ? LIMIT 1',
        { ctx.restaurantKey, targetCitizenId }
    )

    local targetPlayer = exports.qbx_core:GetPlayerByCitizenId(targetCitizenId)
    local targetGrade = emp and tonumber(emp.grade) or 0
    if targetPlayer and targetPlayer.PlayerData and targetPlayer.PlayerData.job then
        targetGrade = targetPlayer.PlayerData.job.grade and targetPlayer.PlayerData.job.grade.level or targetGrade
    end

    if targetGrade >= ctx.grade and ctx.grade < 4 then
        return false, 'Impossible de licencier ce grade.'
    end

    if targetPlayer then
        targetPlayer.Functions.SetJob('unemployed', 0)
        RexDiner.Notify(targetPlayer.PlayerData.source, 'Emploi', 'Vous avez été licencié(e).', 'error')
    end

    MySQL.query.await(
        'DELETE FROM rex_diner_employees WHERE restaurant = ? AND identifier = ?',
        { ctx.restaurantKey, targetCitizenId }
    )

    RexDiner.Notify(source, 'Employés', 'Employé licencié.', 'inform')
    return true, 'Licenciement effectué.'
end

---@param source number
---@param targetCitizenId string
---@param newGrade number
---@return boolean
---@return string
function RexDiner.SetEmployeeGrade(source, targetCitizenId, newGrade)
    if not RexDiner.CheckCooldown(source, 'grade') then
        return false, 'Patientez.'
    end

    local ok, err, ctx = RexDiner.Authorize(source, 'employees')
    if not ok then return false, err end

    newGrade = math.floor(tonumber(newGrade) or 0)
    if newGrade < 0 or newGrade > 4 then
        return false, 'Grade invalide.'
    end
    if type(targetCitizenId) ~= 'string' then
        return false, 'Identifiant invalide.'
    end
    if targetCitizenId == ctx.citizenid then
        return false, 'Vous ne pouvez pas modifier votre propre grade.'
    end
    if newGrade >= ctx.grade and ctx.grade < 4 then
        return false, 'Grade cible trop élevé.'
    end

    local targetPlayer = exports.qbx_core:GetPlayerByCitizenId(targetCitizenId)
    if targetPlayer then
        local currentGrade = targetPlayer.PlayerData.job.grade and targetPlayer.PlayerData.job.grade.level or 0
        if currentGrade >= ctx.grade and ctx.grade < 4 then
            return false, 'Impossible de modifier ce grade.'
        end
        targetPlayer.Functions.SetJob(ctx.restaurant.job, newGrade)
        RexDiner.Notify(targetPlayer.PlayerData.source, 'Grade',
            ('Nouveau grade : %s'):format(GetGradeLabel(newGrade)), 'inform')
    end

    local name = targetPlayer and RexDiner.GetCharName(targetPlayer.PlayerData.source) or targetCitizenId
    RexDiner.EnsureEmployeeRow(ctx.restaurantKey, targetCitizenId, name, newGrade)
    return true, 'Grade mis à jour.'
end
