--[[--------------------------------------------------------------------------
    Client — gestion permis à points via qbx_licenses (PATCH_qbx_idcard)
---------------------------------------------------------------------------]]

PoliceLicensesClient = PoliceLicensesClient or {}

---@return boolean
local function licensesEnabled()
    local cfg = Config.Integrations and Config.Integrations.licenses
    return cfg and cfg.enabled ~= false
end

---@return string
local function licensesResource()
    local cfg = Config.Integrations and Config.Integrations.licenses
    return (cfg and cfg.resource) or 'qbx_licenses'
end

---@return boolean
function PoliceLicensesClient.IsAvailable()
    if not licensesEnabled() then return false end
    return GetResourceState(licensesResource()) == 'started'
end

---@param targetId number|nil
local function openNativeMenu(targetId)
    local resource = licensesResource()
    if targetId and targetId > 0 then
        local ok = pcall(function()
            exports[resource]:OpenPlayerLicenseMenu(targetId)
        end)
        if ok then return true end
    end

    local ok = pcall(function()
        exports[resource]:OpenPoliceMenu()
    end)
    return ok
end

---@return number|nil
local function closestServerId()
    local coords = GetEntityCoords(cache.ped)
    local closest = lib.getClosestPlayer(coords, Config.Distances.interaction or 2.5, false)
    if not closest then return nil end
    return GetPlayerServerId(closest)
end

--- Ouvre la gestion permis (menu natif qbx_licenses ou fallback ox_lib)
---@param targetId number|nil
function PoliceLicensesClient.OpenManage(targetId)
    if not PoliceClient.IsOnDuty() then
        return PoliceClient.Notify(Police.Locale('err_not_onduty'), 'error')
    end

    local snap = PoliceClient.GetSnapshot()
    if not snap.isLeo or not Police.HasPermission(snap.job, snap.grade, 'licenses') then
        return PoliceClient.Notify(Police.Locale('err_no_permission'), 'error')
    end

    if not PoliceLicensesClient.IsAvailable() then
        return PoliceClient.Notify(Police.Locale('licenses_unavailable'), 'error')
    end

    targetId = tonumber(targetId) or closestServerId()
    if not targetId then
        return PoliceClient.Notify(Police.Locale('licenses_no_nearby'), 'error')
    end

    local cfg = Config.Integrations.licenses
    if cfg.useNativeMenu ~= false and openNativeMenu(targetId) then
        return
    end

    -- Fallback : affichage lecture seule + retrait de points simple
    local data = lib.callback.await('qbx_policejob:server:getLicenses', false, targetId)
    if not data or not data.licenses then
        return PoliceClient.Notify(Police.Locale('licenses_unavailable'), 'error')
    end

    local options = {}
    for name, lic in pairs(data.licenses) do
        local statusKey = lic.status == 'valid' and 'licenses_status_valid'
            or (lic.status == 'suspended' and 'licenses_status_suspended' or 'licenses_status_missing')

        options[#options + 1] = {
            title = name,
            description = ('%s — %s pts'):format(Police.Locale(statusKey), lic.points or 0),
            icon = 'id-card',
            onSelect = function()
                if not lic.owned or (lic.points or 0) <= 0 then return end
                local input = lib.inputDialog(Police.Locale('licenses_remove_title'), {
                    {
                        type = 'number',
                        label = Police.Locale('licenses_remove_amount'),
                        required = true,
                        min = 1,
                        max = math.max(1, lic.points),
                        default = 1,
                    },
                    {
                        type = 'input',
                        label = Police.Locale('licenses_remove_reason'),
                    },
                })
                if not input then return end
                TriggerServerEvent(
                    'qbx_policejob:server:removeLicensePoints',
                    targetId,
                    name,
                    input[1],
                    input[2]
                )
            end,
        }
    end

    table.sort(options, function(a, b) return a.title < b.title end)

    lib.registerContext({
        id = 'qbx_policejob_licenses',
        title = Police.Locale('licenses_menu_title'),
        options = options,
    })
    lib.showContext('qbx_policejob_licenses')
end

RegisterNetEvent('qbx_policejob:client:openLicenses', function(targetId)
    PoliceLicensesClient.OpenManage(targetId)
end)

--- Commande /permis — joueur proche
CreateThread(function()
    local cmd = Config.Commands and Config.Commands.licenses
    if not cmd or cmd == '' then return end

    lib.addCommand(cmd, {
        help = Police.Locale('licenses_command_help'),
    }, function()
        PoliceLicensesClient.OpenManage()
    end)
end)

--- Option ox_target (complète celle de qbx_licenses si absente)
CreateThread(function()
    if not Config.UseTarget then return end
    if GetResourceState('ox_target') ~= 'started' then return end

    -- Évite le double menu si qbx_licenses gère déjà le target
    if PoliceLicensesClient.IsAvailable() then
        Police.Debug('qbx_licenses started — skip duplicate ox_target licenses option')
        return
    end

    exports.ox_target:addGlobalPlayer({
        {
            name = 'qbx_policejob_licenses',
            icon = 'fa-solid fa-id-card',
            label = Police.Locale('licenses_target'),
            distance = Config.Distances.target or 2.0,
            canInteract = function()
                return PoliceClient.IsOnDuty()
                    and Police.HasPermission(
                        PoliceClient.GetSnapshot().job,
                        PoliceClient.GetSnapshot().grade,
                        'licenses'
                    )
            end,
            onSelect = function(data)
                local ped = data.entity
                if not ped or ped == 0 then return end
                local idx = NetworkGetPlayerIndexFromPed(ped)
                if idx == -1 then return end
                PoliceLicensesClient.OpenManage(GetPlayerServerId(idx))
            end,
        },
    })
end)

exports('OpenLicenseManage', PoliceLicensesClient.OpenManage)
exports('LicensesAvailable', PoliceLicensesClient.IsAvailable)
