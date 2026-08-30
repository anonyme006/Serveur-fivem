--[[
    Ferme le loading screen une fois le joueur en session.
]]

CreateThread(function()
    while true do
        Wait(500)
        if NetworkIsSessionStarted() then
            ShutdownLoadingScreen()
            ShutdownLoadingScreenNui()
            break
        end
    end
end)
