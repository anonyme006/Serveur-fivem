AdminClient = {}

local function currentPos()
    local ped = cache.ped or PlayerPedId()
    local c = GetEntityCoords(ped)
    local h = GetEntityHeading(ped)
    return { x = c.x, y = c.y, z = c.z, w = h }
end

local function pickType()
    local options = {}
    for typeName, def in pairs(Config.LabTypes) do
        options[#options + 1] = { value = typeName, label = def.label }
    end
    table.sort(options, function(a, b) return a.label < b.label end)
    local input = lib.inputDialog('Lab Type', {
        { type = 'select', label = 'Type', options = options, required = true },
    })
    return input and input[1] or nil
end

function AdminClient.OpenCreator()
    local labType = pickType()
    if not labType then return end

    local typeDef = Config.LabTypes[labType]
    local input = lib.inputDialog('Create Laboratory', {
        { type = 'input', label = 'Identifier (optional)', placeholder = labType .. '_custom' },
        { type = 'input', label = 'Label', default = typeDef.label, required = true },
        { type = 'number', label = 'Purchase price', default = typeDef.defaultPurchasePrice, required = true, min = 0 },
        { type = 'number', label = 'Rent price', default = typeDef.defaultRentPrice, required = true, min = 0 },
        { type = 'select', label = 'Purchase mode', options = {
            { value = 'purchase', label = 'Purchase' },
            { value = 'rent', label = 'Rent' },
            { value = 'public', label = 'Public' },
            { value = 'gang', label = 'Gang' },
            { value = 'admin', label = 'Admin' },
        }, default = 'purchase' },
    })
    if not input then return end

    Bridge.Notify(nil, { description = 'Stand at the exterior entrance, then confirm.', type = 'inform' })
    local confirmEntrance = lib.alertDialog({
        header = 'Exterior Entrance',
        content = 'Use your current position as exterior entrance?',
        centered = true,
        cancel = true,
    })
    if confirmEntrance ~= 'confirm' then return end
    local entrance = currentPos()

    Bridge.Notify(nil, { description = 'Go to interior entrance (or confirm defaults).', type = 'inform' })
    local confirmInterior = lib.alertDialog({
        header = 'Interior Entrance / Exit',
        content = 'Use current position as interior entrance & exit?',
        centered = true,
        cancel = true,
    })
    if confirmInterior ~= 'confirm' then return end
    local interiorPos = currentPos()

    Bridge.Notify(nil, { description = 'Stand at stash location.', type = 'inform' })
    local confirmStash = lib.alertDialog({
        header = 'Stash Position',
        content = 'Use current position as stash?',
        centered = true,
        cancel = true,
    })
    if confirmStash ~= 'confirm' then return end
    local stashPos = currentPos()

    local stations = {}
    local addStations = lib.alertDialog({
        header = 'Stations',
        content = 'Add production stations now? (You can skip)',
        centered = true,
        cancel = true,
        labels = { confirm = 'Add', cancel = 'Skip' },
    })

    if addStations == 'confirm' then
        while true do
            local stationInput = lib.inputDialog('Station', {
                { type = 'input', label = 'Station id (e.g. mix, packing, plant_1)', required = true },
                { type = 'input', label = 'Recipe group', required = true, default = 'pack' },
            })
            if not stationInput then break end
            local confirm = lib.alertDialog({
                header = 'Station Position',
                content = ('Use current position for %s?'):format(stationInput[1]),
                centered = true,
                cancel = true,
            })
            if confirm ~= 'confirm' then break end
            local pos = currentPos()
            stations[stationInput[1]] = {
                coords = pos,
                heading = pos.w,
                recipeGroup = stationInput[2],
            }
            local more = lib.alertDialog({
                header = 'Another station?',
                content = 'Add another production station?',
                centered = true,
                cancel = true,
            })
            if more ~= 'confirm' then break end
        end
    end

    local payload = {
        identifier = input[1] ~= '' and input[1] or nil,
        label = input[2],
        purchasePrice = input[3],
        rentPrice = input[4],
        purchaseMode = input[5],
        type = labType,
        entrance = entrance,
        interior = { entrance = interiorPos, exit = interiorPos },
        stash = {
            coords = stashPos,
            slots = typeDef.stash.slots,
            weight = typeDef.stash.weight,
        },
        stations = stations,
        blip = { enabled = false },
        locked = true,
    }

    local result = lib.callback.await('qbx_druglabs:server:adminCreate', false, payload)
    if not result or not result.ok then
        Bridge.Notify(nil, { description = result and result.error or 'Create failed', type = 'error' })
        return
    end
    Bridge.Notify(nil, { description = ('Created lab #%s'):format(result.data.id), type = 'success' })
end

function AdminClient.OpenManager()
    local result = lib.callback.await('qbx_druglabs:server:adminList', false)
    if not result or not result.ok then
        Bridge.Notify(nil, { description = result and result.error or 'Denied', type = 'error' })
        return
    end

    local options = {
        {
            title = 'Create Laboratory',
            icon = 'plus',
            onSelect = AdminClient.OpenCreator,
        },
    }

    for i = 1, #result.data do
        local lab = result.data[i]
        options[#options + 1] = {
            title = ('#%s %s'):format(lab.id, lab.label),
            description = ('%s | owner:%s | %s%s'):format(
                lab.type,
                lab.ownerIdentifier or lab.ownerGang or 'none',
                lab.locked and 'locked ' or '',
                lab.sealed and 'SEALED' or ''
            ),
            icon = 'flask',
            onSelect = function()
                AdminClient.OpenLabActions(lab)
            end,
        }
    end

    lib.registerContext({
        id = 'druglab_admin_list',
        title = 'Drug Laboratories',
        options = options,
    })
    lib.showContext('druglab_admin_list')
end

function AdminClient.OpenLabActions(lab)
    lib.registerContext({
        id = 'druglab_admin_lab_' .. lab.id,
        title = lab.label,
        menu = 'druglab_admin_list',
        options = {
            {
                title = 'Teleport to Entrance',
                icon = 'location-dot',
                onSelect = function()
                    local res = lib.callback.await('qbx_druglabs:server:adminTeleport', false, lab.id)
                    if res and res.ok then
                        local p = res.data
                        SetEntityCoords(cache.ped or PlayerPedId(), p.x, p.y, p.z, false, false, false, false)
                        SetEntityHeading(cache.ped or PlayerPedId(), p.w or 0.0)
                    end
                end,
            },
            {
                title = 'Reset Owner',
                icon = 'user-slash',
                onSelect = function()
                    lib.callback.await('qbx_druglabs:server:adminReset', false, lab.id)
                end,
            },
            {
                title = lab.locked and 'Unlock' or 'Lock',
                icon = 'lock',
                onSelect = function()
                    lib.callback.await('qbx_druglabs:server:adminSetLocked', false, lab.id, not lab.locked)
                end,
            },
            {
                title = lab.sealed and 'Unseal' or 'Seal',
                icon = 'ban',
                onSelect = function()
                    lib.callback.await('qbx_druglabs:server:adminSetSealed', false, lab.id, not lab.sealed)
                end,
            },
            {
                title = 'Delete Laboratory',
                icon = 'trash',
                onSelect = function()
                    local confirm = lib.alertDialog({
                        header = 'Delete?',
                        content = 'This permanently deletes the laboratory record.',
                        centered = true,
                        cancel = true,
                    })
                    if confirm == 'confirm' then
                        lib.callback.await('qbx_druglabs:server:adminDelete', false, lab.id)
                    end
                end,
            },
        },
    })
    lib.showContext('druglab_admin_lab_' .. lab.id)
end

RegisterCommand(Config.Admin.command, function()
    AdminClient.OpenCreator()
end, false)

RegisterCommand(Config.Admin.manageCommand, function()
    AdminClient.OpenManager()
end, false)

TriggerEvent('chat:addSuggestion', '/' .. Config.Admin.command, 'Create a drug laboratory (admin)')
TriggerEvent('chat:addSuggestion', '/' .. Config.Admin.manageCommand, 'Manage drug laboratories (admin)')
