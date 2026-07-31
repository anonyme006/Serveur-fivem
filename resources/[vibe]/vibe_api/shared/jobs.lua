VibeJobs = {}

function VibeJobs.IsPolice(jobName)
    return jobName and Config.PoliceJobs[jobName] == true
end

function VibeJobs.IsEms(jobName)
    return jobName and Config.EmsJobs[jobName] == true
end

function VibeJobs.IsMechanic(jobName)
    return jobName and Config.MechanicJobs[jobName] == true
end
