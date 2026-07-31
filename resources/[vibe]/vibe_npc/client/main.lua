CreateThread(function()
    for i, p in ipairs(Config.Peds) do
        lib.requestModel(p.model)
        local ped = CreatePed(0, p.model, p.coords.x, p.coords.y, p.coords.z - 1.0, p.coords.w, false, false)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        exports.ox_target:addLocalEntity(ped, {{
            name = 'vibe_npc_' .. i,
            icon = 'fa-solid fa-comments',
            label = p.label,
            onSelect = function()
                lib.alertDialog({ header = p.label, content = p.message, centered = true })
            end,
        }})
    end
end)
