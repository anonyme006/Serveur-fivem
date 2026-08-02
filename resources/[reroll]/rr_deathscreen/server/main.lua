RegisterNetEvent('rr_deathscreen:server:callEms', function()
    local src = source
    local name = exports.rr_api:GetCharName(src) or GetPlayerName(src)
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local pos = { x = coords.x, y = coords.y, z = coords.z }
    local msg = ('%s a besoin d\'assistance médicale'):format(name)

    local ok = pcall(function()
        exports.rr_dispatch:Alert('10-52', msg, pos)
    end)

    if not ok then
        print(('[rr_deathscreen] EMS call from %s (dispatch unavailable)'):format(name))
    end

    exports.rr_api:Notify(src, 'RE ROLL', 'Les secours ont été alertés.', 'inform')
end)
