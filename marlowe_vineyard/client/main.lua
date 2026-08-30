local blips = {}

local function notify(message, nType)
    lib.notify({
        title = Config.Label,
        description = message,
        type = nType or 'inform',
    })
end

local function isMarloweEmployee()
    return QBX.PlayerData
        and QBX.PlayerData.job
        and QBX.PlayerData.job.name == Config.Job
end

local function createBlips()
    for i = 1, #Config.Blips do
        local data = Config.Blips[i]
        local blip = AddBlipForCoord(data.coords.x, data.coords.y, data.coords.z)
        SetBlipSprite(blip, data.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, data.scale)
        SetBlipColour(blip, data.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(data.label)
        EndTextCommandSetBlipName(blip)
        blips[#blips + 1] = blip
    end
end

RegisterCommand(Config.Command, function()
    MarloweMenu.OpenMain()
end, false)

RegisterKeyMapping(Config.Command, 'Ouvrir le menu Marlowe Vineyard', 'keyboard', Config.OpenKey)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    createBlips()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    if LocalPlayer.state.isLoggedIn then
        createBlips()
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    for i = 1, #blips do
        RemoveBlip(blips[i])
    end
end)

exports('OpenMenu', function()
    MarloweMenu.OpenMain()
end)

exports('IsMarloweEmployee', function()
    return isMarloweEmployee()
end)
