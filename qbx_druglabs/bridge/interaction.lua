Bridge = Bridge or {}

local textUiZones = {}

---@param options table
--- Unified interaction registration.
--- options = { name, coords, distance, label, icon, canInteract, onSelect, groups? }
function Bridge.AddSphereZone(options)
    if Config.Interaction == 'textui' then
        textUiZones[options.name] = options
        return options.name
    end

    return exports.ox_target:addSphereZone({
        name = options.name,
        coords = options.coords,
        radius = options.distance or Config.TargetDistance,
        debug = Config.Debug,
        options = {
            {
                name = options.name .. '_opt',
                icon = options.icon or 'fa-solid fa-flask',
                label = options.label,
                groups = options.groups,
                canInteract = options.canInteract,
                onSelect = options.onSelect,
                distance = options.distance or Config.TargetDistance,
            },
        },
    })
end

---@param options table
--- options.options = array of { name, label, icon, canInteract, onSelect }
function Bridge.AddSphereZoneMulti(options)
    if Config.Interaction == 'textui' then
        textUiZones[options.name] = options
        return options.name
    end

    local targetOptions = {}
    for i = 1, #options.options do
        local opt = options.options[i]
        targetOptions[#targetOptions + 1] = {
            name = opt.name or (options.name .. '_' .. i),
            icon = opt.icon or 'fa-solid fa-flask',
            label = opt.label,
            groups = opt.groups,
            canInteract = opt.canInteract,
            onSelect = opt.onSelect,
            distance = options.distance or Config.TargetDistance,
        }
    end

    return exports.ox_target:addSphereZone({
        name = options.name,
        coords = options.coords,
        radius = options.distance or Config.TargetDistance,
        debug = Config.Debug,
        options = targetOptions,
    })
end

---@param id number|string
function Bridge.RemoveZone(id)
    if Config.Interaction == 'textui' then
        textUiZones[id] = nil
        return
    end
    pcall(function()
        exports.ox_target:removeZone(id)
    end)
end

--- Lightweight text UI fallback loop (only when Config.Interaction == 'textui')
CreateThread(function()
    if Config.Interaction ~= 'textui' then return end

    local showing
    while true do
        local sleep = 750
        local ped = cache.ped or PlayerPedId()
        local coords = GetEntityCoords(ped)
        local closest, closestDist, closestOpt

        for _, zone in pairs(textUiZones) do
            local zcoords = zone.coords
            if zcoords then
                local dist = #(coords - vec3(zcoords.x, zcoords.y, zcoords.z))
                local maxDist = zone.distance or Config.TextUIDistance
                if dist <= maxDist and (not closestDist or dist < closestDist) then
                    local options = zone.options or { zone }
                    for i = 1, #options do
                        local opt = options[i]
                        if not opt.canInteract or opt.canInteract() then
                            closest = zone
                            closestDist = dist
                            closestOpt = opt
                            break
                        end
                    end
                end
            end
        end

        if closest and closestOpt then
            sleep = 0
            local label = closestOpt.label or closest.label or 'Interact'
            if showing ~= label then
                lib.showTextUI(('[E] %s'):format(label))
                showing = label
            end
            if IsControlJustReleased(0, 38) then
                closestOpt.onSelect(closestOpt)
            end
        elseif showing then
            lib.hideTextUI()
            showing = nil
        end

        Wait(sleep)
    end
end)
