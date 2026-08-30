--[[
    qbx-duty — client bootstrap
]]

CreateThread(function()
    Wait(1500)
    lib.callback('qbx-duty:server:getDuty', false, function()
        -- sync blips envoyé par le serveur
    end)
end)

print('^2[qbx-duty]^0 client prêt — LocalPlayer.state.duty disponible')
