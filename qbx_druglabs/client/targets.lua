Targets = {
    entrance = {},
}

local function clearZoneMap(map)
    for id, zoneId in pairs(map) do
        Bridge.RemoveZone(zoneId)
        map[id] = nil
    end
end

function Targets.ClearAll()
    clearZoneMap(Targets.entrance)
    Interiors.ClearInteriorZones()
end

local function openAvailableMenu(lab)
    lib.registerContext({
        id = 'druglab_available_' .. lab.id,
        title = lab.label,
        options = {
            {
                title = 'Laboratory available',
                description = ('Type: %s | Price: $%s | Rent: $%s'):format(
                    lab.type,
                    lab.purchasePrice or 0,
                    lab.rentPrice or 0
                ),
                icon = 'flask',
                readOnly = true,
            },
            {
                title = 'Purchase',
                icon = 'cart-shopping',
                disabled = lab.purchaseMode == 'rent',
                onSelect = function()
                    local result = lib.callback.await('qbx_druglabs:server:purchaseLab', false, lab.id)
                    if not result or not result.ok then
                        Bridge.Notify(nil, { description = result and result.error or 'Purchase failed', type = 'error' })
                        return
                    end
                    Bridge.Notify(nil, {
                        description = ('Purchased! Access code: %s'):format(result.data.code),
                        type = 'success',
                        duration = 12000,
                    })
                    pcall(function()
                        lib.setClipboard(tostring(result.data.code))
                    end)
                end,
            },
            {
                title = 'Rent',
                icon = 'key',
                disabled = not Config.Rental.enabled or (lab.rentPrice or 0) <= 0,
                onSelect = function()
                    local result = lib.callback.await('qbx_druglabs:server:rentLab', false, lab.id)
                    if not result or not result.ok then
                        Bridge.Notify(nil, { description = result and result.error or 'Rent failed', type = 'error' })
                        return
                    end
                    Bridge.Notify(nil, {
                        description = ('Rented! Access code: %s'):format(result.data.code),
                        type = 'success',
                        duration = 12000,
                    })
                    pcall(function()
                        lib.setClipboard(tostring(result.data.code))
                    end)
                end,
            },
        },
    })
    lib.showContext('druglab_available_' .. lab.id)
end

local function openOwnedEntranceMenu(lab)
    local options = {
        {
            title = 'Enter Laboratory',
            icon = 'door-open',
            onSelect = function()
                Interiors.Enter(lab.id)
            end,
        },
        {
            title = 'Enter Code',
            icon = 'lock',
            onSelect = function()
                local input = lib.inputDialog('Access Code', {
                    { type = 'input', label = 'Code', password = true, required = true, min = Config.Security.codeMinLength, max = Config.Security.codeMaxLength },
                })
                if not input then return end
                local result = lib.callback.await('qbx_druglabs:server:tryCode', false, lab.id, input[1])
                if not result or not result.ok then
                    Bridge.Notify(nil, { description = result and result.error or 'Wrong code', type = 'error' })
                    return
                end
                Bridge.Notify(nil, { description = 'Unlocked', type = 'success' })
            end,
        },
        {
            title = 'Manage',
            icon = 'screwdriver-wrench',
            onSelect = function()
                Interiors.OpenManagement(lab.id)
            end,
        },
    }

    if lab.sealed then
        options = {
            {
                title = 'Laboratory Sealed',
                description = 'Police seal active',
                icon = 'ban',
                readOnly = true,
            },
        }
    end

    lib.registerContext({
        id = 'druglab_entrance_' .. lab.id,
        title = lab.label,
        options = options,
    })
    lib.showContext('druglab_entrance_' .. lab.id)
end

function Targets.RefreshLab(labId)
    if Targets.entrance[labId] then
        Bridge.RemoveZone(Targets.entrance[labId])
        Targets.entrance[labId] = nil
    end

    local lab = ClientLabs.Get(labId)
    if not lab or lab.deleted or not lab.entrance then return end

    local coords = vec3(lab.entrance.x, lab.entrance.y, lab.entrance.z)
    local policeGroups = {}
    for jobName in pairs(Config.Police.jobs or {}) do
        policeGroups[jobName] = 0
    end

    local zoneId = Bridge.AddSphereZoneMulti({
        name = ('druglab_entrance_%s'):format(lab.id),
        coords = coords,
        distance = Config.TargetDistance,
        options = {
            {
                name = ('druglab_enter_%s'):format(lab.id),
                label = lab.available and 'View Laboratory' or 'Laboratory',
                icon = 'fa-solid fa-flask',
                onSelect = function()
                    local current = ClientLabs.Get(labId)
                    if not current then return end
                    if current.available then
                        openAvailableMenu(current)
                    else
                        openOwnedEntranceMenu(current)
                    end
                end,
            },
            {
                name = ('druglab_police_%s'):format(lab.id),
                label = 'Police Actions',
                icon = 'fa-solid fa-shield-halved',
                groups = policeGroups,
                onSelect = function()
                    PoliceClient.OpenMenu(labId)
                end,
            },
        },
    })
    Targets.entrance[labId] = zoneId
end

function Targets.RefreshAll()
    clearZoneMap(Targets.entrance)
    for i = 1, #ClientLabs.list do
        Targets.RefreshLab(ClientLabs.list[i].id)
    end
end
