CreateThread(function()
    local c = Config.Ped.coords
    lib.requestModel(Config.Ped.model)
    local ped = CreatePed(0, Config.Ped.model, c.x, c.y, c.z - 1.0, c.w, false, false)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    exports.ox_target:addLocalEntity(ped, {{
        name = 'vibe_sellfish',
        icon = 'fa-solid fa-fish',
        label = 'Vendre du poisson',
        onSelect = function()
            TriggerServerEvent('vibe_sellfish:server:sell')
        end,
    }})
end)
