--- Callbacks serveur — étapes suivantes

lib.callback.register('qbx-mechanic:server:getConfig', function(source)
    if not Framework.HasMechanicJob(source) then
        return nil
    end

    return {
        resource = Config.ResourceName,
        version = GetResourceMetadata(GetCurrentResourceName(), 'version', 0),
        job = Config.Job,
        prices = Config.Prices,
        billing = Config.Billing,
    }
end)

lib.callback.register('qbx-mechanic:server:isMechanic', function(source, minGrade)
    return Framework.HasMechanicJob(source, nil, minGrade)
end)

lib.callback.register('qbx-mechanic:server:getPlayerMechanicContext', function(source)
    local job = Framework.GetJob(source)
    if not job then return nil end

    return {
        name = job.name,
        label = job.label,
        grade = job.grade and job.grade.level or 0,
        gradeLabel = job.grade and job.grade.name or '',
        onDuty = job.onduty ~= false,
        citizenid = Framework.GetCitizenId(source),
        playerName = Framework.GetPlayerName(source),
    }
end)
