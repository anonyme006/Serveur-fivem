RegisterNetEvent('rr_evidence:server:open', function(id)
    local src = source
    if not exports.rr_api:HasPoliceJob(src, true) then return end
    local stash = Config.StashPrefix .. id
    exports.ox_inventory:RegisterStash(stash, 'Preuves ' .. id, 50, 200000)
    TriggerClientEvent('ox_inventory:openInventory', src, 'stash', stash)
end)
