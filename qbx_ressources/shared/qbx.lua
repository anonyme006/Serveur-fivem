--[[
    Helpers joueur QBox (citizenid, argent, job)
]]

function Core.GetCitizenId(playerOrSrc)
    if type(playerOrSrc) == 'number' then
        return Core.GetIdentifier(playerOrSrc)
    end
    return playerOrSrc and playerOrSrc.PlayerData and playerOrSrc.PlayerData.citizenid or nil
end

function Core.GetJob(player)
    return player and player.PlayerData and player.PlayerData.job or nil
end

function Core.NormalizeAccount(account)
    if account == 'money' then return 'cash' end
    return account or 'cash'
end
