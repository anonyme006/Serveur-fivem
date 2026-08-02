--[[--------------------------------------------------------------------------
    core_garage — administration SQL (/garageadmin)
---------------------------------------------------------------------------]]

local function requireAdmin(source)
    if not GarageSecurity.IsAdmin(source) then
        GarageNotify(source, _('no_permission'), 'error')
        return false
    end
    return true
end

lib.callback.register('core_garage:admin:isAdmin', function(source)
    return GarageSecurity.IsAdmin(source)
end)

lib.callback.register('core_garage:admin:list', function(source)
    if not GarageSecurity.IsAdmin(source) then return {} end
    return GarageDB.GetPublicGarages()
end)

lib.callback.register('core_garage:admin:create', function(source, data)
    if not requireAdmin(source) then return { ok = false } end
    if type(data) ~= 'table' or not data.name or not data.label or not data.type then
        return { ok = false, error = 'error' }
    end
    if not GarageUtils.ValidTypes[data.type] then
        return { ok = false, error = 'error' }
    end

    local name = tostring(data.name):gsub('%s+', '_'):lower()
    if GarageDB.GetGarage(name) then
        return { ok = false, error = 'error' }
    end

    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    local id = MySQL.insert.await([[
        INSERT INTO garages
            (name, label, type, coords, spawn, heading, store, blip, marker, job, gang, min_grade, vehicle_type, impound_price, impound_time, enabled)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1)
    ]], {
        name,
        data.label,
        data.type,
        GarageUtils.Encode({ x = coords.x, y = coords.y, z = coords.z }),
        GarageUtils.Encode({ x = coords.x, y = coords.y, z = coords.z, w = heading }),
        heading,
        GarageUtils.Encode({ x = coords.x, y = coords.y, z = coords.z }),
        GarageUtils.Encode(GarageUtils.Merge(Config.DefaultBlips[data.type] or Config.DefaultBlips.public, { enabled = true })),
        GarageUtils.Encode(GarageUtils.Merge(Config.DefaultMarkers, { enabled = true })),
        data.job,
        data.gang,
        tonumber(data.minGrade) or 0,
        data.vehicleType or Config.GarageVehicleTypes[data.type] or 'car',
        tonumber(data.impoundPrice) or Config.Impound.defaultPrice,
        tonumber(data.impoundTime) or Config.Impound.defaultTimeMinutes,
    })

    if data.type == 'company' or data.type == 'job' then
        if data.job and data.job ~= '' then
            MySQL.insert.await([[
                INSERT IGNORE INTO garage_company
                    (job, garage, label, min_grade_out, min_grade_store, min_grade_manage, max_out, shared)
                VALUES (?, ?, ?, 0, 0, 2, 5, 1)
            ]], { data.job, name, data.label })
        end
    end

    GarageDB.RefreshGarages()
    GarageDB.RefreshCompanies()
    GarageBroadcast()

    GarageNotify(source, _('admin_created'), 'success')
    return { ok = true, id = id, name = name }
end)

lib.callback.register('core_garage:admin:update', function(source, data)
    if not requireAdmin(source) then return { ok = false } end
    if type(data) ~= 'table' or not data.name then return { ok = false } end

    local g = GarageDB.GetGarage(data.name)
    if not g then return { ok = false, error = 'admin_no_garage' } end

    MySQL.update.await([[
        UPDATE garages SET
            label = COALESCE(?, label),
            type = COALESCE(?, type),
            job = ?,
            gang = ?,
            min_grade = COALESCE(?, min_grade),
            vehicle_type = COALESCE(?, vehicle_type),
            impound_price = COALESCE(?, impound_price),
            impound_time = COALESCE(?, impound_time),
            enabled = COALESCE(?, enabled)
        WHERE name = ?
    ]], {
        data.label,
        data.type,
        data.job,
        data.gang,
        data.minGrade,
        data.vehicleType,
        data.impoundPrice,
        data.impoundTime,
        data.enabled == nil and nil or (data.enabled and 1 or 0),
        data.name,
    })

    GarageDB.RefreshGarages()
    GarageBroadcast()
    GarageNotify(source, _('admin_updated'), 'success')
    return { ok = true }
end)

lib.callback.register('core_garage:admin:delete', function(source, name)
    if not requireAdmin(source) then return { ok = false } end
    name = tostring(name or '')
    if name == '' then return { ok = false } end

    MySQL.update.await('DELETE FROM garages WHERE name = ?', { name })
    MySQL.update.await('DELETE FROM garage_company WHERE garage = ?', { name })
    GarageDB.RefreshGarages()
    GarageDB.RefreshCompanies()
    GarageBroadcast()
    GarageNotify(source, _('admin_deleted'), 'success')
    return { ok = true }
end)

lib.callback.register('core_garage:admin:setCoords', function(source, name, kind)
    if not requireAdmin(source) then return { ok = false } end
    local g = GarageDB.GetGarage(name)
    if not g then return { ok = false, error = 'admin_no_garage' } end

    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local payload = GarageUtils.Encode({ x = coords.x, y = coords.y, z = coords.z, w = heading })

    if kind == 'coords' then
        MySQL.update.await('UPDATE garages SET coords = ? WHERE name = ?', {
            GarageUtils.Encode({ x = coords.x, y = coords.y, z = coords.z }), name
        })
        GarageNotify(source, _('admin_moved'), 'success')
    elseif kind == 'spawn' then
        MySQL.update.await('UPDATE garages SET spawn = ?, heading = ? WHERE name = ?', { payload, heading, name })
        GarageNotify(source, _('admin_spawn_set'), 'success')
    elseif kind == 'store' then
        MySQL.update.await('UPDATE garages SET store = ? WHERE name = ?', {
            GarageUtils.Encode({ x = coords.x, y = coords.y, z = coords.z }), name
        })
        GarageNotify(source, _('admin_store_set'), 'success')
    else
        return { ok = false }
    end

    GarageDB.RefreshGarages()
    GarageBroadcast()
    return { ok = true, coords = { x = coords.x, y = coords.y, z = coords.z, w = heading } }
end)

lib.callback.register('core_garage:admin:setBlip', function(source, name, blip)
    if not requireAdmin(source) then return { ok = false } end
    if not GarageDB.GetGarage(name) then return { ok = false } end
    MySQL.update.await('UPDATE garages SET blip = ? WHERE name = ?', { GarageUtils.Encode(blip or {}), name })
    GarageDB.RefreshGarages()
    GarageBroadcast()
    GarageNotify(source, _('admin_blip_set'), 'success')
    return { ok = true }
end)

lib.callback.register('core_garage:admin:toggle', function(source, name, enabled)
    if not requireAdmin(source) then return { ok = false } end
    MySQL.update.await('UPDATE garages SET enabled = ? WHERE name = ?', { enabled and 1 or 0, name })
    GarageDB.RefreshGarages()
    GarageBroadcast()
    GarageNotify(source, _('admin_updated'), 'success')
    return { ok = true }
end)
