local hudVisible = Config.Enabled

local function setHudVisible(state)
    hudVisible = state and Config.Enabled
    SendNUIMessage({ action = 'hud:toggle', show = hudVisible })
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    setHudVisible(true)
end)

RegisterNetEvent('qbx_core:client:playerLoggedOut', function()
    setHudVisible(false)
end)

CreateThread(function()
    Wait(800)
    if LocalPlayer.state.isLoggedIn then
        setHudVisible(true)
    end
end)

CreateThread(function()
    local wasPaused = false

    while true do
        if hudVisible and LocalPlayer.state.isLoggedIn and Config.General.showVoice then
            SendNUIMessage({
                action = 'hud:update',
                data = {
                    talking = NetworkIsPlayerTalking(cache.playerId),
                },
            })
            Wait(250)
        else
            Wait(1000)
        end

        if Config.General.hideWhenPaused then
            local paused = IsPauseMenuActive()
            if paused ~= wasPaused then
                SendNUIMessage({ action = 'hud:toggle', show = not paused and hudVisible })
                wasPaused = paused
            end
        end
    end
end)

RegisterCommand('hud', function()
    setHudVisible(not hudVisible)
end, false)

exports('SetHudVisible', setHudVisible)
exports('IsHudVisible', function()
    return hudVisible
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    if GetResourceState('qbx_hud') == 'started' then
        print('^3[pn-hud]^7 qbx_hud est actif — désactivez-le dans server.cfg pour éviter les conflits.^0')
    end
end)
