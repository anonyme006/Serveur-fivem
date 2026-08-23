--- Bridge serveur vers qbx_core + ox_inventory + banque

RP = RP or {}

---@param source number
---@param message string
---@param nType? string
---@param duration? number
function Notify(source, message, nType, duration)
    TriggerClientEvent('rp_core:client:notify', source, message, nType or 'inform', duration)
end

exports('Notify', Notify)

---@param citizenid string
---@return table|nil
function RP.GetPlayerByCitizenId(citizenid)
    if not RP.Utils.IsString(citizenid) then return nil end
    return exports.qbx_core:GetPlayerByCitizenId(citizenid)
end

---@param source number
---@param moneyType 'cash'|'bank'
---@param amount number
---@param reason? string
---@return boolean
function RP.AddMoney(source, moneyType, amount, reason)
    local player = RP.GetPlayer(source)
    local sanitized = RP.Utils.SanitizeMoney(amount)
    if not player or not sanitized then return false end
    if moneyType ~= 'cash' and moneyType ~= 'bank' then return false end
    return player.Functions.AddMoney(moneyType, sanitized, reason or 'rp_core')
end

---@param source number
---@param moneyType 'cash'|'bank'
---@param amount number
---@param reason? string
---@return boolean
function RP.RemoveMoney(source, moneyType, amount, reason)
    local player = RP.GetPlayer(source)
    local sanitized = RP.Utils.SanitizeMoney(amount)
    if not player or not sanitized or sanitized < 1 then return false end
    if moneyType ~= 'cash' and moneyType ~= 'bank' then return false end
    return player.Functions.RemoveMoney(moneyType, sanitized, reason or 'rp_core')
end

---@param source number
---@param moneyType 'cash'|'bank'
---@return number
function RP.GetMoney(source, moneyType)
    local player = RP.GetPlayer(source)
    if not player then return 0 end
    return player.Functions.GetMoney(moneyType) or 0
end

--- Compatibilité Renewed-Banking (compte entreprise)
---@param account string
---@param amount number
---@param reason? string
---@return boolean
function RP.AddSocietyMoney(account, amount, reason)
    local sanitized = RP.Utils.SanitizeMoney(amount)
    if not sanitized or not RP.Utils.IsString(account) then return false end
    if Config.Banking == 'renewed' and GetResourceState('Renewed-Banking') == 'started' then
        local ok = pcall(function()
            exports['Renewed-Banking']:addAccountMoney(account, sanitized)
        end)
        return ok
    end
    -- fallback metadata / management
    if GetResourceState('qbx_management') == 'started' then
        -- qbx_management utilise souvent les comptes Renewed ; si absent, no-op sécurisé
        return false
    end
    return false
end

---@param account string
---@param amount number
---@return boolean
function RP.RemoveSocietyMoney(account, amount)
    local sanitized = RP.Utils.SanitizeMoney(amount)
    if not sanitized or sanitized < 1 or not RP.Utils.IsString(account) then return false end
    if Config.Banking == 'renewed' and GetResourceState('Renewed-Banking') == 'started' then
        local ok = pcall(function()
            exports['Renewed-Banking']:removeAccountMoney(account, sanitized)
        end)
        return ok
    end
    return false
end

---@param source number
---@param item string
---@param count? number
---@param metadata? table
---@return boolean
function RP.AddItem(source, item, count, metadata)
    if Config.Inventory ~= 'ox_inventory' then return false end
    if GetResourceState('ox_inventory') ~= 'started' then return false end
    count = tonumber(count) or 1
    if count < 1 or count > 1000 then return false end
    if not RP.Utils.IsString(item) then return false end
    return exports.ox_inventory:AddItem(source, item, count, metadata) and true or false
end

---@param source number
---@param item string
---@param count? number
---@param metadata? table
---@return boolean
function RP.RemoveItem(source, item, count, metadata)
    if GetResourceState('ox_inventory') ~= 'started' then return false end
    count = tonumber(count) or 1
    if count < 1 then return false end
    return exports.ox_inventory:RemoveItem(source, item, count, metadata) and true or false
end

exports('AddMoney', RP.AddMoney)
exports('RemoveMoney', RP.RemoveMoney)
exports('GetMoney', RP.GetMoney)
exports('AddSocietyMoney', RP.AddSocietyMoney)
exports('RemoveSocietyMoney', RP.RemoveSocietyMoney)
exports('AddItem', RP.AddItem)
exports('RemoveItem', RP.RemoveItem)
exports('GetPlayerByCitizenId', RP.GetPlayerByCitizenId)
