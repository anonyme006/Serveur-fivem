Business = Business or {}

---@param name string
---@return table|nil
function Business.Get(name)
    return Config.Businesses[name]
end

---@param source number
---@param businessName string
---@return boolean, table|nil, table|nil
function Business.GetBossContext(source, businessName)
    local def = Business.Get(businessName)
    if not def then return false end
    local player = exports.rp_core:GetPlayer(source)
    if not player then return false end
    local job = player.PlayerData.job
    if not job or job.name ~= businessName then return false end
    local grade = job.grade and job.grade.level or 0
    local isBoss = job.isboss or grade >= (def.bossGrade or 99)
    return true, player, { def = def, job = job, grade = grade, isBoss = isBoss }
end

---@param businessName string
---@param amount number
---@param citizenid string
---@param txType string
---@param reason string
function Business.LogTransaction(businessName, amount, citizenid, txType, reason)
    MySQL.insert.await(
        'INSERT INTO rp_business_transactions (business, citizenid, type, amount, reason) VALUES (?, ?, ?, ?, ?)',
        { businessName, citizenid, txType, amount, reason or '' }
    )
end

---@param businessName string
---@param amount number
---@return boolean
function Business.AddMoney(businessName, amount)
    local def = Business.Get(businessName)
    local sanitized = tonumber(amount)
    if not def or not sanitized or sanitized < 1 then return false end
    sanitized = math.floor(sanitized)
    local ok = exports.rp_core:AddSocietyMoney(def.account, sanitized, 'rp_business')
    if ok then
        MySQL.update.await(
            'INSERT INTO rp_business_accounts (name, balance) VALUES (?, ?) ON DUPLICATE KEY UPDATE balance = balance + VALUES(balance)',
            { businessName, sanitized }
        )
    end
    return ok
end

---@param businessName string
---@param amount number
---@return boolean
function Business.RemoveMoney(businessName, amount)
    local def = Business.Get(businessName)
    local sanitized = tonumber(amount)
    if not def or not sanitized or sanitized < 1 then return false end
    sanitized = math.floor(sanitized)
    local ok = exports.rp_core:RemoveSocietyMoney(def.account, sanitized)
    if ok then
        MySQL.update.await(
            'UPDATE rp_business_accounts SET balance = GREATEST(0, balance - ?) WHERE name = ?',
            { sanitized, businessName }
        )
    end
    return ok
end

---@param businessName string
---@return number
function Business.GetBalance(businessName)
    local row = MySQL.single.await('SELECT balance FROM rp_business_accounts WHERE name = ?', { businessName })
    return row and row.balance or 0
end

exports('GetBusiness', Business.Get)
exports('AddBusinessMoney', Business.AddMoney)
exports('RemoveBusinessMoney', Business.RemoveMoney)
exports('GetBusinessBalance', Business.GetBalance)
exports('LogBusinessTransaction', Business.LogTransaction)
