local nuiOpen = false
local lastResult = nil

local function discordInvite()
    return (Config.Discord and Config.Discord.Invite) or ''
end

local function sendNui(payload)
    SendNUIMessage(payload)
end

local function setFocus(state)
    nuiOpen = state
    SetNuiFocus(state, state)
    SetNuiFocusKeepInput(false)
end

local function openScreen(screen, data)
    setFocus(true)
    sendNui({
        action = 'show',
        screen = screen,
        invite = discordInvite(),
        citizenRoleName = (Config.Discord and Config.Discord.CitizenRoleName) or 'Citoyen',
        data = data or {},
    })
end

local function closeNui()
    setFocus(false)
    sendNui({ action = 'hide' })
end

local function startVerification()
    openScreen('verify')
    TriggerServerEvent('rr_discord_gate:server:verify')
end

local function showCharacters()
    local external = Config.Flow and Config.Flow.ExternalCharacterEvent
    if external and external ~= '' then
        closeNui()
        TriggerEvent(external)
        return
    end
    openScreen('characters', { loading = true })
    TriggerServerEvent('rr_discord_gate:server:getCharacters')
end

local function handleVerifyResult(result)
    lastResult = result
    if not result then
        openScreen('denied_link')
        return
    end

    -- Toujours pousser l'invite depuis la config (jamais hardcodée côté NUI)
    result.invite = discordInvite()

    if result.status == 'disabled' or result.status == 'ok' then
        openScreen('success', {
            checks = {
                { label = 'Discord vérifié', ok = true },
                {
                    label = (Config.Discord.RequireCitizenRole and ('Rôle %s détecté'):format(Config.Discord.CitizenRoleName or 'Citoyen'))
                        or 'Accès Discord validé',
                    ok = true,
                },
            },
        })
        SetTimeout(Config.Flow.SuccessDisplayMs or 1800, function()
            if nuiOpen then
                showCharacters()
            end
        end)
        return
    end

    if result.status == 'no_discord' then
        openScreen('denied_link', result)
        return
    end

    if result.status == 'not_member' then
        openScreen('denied_member', result)
        return
    end

    if result.status == 'no_role' then
        openScreen('denied_role', result)
        return
    end

    -- error / fallback
    openScreen('denied_member', result)
end

RegisterNetEvent('rr_discord_gate:client:verifyResult', function(result)
    handleVerifyResult(result)
end)

RegisterNetEvent('rr_discord_gate:client:characters', function(payload)
    openScreen('characters', payload or { characters = {}, maxCharacters = 4 })
end)

RegisterNetEvent('rr_discord_gate:client:open', function()
    startVerification()
end)

RegisterNetEvent('rr_discord_gate:client:characterSelected', function(_citizenid)
    closeNui()
end)

RegisterNetEvent('rr_discord_gate:client:createRequested', function()
    closeNui()
    -- Hook création : brancher sur ton creator / qbx
    TriggerEvent('rr_discord_gate:client:openCreator')
end)

-- NUI callbacks

RegisterNUICallback('ready', function(_, cb)
    cb({
        ok = true,
        invite = discordInvite(),
        citizenRoleName = (Config.Discord and Config.Discord.CitizenRoleName) or 'Citoyen',
    })
end)

--- Ouvre l'URL Discord depuis la NUI FiveM (invokeNative côté web + filet de sécurité)
RegisterNUICallback('openDiscord', function(_, cb)
    local invite = discordInvite()
    -- La NUI doit appeler window.invokeNative('openUrl', invite).
    -- On renvoie l'URL depuis la config pour qu'elle ne soit jamais hardcodée dans le JS.
    cb({ ok = true, invite = invite })
end)

RegisterNUICallback('recheck', function(_, cb)
    openScreen('verify')
    TriggerServerEvent('rr_discord_gate:server:recheck')
    cb({ ok = true })
end)

RegisterNUICallback('selectCharacter', function(data, cb)
    local id = data and data.id
    if id then
        TriggerServerEvent('rr_discord_gate:server:selectCharacter', id)
    end
    cb({ ok = true })
end)

RegisterNUICallback('createCharacter', function(_, cb)
    TriggerServerEvent('rr_discord_gate:server:createCharacter')
    cb({ ok = true })
end)

RegisterNUICallback('close', function(_, cb)
    -- Ne pas fermer pendant un refus d'accès (le joueur doit rejoindre Discord)
    if lastResult and (lastResult.status == 'no_discord' or lastResult.status == 'not_member' or lastResult.status == 'no_role') then
        cb({ ok = false, locked = true })
        return
    end
    closeNui()
    cb({ ok = true })
end)

-- Auto-start
CreateThread(function()
    if not Config.Flow or not Config.Flow.AutoStartOnJoin then return end
    if not Config.Discord or not Config.Discord.Enabled then
        -- Discord désactivé → sélection personnages directement
        Wait(Config.Flow.AutoStartDelay or 1500)
        showCharacters()
        return
    end
    Wait(Config.Flow.AutoStartDelay or 1500)
    -- Attendre que le joueur soit actif (session solo / loading)
    while not NetworkIsPlayerActive(PlayerId()) do
        Wait(200)
    end
    startVerification()
end)

-- Debug command
if Config.Debug and Config.Debug.Command and Config.Debug.Command ~= '' then
    RegisterCommand(Config.Debug.Command, function(_, args)
        local screen = args[1] or 'verify'
        if screen == 'verify' then
            startVerification()
        elseif screen == 'success' then
            handleVerifyResult({ status = 'ok' })
        elseif screen == 'denied_role' then
            handleVerifyResult({ status = 'no_role' })
        elseif screen == 'denied_link' then
            handleVerifyResult({ status = 'no_discord' })
        elseif screen == 'denied_member' then
            handleVerifyResult({ status = 'not_member' })
        elseif screen == 'characters' then
            showCharacters()
        else
            startVerification()
        end
    end, false)
end

exports('StartVerification', startVerification)
exports('ShowCharacters', showCharacters)
exports('GetInvite', discordInvite)
exports('IsOpen', function()
    return nuiOpen
end)
