local function isAdmin(src)
    return IsPlayerAceAllowed(src, Config.AdminAce)
end

RegisterNetEvent('vibe_teleport:server:tpm', function()
    local src = source
    if not isAdmin(src) then return end
    TriggerClientEvent('vibe_teleport:client:tpm', src)
end)

RegisterNetEvent('vibe_teleport:server:point', function(id)
    local src = source
    if not isAdmin(src) then
        exports.vibe_api:Notify(src, 'TP', 'Admin uniquement.', 'error')
        return
    end
    for _, p in ipairs(Config.Points) do
        if p.id == id then
            TriggerClientEvent('vibe_teleport:client:go', src, p.coords)
            return
        end
    end
end)
