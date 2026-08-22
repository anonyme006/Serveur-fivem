--[[
    Bridge QBox — qbx_rp_core
]]

local QBX = exports.qbx_core

MySQL.ready(function()
    local sql = LoadResourceFile(GetCurrentResourceName(), 'sql/qbx_rp_core.sql')
    if not sql then return end

    for statement in sql:gmatch('([^;]+);') do
        local trimmed = statement:gsub('^%s+', ''):gsub('%s+$', '')
        if trimmed ~= '' and not trimmed:match('^%-%-') then
            MySQL.query.await(trimmed)
        end
    end

    print('^2[qbx_rp_core]^0 tables SQL prêtes')
end)

--- Joueur QBox
function Core.GetPlayer(src)
    return QBX:GetPlayer(src)
end

function Core.GetIdentifier(src)
    local player = QBX:GetPlayer(src)
    return player and player.PlayerData and player.PlayerData.citizenid or nil
end

function Core.GetPlayerName(src)
    local player = QBX:GetPlayer(src)
    if not player or not player.PlayerData or not player.PlayerData.charinfo then
        return GetPlayerName(src) or ('ID %s'):format(src)
    end
    local c = player.PlayerData.charinfo
    return (('%s %s'):format(c.firstname or '', c.lastname or '')):gsub('^%s+', ''):gsub('%s+$', '')
end

function Core.GetMoney(src, account)
    local player = QBX:GetPlayer(src)
    if not player then return 0 end
    account = account == 'money' and 'cash' or (account or 'cash')
    return player.Functions.GetMoney(account) or 0
end

function Core.RemoveMoney(src, account, amount, reason)
    local player = QBX:GetPlayer(src)
    if not player then return false end
    account = account == 'money' and 'cash' or (account or 'cash')
    return player.Functions.RemoveMoney(account, amount, reason or 'qbx_rp_core')
end

function Core.AddMoney(src, account, accountAmount, reason)
    local player = QBX:GetPlayer(src)
    if not player then return false end
    account = account == 'money' and 'cash' or (account or 'cash')
    return player.Functions.AddMoney(account, accountAmount, reason or 'qbx_rp_core')
end

--- Crédite un citizenid hors-ligne (table `players.money` JSON)
function Core.AddMoneyOffline(citizenid, account, amount)
    if not citizenid or not amount or amount <= 0 then return false end
    account = account == 'money' and 'cash' or (account or 'cash')
    local row = MySQL.single.await('SELECT money FROM players WHERE citizenid = ? LIMIT 1', { citizenid })
    if not row or not row.money then return false end
    local money = Core.DecodeJson(row.money)
    money[account] = (tonumber(money[account]) or 0) + amount
    MySQL.update.await('UPDATE players SET money = ? WHERE citizenid = ?', {
        json.encode(money), citizenid
    })
    return true
end

function Core.GetJobGrade(player)
    local job = Core.GetJob(player)
    if not job then return 0 end
    if type(job.grade) == 'table' then
        return tonumber(job.grade.level) or 0
    end
    return tonumber(job.grade) or 0
end

function Core.GetPlayerFromCitizenId(citizenid)
    if not citizenid then return nil end
    local ok, player = pcall(function()
        return QBX:GetPlayerByCitizenId(citizenid)
    end)
    if ok and player then return player end
    return nil
end

function Core.IsAdmin(src)
    if src == 0 then return true end
    local groups = (Config.Weather and Config.Weather.adminGroups) or { admin = true, god = true }
    for group in pairs(groups) do
        local ok, allowed = pcall(function()
            return QBX:HasPermission(src, group)
        end)
        if ok and allowed then return true end
        if IsPlayerAceAllowed(src, 'group.' .. group) then return true end
    end
    return false
end

function Core.RegisterUsableItem(item, cb)
    -- QBox / ox_inventory : export client préféré ; fallback CreateUseableItem
    local ok = pcall(function()
        QBX:CreateUseableItem(item, function(source, _item)
            cb(source, _item)
        end)
    end)
    if not ok then
        print(('^3[qbx_rp_core]^0 CreateUseableItem indisponible pour %s (utilise export ox_inventory)'):format(item))
    end
end

exports('GetIdentifier', Core.GetIdentifier)
exports('GetPlayerName', Core.GetPlayerName)
exports('GetMoney', Core.GetMoney)

lib.callback.register('qbx_rp_core:getIdentifier', function(source)
    return Core.GetIdentifier(source)
end)
