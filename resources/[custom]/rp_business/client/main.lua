RegisterNetEvent('rp_business:client:announce', function(label, message)
    lib.notify({
        title = label,
        description = message,
        type = 'inform',
        duration = 10000,
        position = 'top',
    })
end)

--- Ouverture coffre entreprise (ox_inventory)
RegisterCommand('coffreentreprise', function()
    local pd = exports.qbx_core:GetPlayerData()
    if not pd or not pd.job then return end
    local name = pd.job.name
    -- lecture config via event server would be better; stash id convention
    local stashId = name .. '_stash'
    exports.ox_inventory:openInventory('stash', stashId)
end, false)
