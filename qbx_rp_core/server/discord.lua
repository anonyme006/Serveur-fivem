--[[
    Logger Discord — embeds + file d'attente anti rate-limit
]]

Core.Discord = Core.Discord or {}

local queue = {}
local sending = false

local function cfg()
    return Config.Discord or {}
end

local function getWebhook(category)
    local c = cfg()
    if not c.enabled then return nil end
    local cat = c.categories and c.categories[category]
    if cat and cat.enabled == false then return nil end
    local url = (cat and cat.webhook and cat.webhook ~= '' and cat.webhook) or c.defaultWebhook
    if not url or url == '' then return nil end
    return url
end

local function playerFields(src)
    if not src or src == 0 then return {} end
    local name = GetPlayerName(src) or ('ID %s'):format(src)
    local fields = {
        { name = 'Joueur', value = ('%s `[ID %s]`'):format(name, src), inline = true },
    }

    local identifier = Core.GetIdentifier and Core.GetIdentifier(src)
    if identifier then
        fields[#fields + 1] = { name = 'Identifier', value = ('`%s`'):format(identifier), inline = true }
    end

    if cfg().showIdentifiers then
        local ids = {}
        for i = 0, GetNumPlayerIdentifiers(src) - 1 do
            local id = GetPlayerIdentifier(src, i)
            if id and not id:find('ip:') then
                ids[#ids + 1] = id
            end
        end
        if #ids > 0 then
            fields[#fields + 1] = {
                name = 'IDs',
                value = '```' .. table.concat(ids, '\n') .. '```',
                inline = false,
            }
        end
    end

    return fields
end

local function processQueue()
    if sending then return end
    sending = true

    CreateThread(function()
        while #queue > 0 do
            local job = table.remove(queue, 1)
            local webhook = job.webhook
            local payload = json.encode(job.payload)

            PerformHttpRequest(webhook, function() end, 'POST', payload, {
                ['Content-Type'] = 'application/json',
            })

            Wait(tonumber(cfg().queueDelay) or 750)
        end
        sending = false
    end)
end

---@param category string
---@param title string
---@param description string|nil
---@param opts table|nil { color?, fields?, src?, footer?, image? }
function Core.Discord.Log(category, title, description, opts)
    opts = opts or {}
    local webhook = getWebhook(category)
    if not webhook then return false end

    local c = cfg()
    local colorKey = opts.color or 'info'
    local color = (c.colors and c.colors[colorKey]) or c.colors.info or 5793266

    local fields = opts.fields or {}
    if opts.src then
        for _, f in ipairs(playerFields(opts.src)) do
            fields[#fields + 1] = f
        end
    end

    local embed = {
        title = title,
        description = description or nil,
        color = color,
        fields = fields,
        footer = {
            text = opts.footer or ('qbx_rp_core • %s'):format(category),
        },
        timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
    }

    if opts.image then
        embed.image = { url = opts.image }
    end

    queue[#queue + 1] = {
        webhook = webhook,
        payload = {
            username = c.botName or 'VIBE QBox Logs',
            avatar_url = (c.botAvatar ~= '' and c.botAvatar) or nil,
            embeds = { embed },
        },
    }

    processQueue()
    return true
end

--- Raccourci global
function Core.Log(category, title, description, opts)
    return Core.Discord.Log(category, title, description, opts)
end

exports('DiscordLog', function(category, title, description, opts)
    return Core.Discord.Log(category, title, description, opts)
end)

exports('Log', function(category, title, description, opts)
    return Core.Discord.Log(category, title, description, opts)
end)
