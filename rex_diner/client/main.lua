RexDiner = RexDiner or {}
RexDiner.IsTabletOpen = false
RexDiner.OnDuty = false
RexDiner.RestaurantKey = nil
RexDiner.Blips = {}

---@return string|nil
---@return table|nil
---@return number
---@return boolean
function RexDiner.GetLocalJob()
    local player = exports.qbx_core:GetPlayerData()
    if not player or not player.job then
        return nil, nil, 0, false
    end
    local key, restaurant = GetRestaurantByJob(player.job.name)
    local grade = player.job.grade and player.job.grade.level or 0
    local onDuty = player.job.onduty == true
    return key, restaurant, grade, onDuty
end

---@param permission string
---@return boolean
function RexDiner.HasLocalPermission(permission)
    local _, _, grade = RexDiner.GetLocalJob()
    return HasPermission(grade, permission)
end

function RexDiner.Notify(title, description, nType)
    lib.notify({
        title = title,
        description = description,
        type = nType or 'inform',
        duration = 5000,
    })
end

local function createBlips()
    for _, blip in pairs(RexDiner.Blips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end
    RexDiner.Blips = {}

    for key, restaurant in pairs(Config.Restaurants) do
        local blipCfg = restaurant.blip
        if blipCfg and blipCfg.enabled and blipCfg.coords then
            local blip = AddBlipForCoord(blipCfg.coords.x, blipCfg.coords.y, blipCfg.coords.z)
            SetBlipSprite(blip, blipCfg.sprite or 106)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, blipCfg.scale or 0.75)
            SetBlipColour(blip, blipCfg.color or 1)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(blipCfg.label or restaurant.label)
            EndTextCommandSetBlipName(blip)
            RexDiner.Blips[key] = blip
        end
    end
end

CreateThread(function()
    createBlips()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function()
    local key, _, _, onDuty = RexDiner.GetLocalJob()
    RexDiner.RestaurantKey = key
    RexDiner.OnDuty = onDuty
end)

RegisterNetEvent('qbx_core:client:onJobUpdate', function()
    local key, _, _, onDuty = RexDiner.GetLocalJob()
    RexDiner.RestaurantKey = key
    RexDiner.OnDuty = onDuty
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if RexDiner.IsTabletOpen then
        SetNuiFocus(false, false)
    end
    for _, blip in pairs(RexDiner.Blips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end
end)
