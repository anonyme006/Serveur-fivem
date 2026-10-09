SkyDS = SkyDS or {}
SkyDS.Licenses = SkyDS.Licenses or {}

local function detectLicenseSystem()
    local pref = Config.LicenseSystem or 'auto'
    if pref ~= 'auto' then return pref end
    if GetResourceState('qbx_licenses') == 'started' then return 'qbx_licenses' end
    if GetResourceState('qbx_core') == 'started' then return 'qbox' end
    if GetResourceState('qb-core') == 'started' then return 'qbcore' end
    if GetResourceState('esx_license') == 'started' then return 'esx_license' end
    return 'custom'
end

function SkyDS.Licenses.GetSystem()
    SkyDS._licenseSystem = SkyDS._licenseSystem or detectLicenseSystem()
    return SkyDS._licenseSystem
end

local function readQboxLicences(player)
    local meta = player.PlayerData and player.PlayerData.metadata or {}
    return meta.licences or meta.licenses or {}
end

local function writeQboxLicences(player, licences)
    player.Functions.SetMetaData('licences', licences)
end

---@param src number
---@param categoryId string
---@return boolean
function SkyDS.Licenses.Has(src, categoryId)
    local cat = SkyDS.GetCategory(categoryId)
    if not cat then return false end
    local system = SkyDS.Licenses.GetSystem()
    local player = SkyDS.Bridge.GetPlayer(src)
    if not player then return false end

    -- Always check our SQL table for status/points accuracy
    local citizenid = SkyDS.Bridge.GetCitizenId(src)
    local row = citizenid and SkyDS.DB.GetLicense(citizenid, categoryId)
    if row then
        if row.status == 'revoked' or row.status == 'suspended' then return false end
        if (tonumber(row.points) or 0) <= (Config.Points.suspendAt or 0) then return false end
        return true
    end

    if system == 'qbx_licenses' then
        local key = cat.qbxLicensesKey or cat.licenseKey
        local ok, result = pcall(function()
            return exports.qbx_licenses:HasLicense(src, key)
        end)
        if ok and result then return true end
    end

    if system == 'qbox' or system == 'qbcore' or system == 'qbx_licenses' then
        local licences = readQboxLicences(player)
        local key = cat.licenseKey
        local entry = licences[key]
        if entry == true then return true end
        if type(entry) == 'table' then
            if entry.owned == false then return false end
            if entry.points and entry.points <= (Config.Points.suspendAt or 0) then return false end
            return entry.owned == true or entry.valid == true or entry == true
        end
        return false
    end

    if system == 'esx_license' then
        local has = false
        local p = promise.new()
        TriggerEvent('esx_license:getLicenses', src, function(licenses)
            for _, lic in pairs(licenses or {}) do
                if lic.type == cat.esxLicense then has = true break end
            end
            p:resolve(true)
        end)
        Citizen.Await(p)
        return has
    end

    return false
end

---@param src number
---@param categoryId string
---@param documentId string
---@return boolean, string
function SkyDS.Licenses.Grant(src, categoryId, documentId)
    local cat = SkyDS.GetCategory(categoryId)
    if not cat then return false, 'invalid_category' end
    local player = SkyDS.Bridge.GetPlayer(src)
    if not player then return false, 'no_player' end
    local citizenid = SkyDS.Bridge.GetCitizenId(src)
    if not citizenid then return false, 'no_citizenid' end

    if SkyDS.Licenses.Has(src, categoryId) then
        return false, 'already_licensed'
    end

    local maxPoints = SkyDS.MaxPoints(categoryId)
    local system = SkyDS.Licenses.GetSystem()

    -- Persist in our table (source of truth for points card)
    SkyDS.DB.UpsertLicense(citizenid, categoryId, documentId, 'valid', maxPoints, maxPoints)

    if system == 'qbx_licenses' then
        local key = cat.qbxLicensesKey or cat.licenseKey
        pcall(function()
            exports.qbx_licenses:GrantLicense(src, key, src)
        end)
    end

    if system == 'qbox' or system == 'qbcore' or system == 'qbx_licenses' then
        local licences = readQboxLicences(player)
        local key = cat.licenseKey
        if system == 'qbx_licenses' then
            licences[key] = { owned = true, points = maxPoints }
        else
            -- Keep boolean compatibility with stock Qbox driver licence
            if key == 'driver' or key == 'weapon' or key == 'id' then
                licences[key] = true
            else
                licences[key] = { owned = true, points = maxPoints, valid = true }
            end
        end
        writeQboxLicences(player, licences)
    elseif system == 'esx_license' then
        TriggerEvent('esx_license:addLicense', src, cat.esxLicense)
    end

    if Config.GiveLicenseItem and cat.item then
        SkyDS.Bridge.AddItem(src, cat.item, 1, {
            category = categoryId,
            documentId = documentId,
            points = maxPoints,
            maxPoints = maxPoints,
            status = 'valid',
            label = cat.label,
            description = ('%s — %s/%s pts'):format(cat.label, maxPoints, maxPoints),
        })
    end

    SkyDS.DB.BumpStats(citizenid, 'licenses_earned')
    SkyDS.DB.InsertPointsHistory({
        citizenid = citizenid,
        category = categoryId,
        action = 'grant',
        infraction = nil,
        points_delta = maxPoints,
        points_before = 0,
        points_after = maxPoints,
        reason = 'License issued after practical exam',
        actor_citizenid = 'system',
        actor_name = 'DMV',
    })

    return true, 'ok'
end

---@param src number
---@param categoryId string
---@param reason string
---@param actorSrc number|nil
---@return boolean, string
function SkyDS.Licenses.Revoke(src, categoryId, reason, actorSrc)
    local cat = SkyDS.GetCategory(categoryId)
    if not cat then return false, 'invalid_category' end
    local player = SkyDS.Bridge.GetPlayer(src)
    if not player then return false, 'no_player' end
    local citizenid = SkyDS.Bridge.GetCitizenId(src)
    local row = SkyDS.DB.GetLicense(citizenid, categoryId)
    local before = row and tonumber(row.points) or 0

    SkyDS.DB.UpsertLicense(citizenid, categoryId, row and row.document_id or SkyDS.DB.NewDocumentId(categoryId), 'revoked', 0, SkyDS.MaxPoints(categoryId))

    local system = SkyDS.Licenses.GetSystem()
    if system == 'qbx_licenses' then
        pcall(function()
            exports.qbx_licenses:RevokeLicense(src, cat.qbxLicensesKey or cat.licenseKey, actorSrc, reason)
        end)
    end
    if system == 'qbox' or system == 'qbcore' or system == 'qbx_licenses' then
        local licences = readQboxLicences(player)
        local key = cat.licenseKey
        if type(licences[key]) == 'table' then
            licences[key] = { owned = false, points = 0 }
        else
            licences[key] = false
        end
        writeQboxLicences(player, licences)
    elseif system == 'esx_license' then
        TriggerEvent('esx_license:removeLicense', src, cat.esxLicense)
    end

    local actorCid = actorSrc and SkyDS.Bridge.GetCitizenId(actorSrc) or 'system'
    local actorLabel = 'System'
    if actorSrc then
        local first, last = SkyDS.Bridge.GetCharInfo(actorSrc)
        actorLabel = ((first or '') .. ' ' .. (last or '')):gsub('^%s+', ''):gsub('%s+$', '')
        if actorLabel == '' then actorLabel = 'Officer' end
    end
    SkyDS.DB.InsertPointsHistory({
        citizenid = citizenid,
        category = categoryId,
        action = 'revoke',
        points_delta = -before,
        points_before = before,
        points_after = 0,
        reason = reason or 'Revoked',
        actor_citizenid = actorCid,
        actor_name = actorLabel,
    })

    return true, 'ok'
end

---@param src number
---@return table[]
function SkyDS.Licenses.GetCardData(src)
    local citizenid = SkyDS.Bridge.GetCitizenId(src)
    if not citizenid then return {} end
    local first, last = SkyDS.Bridge.GetCharInfo(src)
    local rows = SkyDS.DB.GetLicenses(citizenid)
    local byCat = {}
    for _, row in ipairs(rows) do
        byCat[row.category] = row
    end

    local cards = {}
    for id, cat in pairs(Config.Categories) do
        if cat.enabled then
            local row = byCat[id]
            local maxPoints = SkyDS.MaxPoints(id)
            local points = row and tonumber(row.points) or 0
            local status = row and row.status or 'none'
            if not row then
                -- Fallback: check framework boolean licences
                if SkyDS.Licenses.Has(src, id) then
                    status = 'valid'
                    points = maxPoints
                else
                    status = 'none'
                end
            else
                status = SkyDS.LicenseStatus(status, points, maxPoints)
            end
            cards[#cards + 1] = {
                category = id,
                label = cat.label,
                short = cat.short,
                icon = cat.icon,
                color = cat.color,
                points = points,
                maxPoints = maxPoints,
                status = status,
                documentId = row and row.document_id or nil,
                issuedAt = row and row.issued_at or nil,
                firstName = first,
                lastName = last,
            }
        end
    end
    table.sort(cards, function(a, b) return a.label < b.label end)
    return cards
end

---@param src number
---@param categoryId string
---@return boolean, string|nil
function SkyDS.Licenses.CheckRequirements(src, categoryId)
    local cat = SkyDS.GetCategory(categoryId)
    if not cat then return false, L('invalid_category') end
    if cat.requires then
        for _, req in ipairs(cat.requires) do
            if not SkyDS.Licenses.Has(src, req) then
                local reqCat = SkyDS.GetCategory(req)
                return false, L('missing_requirement', reqCat and reqCat.label or req)
            end
        end
    end
    return true
end
