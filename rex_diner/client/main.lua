Rex = Rex or {}
Rex.IsTabletOpen = false
Rex.OnDuty = false
Rex.CurrentDelivery = nil
Rex.Blips = {}

function Rex.GetLocalJob()
    local data = exports.qbx_core:GetPlayerData()
    if not data or not data.job then return nil, nil, 0, false end
    local key, restaurant = Rex.GetRestaurantByJob(data.job.name)
    local grade = data.job.grade and data.job.grade.level or 0
    return key, restaurant, grade, data.job.onduty == true
end

function Rex.Can(permission)
    local _, _, grade = Rex.GetLocalJob()
    return Rex.HasPermission(grade, permission)
end

function Rex.Notify(title, description, nType)
    lib.notify({ title = title, description = description, type = nType or 'inform', duration = 5000 })
end

CreateThread(function()
    for key, restaurant in pairs(Config.Restaurants) do
        local cfg = restaurant.blip
        if cfg and cfg.enabled and cfg.coords then
            local blip = AddBlipForCoord(cfg.coords.x, cfg.coords.y, cfg.coords.z)
            SetBlipSprite(blip, cfg.sprite or 106)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, cfg.scale or 0.75)
            SetBlipColour(blip, cfg.color or 1)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(cfg.label or restaurant.label)
            EndTextCommandSetBlipName(blip)
            Rex.Blips[key] = blip
        end
    end
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function()
    local _, _, _, onDuty = Rex.GetLocalJob()
    Rex.OnDuty = onDuty
end)

RegisterNetEvent('qbx_core:client:onJobUpdate', function()
    local _, _, _, onDuty = Rex.GetLocalJob()
    Rex.OnDuty = onDuty
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if Rex.IsTabletOpen then SetNuiFocus(false, false) end
    for _, blip in pairs(Rex.Blips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end
end)
