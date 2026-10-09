SkyDS = SkyDS or {}
SkyDS.Practical = SkyDS.Practical or {}
SkyDS.ActiveExams = SkyDS.ActiveExams or {}
SkyDS.ExamVehicles = SkyDS.ExamVehicles or {} -- [src] = netId

local function formatWait(seconds)
    seconds = math.max(0, math.floor(seconds))
    local m = math.floor(seconds / 60)
    local s = seconds % 60
    if m > 0 then return ('%dm %ds'):format(m, s) end
    return ('%ds'):format(s)
end

local function deleteExamVehicle(src)
    local netId = SkyDS.ExamVehicles[src]
    if not netId then return end
    local entity = NetworkGetEntityFromNetworkId(netId)
    if entity and entity ~= 0 and DoesEntityExist(entity) then
        DeleteEntity(entity)
    end
    SkyDS.ExamVehicles[src] = nil
end

---@param src number
---@param schoolId string
---@param categoryId string
---@return boolean, table|string
function SkyDS.Practical.Start(src, schoolId, categoryId)
    if not SkyDS.AntiCheat.Allow(src, 'practical_start') then
        return false, L('suspicious')
    end
    if SkyDS.ActiveExams[src] then return false, L('exam_active') end

    local cat = SkyDS.GetCategory(categoryId)
    local school = SkyDS.GetSchool(schoolId)
    if not cat or not cat.enabled then return false, L('invalid_category') end
    if not school or not SkyDS.SchoolOffers(school, categoryId) then return false, L('invalid_school') end

    local citizenid = SkyDS.Bridge.GetCitizenId(src)
    if not citizenid then return false, L('player_not_found') end

    if SkyDS.Licenses.Has(src, categoryId) then
        return false, L('already_licensed', cat.label)
    end

    local okReq, reqErr = SkyDS.Licenses.CheckRequirements(src, categoryId)
    if not okReq then return false, reqErr end

    if Config.RequireTheoryBeforePractical and not SkyDS.DB.HasTheoryPass(citizenid, categoryId) then
        return false, L('theory_required')
    end

    local retakeAt = SkyDS.DB.GetRetake(citizenid, categoryId, 'practical')
    local now = os.time()
    if retakeAt > now then
        return false, L('retake_wait', formatWait(retakeAt - now))
    end

    local route = school.routes and school.routes[categoryId]
    local spawn = school.spawn and school.spawn[categoryId]
    if not route or not spawn then
        return false, 'Practical route not configured for this category.'
    end

    local paid, method, err = SkyDS.Payment.Charge(src, cat.practicalPrice, 'dmv_practical_' .. categoryId)
    if not paid then
        return false, L(err or 'payment_failed', cat.practicalPrice)
    end

    local examId = ('PR-%s-%s'):format(citizenid, now)
    local scoring = Config.PracticalScoring or {}

    SkyDS.ActiveExams[src] = {
        id = examId,
        type = 'practical',
        schoolId = schoolId,
        category = categoryId,
        citizenid = citizenid,
        startedAt = now,
        expiresAt = now + (scoring.timeLimitSeconds or 600),
        paidAmount = cat.practicalPrice,
        paymentMethod = method,
        graded = false,
        vehicleNetId = nil,
        score = scoring.startingScore or 100,
        errorCount = 0,
        checkpointsHit = 0,
        checkpointTotal = #(route.checkpoints or {}),
        infractions = {},
    }

    SkyDS.DB.BumpStats(citizenid, 'practical_attempts')
    SkyDS.Bridge.Notify(src, 'DMV', L('payment_success', cat.practicalPrice), 'success')
    SkyDS.Bridge.Notify(src, 'DMV', L('practical_started'), 'inform')

    local cps = {}
    for _, cp in ipairs(route.checkpoints or {}) do
        cps[#cps + 1] = { x = cp.x, y = cp.y, z = cp.z }
    end

    return true, {
        examId = examId,
        category = categoryId,
        label = cat.label,
        vehicleModel = cat.practicalVehicle,
        vehicleType = cat.vehicleType,
        spawn = { x = spawn.x, y = spawn.y, z = spawn.z, w = spawn.w or spawn[4] or 0.0 },
        checkpoints = cps,
        speedLimitMph = route.speedLimitMph or 45,
        zoneCenter = { x = route.zoneCenter.x, y = route.zoneCenter.y, z = route.zoneCenter.z },
        zoneRadius = route.zoneRadius or 400.0,
        timeLimit = scoring.timeLimitSeconds or 600,
        startingScore = scoring.startingScore or 100,
        passScore = scoring.passScore or 70,
        maxErrors = scoring.maxErrors or 8,
        deductions = scoring.deductions,
        speedToleranceMph = scoring.speedToleranceMph or 5,
        checkpointRadius = (cat.vehicleType == 'air' and scoring.airCheckpointRadius)
            or (cat.vehicleType == 'boat' and scoring.boatCheckpointRadius)
            or scoring.checkpointRadius or 8.0,
        requireTakeoff = route.requireTakeoff,
        requireLanding = route.requireLanding,
        minAltitude = route.minAltitude,
        graceZone = (Config.AntiCheat and Config.AntiCheat.zoneGraceMeters) or 35.0,
    }
end

---@param src number
---@param netId number
function SkyDS.Practical.RegisterVehicle(src, netId)
    local exam = SkyDS.ActiveExams[src]
    if not exam or exam.type ~= 'practical' then return false end
    netId = tonumber(netId)
    if not netId then return false end
    exam.vehicleNetId = netId
    SkyDS.ExamVehicles[src] = netId
    return true
end

---@param src number
---@param infraction string
---@param detail table|nil
---@return boolean, table|nil
function SkyDS.Practical.ReportInfraction(src, infraction, detail)
    if not SkyDS.AntiCheat.Allow(src, 'practical_infraction') then return false end
    local exam = SkyDS.ActiveExams[src]
    if not exam or exam.type ~= 'practical' or exam.graded then return false end

    local scoring = Config.PracticalScoring or {}
    local deductions = scoring.deductions or {}
    local amount = tonumber(deductions[infraction]) or 0
    if amount <= 0 and infraction ~= 'checkpoint' then return false end

    if infraction == 'checkpoint' then
        exam.checkpointsHit = (exam.checkpointsHit or 0) + 1
        return true, { score = exam.score, checkpointsHit = exam.checkpointsHit }
    end

    -- Deduplicate spammy infractions with short window
    exam._lastInf = exam._lastInf or {}
    local last = exam._lastInf[infraction] or 0
    local now = os.time()
    if (now - last) < 2 and infraction ~= 'missed_checkpoint' then
        return true, { score = exam.score, errorCount = exam.errorCount }
    end
    exam._lastInf[infraction] = now

    exam.score = math.max(0, (exam.score or 100) - amount)
    exam.errorCount = (exam.errorCount or 0) + 1
    exam.infractions[#exam.infractions + 1] = {
        type = infraction,
        amount = amount,
        detail = detail,
        at = now,
    }

    local failNow = exam.score < (scoring.passScore or 70)
        or exam.errorCount > (scoring.maxErrors or 8)
        or infraction == 'death'
        or infraction == 'abandon'

    return true, {
        score = exam.score,
        errorCount = exam.errorCount,
        failNow = failNow,
        deduction = amount,
    }
end

---@param src number
---@param payload table
---@return boolean, table|string
function SkyDS.Practical.Finish(src, payload)
    if not SkyDS.AntiCheat.Allow(src, 'practical_finish') then
        return false, L('suspicious')
    end
    local exam = SkyDS.ActiveExams[src]
    if not exam or exam.type ~= 'practical' then return false, L('no_active_exam') end
    if exam.graded then
        SkyDS.AntiCheat.Flag(src, 'double_grade_practical', { exam = exam.id })
        return false, L('suspicious')
    end

    local citizenid = SkyDS.Bridge.GetCitizenId(src)
    if citizenid ~= exam.citizenid then
        SkyDS.AntiCheat.Flag(src, 'identity_mismatch', {})
        return false, L('suspicious')
    end

    local okPayload, why = SkyDS.AntiCheat.ValidatePracticalPayload(exam, payload or {})
    if not okPayload then
        SkyDS.AntiCheat.Flag(src, why or 'bad_practical', payload)
        -- Still grade from server state; ignore client pass claim
        payload = payload or {}
    end

    exam.graded = true
    local scoring = Config.PracticalScoring or {}
    local now = os.time()

    -- Merge client-reported infractions cautiously into server tally already tracked
    if type(payload.clientErrors) == 'table' then
        for _, e in ipairs(payload.clientErrors) do
            if type(e) == 'table' and e.type and not e._applied then
                -- already applied live via ReportInfraction for most; ignore duplicates
            end
        end
    end

    local checkpointsHit = math.max(exam.checkpointsHit or 0, tonumber(payload.checkpointsHit) or 0)
    if checkpointsHit > exam.checkpointTotal then
        SkyDS.AntiCheat.Flag(src, 'checkpoint_overflow', { hit = checkpointsHit, total = exam.checkpointTotal })
        checkpointsHit = exam.checkpointTotal
    end

    -- Missed checkpoints penalty if finished early without completing route
    local missed = exam.checkpointTotal - checkpointsHit
    if missed > 0 and not (payload.reason == 'death' or payload.reason == 'abandon') then
        local per = (scoring.deductions and scoring.deductions.missed_checkpoint) or 10
        exam.score = math.max(0, exam.score - (missed * per))
        exam.errorCount = exam.errorCount + missed
        exam.infractions[#exam.infractions + 1] = { type = 'missed_checkpoint', amount = missed * per, count = missed }
    end

    if payload.reason == 'death' then
        exam.score = 0
        exam.infractions[#exam.infractions + 1] = { type = 'death', amount = 100 }
    elseif payload.reason == 'abandon' then
        exam.score = 0
        exam.infractions[#exam.infractions + 1] = { type = 'abandon', amount = 100 }
    elseif payload.reason == 'overtime' then
        local amt = (scoring.deductions and scoring.deductions.overtime) or 15
        exam.score = math.max(0, exam.score - amt)
        exam.infractions[#exam.infractions + 1] = { type = 'overtime', amount = amt }
    end

    local passed = exam.score >= (scoring.passScore or 70)
        and exam.errorCount <= (scoring.maxErrors or 8)
        and checkpointsHit >= exam.checkpointTotal
        and payload.reason ~= 'death'
        and payload.reason ~= 'abandon'

    -- Client cannot force pass
    if payload.passed == true and not passed then
        SkyDS.AntiCheat.Flag(src, 'forced_pass_attempt', { client = payload, serverScore = exam.score })
    end

    local cat = SkyDS.GetCategory(exam.category)
    local documentId = nil

    if passed then
        documentId = SkyDS.DB.NewDocumentId(exam.category)
        local granted, gerr = SkyDS.Licenses.Grant(src, exam.category, documentId)
        if not granted then
            -- Duplicate license race: still record pass
            SkyDS.Debug('Grant failed after pass:', gerr)
        else
            SkyDS.Bridge.Notify(src, 'DMV', L('license_granted', cat.label, SkyDS.MaxPoints(exam.category), SkyDS.MaxPoints(exam.category)), 'success')
            if Config.ShowCardOnGrant then
                TriggerClientEvent('sky_drivingschool:client:showLicenseCard', src, exam.category)
            end
        end
        SkyDS.DB.BumpStats(exam.citizenid, 'practical_passes')
        SkyDS.DB.ClearRetake(exam.citizenid, exam.category, 'practical')
        SkyDS.Bridge.Notify(src, 'DMV', L('practical_passed', exam.score), 'success')
    else
        local delay = (Config.RetakeDelay and Config.RetakeDelay.practical) or 0
        if delay > 0 then
            SkyDS.DB.SetRetake(exam.citizenid, exam.category, 'practical', now + delay)
        end
        SkyDS.Bridge.Notify(src, 'DMV', L('practical_failed', exam.score), 'error')
    end

    SkyDS.DB.InsertExam({
        citizenid = exam.citizenid,
        school_id = exam.schoolId,
        category = exam.category,
        exam_type = 'practical',
        passed = passed,
        score = exam.score,
        max_score = scoring.startingScore or 100,
        errors = exam.infractions,
        duration_seconds = now - exam.startedAt,
        paid_amount = exam.paidAmount,
        payment_method = exam.paymentMethod,
        document_id = documentId,
    })

    deleteExamVehicle(src)
    SkyDS.ActiveExams[src] = nil

    return true, {
        passed = passed,
        score = exam.score,
        passScore = scoring.passScore or 70,
        errors = exam.infractions,
        errorCount = exam.errorCount,
        checkpointsHit = checkpointsHit,
        checkpointTotal = exam.checkpointTotal,
        category = exam.category,
        label = cat and cat.label or exam.category,
        documentId = documentId,
    }
end

function SkyDS.Practical.Cancel(src, reason, refund)
    local exam = SkyDS.ActiveExams[src]
    if not exam or exam.type ~= 'practical' then
        deleteExamVehicle(src)
        return
    end
    if refund and exam.paidAmount and exam.paymentMethod then
        SkyDS.Payment.Refund(src, exam.paidAmount, exam.paymentMethod, 'dmv_practical_cancel')
    end
    deleteExamVehicle(src)
    SkyDS.ActiveExams[src] = nil
    SkyDS.Bridge.Notify(src, 'DMV', reason or L('practical_cancelled'), 'error')
end

function SkyDS.Practical.ForceFail(src, reason)
    local exam = SkyDS.ActiveExams[src]
    if not exam or exam.type ~= 'practical' or exam.graded then return end
    SkyDS.Practical.Finish(src, { reason = reason or 'abandon', checkpointsHit = exam.checkpointsHit or 0 })
end

AddEventHandler('playerDropped', function()
    local src = source
    if SkyDS.ActiveExams[src] then
        if Config.AntiCheat and Config.AntiCheat.disconnectFailExam then
            local exam = SkyDS.ActiveExams[src]
            if exam.type == 'practical' and not exam.graded then
                exam.graded = true
                SkyDS.DB.InsertExam({
                    citizenid = exam.citizenid,
                    school_id = exam.schoolId,
                    category = exam.category,
                    exam_type = 'practical',
                    passed = false,
                    score = 0,
                    max_score = 100,
                    errors = { { type = 'disconnect' } },
                    duration_seconds = os.time() - exam.startedAt,
                    paid_amount = exam.paidAmount,
                    payment_method = exam.paymentMethod,
                })
                local delay = (Config.RetakeDelay and Config.RetakeDelay.practical) or 0
                if delay > 0 then
                    SkyDS.DB.SetRetake(exam.citizenid, exam.category, 'practical', os.time() + delay)
                end
            elseif exam.type == 'theory' then
                SkyDS.ActiveExams[src] = nil
            end
        end
        SkyDS.ActiveExams[src] = nil
    end
    deleteExamVehicle(src)
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for src, _ in pairs(SkyDS.ExamVehicles) do
        deleteExamVehicle(src)
    end
end)
