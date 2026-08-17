PoliceClient = {}

function PoliceClient.OpenMenu(labId)
    local lab = ClientLabs.Get(labId)
    if not lab then return end

    lib.registerContext({
        id = 'druglab_police_' .. labId,
        title = 'Police — ' .. lab.label,
        options = {
            {
                title = 'Force Entry / Raid',
                icon = 'shield-halved',
                onSelect = function()
                    local result = lib.callback.await('qbx_druglabs:server:raidLab', false, labId)
                    if not result or not result.ok then
                        Bridge.Notify(nil, { description = result and result.error or 'Denied', type = 'error' })
                        return
                    end
                    Bridge.Notify(nil, { description = 'Raid authorized — enter the laboratory.', type = 'success' })
                    Interiors.Enter(labId)
                end,
            },
            {
                title = lab.sealed and 'Remove Seal' or 'Seal Laboratory',
                icon = 'ban',
                onSelect = function()
                    local cb = lab.sealed and 'qbx_druglabs:server:unsealLab' or 'qbx_druglabs:server:sealLab'
                    local result = lib.callback.await(cb, false, labId)
                    Bridge.Notify(nil, {
                        description = result and result.ok and 'Updated' or (result and result.error or 'Failed'),
                        type = result and result.ok and 'success' or 'error',
                    })
                end,
            },
            {
                title = 'Search Storage (if inside/sealed)',
                icon = 'magnifying-glass',
                onSelect = function()
                    local result = lib.callback.await('qbx_druglabs:server:openStash', false, labId)
                    if not result or not result.ok then
                        Bridge.Notify(nil, { description = result and result.error or 'Denied', type = 'error' })
                    end
                end,
            },
        },
    })
    lib.showContext('druglab_police_' .. labId)
end
