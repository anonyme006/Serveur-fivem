RegisterCommand('tpm', function()
    TriggerServerEvent('vibe_teleport:server:tpm')
end, false)

RegisterCommand('tp', function()
    local options = {}
    for _, p in ipairs(Config.Points) do
        options[#options+1] = {
            title = p.label,
            onSelect = function()
                TriggerServerEvent('vibe_teleport:server:point', p.id)
            end,
        }
    end
    lib.registerContext({ id = 'vibe_tp', title = 'Téléportations', options = options })
    lib.showContext('vibe_tp')
end, false)

RegisterNetEvent('vibe_teleport:client:go', function(coords)
    DoScreenFadeOut(200)
    Wait(250)
    SetEntityCoords(cache.ped, coords.x, coords.y, coords.z, false, false, false, false)
    if coords.w then SetEntityHeading(cache.ped, coords.w) end
    DoScreenFadeIn(300)
end)

RegisterNetEvent('vibe_teleport:client:tpm', function()
    local blip = GetFirstBlipInfoId(8)
    if not DoesBlipExist(blip) then
        exports.vibe_api:Notify('TP', 'Pas de marqueur.', 'error')
        return
    end
    local coords = GetBlipInfoIdCoord(blip)
    local x, y, z = coords.x, coords.y, 0.0
    for i = 1, 1000 do
        local found, groundZ = GetGroundZFor_3dCoord(x, y, i + 0.0, false)
        if found then z = groundZ break end
    end
    SetPedCoordsKeepVehicle(cache.ped, x, y, z + 1.0)
end)
