local uiOpen = false
local dead = false

local function setUi(open, payload)
    uiOpen = open
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = open and 'open' or 'close',
        tagline = Config.Tagline,
        bleedOut = Config.BleedOutSeconds,
        killer = payload and payload.killer or nil,
        cause = payload and payload.cause or nil,
    })
end

local function isPlayerDead()
    local ped = cache.ped or PlayerPedId()
    if IsEntityDead(ped) or IsPedFatallyInjured(ped) then
        return true
    end
    local meta = LocalPlayer.state and LocalPlayer.state.isDead
    if meta == true then return true end
    local ok, state = pcall(function()
        return exports.qbx_medical:IsDead()
    end)
    if ok and state then return true end
    ok, state = pcall(function()
        return exports.qbx_medical:IsLaststand()
    end)
    if ok and state then return true end
    return false
end

CreateThread(function()
    while true do
        local sleep = 800
        if Config.ShowOnDeath then
            local nowDead = isPlayerDead()
            if nowDead and not dead then
                dead = true
                setUi(true, {})
                sleep = 200
            elseif not nowDead and dead then
                dead = false
                if Config.AutoCloseOnRevive then
                    setUi(false)
                end
            elseif nowDead then
                sleep = 400
            end
        end
        Wait(sleep)
    end
end)

RegisterNetEvent('rr_deathscreen:client:show', function(data)
    dead = true
    setUi(true, data or {})
end)

RegisterNetEvent('rr_deathscreen:client:hide', function()
    dead = false
    setUi(false)
end)

RegisterNUICallback('callEms', function(_, cb)
    TriggerServerEvent('rr_deathscreen:server:callEms')
    cb({ ok = true })
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and uiOpen then
        setUi(false)
    end
end)
