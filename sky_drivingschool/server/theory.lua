SkyDS = SkyDS or {}
SkyDS.Theory = SkyDS.Theory or {}

local QuestionBanks = {} -- category -> full questions with correct index
SkyDS.ActiveExams = SkyDS.ActiveExams or {}

local function loadBank(categoryId)
    if QuestionBanks[categoryId] then return QuestionBanks[categoryId] end
    local cat = SkyDS.GetCategory(categoryId)
    if not cat or not cat.theoryFile then return {} end
    local raw = LoadResourceFile(GetCurrentResourceName(), cat.theoryFile)
    if not raw then
        print(('[sky_drivingschool] Missing theory file: %s'):format(cat.theoryFile))
        return {}
    end
    local ok, data = pcall(json.decode, raw)
    if not ok or type(data) ~= 'table' then return {} end
    QuestionBanks[categoryId] = data.questions or data
    return QuestionBanks[categoryId]
end

--- Strip correct answers before sending to client
local function publicQuestions(bank, count)
    local shuffled = SkyDS.Shuffle(bank)
    local selected = {}
    local answerKey = {} -- [questionId] = correctIndexAfterShuffle
    local n = math.min(count, #shuffled)
    for i = 1, n do
        local q = shuffled[i]
        local answers = {}
        for ai, a in ipairs(q.answers or {}) do
            answers[#answers + 1] = { text = a, originalIndex = ai - 1 }
        end
        answers = SkyDS.Shuffle(answers)
        local correctPublic = 0
        local texts = {}
        for ai, a in ipairs(answers) do
            texts[#texts + 1] = a.text
            if a.originalIndex == (q.correct or 0) then
                correctPublic = ai - 1
            end
        end
        answerKey[q.id] = correctPublic
        selected[#selected + 1] = {
            id = q.id,
            question = q.question,
            answers = texts,
            image = q.image,
        }
    end
    return selected, answerKey
end

local function formatWait(seconds)
    seconds = math.max(0, math.floor(seconds))
    local m = math.floor(seconds / 60)
    local s = seconds % 60
    if m > 0 then return ('%dm %ds'):format(m, s) end
    return ('%ds'):format(s)
end

---@param src number
---@param schoolId string
---@param categoryId string
---@return boolean, table|string
function SkyDS.Theory.Start(src, schoolId, categoryId)
    if not SkyDS.AntiCheat.Allow(src, 'theory_start') then
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

    local retakeAt = SkyDS.DB.GetRetake(citizenid, categoryId, 'theory')
    local now = os.time()
    if retakeAt > now then
        return false, L('retake_wait', formatWait(retakeAt - now))
    end

    local bank = loadBank(categoryId)
    if #bank < 1 then return false, 'No theory questions configured.' end

    local paid, method, err = SkyDS.Payment.Charge(src, cat.theoryPrice, 'dmv_theory_' .. categoryId)
    if not paid then
        return false, L(err or 'payment_failed', cat.theoryPrice)
    end

    local questions, answerKey = publicQuestions(bank, cat.theoryQuestions or 15)
    local examId = ('TH-%s-%s'):format(citizenid, now)

    SkyDS.ActiveExams[src] = {
        id = examId,
        type = 'theory',
        schoolId = schoolId,
        category = categoryId,
        citizenid = citizenid,
        answerKey = answerKey,
        questionIds = (function()
            local ids = {}
            for _, q in ipairs(questions) do ids[#ids + 1] = q.id end
            return ids
        end)(),
        startedAt = now,
        expiresAt = now + (cat.theoryTimeSeconds or 600),
        paidAmount = cat.theoryPrice,
        paymentMethod = method,
        graded = false,
    }

    SkyDS.DB.BumpStats(citizenid, 'theory_attempts')
    SkyDS.Bridge.Notify(src, 'DMV', L('payment_success', cat.theoryPrice), 'success')
    SkyDS.Bridge.Notify(src, 'DMV', L('theory_started'), 'inform')

    return true, {
        examId = examId,
        category = categoryId,
        label = cat.label,
        questions = questions,
        timeSeconds = cat.theoryTimeSeconds or 600,
        passPercent = cat.theoryPassPercent or 80,
    }
end

---@param src number
---@param answers table map questionId -> selectedIndex
---@return boolean, table|string
function SkyDS.Theory.Submit(src, answers)
    if not SkyDS.AntiCheat.Allow(src, 'theory_submit') then
        return false, L('suspicious')
    end
    local exam = SkyDS.ActiveExams[src]
    if not exam or exam.type ~= 'theory' then return false, L('no_active_exam') end
    if exam.graded then
        SkyDS.AntiCheat.Flag(src, 'double_grade', { exam = exam.id })
        return false, L('suspicious')
    end

    local citizenid = SkyDS.Bridge.GetCitizenId(src)
    if citizenid ~= exam.citizenid then
        SkyDS.AntiCheat.Flag(src, 'identity_mismatch', {})
        return false, L('suspicious')
    end

    exam.graded = true
    local now = os.time()
    local timedOut = now > (exam.expiresAt + 5) -- small grace for latency
    local cat = SkyDS.GetCategory(exam.category)
    local total = #(exam.questionIds or {})
    local correct = 0
    local review = {}

    answers = type(answers) == 'table' and answers or {}
    for _, qid in ipairs(exam.questionIds or {}) do
        local expected = exam.answerKey[qid]
        local given = tonumber(answers[qid])
        local ok = given ~= nil and given == expected
        if ok then correct = correct + 1 end
        review[#review + 1] = {
            id = qid,
            correct = ok,
            expected = expected,
            given = given,
        }
    end

    local percent = total > 0 and math.floor((correct / total) * 100 + 0.5) or 0
    local passPercent = cat and cat.theoryPassPercent or 80
    local passed = (not timedOut) and percent >= passPercent

    SkyDS.DB.InsertExam({
        citizenid = exam.citizenid,
        school_id = exam.schoolId,
        category = exam.category,
        exam_type = 'theory',
        passed = passed,
        score = percent,
        max_score = 100,
        errors = review,
        duration_seconds = now - exam.startedAt,
        paid_amount = exam.paidAmount,
        payment_method = exam.paymentMethod,
    })

    if passed then
        SkyDS.DB.SetTheoryPass(exam.citizenid, exam.category, percent)
        SkyDS.DB.BumpStats(exam.citizenid, 'theory_passes')
        SkyDS.DB.ClearRetake(exam.citizenid, exam.category, 'theory')
        SkyDS.Bridge.Notify(src, 'DMV', L('theory_passed', percent), 'success')
    else
        local delay = (Config.RetakeDelay and Config.RetakeDelay.theory) or 0
        if delay > 0 then
            SkyDS.DB.SetRetake(exam.citizenid, exam.category, 'theory', now + delay)
        end
        if timedOut then
            SkyDS.Bridge.Notify(src, 'DMV', L('theory_timeout'), 'error')
        else
            SkyDS.Bridge.Notify(src, 'DMV', L('theory_failed', percent, passPercent), 'error')
        end
    end

    SkyDS.ActiveExams[src] = nil

    return true, {
        passed = passed,
        score = percent,
        correct = correct,
        total = total,
        passPercent = passPercent,
        timedOut = timedOut,
        review = review,
        category = exam.category,
        label = cat and cat.label or exam.category,
    }
end

function SkyDS.Theory.Cancel(src, reason)
    local exam = SkyDS.ActiveExams[src]
    if not exam or exam.type ~= 'theory' then return end
    SkyDS.ActiveExams[src] = nil
    SkyDS.Bridge.Notify(src, 'DMV', reason or L('theory_cancelled'), 'error')
end

-- Load banks on resource start
CreateThread(function()
    Wait(500)
    for id, cat in pairs(Config.Categories or {}) do
        if cat.enabled then loadBank(id) end
    end
end)
