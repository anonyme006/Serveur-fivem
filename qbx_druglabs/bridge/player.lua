Bridge = Bridge or {}

local function getPlayer(source)
    return exports.qbx_core:GetPlayer(source)
end

---@param source number
---@return table|nil
function Bridge.GetPlayer(source)
    return getPlayer(source)
end

---@param source number
---@return string|nil
function Bridge.GetCitizenId(source)
    local player = getPlayer(source)
    return player and player.PlayerData and player.PlayerData.citizenid or nil
end

---@param source number
---@return string
function Bridge.GetCharName(source)
    local player = getPlayer(source)
    if not player or not player.PlayerData or not player.PlayerData.charinfo then
        return GetPlayerName(source) or ('ID %s'):format(source)
    end
    local info = player.PlayerData.charinfo
    return ('%s %s'):format(info.firstname or '', info.lastname or ''):gsub('%s+', ' '):gsub('^%s*(.-)%s*$', '%1')
end

---@param source number
---@param moneyType string
---@return number
function Bridge.GetMoney(source, moneyType)
    return exports.qbx_core:GetMoney(source, moneyType) or 0
end

---@param source number
---@param moneyType string
---@param amount number
---@param reason string
---@return boolean
function Bridge.RemoveMoney(source, moneyType, amount, reason)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end
    return exports.qbx_core:RemoveMoney(source, moneyType, amount, reason) == true
end

---@param source number
---@param moneyType string
---@param amount number
---@param reason string
---@return boolean
function Bridge.AddMoney(source, moneyType, amount, reason)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end
    return exports.qbx_core:AddMoney(source, moneyType, amount, reason) == true
end

---@param source number
---@param amount number
---@param reason string
---@return boolean, string|nil moneyType
function Bridge.TryCharge(source, amount, reason)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end

    if Config.Purchase.allowCash then
        local cash = Bridge.GetMoney(source, 'cash')
        if cash >= amount then
            if Bridge.RemoveMoney(source, 'cash', amount, reason) then
                return true, 'cash'
            end
        end
    end

    local moneyType = Config.Purchase.moneyType or 'bank'
    if Bridge.GetMoney(source, moneyType) >= amount then
        if Bridge.RemoveMoney(source, moneyType, amount, reason) then
            return true, moneyType
        end
    end

    return false
end

---@param source number
---@return string|nil, number
function Bridge.GetJob(source)
    local player = getPlayer(source)
    if not player or not player.PlayerData or not player.PlayerData.job then
        return nil, 0
    end
    local job = player.PlayerData.job
    return job.name, job.grade and job.grade.level or 0
end

---@param source number
---@return boolean
function Bridge.IsPolice(source)
    local jobName = Bridge.GetJob(source)
    return jobName ~= nil and Config.Police.jobs[jobName] == true
end

---@param source number
---@return boolean
function Bridge.IsAdmin(source)
    if IsPlayerAceAllowed(tostring(source), Config.Admin.ace) then
        return true
    end

    local ok, result = pcall(function()
        return exports.qbx_core:HasPermission(source, Config.Admin.permission)
    end)
    if ok and result then return true end

    ok, result = pcall(function()
        return exports.qbx_core:IsPlayerAceAllowed(source, Config.Admin.ace)
    end)
    return ok and result == true
end

---@param citizenid string
---@return number|nil
function Bridge.GetSourceByCitizenId(citizenid)
    local player = exports.qbx_core:GetPlayerByCitizenId(citizenid)
    return player and player.PlayerData and player.PlayerData.source or nil
end
