local inside

CreateThread(function()
    for _, t in ipairs(Config.Territories) do
        local blip = AddBlipForRadius(t.coords.x, t.coords.y, t.coords.z, t.radius)
        SetBlipAlpha(blip, 80)
        local g = Config.Gangs[t.owner]
        SetBlipColour(blip, g and g.color or 0)
    end
end)

CreateThread(function()
    while true do
        local coords = GetEntityCoords(cache.ped)
        local found
        for _, t in ipairs(Config.Territories) do
            if #(coords - t.coords) <= t.radius then
                found = t
                break
            end
        end
        if found and (not inside or inside.id ~= found.id) then
            inside = found
            local owner = Config.Gangs[found.owner]
            lib.showTextUI(('%s — %s'):format(found.label, owner and owner.label or 'Libre'))
        elseif not found and inside then
            inside = nil
            lib.hideTextUI()
        end
        Wait(1000)
    end
end)

RegisterCommand('capture', function()
    if not inside then
        exports.vibe_api:Notify('Gangs', 'Tu n\'es pas dans un territoire.', 'error')
        return
    end
    if lib.progressCircle({
        duration = Config.CaptureSeconds * 1000,
        label = ('Capture de %s...'):format(inside.label),
        position = 'bottom',
        canCancel = true,
        disable = { car = true, combat = true },
    }) then
        TriggerServerEvent('vibe_gangs:server:capture', inside.id)
    end
end, false)
