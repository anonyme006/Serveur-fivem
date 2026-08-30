if Config.Modules and Config.Modules.duty == false then return end

--[[
    qbx-duty — client bootstrap
]]

CreateThread(function()
    Wait(1500)
    lib.callback('qbx_ressources:duty:server:getDuty', false, function()
        -- sync blips envoyé par le serveur
    end)
end)

print('^2[qbx_ressources]^0 client prêt — LocalPlayer.state.duty disponible')
