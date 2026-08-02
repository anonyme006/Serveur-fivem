local tracked = {}

RegisterCommand('bracelet', function()
    if not exports.rr_api:IsPolice(true) then return end
    local input = lib.inputDialog('Bracelet', {
        { type = 'number', label = 'ID joueur', required = true, min = 1 },
        { type = 'select', label = 'Action', options = {
            { value = 'add', label = 'Poser' },
            { value = 'remove', label = 'Retirer' },
        }, required = true },
    })
    if not input then return end
    TriggerServerEvent('rr_bracelet:server:set', tonumber(input[1]), input[2] == 'add')
end, false)

RegisterNetEvent('rr_bracelet:client:sync', function(list)
    for _, blip in pairs(tracked) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end
    tracked = {}
    for src, coords in pairs(list or {}) do
        local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(blip, Config.BlipSprite)
        SetBlipColour(blip, 1)
        SetBlipScale(blip, 0.7)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(('Bracelet #%s'):format(src))
        EndTextCommandSetBlipName(blip)
        tracked[src] = blip
    end
end)
