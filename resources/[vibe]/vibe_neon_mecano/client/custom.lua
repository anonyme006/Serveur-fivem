local previewMods = {}

local function getVeh()
    local veh = Neon.GetTargetVehicle(6.0)
    if veh == 0 then
        Neon.Notify(nil, 'Aucun véhicule dans la zone custom.', 'error')
    end
    return veh
end

local function savePreview(veh)
    previewMods = {
        neon = {},
        color = { GetVehicleColours(veh) },
        tint = GetVehicleWindowTint(veh),
        wheelType = GetVehicleWheelType(veh),
        wheelMod = GetVehicleMod(veh, 23),
    }
    for i = 0, 3 do
        previewMods.neon[i] = IsVehicleNeonLightEnabled(veh, i)
    end
    previewMods.neonColor = { GetVehicleNeonLightsColour(veh) }
end

local function restorePreview(veh)
    if not previewMods.neon then return end
    for i = 0, 3 do
        SetVehicleNeonLightEnabled(veh, i, previewMods.neon[i] or false)
    end
    if previewMods.neonColor then
        SetVehicleNeonLightsColour(veh, previewMods.neonColor[1], previewMods.neonColor[2], previewMods.neonColor[3])
    end
    if previewMods.color then
        SetVehicleColours(veh, previewMods.color[1], previewMods.color[2])
    end
    if previewMods.tint then SetVehicleWindowTint(veh, previewMods.tint) end
    if previewMods.wheelType then
        SetVehicleWheelType(veh, previewMods.wheelType)
        SetVehicleMod(veh, 23, previewMods.wheelMod or -1, false)
    end
end

local function confirmCustom(veh, modType, applyFn)
    savePreview(veh)
    applyFn()
    local ok = lib.alertDialog({
        header = 'Neon Mechanic — Custom',
        content = 'Valider cette modification ? Le client sera facturé.',
        centered = true,
        cancel = true,
    })
    if ok == 'confirm' then
        TriggerServerEvent('vibe_neon_mecano:server:custom', NetworkGetNetworkIdFromEntity(veh), modType)
        previewMods = {}
        Neon.Notify(nil, 'Modification appliquée.', 'success')
    else
        restorePreview(veh)
        previewMods = {}
    end
end

function Neon.OpenCustomMenu()
    if not Neon.IsMechanic() then
        Neon.Notify(nil, 'Service Neon Mechanic requis.', 'error')
        return
    end
    local veh = getVeh()
    if veh == 0 then return end

    lib.registerContext({
        id = 'neon_custom',
        title = 'Custom — Neon Mechanic',
        options = {
            {
                title = 'Néons sous caisse',
                description = ('%d$ — allumage et couleur'):format(Config.Prices.customNeon),
                icon = 'lightbulb',
                onSelect = function()
                    Neon.CustomNeonMenu(veh)
                end,
            },
            {
                title = 'Couleur principale',
                description = ('%d$'):format(Config.Prices.customColor),
                icon = 'palette',
                onSelect = function()
                    Neon.CustomColorMenu(veh)
                end,
            },
            {
                title = 'Vitres teintées',
                description = ('%d$'):format(Config.Prices.customTint),
                icon = 'window-maximize',
                onSelect = function()
                    Neon.CustomTintMenu(veh)
                end,
            },
            {
                title = 'Jantes',
                description = ('%d$ — type et modèle'):format(Config.Prices.customWheels),
                icon = 'circle',
                onSelect = function()
                    Neon.CustomWheelsMenu(veh)
                end,
            },
        },
    })
    lib.showContext('neon_custom')
end

function Neon.CustomNeonMenu(veh)
    local options = {}
    for i = 0, 3 do
        local side = ({ 'Avant', 'Arrière', 'Gauche', 'Droite' })[i + 1]
        options[#options + 1] = {
            title = ('Néon %s'):format(side),
            icon = 'lightbulb',
            onSelect = function()
                confirmCustom(veh, 'neon', function()
                    SetVehicleNeonLightEnabled(veh, i, not IsVehicleNeonLightEnabled(veh, i))
                end)
            end,
        }
    end
    for idx, c in ipairs(Config.CustomMods.neonColors) do
        options[#options + 1] = {
            title = ('Couleur : %s'):format(c.label),
            icon = 'droplet',
            onSelect = function()
                confirmCustom(veh, 'neon', function()
                    SetVehicleNeonLightsColour(veh, c.r, c.g, c.b)
                    for n = 0, 3 do SetVehicleNeonLightEnabled(veh, n, true) end
                end)
            end,
        }
    end
    lib.registerContext({ id = 'neon_custom_neon', title = 'Néons', menu = 'neon_custom', options = options })
    lib.showContext('neon_custom_neon')
end

function Neon.CustomColorMenu(veh)
    local colors = {
        { label = 'Noir', primary = 0 },
        { label = 'Blanc', primary = 111 },
        { label = 'Rouge', primary = 27 },
        { label = 'Bleu', primary = 64 },
        { label = 'Vert', primary = 53 },
        { label = 'Orange', primary = 38 },
        { label = 'Violet', primary = 145 },
        { label = 'Rose néon', primary = 135 },
    }
    local options = {}
    for _, c in ipairs(colors) do
        options[#options + 1] = {
            title = c.label,
            onSelect = function()
                confirmCustom(veh, 'color', function()
                    local _, sec = GetVehicleColours(veh)
                    SetVehicleColours(veh, c.primary, sec)
                end)
            end,
        }
    end
    lib.registerContext({ id = 'neon_custom_color', title = 'Couleurs', menu = 'neon_custom', options = options })
    lib.showContext('neon_custom_color')
end

function Neon.CustomTintMenu(veh)
    local options = {}
    for _, t in ipairs(Config.CustomMods.windowTints) do
        options[#options + 1] = {
            title = t.label,
            onSelect = function()
                confirmCustom(veh, 'tint', function()
                    SetVehicleWindowTint(veh, t.index)
                end)
            end,
        }
    end
    lib.registerContext({ id = 'neon_custom_tint', title = 'Vitres', menu = 'neon_custom', options = options })
    lib.showContext('neon_custom_tint')
end

function Neon.CustomWheelsMenu(veh)
    local options = {}
    for _, wt in ipairs(Config.CustomMods.wheelTypes) do
        options[#options + 1] = {
            title = wt.label,
            onSelect = function()
                confirmCustom(veh, 'wheels', function()
                    SetVehicleWheelType(veh, wt.type)
                    local count = GetNumVehicleMods(veh, 23)
                    if count > 0 then
                        SetVehicleMod(veh, 23, math.random(0, count - 1), false)
                    end
                end)
            end,
        }
    end
    lib.registerContext({ id = 'neon_custom_wheels', title = 'Jantes', menu = 'neon_custom', options = options })
    lib.showContext('neon_custom_wheels')
end

CreateThread(function()
    local c = Config.CustomShop
    exports.ox_target:addSphereZone({
        coords = c.coords,
        radius = c.radius,
        options = {{
            name = 'neon_custom_shop',
            icon = 'fa-solid fa-spray-can',
            label = 'Atelier custom Neon',
            canInteract = Neon.IsMechanic,
            onSelect = function()
                Neon.OpenCustomMenu()
            end,
        }},
    })

    local blip = AddBlipForCoord(c.coords.x, c.coords.y, c.coords.z)
    SetBlipSprite(blip, c.blip.sprite)
    SetBlipColour(blip, c.blip.color)
    SetBlipScale(blip, c.blip.scale)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(c.blip.label)
    EndTextCommandSetBlipName(blip)
end)

RegisterNetEvent('vibe_neon_mecano:client:syncCustom', function(netId, props)
    local veh = NetworkGetEntityFromNetworkId(netId)
    if veh == 0 or not props then return end
    if props.neonColor then
        SetVehicleNeonLightsColour(veh, props.neonColor.r, props.neonColor.g, props.neonColor.b)
    end
    if props.neonEnabled then
        for i = 0, 3 do
            SetVehicleNeonLightEnabled(veh, i, props.neonEnabled[i] or false)
        end
    end
    if props.primary then
        local _, sec = GetVehicleColours(veh)
        SetVehicleColours(veh, props.primary, sec)
    end
    if props.tint then SetVehicleWindowTint(veh, props.tint) end
    if props.wheelType then
        SetVehicleWheelType(veh, props.wheelType)
        if props.wheelMod then SetVehicleMod(veh, 23, props.wheelMod, false) end
    end
end)
