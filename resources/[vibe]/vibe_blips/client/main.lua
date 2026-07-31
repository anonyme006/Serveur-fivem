CreateThread(function()
    for _, b in ipairs(Config.Blips) do
        local blip = AddBlipForCoord(b.coords.x, b.coords.y, b.coords.z)
        SetBlipSprite(blip, b.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, b.scale or 0.8)
        SetBlipColour(blip, b.color or 0)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(b.title)
        EndTextCommandSetBlipName(blip)
    end
end)
