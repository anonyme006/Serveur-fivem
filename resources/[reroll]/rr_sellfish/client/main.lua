CreateThread(function()
    local c = Config.Ped.coords
    lib.requestModel(Config.Ped.model)
    local ped = CreatePed(0, Config.Ped.model, c.x, c.y, c.z - 1.0, c.w, false, false)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    exports.ox_target:addLocalEntity(ped, {{
        name = 'rr_sellfish',
        icon = 'fa-solid fa-fish',
        label = 'Vendre du poisson',
        onSelect = function()
            TriggerServerEvent('rr_sellfish:server:sell')
        end,
    }})
end)
