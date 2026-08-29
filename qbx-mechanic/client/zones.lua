--- Zones garage — implémentation étape 3
--- Blips, duty, boss, stash, garage, repair/tuning zones

local zonesInitialized = false

local function createBlips()
    for mechanicId, mechanic in pairs(Config.Mechanics) do
        local blip = mechanic.blip
        if blip and blip.enabled and blip.coords then
            local handle = AddBlipForCoord(blip.coords.x, blip.coords.y, blip.coords.z)
            SetBlipSprite(handle, blip.sprite or 446)
            SetBlipDisplay(handle, 4)
            SetBlipScale(handle, blip.scale or 0.85)
            SetBlipColour(handle, blip.color or 5)
            SetBlipAsShortRange(handle, blip.shortRange ~= false)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString(blip.label or mechanic.label)
            EndTextCommandSetBlipName(handle)
        end
        Utils.Debug('Blip registered for', mechanicId)
    end
end

AddEventHandler('qbx-mechanic:client:playerReady', function()
    if zonesInitialized then return end
    zonesInitialized = true
    createBlips()
    Utils.Debug('Zones module initialized (blips only — étape 3 pour ox_target)')
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if QBX and QBX.PlayerData and QBX.PlayerData.citizenid then
        TriggerEvent('qbx-mechanic:client:playerReady')
    end
end)
