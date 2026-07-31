local Points = Gruppe6Points

local function canManagePoints(src)
    if IsPlayerAceAllowed(src --[[@as string]], 'command') then return true end
    local job = exports.vibe_api:GetJob(src)
    if not job or job.name ~= Config.Job then return false end
    return job.isboss == true or (job.grade and job.grade.level and job.grade.level >= 1)
end

local function notifyNoAccess(src)
    exports.vibe_api:Notify(src, 'Gruppe 6', 'Accès refusé (boss Gruppe 6 ou admin).', 'error')
end

local function broadcastPoints()
    local points = Points.Load()
    TriggerClientEvent('vibe_gruppe6:client:refreshPoints', -1, points)
end

lib.addCommand('g6addpoint', {
    help = 'Ajouter un point de collecte Gruppe 6 à votre position',
    params = {
        { name = 'type', type = 'string', help = 'magasin | banque | armurerie | grossiste' },
        { name = 'label', type = 'string', help = 'Nom du point (optionnel)', optional = true },
    },
}, function(source, args)
    if not canManagePoints(source) then
        notifyNoAccess(source)
        return
    end

    local pointType = string.lower(args.type or '')
    if not Points.IsValidType(pointType) then
        exports.vibe_api:Notify(source, 'Gruppe 6', 'Type invalide. Utilise: magasin, banque, armurerie, grossiste.', 'error')
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
    exports.vibe_api:Notify(source, 'Gruppe 6', ('Point #%s ajouté: %s (%s)'):format(point.id, label, pointType), 'success')
end)

lib.addCommand('g6delpoint', {
    help = 'Supprimer un point de collecte Gruppe 6',
    params = {
        { name = 'id', type = 'number', help = 'ID du point' },
    },
}, function(source, args)
    if not canManagePoints(source) then
        notifyNoAccess(source)
        return
    end

    local id = tonumber(args.id)
    if not id then return end

    if Points.Delete(id) then
        broadcastPoints()
        exports.vibe_api:Notify(source, 'Gruppe 6', ('Point #%s supprimé.'):format(id), 'success')
    else
        exports.vibe_api:Notify(source, 'Gruppe 6', 'Point introuvable.', 'error')
    end
end)

lib.addCommand('g6togglepoint', {
    help = 'Activer ou désactiver un point de collecte Gruppe 6',
    params = {
        { name = 'id', type = 'number', help = 'ID du point' },
    },
}, function(source, args)
    if not canManagePoints(source) then
        notifyNoAccess(source)
        return
    end

    local id = tonumber(args.id)
    if not id then return end

    local point = Points.GetById(id)
    if not point then
        exports.vibe_api:Notify(source, 'Gruppe 6', 'Point introuvable.', 'error')
        return
    end

    local newState = not point.enabled
    Points.Toggle(id, newState)
    broadcastPoints()
    exports.vibe_api:Notify(source, 'Gruppe 6', ('Point #%s %s.'):format(id, newState and 'activé' or 'désactivé'), 'success')
end)

lib.addCommand('g6listpoints', {
    help = 'Lister les points de collecte Gruppe 6',
}, function(source)
    if not canManagePoints(source) then
        notifyNoAccess(source)
        return
    end

    local points = Points.Load()
    if #points == 0 then
        exports.vibe_api:Notify(source, 'Gruppe 6', 'Aucun point configuré.', 'inform')
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
