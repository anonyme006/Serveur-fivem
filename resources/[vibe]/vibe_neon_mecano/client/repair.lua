local function needsFix(state, fixType)
    if not state then return false end
    if fixType == 'engine' then return state.engine < 900.0 end
    if fixType == 'body' then return state.body < 900.0 end
    if fixType == 'tank' then return state.tank < 900.0 end
    if fixType == 'tires' then
        for _, burst in pairs(state.burst) do
            if burst then return true end
        end
    end
    if fixType == 'clean' then return state.dirty > 0.5 end
    return false
end

local function runRepair(fixType, cfg, veh)
    if not Neon.Progress({
        duration = cfg.duration,
        label = cfg.label,
        anim = cfg.anim,
    }) then
        Neon.StopAnim()
        return
    end
    Neon.StopAnim()
    TriggerServerEvent('vibe_neon_mecano:server:repair', NetworkGetNetworkIdFromEntity(veh), fixType)
end

function Neon.RunDiagnostic(veh)
    veh = veh or Neon.GetTargetVehicle()
    if veh == 0 then
        Neon.Notify(nil, 'Aucun véhicule à proximité.', 'error')
        return
    end

    if not Neon.Progress({
        duration = Config.Repair.diagnosticDuration,
        label = 'Diagnostic électronique...',
        anim = Config.Repair.engine.anim,
    }) then
        Neon.StopAnim()
        return
    end
    Neon.StopAnim()

    local state = Neon.GetVehicleState(veh)
    lib.registerContext({
        id = 'neon_diag',
        title = 'Diagnostic — Neon Mechanic',
        menu = 'neon_main',
        options = {
            { title = ('Moteur : %d%%'):format(Neon.FormatHealth(state.engine)), icon = 'engine', disabled = true },
            { title = ('Carrosserie : %d%%'):format(Neon.FormatHealth(state.body)), icon = 'car', disabled = true },
            { title = ('Réservoir : %d%%'):format(Neon.FormatHealth(state.tank)), icon = 'gas-pump', disabled = true },
            {
                title = 'Pneus',
                description = needsFix(state, 'tires') and 'Un ou plusieurs pneus crevés' or 'OK',
                icon = 'circle',
                disabled = true,
            },
            {
                title = 'Lancer les réparations',
                icon = 'wrench',
                onSelect = function()
                    Neon.OpenRepairMenu(veh, state)
                end,
            },
        },
    })
    lib.showContext('neon_diag')
end

function Neon.OpenRepairMenu(veh, state)
    veh = veh or Neon.GetTargetVehicle()
    state = state or Neon.GetVehicleState(veh)
    if veh == 0 then return end

    local options = {}
    local repairs = {
        { type = 'engine', cfg = Config.Repair.engine, price = Config.Prices.engine, icon = 'engine' },
        { type = 'body', cfg = Config.Repair.body, price = Config.Prices.body, icon = 'car-burst' },
        { type = 'tank', cfg = Config.Repair.tank, price = Config.Prices.tank, icon = 'gas-pump' },
        { type = 'tires', cfg = Config.Repair.tires, price = Config.Prices.tires, icon = 'circle' },
        { type = 'clean', cfg = Config.Repair.clean, price = Config.Prices.clean, icon = 'soap' },
        { type = 'full', cfg = Config.Repair.full, price = Config.Prices.full, icon = 'screwdriver-wrench' },
    }

    for _, r in ipairs(repairs) do
        local required = r.type == 'full' or needsFix(state, r.type)
        options[#options + 1] = {
            title = r.cfg.label,
            description = required and ('%d$ — intervention nécessaire'):format(r.price) or 'Élément en bon état',
            icon = r.icon,
            disabled = not required,
            onSelect = function()
                runRepair(r.type, r.cfg, veh)
            end,
        }
    end

    lib.registerContext({
        id = 'neon_repair',
        title = 'Réparations',
        menu = 'neon_main',
        options = options,
    })
    lib.showContext('neon_repair')
end

function Neon.OpenMainMenu()
    if not Neon.IsMechanic() then
        Neon.Notify(nil, 'Tu dois être en service chez Neon Mechanic.', 'error')
        return
    end

    lib.registerContext({
        id = 'neon_main',
        title = Config.CompanyName,
        options = {
            {
                title = 'Diagnostic véhicule',
                description = 'Analyse moteur, carrosserie, pneus',
                icon = 'stethoscope',
                onSelect = function()
                    Neon.RunDiagnostic()
                end,
            },
            {
                title = 'Réparations',
                description = 'Interventions ciblées ou révision complète',
                icon = 'wrench',
                onSelect = function()
                    Neon.OpenRepairMenu()
                end,
            },
            {
                title = 'Bipeur / Missions',
                description = 'Voir les appels de dépannage',
                icon = 'pager',
                onSelect = function()
                    TriggerEvent('vibe_neon_mecano:client:openBipeur')
                end,
            },
        },
    })
    lib.showContext('neon_main')
end

-- Réparation rapide sur mission (sans facturation client)
function Neon.MissionRepair(veh, missionType)
    veh = veh or Neon.GetTargetVehicle(8.0)
    if veh == 0 then
        Neon.Notify(nil, 'Approche-toi du véhicule en panne.', 'error')
        return false
    end

    local cfg
    if missionType == 'flat' then
        cfg = Config.Repair.tires
    elseif missionType == 'engine' or missionType == 'battery' then
        cfg = Config.Repair.engine
    elseif missionType == 'accident' then
        cfg = Config.Repair.body
    else
        cfg = Config.Repair.full
    end

    if not Neon.Progress({ duration = cfg.duration, label = cfg.label, anim = cfg.anim }) then
        Neon.StopAnim()
        return false
    end
    Neon.StopAnim()
    return true
end

RegisterNetEvent('vibe_neon_mecano:client:openMenu', function()
    Neon.OpenMainMenu()
end)

RegisterCommand('neonmecano', function()
    Neon.OpenMainMenu()
end, false)

RegisterCommand('mecano', function()
    Neon.OpenMainMenu()
end, false)

CreateThread(function()
    for i, zone in ipairs(Config.Workshop.zones) do
        exports.ox_target:addSphereZone({
            coords = zone.coords,
            radius = zone.radius,
            options = {
                {
                    name = 'neon_workshop_' .. i,
                    icon = 'fa-solid fa-wrench',
                    label = zone.label,
                    canInteract = Neon.IsMechanic,
                    onSelect = function()
                        Neon.OpenMainMenu()
                    end,
                },
                {
                    name = 'neon_diag_' .. i,
                    icon = 'fa-solid fa-stethoscope',
                    label = 'Diagnostic',
                    canInteract = Neon.IsMechanic,
                    onSelect = function()
                        Neon.RunDiagnostic()
                    end,
                },
            },
        })
    end
end)

CreateThread(function()
    local w = Config.Workshop
    local blip = AddBlipForCoord(w.zones[1].coords.x, w.zones[1].coords.y, w.zones[1].coords.z)
    SetBlipSprite(blip, w.blip.sprite)
    SetBlipColour(blip, w.blip.color)
    SetBlipScale(blip, w.blip.scale)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(w.blip.label)
    EndTextCommandSetBlipName(blip)
end)
