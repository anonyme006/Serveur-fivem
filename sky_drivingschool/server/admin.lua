SkyDS = SkyDS or {}
SkyDS.Admin = SkyDS.Admin or {}

---@param src number
---@param action string
---@return boolean
function SkyDS.Admin.Can(src, action)
    if SkyDS.Bridge.IsAdmin(src) then return true end
    local job, grade, onduty = SkyDS.Bridge.GetJob(src)
    if not job then return false end
    if Config.RequireOnDuty and not onduty then return false end

    local instructor = Config.InstructorJobs and Config.InstructorJobs[job]
    local police = Config.PoliceJobs and Config.PoliceJobs[job]
    if instructor == nil and police == nil then return false end
    if instructor ~= nil and grade < instructor then return false end
    if police ~= nil and instructor == nil and grade < police then return false end

    local need = (Config.AdminMinGrade and Config.AdminMinGrade[action]) or 0
    return grade >= need
end

lib.callback.register('sky_drivingschool:server:adminDashboard', function(src)
    if not SkyDS.AntiCheat.Allow(src, 'admin_dash') then return { ok = false, error = L('suspicious') } end
    if not SkyDS.Admin.Can(src, 'viewStats') then return { ok = false, error = L('no_permission') } end

    local active = {}
    for playerSrc, exam in pairs(SkyDS.ActiveExams or {}) do
        local first, last = SkyDS.Bridge.GetCharInfo(playerSrc)
        active[#active + 1] = {
            source = playerSrc,
            name = (first or '') .. ' ' .. (last or ''),
            citizenid = exam.citizenid,
            type = exam.type,
            category = exam.category,
            schoolId = exam.schoolId,
            startedAt = exam.startedAt,
            score = exam.score,
        }
    end

    return {
        ok = true,
        stats = SkyDS.DB.GetGlobalStats(),
        active = active,
        recent = SkyDS.DB.GetRecentExams(30),
        logs = SkyDS.Admin.Can(src, 'viewLogs') and SkyDS.DB.GetLogs(40) or {},
        categories = SkyDS.GetEnabledCategories(),
        canEditPrices = SkyDS.Admin.Can(src, 'editPrices'),
        canCancel = SkyDS.Admin.Can(src, 'cancelExam'),
        canRevoke = SkyDS.Admin.Can(src, 'revokeLicense'),
        canManagePoints = SkyDS.Points.CanManage(src, 0, 'managePoints'),
        canRestore = SkyDS.Admin.Can(src, 'restoreLicense'),
        infractions = Config.Points and Config.Points.infractions or {},
    }
end)

lib.callback.register('sky_drivingschool:server:adminCancelExam', function(src, targetSrc)
    if not SkyDS.AntiCheat.Allow(src, 'admin_cancel') then return { ok = false, error = L('suspicious') } end
    if not SkyDS.Admin.Can(src, 'cancelExam') then return { ok = false, error = L('no_permission') } end
    targetSrc = tonumber(targetSrc)
    if not targetSrc or not SkyDS.ActiveExams[targetSrc] then
        return { ok = false, error = L('no_active_exam') }
    end
    local exam = SkyDS.ActiveExams[targetSrc]
    if exam.type == 'practical' then
        SkyDS.Practical.Cancel(targetSrc, L('admin_cancelled'), false)
    else
        SkyDS.Theory.Cancel(targetSrc, L('admin_cancelled'))
    end
    SkyDS.DB.Log(exam.citizenid, SkyDS.Bridge.GetCitizenId(src), 'admin_cancel_exam', {
        target = targetSrc,
        examType = exam.type,
        category = exam.category,
    })
    return { ok = true }
end)

lib.callback.register('sky_drivingschool:server:adminLookup', function(src, targetSrc)
    if not SkyDS.AntiCheat.Allow(src, 'admin_lookup') then return { ok = false, error = L('suspicious') } end
    if not SkyDS.Admin.Can(src, 'viewCandidates') and not SkyDS.Points.CanManage(src, 0, 'managePoints') then
        return { ok = false, error = L('no_permission') }
    end
    targetSrc = tonumber(targetSrc)
    if not targetSrc then return { ok = false, error = L('player_not_found') } end
    local citizenid = SkyDS.Bridge.GetCitizenId(targetSrc)
    if not citizenid then return { ok = false, error = L('player_not_found') } end
    local first, last = SkyDS.Bridge.GetCharInfo(targetSrc)
    return {
        ok = true,
        citizenid = citizenid,
        name = (first or '') .. ' ' .. (last or ''),
        licenses = SkyDS.Licenses.GetCardData(targetSrc),
        history = SkyDS.DB.GetExamHistory(citizenid, 20),
        pointsHistory = SkyDS.DB.GetPointsHistory(citizenid, 30),
        stats = SkyDS.DB.GetStats(citizenid),
    }
end)

lib.callback.register('sky_drivingschool:server:adminRemovePoints', function(src, data)
    if not SkyDS.AntiCheat.Allow(src, 'admin_points') then return { ok = false, error = L('suspicious') } end
    if not SkyDS.Points.CanManage(src, 0, 'managePoints') then
        return { ok = false, error = L('no_permission') }
    end
    data = type(data) == 'table' and data or {}
    local targetSrc = tonumber(data.target)
    if not targetSrc then return { ok = false, error = L('player_not_found') } end
    local ok, err, result
    if data.infraction then
        ok, err, result = SkyDS.Points.ApplyInfraction(targetSrc, data.infraction, data.reason, src, data.category)
    else
        ok, err, result = SkyDS.Points.Remove(targetSrc, data.category, data.amount, data.reason, src, nil)
    end
    if not ok then return { ok = false, error = L(err) ~= err and L(err) or err } end
    SkyDS.DB.Log(SkyDS.Bridge.GetCitizenId(targetSrc), SkyDS.Bridge.GetCitizenId(src), 'admin_remove_points', data)
    return { ok = true, result = result }
end)

lib.callback.register('sky_drivingschool:server:adminRestorePoints', function(src, data)
    if not SkyDS.AntiCheat.Allow(src, 'admin_restore') then return { ok = false, error = L('suspicious') } end
    if not SkyDS.Admin.Can(src, 'restoreLicense') and not SkyDS.Points.CanManage(src, Config.AdminMinGrade.restoreLicense or 2, 'restoreLicense') then
        return { ok = false, error = L('no_permission') }
    end
    data = type(data) == 'table' and data or {}
    local targetSrc = tonumber(data.target)
    if not targetSrc then return { ok = false, error = L('player_not_found') } end
    local ok, err, result = SkyDS.Points.Restore(targetSrc, data.category, data.amount, data.reason, src)
    if not ok then return { ok = false, error = err } end
    SkyDS.DB.Log(SkyDS.Bridge.GetCitizenId(targetSrc), SkyDS.Bridge.GetCitizenId(src), 'admin_restore_points', data)
    return { ok = true, result = result }
end)

lib.callback.register('sky_drivingschool:server:adminRevoke', function(src, data)
    if not SkyDS.AntiCheat.Allow(src, 'admin_revoke') then return { ok = false, error = L('suspicious') } end
    if not SkyDS.Admin.Can(src, 'revokeLicense') then return { ok = false, error = L('no_permission') } end
    data = type(data) == 'table' and data or {}
    local targetSrc = tonumber(data.target)
    if not targetSrc then return { ok = false, error = L('player_not_found') } end
    if type(data.reason) ~= 'string' or data.reason:gsub('%s+', '') == '' then
        return { ok = false, error = L('reason_required') }
    end
    local ok, err = SkyDS.Licenses.Revoke(targetSrc, data.category, data.reason, src)
    if not ok then return { ok = false, error = err } end
    SkyDS.Bridge.Notify(targetSrc, 'DMV', L('license_revoked', (SkyDS.GetCategory(data.category) or {}).label or data.category), 'error')
    SkyDS.DB.Log(SkyDS.Bridge.GetCitizenId(targetSrc), SkyDS.Bridge.GetCitizenId(src), 'admin_revoke', data)
    return { ok = true }
end)

-- Runtime price overrides (session only — permanent changes belong in config.lua)
SkyDS.PriceOverrides = SkyDS.PriceOverrides or {}

lib.callback.register('sky_drivingschool:server:adminSetPrice', function(src, data)
    if not SkyDS.AntiCheat.Allow(src, 'admin_price') then return { ok = false, error = L('suspicious') } end
    if not SkyDS.Admin.Can(src, 'editPrices') then return { ok = false, error = L('no_permission') } end
    data = type(data) == 'table' and data or {}
    local cat = SkyDS.GetCategory(data.category)
    if not cat then return { ok = false, error = L('invalid_category') } end
    local theory = tonumber(data.theoryPrice)
    local practical = tonumber(data.practicalPrice)
    if theory then cat.theoryPrice = math.max(0, math.floor(theory)) end
    if practical then cat.practicalPrice = math.max(0, math.floor(practical)) end
    SkyDS.PriceOverrides[data.category] = {
        theoryPrice = cat.theoryPrice,
        practicalPrice = cat.practicalPrice,
    }
    SkyDS.DB.Log(nil, SkyDS.Bridge.GetCitizenId(src), 'admin_set_price', {
        category = data.category,
        theoryPrice = cat.theoryPrice,
        practicalPrice = cat.practicalPrice,
    })
    return { ok = true, theoryPrice = cat.theoryPrice, practicalPrice = cat.practicalPrice }
end)
