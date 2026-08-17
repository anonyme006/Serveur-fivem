local function fail(msg)
    return { ok = false, error = msg }
end

local function ok(data)
    return { ok = true, data = data }
end

lib.callback.register('qbx_druglabs:server:getLabs', function(source)
    return ok(Repository.SerializeAllPublic())
end)

lib.callback.register('qbx_druglabs:server:getLab', function(source, labId)
    if not DrugLabs.IsValidId(labId) then return fail('invalid_lab') end
    local lab = Repository.Get(labId)
    if not lab then return fail('invalid_lab') end
    local detailed = Access.Can(source, lab, nil) or Bridge.IsAdmin(source) or Bridge.IsPolice(source)
    return ok(Repository.SerializeLabPublic(lab, detailed))
end)

lib.callback.register('qbx_druglabs:server:getManagement', function(source, labId)
    if not DrugLabs.IsValidId(labId) then return fail('invalid_lab') end
    local lab = Repository.Get(labId)
    if not lab then return fail('invalid_lab') end
    if not Access.Can(source, lab, DrugLabs.Permissions.ENTER) and not Bridge.IsAdmin(source) then
        return fail('no_permission')
    end

    local citizenid = Bridge.GetCitizenId(source)
    local perms = DrugLabs.DefaultMemberPermissions
    if lab.owner_identifier == citizenid then
        perms = DrugLabs.OwnerPermissions
    elseif lab.ownership_type == 'gang' then
        local _, grade = Bridge.GetGang(source)
        perms = Bridge.GetGangPermissions(grade)
    else
        local member = Repository.GetMember(labId, citizenid)
        if member then perms = member.permissions end
    end

    return ok({
        lab = Repository.SerializeLabPublic(lab, true),
        permissions = perms,
        members = Repository.GetMembers(labId),
        plants = lab.type == 'weed' and Plants.GetForLab(labId) or {},
        rental = Repository.GetRental(labId),
        isOwner = lab.owner_identifier == citizenid,
        isAdmin = Bridge.IsAdmin(source),
        isPolice = Bridge.IsPolice(source),
    })
end)

lib.callback.register('qbx_druglabs:server:purchaseLab', function(source, labId, moneyPreference)
    local success, result = Ownership.Purchase(source, labId, moneyPreference)
    if not success then return fail(result) end
    return ok(result)
end)

lib.callback.register('qbx_druglabs:server:rentLab', function(source, labId)
    local success, result = Ownership.Rent(source, labId)
    if not success then return fail(result) end
    return ok(result)
end)

lib.callback.register('qbx_druglabs:server:renewRent', function(source, labId)
    local success, result = Rentals.Renew(source, labId)
    if not success then return fail(result) end
    return ok(result)
end)

lib.callback.register('qbx_druglabs:server:sellLab', function(source, labId)
    local success, result = Ownership.SellToServer(source, labId)
    if not success then return fail(result) end
    return ok(result)
end)

lib.callback.register('qbx_druglabs:server:transferLab', function(source, labId, targetSource)
    local success, result = Ownership.Transfer(source, labId, targetSource)
    if not success then return fail(result) end
    return ok(result)
end)

lib.callback.register('qbx_druglabs:server:enterLab', function(source, labId)
    if not RateLimit.Check(source, 'entry') then return fail('rate_limited') end
    if not DrugLabs.IsValidId(labId) then return fail('invalid_lab') end
    local lab = Repository.Get(labId)
    if not lab then return fail('invalid_lab') end

    if lab.sealed then
        if Bridge.IsPolice(source) or Bridge.IsAdmin(source) then
            Buckets.Enter(source, labId)
            return ok({ lab = Repository.SerializeLabPublic(lab, true), plants = Plants.GetForLab(labId) })
        end
        return fail('sealed')
    end

    if not Access.CanEnter(source, lab) then
        if Access.Can(source, lab, DrugLabs.Permissions.ENTER) and lab.locked then
            return fail('locked')
        end
        return fail('no_access')
    end

    Buckets.Enter(source, labId)
    LogAction('lab_enter', { labId = labId, actor = Bridge.GetCitizenId(source) })
    return ok({
        lab = Repository.SerializeLabPublic(lab, true),
        plants = lab.type == 'weed' and Plants.GetForLab(labId) or {},
        recipes = Config.Recipes[lab.type] or {},
    })
end)

lib.callback.register('qbx_druglabs:server:leaveLab', function(source)
    local labId = Buckets.GetPlayerLab(source)
    Buckets.Leave(source)
    if labId then
        LogAction('lab_leave', { labId = labId, actor = Bridge.GetCitizenId(source) })
    end
    return ok(true)
end)

lib.callback.register('qbx_druglabs:server:tryCode', function(source, labId, code)
    local success, result = Access.TryCode(source, labId, tostring(code or ''))
    if not success then return fail(result) end
    return ok(true)
end)

lib.callback.register('qbx_druglabs:server:setLocked', function(source, labId, locked)
    if not DrugLabs.IsValidId(labId) then return fail('invalid_lab') end
    local lab = Repository.Get(labId)
    if not lab or not Access.Can(source, lab, DrugLabs.Permissions.LOCK_LAB) then
        return fail('no_permission')
    end
    Repository.UpdateLabFields(labId, { locked = locked and true or false })
    TriggerClientEvent(DrugLabs.Events.client.refreshLab, -1, Repository.SerializeLabPublic(Repository.Get(labId), false))
    LogAction('lab_lock_toggle', { labId = labId, actor = Bridge.GetCitizenId(source), locked = locked })
    return ok(true)
end)

lib.callback.register('qbx_druglabs:server:changeCode', function(source, labId, newCode)
    if not DrugLabs.IsValidId(labId) then return fail('invalid_lab') end
    local lab = Repository.Get(labId)
    if not lab or not Access.Can(source, lab, DrugLabs.Permissions.CHANGE_CODE) then
        return fail('no_permission')
    end
    if not Access.ValidateCodeFormat(tostring(newCode or '')) then
        return fail('invalid_format')
    end
    Repository.SetCodeHash(labId, Access.HashCode(tostring(newCode)))
    LogAction('code_changed', { labId = labId, actor = Bridge.GetCitizenId(source) })
    return ok(true)
end)

lib.callback.register('qbx_druglabs:server:openStash', function(source, labId)
    local success, result = Stash.Open(source, labId)
    if not success then return fail(result) end
    return ok(true)
end)

lib.callback.register('qbx_druglabs:server:startProduction', function(source, labId, stationId, recipeId)
    local success, result = Production.Start(source, labId, stationId, recipeId)
    if not success then return fail(result) end
    return ok(result)
end)

lib.callback.register('qbx_druglabs:server:finishProduction', function(source, token, clientResult)
    local success, result = Production.Finish(source, token, clientResult)
    if not success then return fail(result) end
    return ok(result)
end)

lib.callback.register('qbx_druglabs:server:cancelProduction', function(source, token)
    local success, result = Production.Cancel(source, token)
    if not success then return fail(result) end
    return ok(result)
end)

lib.callback.register('qbx_druglabs:server:plantAction', function(source, labId, stationId, action)
    local success, result = Plants.Action(source, labId, stationId, action)
    if not success then return fail(result) end
    return ok(result)
end)

lib.callback.register('qbx_druglabs:server:addMember', function(source, labId, targetSource, permissions)
    if not DrugLabs.IsValidId(labId) then return fail('invalid_lab') end
    local lab = Repository.Get(labId)
    if not lab or not Access.Can(source, lab, DrugLabs.Permissions.MANAGE_MEMBERS) then
        return fail('no_permission')
    end
    local members = Repository.GetMembers(labId)
    if #members >= Config.Labs.maxMembersPerLab then return fail('max_members') end

    targetSource = tonumber(targetSource)
    local targetCid = targetSource and Bridge.GetCitizenId(targetSource)
    if not targetCid then return fail('invalid_target') end
    if targetCid == lab.owner_identifier then return fail('is_owner') end

    local perms = type(permissions) == 'table' and permissions or DrugLabs.DefaultMemberPermissions
    -- never allow sell from members unless owner explicitly sets it (still capped)
    Repository.UpsertMember(labId, targetCid, perms, Bridge.GetCitizenId(source))
    LogAction('member_added', { labId = labId, actor = Bridge.GetCitizenId(source), member = targetCid })
    Bridge.Notify(targetSource, { description = ('You were added to %s'):format(lab.label), type = 'success' })
    return ok(Repository.GetMembers(labId))
end)

lib.callback.register('qbx_druglabs:server:removeMember', function(source, labId, citizenid)
    if not DrugLabs.IsValidId(labId) or not DrugLabs.IsNonEmptyString(citizenid) then
        return fail('invalid_args')
    end
    local lab = Repository.Get(labId)
    if not lab or not Access.Can(source, lab, DrugLabs.Permissions.MANAGE_MEMBERS) then
        return fail('no_permission')
    end
    Repository.RemoveMember(labId, citizenid)
    LogAction('member_removed', { labId = labId, actor = Bridge.GetCitizenId(source), member = citizenid })
    return ok(Repository.GetMembers(labId))
end)

lib.callback.register('qbx_druglabs:server:updateMember', function(source, labId, citizenid, permissions)
    if not DrugLabs.IsValidId(labId) or not DrugLabs.IsNonEmptyString(citizenid) or type(permissions) ~= 'table' then
        return fail('invalid_args')
    end
    local lab = Repository.Get(labId)
    if not lab or not Access.Can(source, lab, DrugLabs.Permissions.MANAGE_MEMBERS) then
        return fail('no_permission')
    end
    Repository.UpsertMember(labId, citizenid, permissions, Bridge.GetCitizenId(source))
    LogAction('member_updated', { labId = labId, actor = Bridge.GetCitizenId(source), member = citizenid })
    return ok(Repository.GetMembers(labId))
end)

lib.callback.register('qbx_druglabs:server:sealLab', function(source, labId)
    local success, result = Police.Seal(source, labId)
    if not success then return fail(result) end
    return ok(true)
end)

lib.callback.register('qbx_druglabs:server:unsealLab', function(source, labId)
    local success, result = Police.Unseal(source, labId)
    if not success then return fail(result) end
    return ok(true)
end)

lib.callback.register('qbx_druglabs:server:raidLab', function(source, labId)
    local success, result = Police.Raid(source, labId)
    if not success then return fail(result) end
    return ok(result)
end)

lib.callback.register('qbx_druglabs:server:adminList', function(source)
    local success, result = Admin.List(source)
    if not success then return fail(result) end
    return ok(result)
end)

lib.callback.register('qbx_druglabs:server:adminCreate', function(source, payload)
    local success, result = Admin.Create(source, payload)
    if not success then return fail(result) end
    return ok(result)
end)

lib.callback.register('qbx_druglabs:server:adminDelete', function(source, labId)
    local success, result = Admin.Delete(source, labId)
    if not success then return fail(result) end
    return ok(true)
end)

lib.callback.register('qbx_druglabs:server:adminTeleport', function(source, labId)
    local success, result = Admin.Teleport(source, labId)
    if not success then return fail(result) end
    return ok(result)
end)

lib.callback.register('qbx_druglabs:server:adminReset', function(source, labId)
    local success, result = Ownership.Reset(source, labId)
    if not success then return fail(result) end
    return ok(true)
end)

lib.callback.register('qbx_druglabs:server:adminSetLocked', function(source, labId, locked)
    local success, result = Admin.SetLocked(source, labId, locked)
    if not success then return fail(result) end
    return ok(true)
end)

lib.callback.register('qbx_druglabs:server:adminSetSealed', function(source, labId, sealed)
    local success, result = Admin.SetSealed(source, labId, sealed)
    if not success then return fail(result) end
    return ok(true)
end)

lib.callback.register('qbx_druglabs:server:getRecipes', function(source, labType)
    if type(labType) ~= 'string' then return fail('invalid') end
    return ok(Config.Recipes[labType] or {})
end)
