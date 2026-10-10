PortalQbx = PortalQbx or {}

local function hasExport(resource, exportName)
    local ok, result = pcall(function()
        return exports[resource][exportName]
    end)
    return ok and result ~= nil
end

function PortalQbx.isReady()
    return GetResourceState('qbx_core') == 'started'
end

---@return table|nil
function PortalQbx.getPlayer(source)
    if not PortalQbx.isReady() then return nil end

    if hasExport('qbx_core', 'GetPlayer') then
        local ok, player = pcall(function()
            return exports.qbx_core:GetPlayer(source)
        end)
        if ok and player then return player end
    end

    return nil
end

function PortalQbx.getCitizenId(player)
    if not player then return nil end
    if player.PlayerData and player.PlayerData.citizenid then
        return player.PlayerData.citizenid
    end
    return nil
end

function PortalQbx.getLicense(source, player)
    local license2 = GetPlayerIdentifierByType(source --[[@as string]], 'license2')
    local license = GetPlayerIdentifierByType(source --[[@as string]], 'license')
    if license2 and license2 ~= '' then return license2 end
    if license and license ~= '' then return license end
    if player and player.PlayerData and player.PlayerData.license then
        return player.PlayerData.license
    end
    return nil
end

function PortalQbx.getDiscordId(source)
    local discord = GetPlayerIdentifierByType(source --[[@as string]], 'discord')
    if not discord or discord == '' then return nil end
    return discord:gsub('^discord:', '')
end

function PortalQbx.getCharacterSnapshot(player)
    if not player or not player.PlayerData then return nil end
    local pd = player.PlayerData
    local money = pd.money or {}
    local charinfo = pd.charinfo or {}
    local metadata = pd.metadata or {}

    return {
        citizenid = pd.citizenid,
        cid = pd.cid,
        license = pd.license,
        name = pd.name,
        firstname = charinfo.firstname,
        lastname = charinfo.lastname,
        cash = money.cash or 0,
        bank = money.bank or 0,
        job = pd.job and pd.job.name or nil,
        playtime = metadata.playtime or 0,
    }
end
