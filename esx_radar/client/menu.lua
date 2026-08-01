---@diagnostic disable: undefined-global
--[[
    client/menu.lua
    Menus ox_lib : création, suppression, administration des radars.
]]

RadarMenu = {}

--- Construit les options de sélection pour les limitations
---@return table
local function speedLimitOptions()
    local opts = {}
    for i = 1, #Config.SpeedLimits do
        local v = Config.SpeedLimits[i]
        opts[#opts + 1] = { value = v, label = ('%s km/h'):format(v) }
    end
    return opts
end

local function toleranceOptions()
    local opts = {}
    for i = 1, #Config.ToleranceOptions do
        local v = Config.ToleranceOptions[i]
        opts[#opts + 1] = { value = v, label = ('%s km/h'):format(v) }
    end
    return opts
end

local function detectionOptions()
    local opts = {}
    for i = 1, #Config.DetectionDistances do
        local v = Config.DetectionDistances[i]
        opts[#opts + 1] = { value = v, label = ('%s m'):format(v) }
    end
    return opts
end

local function directionOptions()
    local opts = {}
    for i = 1, #Config.Directions do
        local d = Config.Directions[i]
        opts[#opts + 1] = { value = d.value, label = d.label }
    end
    return opts
end

--- Menu de création /createradar
function RadarMenu.OpenCreate()
    local input = lib.inputDialog('Créer un radar', {
        {
            type = 'input',
            label = 'Nom du radar',
            description = 'Identifiant interne (ex: Radar LS01)',
            required = true,
            min = 2,
            max = 64,
        },
        {
            type = 'input',
            label = 'Nom de la route',
            description = 'Affiché sur la notification (ex: Grapeseed Main Street)',
            required = true,
            min = 2,
            max = 128,
        },
        {
            type = 'select',
            label = 'Limitation de vitesse',
            options = speedLimitOptions(),
            default = 90,
            required = true,
        },
        {
            type = 'select',
            label = 'Tolérance de vitesse',
            options = toleranceOptions(),
            default = Config.Tolerance or 5,
            required = true,
        },
        {
            type = 'select',
            label = 'Distance de détection',
            options = detectionOptions(),
            default = 20.0,
            required = true,
        },
        {
            type = 'select',
            label = 'Sens du radar',
            options = directionOptions(),
            default = 'both',
            required = true,
        },
    })

    if not input then
        return
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    local payload = {
        name = input[1],
        road_name = input[2],
        speed_limit = tonumber(input[3]) or 90,
        tolerance = tonumber(input[4]) or Config.Tolerance,
        detection_distance = tonumber(input[5]) or 20.0,
        direction = input[6] or 'both',
        x = coords.x,
        y = coords.y,
        z = coords.z,
        heading = heading,
    }

    local confirmed = lib.alertDialog({
        header = 'Confirmer le placement',
        content = ('Placer **%s** ici ?\nRoute : %s\nLimite : %s km/h (+%s)\nDistance : %s m\nSens : %s'):format(
            payload.name,
            payload.road_name,
            payload.speed_limit,
            payload.tolerance,
            payload.detection_distance,
            Utils.DirectionLabel(payload.direction)
        ),
        centered = true,
        cancel = true,
    })

    if confirmed ~= 'confirm' then
        RadarEffects.Notify('Création annulée.', 'inform')
        return
    end

    TriggerServerEvent('esx_radar:server:createRadar', payload)
end

--- /deleteradar — radar le plus proche
function RadarMenu.OpenDeleteNearest()
    local radars = RadarClient.GetRadars()
    if not radars or #radars == 0 then
        RadarEffects.Notify('Aucun radar enregistré.', 'error')
        return
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local nearest, nearestDist = nil, 9999.0

    for i = 1, #radars do
        local r = radars[i]
        local d = Utils.Dist3D(coords, r)
        if d < nearestDist then
            nearestDist = d
            nearest = r
        end
    end

    if not nearest or nearestDist > 25.0 then
        RadarEffects.Notify('Aucun radar à proximité (25 m).', 'error')
        return
    end

    local confirmed = lib.alertDialog({
        header = 'Supprimer le radar',
        content = ('Supprimer **%s** (%s) ?\nDistance : %.1f m'):format(
            nearest.name,
            nearest.road_name,
            nearestDist
        ),
        centered = true,
        cancel = true,
    })

    if confirmed ~= 'confirm' then
        return
    end

    TriggerServerEvent('esx_radar:server:deleteRadar', nearest.id)
end

--- Menu édition d'un radar existant
---@param radar table
function RadarMenu.OpenEdit(radar)
    local input = lib.inputDialog(('Modifier — %s'):format(radar.name), {
        {
            type = 'input',
            label = 'Nom du radar',
            default = radar.name,
            required = true,
            min = 2,
            max = 64,
        },
        {
            type = 'input',
            label = 'Nom de la route',
            default = radar.road_name,
            required = true,
            min = 2,
            max = 128,
        },
        {
            type = 'select',
            label = 'Limitation de vitesse',
            options = speedLimitOptions(),
            default = radar.speed_limit,
            required = true,
        },
        {
            type = 'select',
            label = 'Tolérance de vitesse',
            options = toleranceOptions(),
            default = radar.tolerance,
            required = true,
        },
        {
            type = 'select',
            label = 'Distance de détection',
            options = detectionOptions(),
            default = radar.detection_distance,
            required = true,
        },
        {
            type = 'select',
            label = 'Sens du radar',
            options = directionOptions(),
            default = radar.direction,
            required = true,
        },
    })

    if not input then
        return
    end

    TriggerServerEvent('esx_radar:server:updateRadar', {
        id = radar.id,
        name = input[1],
        road_name = input[2],
        speed_limit = tonumber(input[3]),
        tolerance = tonumber(input[4]),
        detection_distance = tonumber(input[5]),
        direction = input[6],
    })
end

--- Options contextuelles pour un radar (/radars)
---@param radar table
local function openRadarActions(radar)
    local enabled = radar.enabled == 1 or radar.enabled == true
    local statusLabel = enabled and 'Actif' or 'Désactivé'

    lib.registerContext({
        id = 'esx_radar_actions',
        title = ('%s [%s]'):format(radar.name, statusLabel),
        menu = 'esx_radar_list',
        options = {
            {
                title = 'Téléportation au radar',
                description = ('%s — %.1f, %.1f'):format(radar.road_name, radar.x, radar.y),
                icon = 'location-arrow',
                onSelect = function()
                    SetEntityCoords(PlayerPedId(), radar.x, radar.y, radar.z + 0.5, false, false, false, false)
                    SetEntityHeading(PlayerPedId(), radar.heading or 0.0)
                    RadarEffects.Notify(('Téléporté à %s'):format(radar.name), 'success')
                end,
            },
            {
                title = 'Modifier',
                description = 'Changer nom, limite, tolérance, sens…',
                icon = 'pen',
                onSelect = function()
                    RadarMenu.OpenEdit(radar)
                end,
            },
            {
                title = 'Activer',
                description = 'Réactiver la détection',
                icon = 'toggle-on',
                disabled = radar.enabled == 1 or radar.enabled == true,
                onSelect = function()
                    TriggerServerEvent('esx_radar:server:setEnabled', radar.id, true)
                end,
            },
            {
                title = 'Désactiver',
                description = 'Couper la détection sans supprimer',
                icon = 'toggle-off',
                disabled = not (radar.enabled == 1 or radar.enabled == true),
                onSelect = function()
                    TriggerServerEvent('esx_radar:server:setEnabled', radar.id, false)
                end,
            },
            {
                title = 'Supprimer',
                description = 'Suppression définitive',
                icon = 'trash',
                iconColor = '#e74c3c',
                onSelect = function()
                    local confirmed = lib.alertDialog({
                        header = 'Supprimer le radar',
                        content = ('Supprimer définitivement **%s** ?'):format(radar.name),
                        centered = true,
                        cancel = true,
                    })
                    if confirmed == 'confirm' then
                        TriggerServerEvent('esx_radar:server:deleteRadar', radar.id)
                    end
                end,
            },
        },
    })

    lib.showContext('esx_radar_actions')
end

--- Menu admin /radars
function RadarMenu.OpenAdmin()
    local radars = lib.callback.await('esx_radar:server:getRadars', false)
    if not radars then
        RadarEffects.Notify('Accès refusé ou erreur.', 'error')
        return
    end

    if #radars == 0 then
        RadarEffects.Notify('Aucun radar enregistré.', 'inform')
        return
    end

    local options = {}
    for i = 1, #radars do
        local r = radars[i]
        local enabled = r.enabled == 1 or r.enabled == true
        options[#options + 1] = {
            title = r.name,
            description = ('%s | %s km/h | %s | %s'):format(
                r.road_name,
                r.speed_limit,
                Utils.DirectionLabel(r.direction),
                enabled and 'Actif' or 'Off'
            ),
            icon = enabled and 'camera' or 'ban',
            arrow = true,
            onSelect = function()
                openRadarActions(r)
            end,
        }
    end

    lib.registerContext({
        id = 'esx_radar_list',
        title = ('Radars (%s)'):format(#radars),
        options = options,
    })

    lib.showContext('esx_radar_list')
end
