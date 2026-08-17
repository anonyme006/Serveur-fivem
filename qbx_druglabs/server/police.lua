Police = {}

local function countPolice()
    local count = 0
    for _, playerId in pairs(GetPlayers()) do
        local src = tonumber(playerId)
        if src and Bridge.IsPolice(src) then
            count += 1
        end
    end
    return count
end

function Police.CanAct(source, minGrade)
    if Bridge.IsAdmin(source) then return true end
    if not Bridge.IsPolice(source) then return false, 'not_police' end
    local _, grade = Bridge.GetJob(source)
    minGrade = minGrade or 0
    if grade < minGrade then return false, 'grade' end
    if Config.Police.minimumPolice > 0 and countPolice() < Config.Police.minimumPolice then
        return false, 'not_enough_police'
    end
    return true
end

function Police.Seal(source, labId)
    if not DrugLabs.IsValidId(labId) then return false, 'invalid_lab' end
    local ok, reason = Police.CanAct(source, Config.Police.minimumGradeToSeal)
    if not ok then return false, reason end

    local lab = Repository.Get(labId)
    if not lab then return false, 'invalid_lab' end

    Repository.UpdateLabFields(labId, { sealed = true, locked = true })
    local updated = Repository.Get(labId)
    TriggerClientEvent(DrugLabs.Events.client.refreshLab, -1, Repository.SerializeLabPublic(updated, false))

    -- Kick occupants
    for _, playerId in pairs(GetPlayers()) do
        local src = tonumber(playerId)
        if src and Buckets.GetPlayerLab(src) == labId and not Bridge.IsPolice(src) then
            Buckets.ForceLeave(src, 'sealed')
        end
    end

    LogAction('lab_sealed', { labId = labId, actor = Bridge.GetCitizenId(source) })
    return true
end

function Police.Unseal(source, labId)
    if not DrugLabs.IsValidId(labId) then return false, 'invalid_lab' end
    local ok, reason = Police.CanAct(source, Config.Police.minimumGradeToSeal)
    if not ok then return false, reason end

    Repository.UpdateLabFields(labId, { sealed = false })
    TriggerClientEvent(DrugLabs.Events.client.refreshLab, -1, Repository.SerializeLabPublic(Repository.Get(labId), false))
    LogAction('lab_unsealed', { labId = labId, actor = Bridge.GetCitizenId(source) })
    return true
end

function Police.Raid(source, labId)
    if not DrugLabs.IsValidId(labId) then return false, 'invalid_lab' end
    local ok, reason = Police.CanAct(source, Config.Police.minimumGradeToRaid)
    if not ok then return false, reason end

    local lab = Repository.Get(labId)
    if not lab then return false, 'invalid_lab' end

    -- Grant temporary unlock for raiding officers
    local citizenid = Bridge.GetCitizenId(source)
    Access.GrantUnlockSession(labId, citizenid, 600)

    Bridge.SendPoliceAlert({
        title = 'Lab Raid in Progress',
        message = ('Officers are raiding %s'):format(lab.label),
        coords = lab.entrance,
        code = '10-31',
        priority = 1,
    })

    LogAction('lab_raid', { labId = labId, actor = citizenid })
    return true, { lab = Repository.SerializeLabPublic(lab, false) }
end

function Police.ForceEnter(source, labId)
    local ok, data = Police.Raid(source, labId)
    if not ok then return false, data end
    return Buckets.Enter(source, labId) or true, data
end
