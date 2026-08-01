---@diagnostic disable: undefined-global
--[[
    client/effects.lua
    Flash blanc, son appareil photo, léger effet caméra, notification style 911.
]]

RadarEffects = {}

local flashActive = false
local notifyActive = false
local notifyData = nil
local notifyEndAt = 0

--- Son d'appareil photo (native GTA)
local function playCameraSound()
    if not Config.CameraSound then
        return
    end
    PlaySoundFrontend(-1, 'Camera_Shoot', 'Phone_Soundset_Franklin', true)
end

--- Léger shake caméra au moment du flash
local function cameraShake()
    ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.08)
    SetTimeout(350, function()
        StopGameplayCamShaking(true)
    end)
end

--- Flash blanc plein écran
local function runWhiteFlash()
    if not Config.CameraFlash or flashActive then
        return
    end

    flashActive = true
    CreateThread(function()
        local alpha = 220
        local start = GetGameTimer()
        while alpha > 0 do
            local elapsed = GetGameTimer() - start
            -- Pic rapide puis fondu
            if elapsed < 80 then
                alpha = 220
            else
                alpha = math.max(0, 220 - math.floor((elapsed - 80) * 1.2))
            end

            DrawRect(0.5, 0.5, 1.0, 1.0, 255, 255, 255, alpha)
            Wait(0)
        end
        flashActive = false
    end)
end

--- Helpers dessin texte
local function drawText(x, y, scale, text, r, g, b, a, center, font)
    SetTextFont(font or 4)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a or 255)
    SetTextCentre(center == true)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 200)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(x, y)
end

--- Notification style capture d'écran (911 Emergency)
---@param data table
function RadarEffects.ShowFlashNotify(data)
    notifyData = data
    notifyEndAt = GetGameTimer() + (Config.Notify.duration or 8000)
    notifyActive = true

    CreateThread(function()
        while notifyActive and GetGameTimer() < notifyEndAt do
            -- Panneau semi-transparent à droite
            local x, y = 0.82, 0.22
            local w, h = 0.28, 0.28

            DrawRect(x, y + 0.02, w, h, 15, 15, 20, 200)

            -- Titre rouge
            drawText(x, y - 0.11, 0.42, data.title or Config.Notify.title, 220, 40, 40, 255, true, 4)

            -- Sous-titre
            drawText(x, y - 0.08, 0.32, data.subtitle or Config.Notify.subtitle, 230, 230, 230, 255, true, 4)

            -- Portion
            drawText(x, y - 0.055, 0.30, ('Portion %s km/h'):format(data.speedLimit or '?'), 200, 200, 200, 255, true, 4)

            -- Nom de la route (jaune)
            drawText(x, y - 0.025, 0.30, ('[%s]'):format(data.roadName or 'Route'), 255, 210, 50, 255, true, 4)

            -- Message flashé
            drawText(x, y + 0.01, 0.30, data.flashed or Config.Notify.flashed, 230, 230, 230, 255, true, 4)

            -- Vitesse
            drawText(x, y + 0.04, 0.30, ('Vitesse : %s km/h'):format(data.speed or 0), 230, 230, 230, 255, true, 4)

            -- Vitesse retenue (rose)
            drawText(x, y + 0.065, 0.30, ('Vitesse retenue : %s km/h'):format(data.retainedSpeed or 0), 255, 105, 180, 255, true, 4)

            -- Plaque (bleue)
            drawText(x, y + 0.095, 0.32, ('Plaque : %s'):format(data.plate or 'N/A'), 80, 160, 255, 255, true, 4)

            -- Statut : autorisé (vert) ou amende
            if data.authorized then
                drawText(x, y + 0.125, 0.32, Config.Notify.authorized or 'Véhicule autorisé', 60, 220, 100, 255, true, 4)
            else
                drawText(x, y + 0.125, 0.30, ('Amende : %s $'):format(data.fineAmount or 0), 230, 230, 230, 255, true, 4)
            end

            Wait(0)
        end
        notifyActive = false
        notifyData = nil
    end)
end

--- Déclenche tous les effets de flash (visuel + son + caméra + notif)
---@param data table
function RadarEffects.TriggerFlash(data)
    playCameraSound()
    cameraShake()
    runWhiteFlash()
    RadarEffects.ShowFlashNotify(data)
end

--- Notification ox_lib simple (succès / erreur menus)
---@param msg string
---@param nType string|nil
function RadarEffects.Notify(msg, nType)
    lib.notify({
        title = 'Radar',
        description = msg,
        type = nType or 'inform',
        duration = 4000,
    })
end
