SkyDS = SkyDS or {}
SkyDS.Payment = SkyDS.Payment or {}

--- Attempt payment preferring bank then cash based on config.
---@param src number
---@param amount number
---@param reason string
---@return boolean success, string|nil method, string|nil errorKey
function SkyDS.Payment.Charge(src, amount, reason)
    amount = math.floor(tonumber(amount) or 0)
    if amount < 0 then return false, nil, 'payment_failed' end
    if amount == 0 then return true, 'free', nil end

    local cfg = Config.Payment or {}
    local order = {}
    if cfg.preferBank then
        if cfg.allowBank then order[#order + 1] = 'bank' end
        if cfg.allowCash then order[#order + 1] = 'cash' end
    else
        if cfg.allowCash then order[#order + 1] = 'cash' end
        if cfg.allowBank then order[#order + 1] = 'bank' end
    end

    for _, method in ipairs(order) do
        local balance = SkyDS.Bridge.GetMoney(src, method)
        if balance >= amount then
            if SkyDS.Bridge.RemoveMoney(src, method, amount, reason or 'dmv_exam') then
                if cfg.societyAccount and amount > 0 then
                    pcall(function()
                        if GetResourceState('Renewed-Banking') == 'started' then
                            exports['Renewed-Banking']:addAccountMoney(cfg.societyAccount, amount)
                        elseif GetResourceState('qb-management') == 'started' then
                            exports['qb-management']:AddMoney(cfg.societyAccount, amount)
                        end
                    end)
                end
                return true, method, nil
            end
        end
    end

    return false, nil, 'insufficient_funds'
end

---@param src number
---@param amount number
---@param method string
---@param reason string
function SkyDS.Payment.Refund(src, amount, method, reason)
    amount = math.floor(tonumber(amount) or 0)
    if amount < 1 then return end
    method = method or 'bank'
    SkyDS.Bridge.AddMoney(src, method, amount, reason or 'dmv_refund')
end
