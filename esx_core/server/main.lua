local ESX = exports['es_extended']:getSharedObject()

MySQL.ready(function()
    local sql = LoadResourceFile(GetCurrentResourceName(), 'sql/esx_core.sql')
    if not sql then return end

    for statement in sql:gmatch('([^;]+);') do
        local trimmed = statement:gsub('^%s+', ''):gsub('%s+$', '')
        if trimmed ~= '' and not trimmed:match('^%-%-') then
            MySQL.query.await(trimmed)
        end
    end

    print('^2[esx_core]^0 tables SQL prêtes')
end)

--- Export helper joueur
function Core.GetPlayer(src)
    return ESX.GetPlayerFromId(src)
end

function Core.GetIdentifier(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    return xPlayer and xPlayer.identifier or nil
end

exports('GetIdentifier', Core.GetIdentifier)

lib.callback.register('esx_core:getIdentifier', function(source)
    return Core.GetIdentifier(source)
end)
