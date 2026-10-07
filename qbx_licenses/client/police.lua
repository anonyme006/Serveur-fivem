local function isPoliceJob()
    local pd = exports.qbx_core:GetPlayerData()
    if not pd or not pd.job then return false end
    local min = Config.PoliceJobs[pd.job.name]
    if min == nil then return false end
    if Config.RequireOnDuty and pd.job.onduty == false then return false end
    local grade = pd.job.grade and (pd.job.grade.level or pd.job.grade) or 0
    if type(grade) == 'table' then grade = grade.level or 0 end
    return (tonumber(grade) or 0) >= min
end

local function openRemovePointsDialog(targetId, license)
    local input = lib.inputDialog(L('menu_remove') .. ' — ' .. license.label, {
        {
            type = 'number',
            label = L('select_amount'),
            description = ('Actuel : %s / %s'):format(license.points, license.maxPoints),
            required = true,
            min = 1,
            max = math.max(1, license.points),
            default = 1,
        },
        {
            type = 'input',
            label = 'Motif (optionnel)',
            placeholder = 'Excès de vitesse, accident…',
        },
    })

    if not input then return end
    TriggerServerEvent('qbx_licenses:server:removePoints', targetId, license.name, input[1], input[2])
end

local function openPlayerLicenseMenu(targetId)
    local data = lib.callback.await('qbx_licenses:getTarget', false, targetId)
    if not data then
        return lib.notify({ title = 'Permis', description = L('no_perm'), type = 'error' })
    end

    local perms = lib.callback.await('qbx_licenses:canManage', false) or {}
    local options = {
        {
            title = data.name,
            description = ('ID %s · %s'):format(data.serverId, data.citizenid or '—'),
            icon = 'user',
            disabled = true,
        },
    }

    for _, lic in ipairs(data.licenses) do
        local status
        if lic.valid then
            status = ('%s pts'):format(lic.points)
        elseif lic.owned then
            status = 'Suspendu'
        else
            status = 'Non détenu'
        end

        options[#options + 1] = {
            title = lic.label,
            description = status .. (' / %s max'):format(lic.maxPoints),
            icon = lic.icon or 'id-card',
            metadata = {
                { label = 'Points', value = ('%s/%s'):format(lic.points, lic.maxPoints) },
                { label = 'État', value = lic.valid and 'Valide' or (lic.owned and 'Suspendu' or 'Non détenu') },
            },
            arrow = true,
            onSelect = function()
                local actions = {}

                if perms.police and lic.owned and lic.points > 0 then
                    actions[#actions + 1] = {
                        title = L('menu_remove'),
                        icon = 'minus',
                        description = 'Retirer des points de ce permis',
                        onSelect = function()
                            openRemovePointsDialog(targetId, lic)
                        end,
                    }
                end

                if perms.grant and not lic.valid then
                    actions[#actions + 1] = {
                        title = L('menu_grant'),
                        icon = 'plus',
                        onSelect = function()
                            TriggerServerEvent('qbx_licenses:server:grant', targetId, lic.name)
                        end,
                    }
                end

                if perms.revoke and lic.owned then
                    actions[#actions + 1] = {
                        title = L('menu_revoke'),
                        icon = 'ban',
                        onSelect = function()
                            TriggerServerEvent('qbx_licenses:server:revoke', targetId, lic.name)
                        end,
                    }
                end

                actions[#actions + 1] = {
                    title = 'Voir sur la carte',
                    icon = 'id-card',
                    onSelect = function()
                        TriggerEvent('qbx_licenses:client:openCard', targetId)
                    end,
                }

                if #actions == 0 then
                    lib.notify({ title = 'Permis', description = 'Aucune action disponible.', type = 'inform' })
                    return
                end

                lib.registerContext({
                    id = 'qbx_licenses_actions',
                    title = lic.label,
                    menu = 'qbx_licenses_player',
                    options = actions,
                })
                lib.showContext('qbx_licenses_actions')
            end,
        }
    end

    lib.registerContext({
        id = 'qbx_licenses_player',
        title = L('menu_player', targetId),
        options = options,
    })
    lib.showContext('qbx_licenses_player')
end

local function getClosestServerId()
    local coords = GetEntityCoords(cache.ped)
    local closest = lib.getClosestPlayer(coords, Config.TargetDistance or 2.5, false)
    if not closest then return nil end
    return GetPlayerServerId(closest)
end

--- Menu F6 / commande police
local function openPoliceMenu()
    if not isPoliceJob() then
        return lib.notify({ title = 'Permis', description = L('no_perm'), type = 'error' })
    end

    local targetId = getClosestServerId()
    if not targetId then
        return lib.notify({ title = 'Permis', description = L('no_nearby'), type = 'error' })
    end

    openPlayerLicenseMenu(targetId)
end

RegisterNetEvent('qbx_licenses:client:openPoliceMenu', openPoliceMenu)

lib.addKeybind({
    name = 'qbx_licenses_police',
    description = 'Gestion permis à points (police)',
    defaultKey = '',
    onPressed = openPoliceMenu,
})

lib.addCommand('permispolice', {
    help = 'Ouvrir la gestion des permis du joueur proche',
}, function()
    openPoliceMenu()
end)

-- ox_target sur les joueurs
CreateThread(function()
    if GetResourceState('ox_target') ~= 'started' then return end

    exports.ox_target:addGlobalPlayer({
        {
            name = 'qbx_licenses_manage',
            icon = 'fa-solid fa-id-card',
            label = L('ox_target_manage'),
            distance = Config.TargetDistance or 2.5,
            canInteract = function()
                return isPoliceJob()
            end,
            onSelect = function(data)
                local ped = data.entity
                if not ped or ped == 0 then return end
                local playerIdx = NetworkGetPlayerIndexFromPed(ped)
                if playerIdx == -1 then return end
                local sid = GetPlayerServerId(playerIdx)
                if sid and sid > 0 then
                    openPlayerLicenseMenu(sid)
                end
            end,
        },
    })
end)

exports('OpenPoliceMenu', openPoliceMenu)
exports('OpenPlayerLicenseMenu', openPlayerLicenseMenu)
