PortalDB = PortalDB or {}

local function dbg(msg)
    if Config.Debug then
        print(('[qbx_player_portal:db] %s'):format(msg))
    end
end

function PortalDB.logSyncError(sourceName, citizenid, errorCode, message, payload)
    MySQL.insert.await([[
        INSERT INTO portal_sync_errors (source, citizenid, error_code, message, payload_json)
        VALUES (?, ?, ?, ?, ?)
    ]], {
        sourceName,
        citizenid,
        errorCode,
        message,
        payload and json.encode(payload) or nil,
    })
end

function PortalDB.createLinkCode(codeHash, citizenid, license, fivemDiscordId, expiresAt)
    return MySQL.insert.await([[
        INSERT INTO portal_link_codes
            (code_hash, citizenid, license, fivem_discord_id, expires_at)
        VALUES (?, ?, ?, ?, FROM_UNIXTIME(?))
    ]], { codeHash, citizenid, license, fivemDiscordId, expiresAt })
end

function PortalDB.openPlaytimeSession(citizenid, license, sessionToken)
    -- Ferme toute session ouverte restante (anti double-comptage)
    MySQL.update.await([[
        UPDATE portal_playtime_sessions
        SET ended_at = NOW(),
            seconds = TIMESTAMPDIFF(SECOND, started_at, NOW())
        WHERE citizenid = ? AND ended_at IS NULL
    ]], { citizenid })

    return MySQL.insert.await([[
        INSERT INTO portal_playtime_sessions
            (citizenid, license, started_at, session_token)
        VALUES (?, ?, NOW(), ?)
    ]], { citizenid, license, sessionToken })
end

function PortalDB.closePlaytimeSession(sessionToken)
    return MySQL.update.await([[
        UPDATE portal_playtime_sessions
        SET ended_at = NOW(),
            seconds = TIMESTAMPDIFF(SECOND, started_at, NOW())
        WHERE session_token = ? AND ended_at IS NULL
    ]], { sessionToken })
end

function PortalDB.heartbeatPlaytime(sessionToken)
    -- Ne compte pas deux fois : on ne fait que vérifier que la session est toujours ouverte
    local row = MySQL.single.await([[
        SELECT id FROM portal_playtime_sessions
        WHERE session_token = ? AND ended_at IS NULL
        LIMIT 1
    ]], { sessionToken })
    return row ~= nil
end

function PortalDB.addActivity(citizenid, category, summary, meta)
    MySQL.insert.await([[
        INSERT INTO portal_activities (citizenid, category, summary, meta_json)
        VALUES (?, ?, ?, ?)
    ]], { citizenid, category, summary, meta and json.encode(meta) or nil })
end

function PortalDB.addNotification(citizenid, title, body, level)
    MySQL.insert.await([[
        INSERT INTO portal_notifications (citizenid, title, body, level)
        VALUES (?, ?, ?, ?)
    ]], { citizenid, title, body, level or 'info' })
end

dbg('database module loaded')
