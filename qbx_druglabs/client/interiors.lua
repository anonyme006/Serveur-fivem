Interiors = {
    zones = {},
}

function Interiors.ClearInteriorZones()
    for _, zoneId in pairs(Interiors.zones) do
        Bridge.RemoveZone(zoneId)
    end
    Interiors.zones = {}
end

local function teleportTo(coords)
    local ped = cache.ped or PlayerPedId()
    DoScreenFadeOut(Config.Labs.entryFadeMs)
    while not IsScreenFadedOut() do Wait(0) end
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    if coords.w then
        SetEntityHeading(ped, coords.w)
    end
    Wait(100)
    DoScreenFadeIn(Config.Labs.entryFadeMs)
end

function Interiors.RebuildInteriorTargets(lab)
    Interiors.ClearInteriorZones()
    if not lab then return end

    local exit = lab.interior and lab.interior.exit or lab.interior and lab.interior.entrance
    if exit then
        Interiors.zones.exit = Bridge.AddSphereZone({
            name = ('druglab_exit_%s'):format(lab.id),
            coords = vec3(exit.x, exit.y, exit.z),
            label = 'Exit Laboratory',
            icon = 'fa-solid fa-door-open',
            onSelect = function()
                Interiors.Leave()
            end,
        })
    end

    local stash = lab.stash
    if stash and stash.coords then
        Interiors.zones.stash = Bridge.AddSphereZone({
            name = ('druglab_stash_%s'):format(lab.id),
            coords = vec3(stash.coords.x, stash.coords.y, stash.coords.z),
            label = 'Open Storage',
            icon = 'fa-solid fa-box',
            onSelect = function()
                local result = lib.callback.await('qbx_druglabs:server:openStash', false, lab.id)
                if not result or not result.ok then
                    Bridge.Notify(nil, { description = result and result.error or 'Denied', type = 'error' })
                end
            end,
        })
    end

    for stationId, station in pairs(lab.stations or {}) do
        local c = station.coords
        if c then
            Interiors.zones['station_' .. stationId] = Bridge.AddSphereZone({
                name = ('druglab_station_%s_%s'):format(lab.id, stationId),
                coords = vec3(c.x, c.y, c.z),
                label = 'Use Station',
                icon = 'fa-solid fa-flask-vial',
                onSelect = function()
                    if lab.type == 'weed' and (station.recipeGroup == 'plant' or stationId:find('plant', 1, true)) then
                        PlantsClient.OpenStation(lab.id, stationId)
                    else
                        ProductionClient.OpenStation(lab.id, stationId, station)
                    end
                end,
            })
        end
    end

    Interiors.zones.manage = Bridge.AddSphereZone({
        name = ('druglab_manage_%s'):format(lab.id),
        coords = vec3((exit and exit.x or 0) + 0.01, (exit and exit.y or 0), exit and exit.z or 0),
        label = 'Laboratory Management',
        icon = 'fa-solid fa-briefcase',
        distance = 2.5,
        onSelect = function()
            Interiors.OpenManagement(lab.id)
        end,
    })
end

function Interiors.Enter(labId)
    local result = lib.callback.await('qbx_druglabs:server:enterLab', false, labId)
    if not result or not result.ok then
        local err = result and result.error or 'Cannot enter'
        if err == 'locked' then
            Bridge.Notify(nil, { description = 'Laboratory is locked. Enter the code first.', type = 'error' })
        elseif err == 'sealed' then
            Bridge.Notify(nil, { description = 'Laboratory is sealed by police.', type = 'error' })
        else
            Bridge.Notify(nil, { description = err, type = 'error' })
        end
        return
    end

    local lab = result.data.lab
    ClientLabs.Set(lab)
    ClientLabs.insideLabId = lab.id
    LocalPlayer.state:set('druglabId', lab.id, false)

    local entrance = lab.interior and lab.interior.entrance
    if entrance then
        teleportTo(vec4(entrance.x, entrance.y, entrance.z, entrance.w or 0.0))
    end

    Interiors.RebuildInteriorTargets(lab)
    if lab.type == 'weed' then
        PlantsClient.Cache = result.data.plants or {}
    end
    Bridge.Notify(nil, { description = ('Entered %s'):format(lab.label), type = 'inform' })
end

function Interiors.Leave(forced)
    local labId = ClientLabs.insideLabId
    local lab = labId and ClientLabs.Get(labId)
    Interiors.ClearInteriorZones()
    ClientLabs.insideLabId = nil
    LocalPlayer.state:set('druglabId', nil, false)
    MaskEffects.Stop()

    if not forced then
        lib.callback.await('qbx_druglabs:server:leaveLab', false)
    end

    if lab and lab.entrance then
        teleportTo(vec4(lab.entrance.x, lab.entrance.y, lab.entrance.z, lab.entrance.w or 0.0))
    end
end

RegisterNetEvent(DrugLabs.Events.client.leaveLab, function(reason)
    if ClientLabs.insideLabId then
        Interiors.Leave(true)
        Bridge.Notify(nil, { description = ('Removed from laboratory (%s)'):format(reason or 'forced'), type = 'warning' })
    end
end)

RegisterNetEvent(DrugLabs.Events.client.enterLab, function(labId)
    Interiors.Enter(labId)
end)

function Interiors.OpenManagement(labId)
    local result = lib.callback.await('qbx_druglabs:server:getManagement', false, labId)
    if not result or not result.ok then
        Bridge.Notify(nil, { description = result and result.error or 'Denied', type = 'error' })
        return
    end

    local data = result.data
    local lab = data.lab
    local perms = data.permissions or {}

    local options = {
        {
            title = 'Status',
            description = ('%s | %s | %s'):format(
                lab.locked and 'Locked' or 'Unlocked',
                lab.sealed and 'Sealed' or 'Not sealed',
                lab.ownershipType
            ),
            icon = 'circle-info',
            readOnly = true,
        },
    }

    if perms.LOCK_LAB then
        options[#options + 1] = {
            title = lab.locked and 'Unlock Laboratory' or 'Lock Laboratory',
            icon = 'lock',
            onSelect = function()
                local res = lib.callback.await('qbx_druglabs:server:setLocked', false, lab.id, not lab.locked)
                Bridge.Notify(nil, {
                    description = res and res.ok and 'Updated' or (res and res.error or 'Failed'),
                    type = res and res.ok and 'success' or 'error',
                })
            end,
        }
    end

    if perms.CHANGE_CODE then
        options[#options + 1] = {
            title = 'Change Access Code',
            icon = 'key',
            onSelect = function()
                local input = lib.inputDialog('New Code', {
                    { type = 'input', label = 'Digits only', password = true, required = true, min = Config.Security.codeMinLength, max = Config.Security.codeMaxLength },
                })
                if not input then return end
                local res = lib.callback.await('qbx_druglabs:server:changeCode', false, lab.id, input[1])
                Bridge.Notify(nil, {
                    description = res and res.ok and 'Code updated' or (res and res.error or 'Failed'),
                    type = res and res.ok and 'success' or 'error',
                })
            end,
        }
    end

    if perms.MANAGE_MEMBERS then
        options[#options + 1] = {
            title = 'Members',
            icon = 'users',
            onSelect = function()
                Interiors.OpenMembersMenu(lab.id, data.members or {})
            end,
        }
    end

    if perms.SELL_LAB then
        options[#options + 1] = {
            title = 'Sell to Server',
            icon = 'dollar-sign',
            onSelect = function()
                local confirm = lib.alertDialog({
                    header = 'Sell Laboratory',
                    content = ('Sell for $%s?'):format(math.floor((lab.purchasePrice or 0) * (lab.sellPercentage or 0.65))),
                    centered = true,
                    cancel = true,
                })
                if confirm ~= 'confirm' then return end
                local res = lib.callback.await('qbx_druglabs:server:sellLab', false, lab.id)
                Bridge.Notify(nil, {
                    description = res and res.ok and ('Sold for $%s'):format(res.data.payout) or (res and res.error or 'Failed'),
                    type = res and res.ok and 'success' or 'error',
                })
                if res and res.ok and ClientLabs.insideLabId == lab.id then
                    Interiors.Leave()
                end
            end,
        }
        options[#options + 1] = {
            title = 'Transfer Ownership',
            icon = 'right-left',
            onSelect = function()
                local input = lib.inputDialog('Transfer', {
                    { type = 'number', label = 'Player server ID', required = true },
                })
                if not input then return end
                local res = lib.callback.await('qbx_druglabs:server:transferLab', false, lab.id, input[1])
                Bridge.Notify(nil, {
                    description = res and res.ok and 'Transferred' or (res and res.error or 'Failed'),
                    type = res and res.ok and 'success' or 'error',
                })
            end,
        }
    end

    if data.rental and data.isOwner then
        options[#options + 1] = {
            title = 'Renew Rental',
            icon = 'calendar',
            onSelect = function()
                local res = lib.callback.await('qbx_druglabs:server:renewRent', false, lab.id)
                Bridge.Notify(nil, {
                    description = res and res.ok and 'Renewed' or (res and res.error or 'Failed'),
                    type = res and res.ok and 'success' or 'error',
                })
            end,
        }
    end

    lib.registerContext({
        id = 'druglab_manage_' .. lab.id,
        title = 'Laboratory Management',
        options = options,
    })
    lib.showContext('druglab_manage_' .. lab.id)
end

function Interiors.OpenMembersMenu(labId, members)
    local options = {
        {
            title = 'Add Nearby Player',
            icon = 'user-plus',
            onSelect = function()
                local input = lib.inputDialog('Add Member', {
                    { type = 'number', label = 'Player server ID', required = true },
                })
                if not input then return end
                local res = lib.callback.await('qbx_druglabs:server:addMember', false, labId, input[1])
                Bridge.Notify(nil, {
                    description = res and res.ok and 'Member added' or (res and res.error or 'Failed'),
                    type = res and res.ok and 'success' or 'error',
                })
            end,
        },
    }

    for i = 1, #members do
        local member = members[i]
        options[#options + 1] = {
            title = member.citizenid,
            description = 'Remove or edit permissions',
            icon = 'user',
            onSelect = function()
                lib.registerContext({
                    id = 'druglab_member_' .. member.citizenid,
                    title = member.citizenid,
                    menu = 'druglab_members_' .. labId,
                    options = {
                        {
                            title = 'Remove Member',
                            icon = 'user-minus',
                            onSelect = function()
                                lib.callback.await('qbx_druglabs:server:removeMember', false, labId, member.citizenid)
                            end,
                        },
                        {
                            title = 'Edit Permissions',
                            icon = 'sliders',
                            onSelect = function()
                                local perms = member.permissions or DrugLabs.DefaultMemberPermissions
                                local input = lib.inputDialog('Permissions (1=yes 0=no)', {
                                    { type = 'number', label = 'USE_STASH', default = perms.USE_STASH and 1 or 0 },
                                    { type = 'number', label = 'START_PRODUCTION', default = perms.START_PRODUCTION and 1 or 0 },
                                    { type = 'number', label = 'COLLECT_PRODUCTION', default = perms.COLLECT_PRODUCTION and 1 or 0 },
                                    { type = 'number', label = 'LOCK_LAB', default = perms.LOCK_LAB and 1 or 0 },
                                    { type = 'number', label = 'CHANGE_CODE', default = perms.CHANGE_CODE and 1 or 0 },
                                    { type = 'number', label = 'MANAGE_MEMBERS', default = perms.MANAGE_MEMBERS and 1 or 0 },
                                })
                                if not input then return end
                                local newPerms = DrugLabs.DeepCopy(DrugLabs.DefaultMemberPermissions)
                                newPerms.USE_STASH = input[1] == 1
                                newPerms.START_PRODUCTION = input[2] == 1
                                newPerms.COLLECT_PRODUCTION = input[3] == 1
                                newPerms.LOCK_LAB = input[4] == 1
                                newPerms.CHANGE_CODE = input[5] == 1
                                newPerms.MANAGE_MEMBERS = input[6] == 1
                                newPerms.ENTER = true
                                newPerms.SELL_LAB = false
                                lib.callback.await('qbx_druglabs:server:updateMember', false, labId, member.citizenid, newPerms)
                            end,
                        },
                    },
                })
                lib.showContext('druglab_member_' .. member.citizenid)
            end,
        }
    end

    lib.registerContext({
        id = 'druglab_members_' .. labId,
        title = 'Members',
        options = options,
    })
    lib.showContext('druglab_members_' .. labId)
end
