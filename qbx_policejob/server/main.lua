--[[--------------------------------------------------------------------------
    Server bootstrap — intégration Qbox (PHASE 1)
---------------------------------------------------------------------------]]

PoliceServer = PoliceServer or {}

local function dependencyState(name)
    return GetResourceState(name)
end

local function assertDependencies()
    local required = {
        'ox_lib',
        'oxmysql',
        'qbx_core',
        'ox_target',
        'ox_inventory',
    }
    local missing = {}
    for i = 1, #required do
        local name = required[i]
        local state = dependencyState(name)
        if state ~= 'started' and state ~= 'starting' then
            missing[#missing + 1] = ('%s (%s)'):format(name, state)
        end
    end
    if #missing > 0 then
        print('[qbx_policejob] Missing/stopped dependencies:')
        for i = 1, #missing do
            print(('  - %s'):format(missing[i]))
        end
    end
end

local function logIntegrations()
    local integ = Config.Integrations or {}
    Police.Debug('Integrations snapshot:')
    Police.Debug(('  externalDuty: %s (%s)'):format(tostring(integ.externalDuty and integ.externalDuty.enabled), integ.externalDuty and integ.externalDuty.resource))
    Police.Debug(('  garage: %s (%s)'):format(tostring(integ.garage and integ.garage.enabled), integ.garage and integ.garage.resource))
    Police.Debug(('  appearance: %s (%s)'):format(tostring(integ.appearance and integ.appearance.enabled), integ.appearance and integ.appearance.resource))
    Police.Debug(('  phone provider: %s'):format(integ.phone and integ.phone.provider))
    Police.Debug(('  vehicles table: %s'):format(integ.vehicles and integ.vehicles.table))
    local lic = integ.licenses
    local licState = lic and GetResourceState(lic.resource or 'qbx_licenses') or 'n/a'
    Police.Debug(('  licenses: %s (%s) state=%s'):format(
        tostring(lic and lic.enabled),
        lic and lic.resource,
        licState
    ))
end

--- Infos joueur fiables (serveur)
---@param source number
---@return table|nil
function PoliceServer.GetPlayerInfo(source)
    return PoliceSecurity.GetPlayerInfo(source)
end

--- Argent (exports qbx_core)
---@param source number
---@param moneyType 'cash'|'bank'|'crypto'
---@return number
function PoliceServer.GetMoney(source, moneyType)
    local amount = exports.qbx_core:GetMoney(source, moneyType or 'cash')
    return type(amount) == 'number' and amount or 0
end

---@param source number
---@param moneyType 'cash'|'bank'|'crypto'
---@param amount number
---@param reason string|nil
---@return boolean
function PoliceServer.RemoveMoney(source, moneyType, amount, reason)
    amount = PoliceSecurity.SanitizeAmount(amount, 1)
    if not amount then return false end
    return exports.qbx_core:RemoveMoney(source, moneyType, amount, reason or 'qbx_policejob') == true
end

---@param source number
---@param moneyType 'cash'|'bank'|'crypto'
---@param amount number
---@param reason string|nil
---@return boolean
function PoliceServer.AddMoney(source, moneyType, amount, reason)
    amount = PoliceSecurity.SanitizeAmount(amount, 1)
    if not amount then return false end
    return exports.qbx_core:AddMoney(source, moneyType, amount, reason or 'qbx_policejob') == true
end

---@param source number
---@param onDuty boolean
---@return boolean
function PoliceServer.SetDuty(source, onDuty)
    local info = PoliceSecurity.GetPlayerInfo(source)
    if not info or not info.isLeo then return false end
    exports.qbx_core:SetJobDuty(source, onDuty == true)
    return true
end

--- Téléphone selon Config.Integrations.phone
---@param source number
---@return string
function PoliceServer.GetPhoneNumber(source)
    local info = PoliceSecurity.GetPlayerInfo(source)
    if not info then return '' end

    local provider = Config.Integrations.phone and Config.Integrations.phone.provider or 'qbx'
    if provider == 'qbx' then
        return info.phone or ''
    end

    -- Extensions futures (pulse-phone / npwd) sans forcer l'intégration
    return info.phone or ''
end

lib.callback.register('qbx_policejob:server:getPlayerInfo', function(source, target)
    local targetSrc = source
    if type(target) == 'number' and target > 0 then
        -- Infos cible uniquement pour un LEO en service
        local leo = PoliceSecurity.RequireLeo(source, true)
        if not leo then return nil end
        local near, err = PoliceSecurity.IsNearPlayer(source, target, Config.Distances.maxServer)
        if not near then
            PoliceSecurity.NotifyLocale(source, err or 'err_too_far', 'error')
            return nil
        end
        targetSrc = target
    end
    local info = PoliceServer.GetPlayerInfo(targetSrc)
    if info and PoliceLicenses then
        info = PoliceLicenses.AttachToPlayerInfo(info, targetSrc)
    end
    return info
end)

lib.callback.register('qbx_policejob:server:getSelfSnapshot', function(source)
    local info = PoliceServer.GetPlayerInfo(source)
    if info and PoliceLicenses then
        info = PoliceLicenses.AttachToPlayerInfo(info, source)
    end
    return info
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    assertDependencies()
    Police.BuildJobIndex()
    PoliceDB.EnsureSchema()
    PoliceDepartments.ValidateAgainstCore()
    logIntegrations()
    print('[qbx_policejob] PHASE 1 ready — architecture + Qbox bridge')
end)

exports('GetPlayerInfo', PoliceServer.GetPlayerInfo)
exports('GetMoney', PoliceServer.GetMoney)
exports('SetDuty', PoliceServer.SetDuty)
exports('GetPhoneNumber', PoliceServer.GetPhoneNumber)
