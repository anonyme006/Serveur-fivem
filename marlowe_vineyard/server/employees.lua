local QBX = exports.qbx_core

local function getEmployees()
    local employees = {}
    local players = QBX:GetQBPlayers()

    for _, player in pairs(players) do
        if player.PlayerData.job.name == Config.Job then
            employees[#employees + 1] = {
                source = player.PlayerData.source,
                citizenid = player.PlayerData.citizenid,
                name = ('%s %s'):format(
                    player.PlayerData.charinfo.firstname,
                    player.PlayerData.charinfo.lastname
                ),
                grade = player.PlayerData.job.grade.level,
                gradeName = player.PlayerData.job.grade.name,
                onDuty = player.PlayerData.job.onduty,
                online = true,
            }
        end
    end

    local offlineRows = MySQL.query.await([[
        SELECT citizenid, charinfo, job
        FROM players
        WHERE JSON_UNQUOTE(JSON_EXTRACT(job, '$.name')) = ?
    ]], { Config.Job }) or {}

    for i = 1, #offlineRows do
        local row = offlineRows[i]
        local alreadyListed = false

        for j = 1, #employees do
            if employees[j].citizenid == row.citizenid then
                alreadyListed = true
                break
            end
        end

        if not alreadyListed then
            local charinfo = json.decode(row.charinfo) or {}
            local job = json.decode(row.job) or {}
            employees[#employees + 1] = {
                source = nil,
                citizenid = row.citizenid,
                name = ('%s %s'):format(charinfo.firstname or 'Inconnu', charinfo.lastname or ''),
                grade = job.grade and job.grade.level or 0,
                gradeName = job.grade and job.grade.name or 'Employé',
                onDuty = false,
                online = false,
            }
        end
    end

    table.sort(employees, function(a, b)
        if a.grade == b.grade then
            return a.name < b.name
        end
        return a.grade > b.grade
    end)

    return employees
end

lib.callback.register('marlowe:server:getEmployees', function(source)
    local player, err = Marlowe.ValidatePlayer(source, Config.Permissions.Employees, false)
    if not player then return nil, err end
    return getEmployees()
end)

lib.callback.register('marlowe:server:recruitPlayer', function(source, targetId)
    local player, err = Marlowe.ValidatePlayer(source, Config.Permissions.Employees, false)
    if not player then return false, err end

    local target = QBX:GetPlayer(targetId)
    if not target then return false, 'Joueur introuvable.' end

    local bossCoords = Marlowe.GetPlayerCoords(source)
    local targetCoords = Marlowe.GetPlayerCoords(targetId)
    if not bossCoords or not targetCoords or #(bossCoords - targetCoords) > 5.0 then
        return false, Config.Notifications.TooFar
    end

    local success = exports.qbx_core:AddPlayerToJob(target.PlayerData.citizenid, Config.Job, Config.Grades.Stagiaire)
    if not success then
        return false, 'Recrutement impossible.'
    end

    exports.qbx_core:SetJob(targetId, Config.Job, Config.Grades.Stagiaire)
    return true
end)

lib.callback.register('marlowe:server:manageEmployee', function(source, citizenid, action)
    local player, err = Marlowe.ValidatePlayer(source, Config.Permissions.Employees, false)
    if not player then return false, err end

    if player.PlayerData.citizenid == citizenid then
        return false, 'Vous ne pouvez pas vous gérer vous-même.'
    end

    local target = QBX:GetPlayerByCitizenId(citizenid)
    local currentGrade

    if target then
        if target.PlayerData.job.name ~= Config.Job then
            return false, 'Cet employé ne fait pas partie du domaine.'
        end
        currentGrade = target.PlayerData.job.grade.level
    else
        local row = MySQL.single.await('SELECT job FROM players WHERE citizenid = ?', { citizenid })
        if not row then return false, 'Employé introuvable.' end
        local job = json.decode(row.job) or {}
        if job.name ~= Config.Job then return false, 'Cet employé ne fait pas partie du domaine.' end
        currentGrade = job.grade and job.grade.level or 0
    end

    if currentGrade >= player.PlayerData.job.grade.level then
        return false, 'Vous ne pouvez pas gérer un grade égal ou supérieur au vôtre.'
    end

    if action == 'fire' then
        if target then
            exports.qbx_core:RemovePlayerFromJob(target.PlayerData.source, Config.Job)
            exports.qbx_core:SetJob(target.PlayerData.source, 'unemployed', 0)
        else
            MySQL.update.await([[
                UPDATE players
                SET job = JSON_SET(job, '$.name', 'unemployed', '$.grade.level', 0, '$.grade.name', 'Chômeur')
                WHERE citizenid = ?
            ]], { citizenid })
        end
        return true
    end

    local newGrade = currentGrade
    if action == 'promote' then
        newGrade = math.min(currentGrade + 1, Config.Grades.Directeur)
    elseif action == 'demote' then
        newGrade = math.max(currentGrade - 1, Config.Grades.Stagiaire)
    else
        return false, 'Action invalide.'
    end

    if target then
        exports.qbx_core:SetJob(target.PlayerData.source, Config.Job, newGrade)
    else
        local jobs = exports.qbx_core:GetJobs()
        local jobData = jobs[Config.Job]
        local gradeName = jobData and jobData.grades[tostring(newGrade)] and jobData.grades[tostring(newGrade)].name or 'Employé'
        MySQL.update.await([[
            UPDATE players
            SET job = JSON_SET(job, '$.grade.level', ?, '$.grade.name', ?)
            WHERE citizenid = ?
        ]], { newGrade, gradeName, citizenid })
    end

    return true, newGrade
end)
