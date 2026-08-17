Rentals = {}

local function parseMysqlTs(value)
    if type(value) == 'number' then return value end
    if type(value) ~= 'string' then return nil end
    local ts = MySQL.scalar.await('SELECT UNIX_TIMESTAMP(?)', { value })
    return tonumber(ts)
end

function Rentals.ProcessExpirations()
    local rentals = MySQL.query.await([[
        SELECT * FROM drug_lab_rentals WHERE status IN ('active', 'grace')
    ]]) or {}

    local now = os.time()
    for i = 1, #rentals do
        local rental = rentals[i]
        local expires = parseMysqlTs(rental.expires_at) or 0
        local graceUntil = parseMysqlTs(rental.grace_until) or (expires + Config.Rental.gracePeriod)

        if rental.status == 'active' and now >= expires then
            if rental.auto_renew == 1 or rental.auto_renew == true then
                local lab = Repository.Get(rental.lab_id)
                local target = Bridge.GetSourceByCitizenId(rental.renter)
                local price = lab and lab.rent_price or 0
                local renewed = false
                if target and price > 0 then
                    renewed = select(1, Bridge.TryCharge(target, price, 'druglab-autorenew'))
                elseif price <= 0 then
                    renewed = true
                end

                if renewed then
                    local newExpires = now + Config.Rental.duration
                    local newGrace = newExpires + Config.Rental.gracePeriod
                    MySQL.update.await(
                        'UPDATE drug_lab_rentals SET expires_at = FROM_UNIXTIME(?), grace_until = FROM_UNIXTIME(?), status = ? WHERE id = ?',
                        { newExpires, newGrace, 'active', rental.id }
                    )
                    Repository.ReloadLab(rental.lab_id)
                    if target then
                        Bridge.Notify(target, { description = 'Your laboratory rental was auto-renewed.', type = 'success' })
                    end
                    LogAction('rental_autorenew', { labId = rental.lab_id, actor = rental.renter, price = price })
                else
                    MySQL.update.await(
                        'UPDATE drug_lab_rentals SET status = ? WHERE id = ?',
                        { 'grace', rental.id }
                    )
                    Repository.ReloadLab(rental.lab_id)
                    if target then
                        Bridge.Notify(target, {
                            description = 'Rental expired. Grace period started — renew soon.',
                            type = 'warning',
                        })
                    end
                    LogAction('rental_grace', { labId = rental.lab_id, actor = rental.renter })
                end
            else
                MySQL.update.await('UPDATE drug_lab_rentals SET status = ? WHERE id = ?', { 'grace', rental.id })
                Repository.ReloadLab(rental.lab_id)
                local target = Bridge.GetSourceByCitizenId(rental.renter)
                if target then
                    Bridge.Notify(target, {
                        description = 'Your laboratory rental expired. Grace period active.',
                        type = 'warning',
                    })
                end
                LogAction('rental_grace', { labId = rental.lab_id, actor = rental.renter })
            end
        elseif (rental.status == 'grace' or rental.status == 'active') and now >= graceUntil then
            MySQL.update.await('UPDATE drug_lab_rentals SET status = ? WHERE id = ?', { 'expired', rental.id })
            Repository.UpdateLabFields(rental.lab_id, {
                ownership_type = 'none',
                owner_identifier = nil,
                owner_gang = nil,
                access_code_hash = nil,
                locked = true,
            })
            TriggerClientEvent(DrugLabs.Events.client.refreshLab, -1, Repository.SerializeLabPublic(Repository.Get(rental.lab_id), false))
            local target = Bridge.GetSourceByCitizenId(rental.renter)
            if target then
                -- kick from bucket if inside
                Buckets.ForceLeave(target, 'rental_expired')
                Bridge.Notify(target, {
                    description = 'Laboratory rental fully expired. Access revoked (stash preserved).',
                    type = 'error',
                })
            end
            LogAction('rental_expired', { labId = rental.lab_id, actor = rental.renter })
        end
    end
end

function Rentals.Renew(source, labId)
    if not Config.Rental.enabled then return false, 'disabled' end
    if not DrugLabs.IsValidId(labId) then return false, 'invalid_lab' end

    local lab = Repository.Get(labId)
    local rental = Repository.GetRental(labId)
    local citizenid = Bridge.GetCitizenId(source)
    if not lab or not rental or rental.renter ~= citizenid then
        return false, 'not_renter'
    end

    local price = lab.rent_price or 0
    if price > 0 and not select(1, Bridge.TryCharge(source, price, 'druglab-renew')) then
        return false, 'insufficient_funds'
    end

    local now = os.time()
    local newExpires = now + Config.Rental.duration
    local newGrace = newExpires + Config.Rental.gracePeriod
    MySQL.update.await(
        'UPDATE drug_lab_rentals SET expires_at = FROM_UNIXTIME(?), grace_until = FROM_UNIXTIME(?), status = ? WHERE id = ?',
        { newExpires, newGrace, 'active', rental.id }
    )
    Repository.ReloadLab(labId)
    TriggerClientEvent(DrugLabs.Events.client.refreshLab, -1, Repository.SerializeLabPublic(Repository.Get(labId), false))
    LogAction('rental_renewed', { labId = labId, actor = citizenid, price = price })
    return true
end

CreateThread(function()
    while true do
        Wait(60000)
        local ok, err = pcall(Rentals.ProcessExpirations)
        if not ok then
            print('[qbx_druglabs] Rental process error:', err)
        end
    end
end)
