SkyDS = SkyDS or {}
SkyDS.Points = SkyDS.Points or {}

local function actorName(src)
    if not src then return 'System' end
    local first, last = SkyDS.Bridge.GetCharInfo(src)
    return (first or '') .. ' ' .. (last or '')
end

---@param src number
---@param minGrade number
---@param action string
---@return boolean
function SkyDS.Points.CanManage(src, minGrade, action)
    if SkyDS.Bridge.IsAdmin(src) then return true end
    local job, grade, onduty = SkyDS.Bridge.GetJob(src)
    if not job then return false end
    if Config.RequireOnDuty and not onduty then return false end

    local policeGrade = Config.PoliceJobs and Config.PoliceJobs[job]
    local instructorGrade = Config.InstructorJobs and Config.InstructorJobs[job]
    local allowed = false
    local g = 0
    if policeGrade ~= nil then
        allowed = true
        g = grade
        if grade < policeGrade then allowed = false end
    end
    if instructorGrade ~= nil and grade >= instructorGrade then
        allowed = true
        g = math.max(g, grade)
    end
    if not allowed then return false end

    local need = minGrade or 0
    if action and Config.AdminMinGrade and Config.AdminMinGrade[action] ~= nil then
        need = Config.AdminMinGrade[action]
    end
    return g >= need
end

---@param targetSrc number
---@param categoryId string
---@param amount number
---@param reason string
---@param actorSrc number
---@param infraction string|nil
---@return boolean, string, table|nil
function SkyDS.Points.Remove(targetSrc, categoryId, amount, reason, actorSrc, infraction)
    if not Config.Points or not Config.Points.enabled then return false, 'disabled' end
    amount = math.floor(tonumber(amount) or 0)
    if amount < 1 then return false, 'invalid_amount' end
    if type(reason) ~= 'string' or reason:gsub('%s+', '') == '' then
        return false, 'reason_required'
    end
    if not SkyDS.GetCategory(categoryId) then return false, 'invalid_category' end

    local citizenid = SkyDS.Bridge.GetCitizenId(targetSrc)
    if not citizenid then return false, 'no_player' end

    local row = SkyDS.DB.GetLicense(citizenid, categoryId)
    if not row or row.status == 'revoked' then return false, 'not_owned' end

    local maxPoints = tonumber(row.max_points) or SkyDS.MaxPoints(categoryId)
    local before = tonumber(row.points) or 0
    local after = math.max(0, before - amount)
    local status = 'valid'
    if after <= (Config.Points.suspendAt or 0) then
        status = Config.Points.revokeAtZero and after <= 0 and 'revoked' or 'suspended'
    end

    SkyDS.DB.UpdateLicensePoints(citizenid, categoryId, after, status)
    SkyDS.DB.InsertPointsHistory({
        citizenid = citizenid,
        category = categoryId,
        action = status == 'revoked' and 'revoke' or (status == 'suspended' and 'suspend' or 'remove'),
        infraction = infraction,
        points_delta = -amount,
        points_before = before,
        points_after = after,
        reason = reason,
        actor_citizenid = SkyDS.Bridge.GetCitizenId(actorSrc),
        actor_name = actorName(actorSrc),
    })

    -- Sync framework metadata points when table-shaped
    local player = SkyDS.Bridge.GetPlayer(targetSrc)
    local cat = SkyDS.GetCategory(categoryId)
    if player and cat then
        local meta = player.PlayerData and player.PlayerData.metadata or {}
        local licences = meta.licences or {}
        local key = cat.licenseKey
        if type(licences[key]) == 'table' then
            licences[key].points = after
            licences[key].owned = status ~= 'revoked'
            player.Functions.SetMetaData('licences', licences)
        elseif status == 'revoked' or status == 'suspended' then
            licences[key] = false
            player.Functions.SetMetaData('licences', licences)
        end
    end

    SkyDS.Bridge.Notify(targetSrc, 'DMV', L('points_removed', amount, cat and cat.label or categoryId, after, maxPoints), 'error')
    if status == 'suspended' then
        SkyDS.Bridge.Notify(targetSrc, 'DMV', L('license_suspended', cat and cat.label or categoryId), 'error')
    elseif status == 'revoked' then
        SkyDS.Bridge.Notify(targetSrc, 'DMV', L('license_revoked', cat and cat.label or categoryId), 'error')
    end

    return true, 'ok', { points = after, status = status, maxPoints = maxPoints }
end

---@param targetSrc number
---@param categoryId string
---@param amount number
---@param reason string
---@param actorSrc number
---@return boolean, string, table|nil
function SkyDS.Points.Restore(targetSrc, categoryId, amount, reason, actorSrc)
    if not Config.Points or not Config.Points.enabled then return false, 'disabled' end
    amount = math.floor(tonumber(amount) or 0)
    if amount < 1 then return false, 'invalid_amount' end
    if type(reason) ~= 'string' or reason:gsub('%s+', '') == '' then
        return false, 'reason_required'
    end

    local citizenid = SkyDS.Bridge.GetCitizenId(targetSrc)
    if not citizenid then return false, 'no_player' end
    local row = SkyDS.DB.GetLicense(citizenid, categoryId)
    if not row then return false, 'not_owned' end

    local maxPoints = tonumber(row.max_points) or SkyDS.MaxPoints(categoryId)
    local before = tonumber(row.points) or 0
    local after = math.min(maxPoints, before + amount)
    local status = after > (Config.Points.suspendAt or 0) and 'valid' or 'suspended'
    if row.status == 'revoked' and after > 0 then
        status = 'valid'
    end

    SkyDS.DB.UpdateLicensePoints(citizenid, categoryId, after, status)
    SkyDS.DB.InsertPointsHistory({
        citizenid = citizenid,
        category = categoryId,
        action = 'restore',
        points_delta = amount,
        points_before = before,
        points_after = after,
        reason = reason,
        actor_citizenid = SkyDS.Bridge.GetCitizenId(actorSrc),
        actor_name = actorName(actorSrc),
    })

    local cat = SkyDS.GetCategory(categoryId)
    SkyDS.Bridge.Notify(targetSrc, 'DMV', L('points_restored', amount, cat and cat.label or categoryId, after, maxPoints), 'success')
    return true, 'ok', { points = after, status = status, maxPoints = maxPoints }
end

---@param targetSrc number
---@param infractionKey string
---@param reason string
---@param actorSrc number
---@param categoryId string|nil forced category
---@return boolean, string, table|nil
function SkyDS.Points.ApplyInfraction(targetSrc, infractionKey, reason, actorSrc, categoryId)
    local def = Config.Points and Config.Points.infractions and Config.Points.infractions[infractionKey]
    if not def then return false, 'invalid_infraction' end

    local category = categoryId
    if not category then
        -- pick first owned matching category
        for _, catId in ipairs(def.categories or {}) do
            if SkyDS.Licenses.Has(targetSrc, catId) then
                category = catId
                break
            end
        end
    end
    if not category then return false, 'no_matching_license' end

    if def.categories then
        local ok = false
        for _, c in ipairs(def.categories) do
            if c == category then ok = true break end
        end
        if not ok then return false, 'category_not_applicable' end
    end

    return SkyDS.Points.Remove(targetSrc, category, def.points, reason or def.label, actorSrc, infractionKey)
end

-- Passive recovery tick (optional)
CreateThread(function()
    if not (Config.Points and Config.Points.recovery and Config.Points.recovery.enabled) then return end
    local periodHours = Config.Points.recovery.periodHours or 168
    local pts = Config.Points.recovery.pointsPerPeriod or 1
    while true do
        Wait(3600 * 1000) -- hourly check
        local rows = MySQL.query.await([[
            SELECT citizenid, category, points, max_points, status, UNIX_TIMESTAMP(updated_at) AS updated_unix
            FROM sky_ds_licenses
            WHERE status IN ('valid','suspended') AND points < max_points
        ]]) or {}
        local now = os.time()
        local needSeconds = periodHours * 3600
        for _, row in ipairs(rows) do
            local updated = tonumber(row.updated_unix) or 0
            if (now - updated) >= needSeconds then
                local after = math.min(tonumber(row.max_points) or 12, (tonumber(row.points) or 0) + pts)
                local status = after > (Config.Points.suspendAt or 0) and 'valid' or 'suspended'
                SkyDS.DB.UpdateLicensePoints(row.citizenid, row.category, after, status)
                SkyDS.DB.InsertPointsHistory({
                    citizenid = row.citizenid,
                    category = row.category,
                    action = 'recovery',
                    points_delta = pts,
                    points_before = tonumber(row.points) or 0,
                    points_after = after,
                    reason = 'Automatic point recovery',
                    actor_citizenid = 'system',
                    actor_name = 'DMV Recovery',
                })
            end
        end
    end
end)
