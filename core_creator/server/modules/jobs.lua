local MODULE = 'jobs'

CoreCreator.RegisterModule(MODULE, {
    afterCreate = function(_, id, data)
        local grades = {}
        for _, g in ipairs((data.data and data.data.grades) or {}) do
            grades[tonumber(g.grade) or 0] = {
                name = g.name,
                label = g.label,
                salary = g.salary,
                skin_male = g.skin_male,
                skin_female = g.skin_female,
            }
        end
        Bridge.EnsureJob(data.name, data.label, grades)
    end,
    afterUpdate = function(_, _, data)
        local grades = {}
        for _, g in ipairs((data.data and data.data.grades) or {}) do
            grades[tonumber(g.grade) or 0] = {
                name = g.name,
                label = g.label,
                salary = g.salary,
            }
        end
        Bridge.EnsureJob(data.name, data.label, grades)
    end,
})

RegisterNetEvent('core_creator:jobs:setJob', function(targetId, jobName, grade)
    local src = source
    if not Permissions.Guard(src, MODULE) then return end
    targetId = tonumber(targetId)
    grade = tonumber(grade) or 0
    if not targetId or type(jobName) ~= 'string' then return end
    local job = Database.GetByName(MODULE, jobName)
    if not job or not job.active then
        Bridge.Notify(src, _('error.not_found'), 'error')
        return
    end
    if Bridge.SetPlayerJob(targetId, jobName, grade) then
        Bridge.Notify(src, 'Job attribué', 'success')
        Bridge.Notify(targetId, ('Nouveau job: %s (%s)'):format(job.label, grade), 'inform')
        Logger.Log(src, 'job_set', MODULE, job.id, { target = Bridge.GetIdentifier(targetId), grade = grade })
    end
end)

RegisterNetEvent('core_creator:jobs:requestSync', function()
    TriggerClientEvent('core_creator:jobs:sync', source, Database.GetAll(MODULE, true))
end)

AddEventHandler('core_creator:databaseReady', function()
    Wait(150)
    local jobs = Database.GetAll(MODULE, true)
    for i = 1, #jobs do
        local row = jobs[i]
        local grades = {}
        for _, g in ipairs((row.data and row.data.grades) or {}) do
            grades[tonumber(g.grade) or 0] = {
                name = g.name,
                label = g.label,
                salary = g.salary,
            }
        end
        Bridge.EnsureJob(row.name, row.label, grades)
    end
    TriggerClientEvent('core_creator:jobs:sync', -1, jobs)
end)

AddEventHandler('core_creator:entityChanged', function(moduleName)
    if moduleName ~= MODULE then return end
    TriggerClientEvent('core_creator:jobs:sync', -1, Database.GetAll(MODULE, true))
end)

exports('GetCreatedJobs', function()
    return Database.GetAll(MODULE, true)
end)
