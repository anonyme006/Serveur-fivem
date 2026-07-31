local Points = Gruppe6Points

local function notify(src, msg, nType)
    TriggerClientEvent('esx_gruppe6:notify', src, 'Gruppe 6', msg, nType or 'inform')
end

local function canManagePoints(src)
    if IsPlayerAceAllowed(src --[[@as string]], 'command') then return true end
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not xPlayer.job or xPlayer.job.name ~= Config.Job then return false end
    return (xPlayer.job.grade or 0) >= (Config.BossMinGrade or 1)
end

local function broadcastPoints()
    TriggerClientEvent('esx_gruppe6:client:refreshPoints', -1, Points.Load())
end

lib.addCommand('g6addpoint', {
    help = 'Ajouter un point de collecte Gruppe 6 à votre position',
    params = {
        { name = 'type', type = 'string', help = 'magasin | banque | armurerie | grossiste' },
        { name = 'label', type = 'string', help = 'Nom du point (optionnel)', optional = true },
    },
}, function(source, args)
    if not canManagePoints(source) then
        notify(source, L('access_denied'), 'error')
        return
    end

    local pointType = string.lower(args.type or '')
    if not Points.IsValidType(pointType) then
        notify(source, L('invalid_type'), 'error')
        return
    end

    local ped = GetPlayerPed(source)
    if ped == 0 then return end
    local coords = GetEntityCoords(ped)
    local label = args.label
    if not label or label == '' then
        label = ('%s #%s'):format(Config.TypeLabels[pointType] or pointType, os.time())
    end

    local point = Points.Add(pointType, label, coords)
    broadcastPoints()
    notify(source, L('point_added', point.id, label, pointType), 'success')
end)

lib.addCommand('g6delpoint', {
    help = 'Supprimer un point de collecte Gruppe 6',
    params = {
        { name = 'id', type = 'number', help = 'ID du point' },
    },
}, function(source, args)
    if not canManagePoints(source) then
        notify(source, L('access_denied'), 'error')
        return
    end

    local id = tonumber(args.id)
    if not id then return end

    if Points.Delete(id) then
        broadcastPoints()
        notify(source, L('point_deleted', id), 'success')
    else
        notify(source, L('point_not_found'), 'error')
    end
end)

lib.addCommand('g6togglepoint', {
    help = 'Activer ou désactiver un point de collecte Gruppe 6',
    params = {
        { name = 'id', type = 'number', help = 'ID du point' },
    },
}, function(source, args)
    if not canManagePoints(source) then
        notify(source, L('access_denied'), 'error')
        return
    end

    local id = tonumber(args.id)
    if not id then return end

    local point = Points.GetById(id)
    if not point then
        notify(source, L('point_not_found'), 'error')
        return
    end

    local newState = not point.enabled
    Points.Toggle(id, newState)
    broadcastPoints()
    notify(source, L('point_toggled', id, newState and 'activé' or 'désactivé'), 'success')
end)

lib.addCommand('g6listpoints', {
    help = 'Lister les points de collecte Gruppe 6',
}, function(source)
    if not canManagePoints(source) then
        notify(source, L('access_denied'), 'error')
        return
    end

    local points = Points.Load()
    if #points == 0 then
        notify(source, L('no_points'), 'inform')
        return
    end

    TriggerClientEvent('chat:addMessage', source, {
        color = { 46, 125, 50 },
        multiline = true,
        args = { 'Gruppe 6', ('%s point(s) configuré(s):'):format(#points) },
    })

    for i = 1, #points do
        local p = points[i]
        TriggerClientEvent('chat:addMessage', source, {
            color = { 200, 200, 200 },
            multiline = true,
            args = {
                'Gruppe 6',
                ('#%s [%s] %s — %s (%.1f, %.1f, %.1f)'):format(
                    p.id,
                    p.enabled and 'ON' or 'OFF',
                    p.type,
                    p.label,
                    p.coords.x,
                    p.coords.y,
                    p.coords.z
                ),
            },
        })
    end
end)
