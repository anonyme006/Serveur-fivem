local MODULE = 'gangs'

CoreCreator.RegisterModule(MODULE, {})

RegisterNetEvent('core_creator:gangs:setMember', function(targetId, gangName, grade)
    local src = source
    if not Permissions.Guard(src, MODULE) then return end
    targetId = tonumber(targetId)
    grade = tonumber(grade) or 0
    if not targetId or type(gangName) ~= 'string' then return end

    local gang = Database.GetByName(MODULE, gangName)
    if not gang or not gang.active then
        Bridge.Notify(src, _('error.not_found'), 'error')
        return
    end

    local identifier = Bridge.GetIdentifier(targetId)
    if Bridge.Framework == 'qbcore' or Bridge.Framework == 'qbox' then
        Bridge.SetPlayerGang(targetId, gangName, grade)
    end

    MySQL.query.await(
        'INSERT INTO core_creator_gang_members (gang_name, identifier, grade) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE grade = VALUES(grade)',
        { gangName, identifier, grade }
    )

    Bridge.Notify(src, 'Membre de gang mis à jour', 'success')
    Bridge.Notify(targetId, ('Gang: %s (grade %s)'):format(gang.label, grade), 'inform')
    Logger.Log(src, 'gang_set_member', MODULE, gang.id, { target = identifier, grade = grade })
end)

RegisterNetEvent('core_creator:gangs:removeMember', function(targetId, gangName)
    local src = source
    if not Permissions.Guard(src, MODULE) then return end
    targetId = tonumber(targetId)
    if not targetId or type(gangName) ~= 'string' then return end
    local identifier = Bridge.GetIdentifier(targetId)
    MySQL.update.await('DELETE FROM core_creator_gang_members WHERE gang_name = ? AND identifier = ?', { gangName, identifier })
    if Bridge.Framework == 'qbcore' or Bridge.Framework == 'qbox' then
        Bridge.SetPlayerGang(targetId, 'none', 0)
    end
    Logger.Log(src, 'gang_remove_member', MODULE, nil, { target = identifier, gang = gangName })
    Bridge.Notify(src, 'Membre retiré', 'success')
end)

RegisterNetEvent('core_creator:gangs:requestSync', function()
    TriggerClientEvent('core_creator:gangs:sync', source, Database.GetAll(MODULE, true))
end)

AddEventHandler('core_creator:databaseReady', function()
    Wait(100)
    TriggerClientEvent('core_creator:gangs:sync', -1, Database.GetAll(MODULE, true))
end)

AddEventHandler('core_creator:entityChanged', function(moduleName)
    if moduleName ~= MODULE then return end
    TriggerClientEvent('core_creator:gangs:sync', -1, Database.GetAll(MODULE, true))
end)

exports('GetGangMembers', function(gangName)
    return MySQL.query.await('SELECT * FROM core_creator_gang_members WHERE gang_name = ?', { gangName }) or {}
end)

exports('PlayerGang', function(src)
    local identifier = Bridge.GetIdentifier(src)
    return MySQL.single.await('SELECT * FROM core_creator_gang_members WHERE identifier = ? LIMIT 1', { identifier })
end)
