RegisterNetEvent('qbx_licenses:client:pointsUpdated', function(targetSrc, licenseType, entry)
    TriggerEvent('qbx_licenses:client:refreshCard', targetSrc)
end)

--- Commande / menu perso déjà côté server → showCard
RegisterNetEvent('qbx_licenses:client:showCard', function(ownerSrc)
    ownerSrc = tonumber(ownerSrc) or cache.serverId
    -- Montrer au joueur le plus proche si possible
    local coords = GetEntityCoords(cache.ped)
    local closest = lib.getClosestPlayer(coords, Config.TargetDistance or 2.5, false)
    if closest and closest ~= PlayerId() then
        local viewer = GetPlayerServerId(closest)
        TriggerServerEvent('qbx_licenses:server:showCard', viewer)
        lib.notify({
            title = 'Permis',
            description = 'Tu montres ta carte de permis.',
            type = 'success',
            icon = 'id-card',
        })
    end
    -- Toujours afficher aussi pour soi
    TriggerEvent('qbx_licenses:client:openCard', ownerSrc)
end)
