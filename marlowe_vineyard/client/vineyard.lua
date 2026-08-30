local function notify(message, nType)
    lib.notify({
        title = Config.Label,
        description = message,
        type = nType or 'inform',
    })
end

local function canHarvest()
    if not QBX.PlayerData or QBX.PlayerData.job.name ~= Config.Job then
        return false
    end
    if Config.RequireDuty.Harvest and not QBX.PlayerData.job.onduty then
        return false
    end
    return QBX.PlayerData.job.grade.level >= Config.Production.Harvest.minGrade
end

local function playHarvestAnimation()
    local anim = Config.Production.Harvest.anim
    lib.requestAnimDict(anim.dict)
    TaskPlayAnim(cache.ped, anim.dict, anim.clip, 8.0, -8.0, -1, anim.flag, 0, false, false, false)
end

local function stopHarvestAnimation()
    ClearPedTasks(cache.ped)
end

function StartGrapeHarvest(zoneIndex)
    if not canHarvest() then
        notify(Config.Notifications.NoDuty, 'error')
        return
    end

    playHarvestAnimation()

    local success = lib.progressBar({
        duration = Config.Production.Harvest.duration,
        label = 'Récolte du raisin...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
        },
    })

    stopHarvestAnimation()

    if not success then return end

    local ok, result = lib.callback.await('marlowe:server:harvestGrapes', false, zoneIndex)
    if ok then
        notify(('Vous avez récolté %s raisins.'):format(result), 'success')
    else
        notify(result or Config.Notifications.Failed, 'error')
    end
end

CreateThread(function()
    for index, zone in ipairs(Config.Vineyard.HarvestZones) do
        exports.ox_target:addSphereZone({
            coords = zone.coords,
            radius = zone.radius,
            debug = false,
            options = {
                {
                    name = ('marlowe_harvest_%s'):format(index),
                    icon = 'fa-solid fa-grapes',
                    label = 'Récolter le raisin',
                    canInteract = function()
                        return canHarvest()
                    end,
                    onSelect = function()
                        StartGrapeHarvest(index)
                    end,
                    distance = 2.5,
                },
            },
        })
    end

    exports.ox_target:addSphereZone({
        coords = Config.Vineyard.ProductionPoint.coords,
        radius = Config.Vineyard.ProductionPoint.radius,
        debug = false,
        options = {
            {
                name = 'marlowe_production',
                icon = 'fa-solid fa-wine-bottle',
                label = 'Ouvrir la production',
                canInteract = function()
                    return QBX.PlayerData and QBX.PlayerData.job.name == Config.Job
                end,
                onSelect = function()
                    MarloweMenu.OpenProduction()
                end,
                distance = 2.0,
            },
        },
    })

    exports.ox_target:addSphereZone({
        coords = Config.Vineyard.StockPoint.coords,
        radius = Config.Vineyard.StockPoint.radius,
        debug = false,
        options = {
            {
                name = 'marlowe_stock',
                icon = 'fa-solid fa-boxes-stacked',
                label = 'Ouvrir le stock',
                canInteract = function()
                    return QBX.PlayerData and QBX.PlayerData.job.name == Config.Job
                end,
                onSelect = function()
                    MarloweMenu.OpenStock()
                end,
                distance = 2.0,
            },
        },
    })

    exports.ox_target:addSphereZone({
        coords = Config.Vineyard.MenuPoint.coords,
        radius = Config.Vineyard.MenuPoint.radius,
        debug = false,
        options = {
            {
                name = 'marlowe_menu',
                icon = 'fa-solid fa-wine-glass',
                label = 'Gestion du domaine',
                canInteract = function()
                    return QBX.PlayerData and QBX.PlayerData.job.name == Config.Job
                end,
                onSelect = function()
                    MarloweMenu.OpenMain()
                end,
                distance = 2.0,
            },
        },
    })

    exports.ox_target:addSphereZone({
        coords = Config.Vineyard.BossPoint.coords,
        radius = Config.Vineyard.BossPoint.radius,
        debug = false,
        options = {
            {
                name = 'marlowe_boss',
                icon = 'fa-solid fa-briefcase',
                label = 'Bureau direction',
                canInteract = function()
                    return QBX.PlayerData
                        and QBX.PlayerData.job.name == Config.Job
                        and QBX.PlayerData.job.grade.level >= Config.Permissions.Employees
                end,
                onSelect = function()
                    MarloweMenu.OpenBoss()
                end,
                distance = 2.0,
            },
        },
    })
end)
