--[[
    Bootstrap serveur qbx_ressources — SQL unifié + modules
]]

local modules = Config.Modules or {}

MySQL.ready(function()
    local sql = LoadResourceFile(GetCurrentResourceName(), 'sql/qbx_ressources.sql')
    if not sql then
        print('^1[qbx_ressources]^0 sql/qbx_ressources.sql introuvable')
        return
    end

    for statement in sql:gmatch('([^;]+);') do
        local trimmed = statement:gsub('^%s+', ''):gsub('%s+$', '')
        if trimmed ~= '' and not trimmed:match('^%-%-') then
            MySQL.query.await(trimmed)
        end
    end

    print('^2[qbx_ressources]^0 schéma SQL unifié prêt')
end)

if modules.core ~= false then
    print('^2[qbx_ressources]^0 module core activé')
end

if modules.duty ~= false then
    print('^2[qbx_ressources]^0 module duty activé')
end

if modules.sleeping ~= false then
    print('^2[qbx_ressources]^0 module sleeping activé')
end
