lib.callback.register('rr_vehicle_restrictions:server:canDrive', function(source, model, class)
    local job = exports.rr_api:GetJob(source)
    local modelName
    -- model is hash; check class first
    local classRule = Config.EmergencyClasses[class]
    if classRule then
        if not job or not classRule[job.name] or not job.onduty then return false end
    end
    for name, jobs in pairs(Config.Models) do
        if joaat(name) == model then
            if not job or not jobs[job.name] or not job.onduty then return false end
        end
    end
    return true
end)
