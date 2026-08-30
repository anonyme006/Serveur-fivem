function Rest.ToggleService(source)
    local ok, err, ctx = Rest.Authorize(source, 'service', false)
    if not ok then return false, err end
    local player = Rest.GetPlayer(source)
    if not player then return false, 'Joueur invalide.' end

    if Rest.Service[source] then
        local duration = math.max(0, os.time() - (Rest.Service[source].startedAt or os.time()))
        MySQL.update.await([[
            UPDATE qbox_restaurants_service SET ended_at = CURRENT_TIMESTAMP, duration_seconds = ?
            WHERE identifier = ? AND restaurant = ? AND ended_at IS NULL
        ]], { duration, ctx.citizenid, ctx.key })
        MySQL.update.await([[
            UPDATE qbox_restaurants_employees SET total_service_seconds = total_service_seconds + ?
            WHERE restaurant = ? AND identifier = ?
        ]], { duration, ctx.key, ctx.citizenid })
        Rest.Service[source] = nil
        player.Functions.SetJobDuty(false)
        Rest.Notify(source, 'Service', 'Vous êtes hors service.', 'inform')
        return true, { onDuty = false, duration = duration }
    end

    Rest.EnsureEmployee(ctx.key, ctx.citizenid, ctx.name, ctx.grade)
    MySQL.insert.await(
        'INSERT INTO qbox_restaurants_service (restaurant, identifier, name) VALUES (?, ?, ?)',
        { ctx.key, ctx.citizenid, ctx.name }
    )
    Rest.Service[source] = { restaurant = ctx.key, startedAt = os.time() }
    player.Functions.SetJobDuty(true)
    Rest.Notify(source, 'Service', 'Vous êtes en service.', 'success')
    return true, { onDuty = true }
end

function Rest.GetServiceStats(citizenid, restaurantKey)
    local today = MySQL.single.await([[
        SELECT COALESCE(SUM(duration_seconds),0) AS total FROM qbox_restaurants_service
        WHERE restaurant = ? AND identifier = ? AND DATE(started_at) = CURDATE()
    ]], { restaurantKey, citizenid })
    local week = MySQL.single.await([[
        SELECT COALESCE(SUM(duration_seconds),0) AS total FROM qbox_restaurants_service
        WHERE restaurant = ? AND identifier = ? AND started_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
    ]], { restaurantKey, citizenid })
    local active = MySQL.single.await([[
        SELECT id FROM qbox_restaurants_service
        WHERE restaurant = ? AND identifier = ? AND ended_at IS NULL LIMIT 1
    ]], { restaurantKey, citizenid })

    local todaySec = tonumber(today and today.total) or 0
    local weekSec = tonumber(week and week.total) or 0
    for src, cache in pairs(Rest.Service) do
        if cache.restaurant == restaurantKey and Rest.GetCitizenId(src) == citizenid then
            local live = os.time() - (cache.startedAt or os.time())
            todaySec = todaySec + live
            weekSec = weekSec + live
            break
        end
    end
    return { today = todaySec, week = weekSec, onDuty = active ~= nil }
end

function Rest.GetEmployees(restaurantKey)
    local rows = MySQL.query.await(
        'SELECT * FROM qbox_restaurants_employees WHERE restaurant = ? ORDER BY grade DESC, name ASC',
        { restaurantKey }
    ) or {}
    local restaurant = Rest.GetRestaurant(restaurantKey)
    local online = {}

    for src, player in pairs(Rest.GetOnlinePlayers()) do
        local job = player.PlayerData and player.PlayerData.job
        if job and restaurant and job.name == restaurant.job then
            online[player.PlayerData.citizenid] = {
                source = src,
                onDuty = job.onduty == true or Rest.Service[src] ~= nil,
                grade = job.grade and job.grade.level or 0,
                name = Rest.GetName(src),
            }
        end
    end

    local list, seen = {}, {}
    for i = 1, #rows do
        local row = rows[i]
        local live = online[row.identifier]
        seen[row.identifier] = true
        local grade = live and live.grade or row.grade
        list[#list + 1] = {
            identifier = row.identifier,
            name = (live and live.name) or row.name,
            grade = grade,
            gradeLabel = Rest.GetGradeLabel(grade),
            commission = math.floor((Rest.GetCommissionRate(grade) or 0) * 100),
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
                gradeLabel = Rest.GetGradeLabel(live.grade),
                commission = math.floor((Rest.GetCommissionRate(live.grade) or 0) * 100),
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

function Rest.HireEmployee(source, targetId, grade)
    if not Config.EnableEmployeeManagement then return false, 'Gestion désactivée.' end
    if not Rest.Cooldown(source, 'hire') then return false, 'Patientez.' end
    local ok, err, ctx = Rest.Authorize(source, 'employees')
    if not ok then return false, err end

    targetId = tonumber(targetId)
    grade = math.floor(tonumber(grade) or 0)
    if grade < 0 then grade = 0 end
    if grade >= ctx.grade and ctx.grade < 4 then return false, 'Grade trop élevé.' end
    if not targetId or GetPlayerPed(targetId) == 0 then return false, 'Cible invalide.' end

    local target = Rest.GetPlayer(targetId)
    if not target then return false, 'Joueur introuvable.' end
    target.Functions.SetJob(ctx.restaurant.job, grade)

    local cid = Rest.GetCitizenId(targetId)
    local name = Rest.GetName(targetId)
    Rest.EnsureEmployee(ctx.key, cid, name, grade)
    Rest.Notify(source, 'Employés', ('%s recruté (%s).'):format(name, Rest.GetGradeLabel(grade)), 'success')
    Rest.Notify(targetId, 'Emploi', ('Recruté chez %s.'):format(ctx.restaurant.label), 'success')
    return true, 'OK'
end

function Rest.FireEmployee(source, targetCitizenId)
    if not Config.EnableEmployeeManagement then return false, 'Gestion désactivée.' end
    local ok, err, ctx = Rest.Authorize(source, 'employees')
    if not ok then return false, err end
    if type(targetCitizenId) ~= 'string' or targetCitizenId == '' then return false, 'ID invalide.' end
    if targetCitizenId == ctx.citizenid then return false, 'Impossible.' end

    local emp = MySQL.single.await(
        'SELECT * FROM qbox_restaurants_employees WHERE restaurant = ? AND identifier = ? LIMIT 1',
        { ctx.key, targetCitizenId }
    )
    local targetPlayer = exports.qbx_core:GetPlayerByCitizenId(targetCitizenId)
    local targetGrade = emp and tonumber(emp.grade) or 0
    if targetPlayer and targetPlayer.PlayerData.job then
        targetGrade = targetPlayer.PlayerData.job.grade and targetPlayer.PlayerData.job.grade.level or targetGrade
    end
    if targetGrade >= ctx.grade and ctx.grade < 4 then return false, 'Grade trop élevé.' end

    if targetPlayer then
        targetPlayer.Functions.SetJob('unemployed', 0)
        Rest.Notify(targetPlayer.PlayerData.source, 'Emploi', 'Vous avez été licencié.', 'error')
    end
    MySQL.query.await(
        'DELETE FROM qbox_restaurants_employees WHERE restaurant = ? AND identifier = ?',
        { ctx.key, targetCitizenId }
    )
    Rest.Notify(source, 'Employés', 'Employé licencié.', 'inform')
    return true, 'OK'
end

function Rest.SetEmployeeGrade(source, targetCitizenId, newGrade)
    if not Rest.Cooldown(source, 'grade') then return false, 'Patientez.' end
    local ok, err, ctx = Rest.Authorize(source, 'employees')
    if not ok then return false, err end
    newGrade = math.floor(tonumber(newGrade) or 0)
    if newGrade < 0 or newGrade > 4 then return false, 'Grade invalide.' end
    if type(targetCitizenId) ~= 'string' then return false, 'ID invalide.' end
    if targetCitizenId == ctx.citizenid then return false, 'Impossible.' end
    if newGrade >= ctx.grade and ctx.grade < 4 then return false, 'Grade trop élevé.' end

    local targetPlayer = exports.qbx_core:GetPlayerByCitizenId(targetCitizenId)
    if targetPlayer then
        local current = targetPlayer.PlayerData.job.grade and targetPlayer.PlayerData.job.grade.level or 0
        if current >= ctx.grade and ctx.grade < 4 then return false, 'Impossible.' end
        targetPlayer.Functions.SetJob(ctx.restaurant.job, newGrade)
        Rest.Notify(targetPlayer.PlayerData.source, 'Grade',
            ('Nouveau grade : %s'):format(Rest.GetGradeLabel(newGrade)), 'inform')
    end
    local name = targetPlayer and Rest.GetName(targetPlayer.PlayerData.source) or targetCitizenId
    Rest.EnsureEmployee(ctx.key, targetCitizenId, name, newGrade)
    return true, 'OK'
end
