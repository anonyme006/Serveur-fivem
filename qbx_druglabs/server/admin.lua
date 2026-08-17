Admin = {}

local function requireAdmin(source)
    if not RateLimit.Check(source, 'admin') then return false, 'rate_limited' end
    if not Bridge.IsAdmin(source) then return false, 'no_permission' end
    return true
end

function Admin.List(source)
    local ok, err = requireAdmin(source)
    if not ok then return false, err end
    local labs = {}
    for _, lab in pairs(Repository.GetAll()) do
        labs[#labs + 1] = Repository.SerializeLabPublic(lab, true)
    end
    table.sort(labs, function(a, b) return a.id < b.id end)
    return true, labs
end

function Admin.Create(source, payload)
    local ok, err = requireAdmin(source)
    if not ok then return false, err end
    if type(payload) ~= 'table' then return false, 'invalid_payload' end

    local labType = payload.type
    if not Config.LabTypes[labType] then return false, 'invalid_type' end
    if not DrugLabs.IsNonEmptyString(payload.label) then return false, 'invalid_label' end
    if type(payload.entrance) ~= 'table' or not payload.entrance.x then return false, 'invalid_entrance' end
    if type(payload.interior) ~= 'table' then return false, 'invalid_interior' end

    local identifier = payload.identifier
    if not DrugLabs.IsNonEmptyString(identifier) then
        identifier = ('%s_%s'):format(labType, os.time())
    end
    identifier = identifier:lower():gsub('%W+', '_'):gsub('_+', '_'):gsub('^_|_$', '')

    if Repository.GetByIdentifier(identifier) then
        return false, 'identifier_exists'
    end

    local typeDef = Config.LabTypes[labType]
    local code = payload.code
    local codeHash = nil
    if code and Access.ValidateCodeFormat(tostring(code)) then
        codeHash = Access.HashCode(tostring(code))
    end

    local insertId = Repository.CreateLab({
        identifier = identifier,
        type = labType,
        label = payload.label,
        purchaseMode = payload.purchaseMode or 'purchase',
        purchasePrice = math.floor(tonumber(payload.purchasePrice) or typeDef.defaultPurchasePrice or 0),
        rentPrice = math.floor(tonumber(payload.rentPrice) or typeDef.defaultRentPrice or 0),
        sellPercentage = tonumber(payload.sellPercentage) or Config.Sell.sellPercentage,
        locked = payload.locked ~= false,
        codeHash = codeHash,
        entrance = DrugLabs.SerializeCoords(payload.entrance),
        interior = {
            entrance = DrugLabs.SerializeCoords(payload.interior.entrance or payload.interior),
            exit = DrugLabs.SerializeCoords(payload.interior.exit or payload.interior.entrance or payload.interior),
        },
        stash = {
            coords = DrugLabs.SerializeCoords(payload.stash and payload.stash.coords or payload.interior.entrance),
            slots = (payload.stash and payload.stash.slots) or typeDef.stash.slots,
            weight = (payload.stash and payload.stash.weight) or typeDef.stash.weight,
        },
        stations = payload.stations or {},
        blip = payload.blip or Config.Blip.default,
    })

    if not insertId then return false, 'db_error' end
    local lab = Repository.Get(insertId)
    Stash.Ensure(lab)
    TriggerClientEvent(DrugLabs.Events.client.refreshLab, -1, Repository.SerializeLabPublic(lab, false))
    LogAction('admin_create_lab', { labId = insertId, actor = Bridge.GetCitizenId(source), identifier = identifier })
    return true, Repository.SerializeLabPublic(lab, true)
end

function Admin.Delete(source, labId)
    local ok, err = requireAdmin(source)
    if not ok then return false, err end
    if not DrugLabs.IsValidId(labId) then return false, 'invalid_lab' end

    for _, playerId in pairs(GetPlayers()) do
        local src = tonumber(playerId)
        if src and Buckets.GetPlayerLab(src) == labId then
            Buckets.ForceLeave(src, 'deleted')
        end
    end

    Repository.DeleteLab(labId)
    TriggerClientEvent(DrugLabs.Events.client.refreshLab, -1, { id = labId, deleted = true })
    LogAction('admin_delete_lab', { labId = labId, actor = Bridge.GetCitizenId(source) })
    return true
end

function Admin.Teleport(source, labId)
    local ok, err = requireAdmin(source)
    if not ok then return false, err end
    local lab = Repository.Get(labId)
    if not lab then return false, 'invalid_lab' end
    local e = lab.entrance
    return true, { x = e.x, y = e.y, z = e.z, w = e.w or 0.0 }
end

function Admin.SetSealed(source, labId, sealed)
    local ok, err = requireAdmin(source)
    if not ok then return false, err end
    if sealed then return Police.Seal(source, labId) end
    return Police.Unseal(source, labId)
end

function Admin.SetLocked(source, labId, locked)
    local ok, err = requireAdmin(source)
    if not ok then return false, err end
    Repository.UpdateLabFields(labId, { locked = locked and true or false })
    TriggerClientEvent(DrugLabs.Events.client.refreshLab, -1, Repository.SerializeLabPublic(Repository.Get(labId), false))
    LogAction('admin_set_locked', { labId = labId, actor = Bridge.GetCitizenId(source), locked = locked })
    return true
end
