SkyDS = SkyDS or {}
SkyDS.ActiveExams = SkyDS.ActiveExams or {}

MySQL.ready(function()
    SkyDS.DB.Init()
    print('^2[sky_drivingschool]^7 Database ready — license system: ' .. SkyDS.Licenses.GetSystem())
end)

local function buildDashboard(src, schoolId)
    local citizenid = SkyDS.Bridge.GetCitizenId(src)
    if not citizenid then return nil end
    local school = SkyDS.GetSchool(schoolId)
    if not school then return nil end

    local first, last = SkyDS.Bridge.GetCharInfo(src)
    local categories = {}
    for _, cat in ipairs(SkyDS.GetEnabledCategories()) do
        if SkyDS.SchoolOffers(school, cat.id) then
            local full = SkyDS.GetCategory(cat.id)
            cat.hasLicense = SkyDS.Licenses.Has(src, cat.id)
            cat.hasTheory = SkyDS.DB.HasTheoryPass(citizenid, cat.id)
            cat.theoryRetakeAt = SkyDS.DB.GetRetake(citizenid, cat.id, 'theory')
            cat.practicalRetakeAt = SkyDS.DB.GetRetake(citizenid, cat.id, 'practical')
            cat.theoryPrice = full.theoryPrice
            cat.practicalPrice = full.practicalPrice
            categories[#categories + 1] = cat
        end
    end

    return {
        school = {
            id = school.id,
            label = school.label,
        },
        player = {
            citizenid = citizenid,
            firstName = first,
            lastName = last,
            bank = SkyDS.Bridge.GetMoney(src, 'bank'),
            cash = SkyDS.Bridge.GetMoney(src, 'cash'),
        },
        categories = categories,
        licenses = SkyDS.Licenses.GetCardData(src),
        history = SkyDS.DB.GetExamHistory(citizenid, 20),
        pointsHistory = SkyDS.DB.GetPointsHistory(citizenid, 25),
        stats = SkyDS.DB.GetStats(citizenid),
        locale = Config.Locale,
        strings = Locales[Config.Locale] or Locales.en,
        now = os.time(),
        requireTheory = Config.RequireTheoryBeforePractical,
        pointsEnabled = Config.Points and Config.Points.enabled,
        infractions = Config.Points and Config.Points.infractions or {},
        isAdmin = SkyDS.Admin.Can(src, 'viewStats') or SkyDS.Points.CanManage(src, 0, 'managePoints'),
        payment = Config.Payment,
    }
end

lib.callback.register('sky_drivingschool:server:openSchool', function(src, schoolId)
    if not SkyDS.AntiCheat.Allow(src, 'open_school') then
        return { ok = false, error = L('suspicious') }
    end
    local data = buildDashboard(src, schoolId)
    if not data then return { ok = false, error = L('invalid_school') } end
    return { ok = true, data = data }
end)

lib.callback.register('sky_drivingschool:server:startTheory', function(src, schoolId, categoryId)
    local ok, result = SkyDS.Theory.Start(src, schoolId, categoryId)
    if not ok then return { ok = false, error = result } end
    return { ok = true, exam = result }
end)

lib.callback.register('sky_drivingschool:server:submitTheory', function(src, answers)
    local ok, result = SkyDS.Theory.Submit(src, answers)
    if not ok then return { ok = false, error = result } end
    return { ok = true, result = result }
end)

lib.callback.register('sky_drivingschool:server:cancelTheory', function(src)
    SkyDS.Theory.Cancel(src, L('theory_cancelled'))
    return { ok = true }
end)

lib.callback.register('sky_drivingschool:server:startPractical', function(src, schoolId, categoryId)
    local ok, result = SkyDS.Practical.Start(src, schoolId, categoryId)
    if not ok then return { ok = false, error = result } end
    return { ok = true, exam = result }
end)

lib.callback.register('sky_drivingschool:server:registerExamVehicle', function(src, netId)
    return { ok = SkyDS.Practical.RegisterVehicle(src, netId) == true }
end)

lib.callback.register('sky_drivingschool:server:practicalInfraction', function(src, infraction, detail)
    local ok, state = SkyDS.Practical.ReportInfraction(src, infraction, detail)
    return { ok = ok, state = state }
end)

lib.callback.register('sky_drivingschool:server:finishPractical', function(src, payload)
    local ok, result = SkyDS.Practical.Finish(src, payload)
    if not ok then return { ok = false, error = result } end
    return { ok = true, result = result }
end)

lib.callback.register('sky_drivingschool:server:getLicenseCard', function(src, categoryId)
    if not SkyDS.AntiCheat.Allow(src, 'license_card') then
        return { ok = false, error = L('suspicious') }
    end
    local cards = SkyDS.Licenses.GetCardData(src)
    local first, last = SkyDS.Bridge.GetCharInfo(src)
    local selected = nil
    if categoryId then
        for _, c in ipairs(cards) do
            if c.category == categoryId then selected = c break end
        end
    end
    return {
        ok = true,
        firstName = first,
        lastName = last,
        cards = cards,
        selected = selected,
        title = L('card_title'),
        locale = Config.Locale,
    }
end)

lib.callback.register('sky_drivingschool:server:getHistory', function(src)
    local citizenid = SkyDS.Bridge.GetCitizenId(src)
    if not citizenid then return { ok = false } end
    return {
        ok = true,
        history = SkyDS.DB.GetExamHistory(citizenid, 40),
        pointsHistory = SkyDS.DB.GetPointsHistory(citizenid, 40),
    }
end)

-- Exports for other resources
exports('HasLicense', function(src, categoryId)
    return SkyDS.Licenses.Has(src, categoryId)
end)

exports('GrantLicense', function(src, categoryId, documentId)
    documentId = documentId or SkyDS.DB.NewDocumentId(categoryId)
    return SkyDS.Licenses.Grant(src, categoryId, documentId)
end)

exports('RevokeLicense', function(src, categoryId, reason, actorSrc)
    return SkyDS.Licenses.Revoke(src, categoryId, reason, actorSrc)
end)

exports('RemovePoints', function(src, categoryId, amount, reason, actorSrc)
    return SkyDS.Points.Remove(src, categoryId, amount, reason, actorSrc)
end)

exports('RestorePoints', function(src, categoryId, amount, reason, actorSrc)
    return SkyDS.Points.Restore(src, categoryId, amount, reason, actorSrc)
end)

exports('ApplyInfraction', function(src, infractionKey, reason, actorSrc, categoryId)
    return SkyDS.Points.ApplyInfraction(src, infractionKey, reason, actorSrc, categoryId)
end)

exports('GetLicenseCard', function(src)
    return SkyDS.Licenses.GetCardData(src)
end)

exports('IsExamActive', function(src)
    return SkyDS.ActiveExams[src] ~= nil
end)

RegisterCommand('dmvcard', function(src)
    if src == 0 then return end
    TriggerClientEvent('sky_drivingschool:client:showLicenseCard', src, nil)
end, false)

RegisterCommand('dmvadmin', function(src)
    if src == 0 then return end
    if not (SkyDS.Admin.Can(src, 'viewStats') or SkyDS.Points.CanManage(src, 0, 'managePoints')) then
        SkyDS.Bridge.Notify(src, 'DMV', L('no_permission'), 'error')
        return
    end
    TriggerClientEvent('sky_drivingschool:client:openAdmin', src)
end, false)
