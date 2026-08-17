Stash = {}

function Stash.Ensure(lab)
    if not lab then return end
    local data = lab.stash_data or {}
    Bridge.RegisterStash(lab.id, data.slots or 50, data.weight or 200000, lab.label)
end

function Stash.EnsureAll()
    for _, lab in pairs(Repository.GetAll()) do
        Stash.Ensure(lab)
    end
end

function Stash.Open(source, labId)
    if not DrugLabs.IsValidId(labId) then return false, 'invalid_lab' end
    local lab = Repository.Get(labId)
    if not lab then return false, 'invalid_lab' end

    if lab.sealed and not Bridge.IsPolice(source) and not Bridge.IsAdmin(source) then
        return false, 'sealed'
    end

    local inLab = Buckets.GetPlayerLab(source) == labId
    if not inLab and not Bridge.IsAdmin(source) then
        return false, 'not_inside'
    end

    if Bridge.IsPolice(source) and lab.sealed then
        Stash.Ensure(lab)
        Bridge.OpenStash(source, labId)
        LogAction('police_stash', { labId = labId, actor = Bridge.GetCitizenId(source) })
        return true
    end

    if not Access.Can(source, lab, DrugLabs.Permissions.USE_STASH) then
        return false, 'no_permission'
    end

    Stash.Ensure(lab)
    Bridge.OpenStash(source, labId)
    return true
end
