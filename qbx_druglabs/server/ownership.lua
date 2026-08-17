Ownership = {}

local function syncLab(labId)
    local lab = Repository.ReloadLab(labId)
    TriggerClientEvent(DrugLabs.Events.client.refreshLab, -1, Repository.SerializeLabPublic(lab, false))
    return lab
end

function Ownership.Purchase(source, labId, moneyPreference)
    if not RateLimit.Check(source, 'purchase') then
        return false, 'rate_limited'
    end
    if not DrugLabs.IsValidId(labId) then return false, 'invalid_lab' end

    local lab = Repository.Get(labId)
    if not Access.IsAvailableForPurchase(lab) then return false, 'unavailable' end
    if lab.purchase_mode ~= 'purchase' and lab.purchase_mode ~= 'public' then
        return false, 'not_purchasable'
    end

    local citizenid = Bridge.GetCitizenId(source)
    if not citizenid then return false, 'no_player' end

    if Repository.CountOwnedByCitizen(citizenid) >= Config.Labs.maxOwnedPerPlayer then
        return false, 'max_owned'
    end

    local price = lab.purchase_price
    if price < 0 then return false, 'invalid_price' end

    -- Atomic-ish ownership claim
    local affected = MySQL.update.await([[
        UPDATE drug_labs
        SET ownership_type = 'player', owner_identifier = ?, owner_gang = NULL, locked = 1
        WHERE id = ? AND ownership_type = 'none' AND sealed = 0
    ]], { citizenid, labId })

    if not affected or affected < 1 then
        return false, 'already_taken'
    end

    local charged, moneyType = false, nil
    if price > 0 then
        if moneyPreference == 'cash' and Config.Purchase.allowCash then
            charged = Bridge.RemoveMoney(source, 'cash', price, 'druglab-purchase')
            moneyType = 'cash'
        else
            charged = Bridge.RemoveMoney(source, Config.Purchase.moneyType or 'bank', price, 'druglab-purchase')
            moneyType = Config.Purchase.moneyType or 'bank'
            if not charged and Config.Purchase.allowCash then
                charged = Bridge.RemoveMoney(source, 'cash', price, 'druglab-purchase')
                moneyType = 'cash'
            end
        end
    else
        charged = true
    end

    if not charged then
        MySQL.update.await([[
            UPDATE drug_labs
            SET ownership_type = 'none', owner_identifier = NULL, locked = ?
            WHERE id = ?
        ]], { Config.Security.defaultLocked and 1 or 0, labId })
        Repository.ReloadLab(labId)
        return false, 'insufficient_funds'
    end

    local code = tostring(math.random(10 ^ (Config.Security.codeMinLength - 1), (10 ^ Config.Security.codeMaxLength) - 1))
    Repository.SetCodeHash(labId, Access.HashCode(code))

    local updated = syncLab(labId)
    Bridge.RegisterStash(labId, updated.stash_data.slots or 50, updated.stash_data.weight or 200000, updated.label)

    LogAction('lab_purchased', {
        labId = labId,
        actor = citizenid,
        price = price,
        moneyType = moneyType,
    })

    return true, { code = code, lab = Repository.SerializeLabPublic(updated, true) }
end

function Ownership.Rent(source, labId)
    if not Config.Rental.enabled then return false, 'disabled' end
    if not RateLimit.Check(source, 'purchase') then return false, 'rate_limited' end
    if not DrugLabs.IsValidId(labId) then return false, 'invalid_lab' end

    local lab = Repository.Get(labId)
    if not Access.IsAvailableForPurchase(lab) then return false, 'unavailable' end
    if lab.purchase_mode ~= 'rent' and lab.purchase_mode ~= 'purchase' then
        -- allow rent when rent price configured
        if (lab.rent_price or 0) <= 0 then return false, 'not_rentable' end
    end

    local citizenid = Bridge.GetCitizenId(source)
    if not citizenid then return false, 'no_player' end
    if Repository.CountOwnedByCitizen(citizenid) >= Config.Labs.maxOwnedPerPlayer then
        return false, 'max_owned'
    end

    local price = lab.rent_price or 0
    local affected = MySQL.update.await([[
        UPDATE drug_labs
        SET ownership_type = 'player', owner_identifier = ?, owner_gang = NULL, locked = 1
        WHERE id = ? AND ownership_type = 'none' AND sealed = 0
    ]], { citizenid, labId })
    if not affected or affected < 1 then return false, 'already_taken' end

    local charged = true
    if price > 0 then
        charged = select(1, Bridge.TryCharge(source, price, 'druglab-rent'))
    end
    if not charged then
        MySQL.update.await(
            'UPDATE drug_labs SET ownership_type = \'none\', owner_identifier = NULL WHERE id = ?',
            { labId }
        )
        Repository.ReloadLab(labId)
        return false, 'insufficient_funds'
    end

    local now = os.time()
    local expires = now + Config.Rental.duration
    local grace = expires + Config.Rental.gracePeriod
    Repository.CreateRental(labId, citizenid, expires, grace, Config.Rental.autoRenewDefault)

    local code = tostring(math.random(1000, 99999999)):sub(1, Config.Security.codeMaxLength)
    if #code < Config.Security.codeMinLength then
        code = code .. string.rep('0', Config.Security.codeMinLength - #code)
    end
    Repository.SetCodeHash(labId, Access.HashCode(code))

    local updated = syncLab(labId)
    Bridge.RegisterStash(labId, updated.stash_data.slots or 50, updated.stash_data.weight or 200000, updated.label)
    LogAction('lab_rented', { labId = labId, actor = citizenid, price = price, expires = expires })
    return true, { code = code, lab = Repository.SerializeLabPublic(updated, true) }
end

function Ownership.SellToServer(source, labId)
    if not Config.Sell.allowServerSell then return false, 'disabled' end
    if not DrugLabs.IsValidId(labId) then return false, 'invalid_lab' end

    local lab = Repository.Get(labId)
    if not lab then return false, 'invalid_lab' end

    local ok = Access.Can(source, lab, DrugLabs.Permissions.SELL_LAB)
    if not ok then return false, 'no_permission' end
    if lab.sealed then return false, 'sealed' end

    local citizenid = Bridge.GetCitizenId(source)
    local payout = math.floor((lab.purchase_price or 0) * (lab.sell_percentage or Config.Sell.sellPercentage))

    Repository.UpdateLabFields(labId, {
        ownership_type = 'none',
        owner_identifier = nil,
        owner_gang = nil,
        locked = Config.Security.defaultLocked,
        access_code_hash = nil,
    })

    local rental = Repository.GetRental(labId)
    if rental then
        Repository.UpdateRentalStatus(rental.id, 'cancelled')
    end

    MySQL.update.await('DELETE FROM drug_lab_members WHERE lab_id = ?', { labId })
    syncLab(labId)

    if payout > 0 then
        Bridge.AddMoney(source, Config.Purchase.moneyType or 'bank', payout, 'druglab-sell')
    end

    LogAction('lab_sold', { labId = labId, actor = citizenid, payout = payout })
    return true, { payout = payout }
end

function Ownership.Transfer(source, labId, targetSource)
    if not Config.Sell.allowTransfer then return false, 'disabled' end
    if not DrugLabs.IsValidId(labId) then return false, 'invalid_lab' end
    targetSource = tonumber(targetSource)
    if not targetSource then return false, 'invalid_target' end

    local lab = Repository.Get(labId)
    if not lab then return false, 'invalid_lab' end
    if not Access.Can(source, lab, DrugLabs.Permissions.SELL_LAB) then return false, 'no_permission' end
    if lab.sealed then return false, 'sealed' end

    local targetCid = Bridge.GetCitizenId(targetSource)
    if not targetCid then return false, 'target_offline' end
    if Repository.CountOwnedByCitizen(targetCid) >= Config.Labs.maxOwnedPerPlayer then
        return false, 'target_max_owned'
    end

    local actor = Bridge.GetCitizenId(source)
    if targetCid == actor then return false, 'self_transfer' end

    Repository.UpdateLabFields(labId, {
        ownership_type = 'player',
        owner_identifier = targetCid,
        owner_gang = nil,
    })
    MySQL.update.await('DELETE FROM drug_lab_members WHERE lab_id = ?', { labId })
    syncLab(labId)

    LogAction('lab_transferred', { labId = labId, actor = actor, target = targetCid })
    Bridge.Notify(targetSource, { description = ('You received ownership of %s'):format(lab.label), type = 'success' })
    return true
end

function Ownership.AssignGang(source, labId, gangName)
    if not Bridge.IsAdmin(source) then return false, 'no_permission' end
    if not DrugLabs.IsValidId(labId) or not DrugLabs.IsNonEmptyString(gangName) then
        return false, 'invalid'
    end
    Repository.UpdateLabFields(labId, {
        ownership_type = 'gang',
        owner_identifier = nil,
        owner_gang = gangName,
    })
    syncLab(labId)
    LogAction('lab_assigned_gang', { labId = labId, actor = Bridge.GetCitizenId(source), gang = gangName })
    return true
end

function Ownership.Reset(source, labId)
    if not Bridge.IsAdmin(source) then return false, 'no_permission' end
    Repository.UpdateLabFields(labId, {
        ownership_type = 'none',
        owner_identifier = nil,
        owner_gang = nil,
        locked = Config.Security.defaultLocked,
        access_code_hash = nil,
        sealed = false,
    })
    MySQL.update.await('DELETE FROM drug_lab_members WHERE lab_id = ?', { labId })
    local rental = Repository.GetRental(labId)
    if rental then Repository.UpdateRentalStatus(rental.id, 'cancelled') end
    syncLab(labId)
    LogAction('lab_reset', { labId = labId, actor = Bridge.GetCitizenId(source) })
    return true
end
