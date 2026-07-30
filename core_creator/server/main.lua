CoreCreator = CoreCreator or {}
CoreCreator.Modules = CoreCreator.Modules or {}

local function authorOf(src)
    if not src or src <= 0 then return 'console' end
    return Bridge.GetIdentifier(src) or ('src:' .. tostring(src))
end

function CoreCreator.RegisterModule(name, definition)
    CoreCreator.Modules[name] = definition or {}
    CoreUtils.Debug('Registered module', name)
end

function CoreCreator.ListEnabledModules()
    local list = {}
    for name, enabled in pairs(Config.Modules) do
        if enabled then
            list[#list + 1] = name
        end
    end
    table.sort(list)
    return list
end

local function respond(ok, data, message)
    return { ok = ok, data = data, message = message }
end

local function useOxLibCallbacks()
    return CoreUtils.ResourceStarted('ox_lib') and lib and lib.callback and lib.callback.register
end

local function registerCb(name, fn)
    if useOxLibCallbacks() then
        lib.callback.register(name, fn)
        return
    end

    RegisterNetEvent(name .. ':request', function(requestId, payload)
        local src = source
        local ok, result = pcall(fn, src, payload)
        if not ok then
            CoreUtils.Print('Callback error', name, result)
            result = respond(false, nil, 'internal_error')
        end
        TriggerClientEvent(name .. ':response', src, requestId, result)
    end)
end

CreateThread(function()
    Wait(250)

    registerCb('core_creator:getBootstrap', function(src)
        if not Permissions.IsAdmin(src) then
            return respond(false, nil, 'permission')
        end
        local counts = {}
        for _, moduleName in ipairs(CoreCreator.ListEnabledModules()) do
            counts[moduleName] = #Database.GetAll(moduleName)
        end
        return respond(true, {
            modules = CoreCreator.ListEnabledModules(),
            counts = counts,
            locale = Config.Locale,
            framework = Bridge.Framework,
            autoSave = Config.AutoSave,
            permissions = {
                admin = true,
                modules = Config.Modules,
            },
        })
    end)

    registerCb('core_creator:list', function(src, payload)
        local moduleName = payload and payload.module
        if not ServerValidator.AssertAdmin(src, moduleName) then
            return respond(false, nil, 'permission')
        end
        return respond(true, Database.GetAll(moduleName))
    end)

    registerCb('core_creator:get', function(src, payload)
        local moduleName = payload and payload.module
        if not ServerValidator.AssertAdmin(src, moduleName) then
            return respond(false, nil, 'permission')
        end
        local row = Database.GetById(moduleName, payload.id)
        if not row then return respond(false, nil, 'not_found') end
        return respond(true, row)
    end)

    registerCb('core_creator:create', function(src, payload)
        local moduleName = payload and payload.module
        if not ServerValidator.AssertAdmin(src, moduleName) then
            return respond(false, nil, 'permission')
        end
        local ok, data = Validator.ValidateEntity(moduleName, payload.entity or payload, false)
        if not ok then return respond(false, nil, data) end
        if Database.GetByName(moduleName, data.name) then
            return respond(false, nil, 'name_exists')
        end

        local mod = CoreCreator.Modules[moduleName]
        if mod and mod.beforeCreate then
            local bok, bmsg = mod.beforeCreate(src, data)
            if bok == false then return respond(false, nil, bmsg or 'rejected') end
        end

        local id = Database.Create(moduleName, data, authorOf(src))
        if not id then return respond(false, nil, 'db_error') end

        Logger.Log(src, 'create', moduleName, id, { name = data.name })
        TriggerEvent('core_creator:entityChanged', moduleName, 'create', id)
        TriggerClientEvent('core_creator:syncModule', -1, moduleName)
        if mod and mod.afterCreate then mod.afterCreate(src, id, data) end
        return respond(true, { id = id }, 'created')
    end)

    registerCb('core_creator:update', function(src, payload)
        local moduleName = payload and payload.module
        if not ServerValidator.AssertAdmin(src, moduleName) then
            return respond(false, nil, 'permission')
        end
        local ok, data = Validator.ValidateEntity(moduleName, payload.entity or payload, true)
        if not ok then return respond(false, nil, data) end

        local mod = CoreCreator.Modules[moduleName]
        if mod and mod.beforeUpdate then
            local bok, bmsg = mod.beforeUpdate(src, data)
            if bok == false then return respond(false, nil, bmsg or 'rejected') end
        end

        local success, err = Database.Update(moduleName, data.id, data, authorOf(src))
        if not success then return respond(false, nil, err or 'db_error') end

        Logger.Log(src, 'update', moduleName, data.id, { name = data.name })
        TriggerEvent('core_creator:entityChanged', moduleName, 'update', data.id)
        TriggerClientEvent('core_creator:syncModule', -1, moduleName)
        if mod and mod.afterUpdate then mod.afterUpdate(src, data.id, data) end
        return respond(true, { id = data.id }, 'updated')
    end)

    registerCb('core_creator:delete', function(src, payload)
        local moduleName = payload and payload.module
        if not ServerValidator.AssertAdmin(src, moduleName) then
            return respond(false, nil, 'permission')
        end
        local id = tonumber(payload and payload.id)
        if not id then return respond(false, nil, 'invalid_id') end

        local mod = CoreCreator.Modules[moduleName]
        if mod and mod.beforeDelete then
            local bok, bmsg = mod.beforeDelete(src, id)
            if bok == false then return respond(false, nil, bmsg or 'rejected') end
        end

        Database.Delete(moduleName, id)
        Logger.Log(src, 'delete', moduleName, id, {})
        TriggerEvent('core_creator:entityChanged', moduleName, 'delete', id)
        TriggerClientEvent('core_creator:syncModule', -1, moduleName)
        if mod and mod.afterDelete then mod.afterDelete(src, id) end
        return respond(true, { id = id }, 'deleted')
    end)

    registerCb('core_creator:toggle', function(src, payload)
        local moduleName = payload and payload.module
        if not ServerValidator.AssertAdmin(src, moduleName) then
            return respond(false, nil, 'permission')
        end
        local id = tonumber(payload and payload.id)
        if not id then return respond(false, nil, 'invalid_id') end
        local active = payload.active and true or false
        Database.SetActive(moduleName, id, active, authorOf(src))
        Logger.Log(src, active and 'enable' or 'disable', moduleName, id, {})
        TriggerClientEvent('core_creator:syncModule', -1, moduleName)
        return respond(true, { id = id, active = active }, 'toggled')
    end)

    registerCb('core_creator:duplicate', function(src, payload)
        local moduleName = payload and payload.module
        if not ServerValidator.AssertAdmin(src, moduleName) then
            return respond(false, nil, 'permission')
        end
        local id = tonumber(payload and payload.id)
        local newId, err = Database.Duplicate(moduleName, id, authorOf(src))
        if not newId then return respond(false, nil, err or 'db_error') end
        Logger.Log(src, 'duplicate', moduleName, newId, { from = id })
        TriggerClientEvent('core_creator:syncModule', -1, moduleName)
        return respond(true, { id = newId }, 'duplicated')
    end)

    registerCb('core_creator:exportOne', function(src, payload)
        local moduleName = payload and payload.module
        if not ServerValidator.AssertAdmin(src, moduleName) then
            return respond(false, nil, 'permission')
        end
        local row = Database.GetById(moduleName, payload.id)
        if not row then return respond(false, nil, 'not_found') end
        return respond(true, {
            version = 1,
            module = moduleName,
            exported_at = CoreUtils.ISODate(),
            entity = {
                name = row.name,
                label = row.label,
                coords = row.coords,
                data = row.data,
                active = row.active,
            },
        })
    end)

    registerCb('core_creator:importOne', function(src, payload)
        local moduleName = payload and payload.module
        if not ServerValidator.AssertAdmin(src, moduleName) then
            return respond(false, nil, 'permission')
        end
        local entity = payload and payload.entity
        if type(entity) ~= 'table' then return respond(false, nil, 'invalid') end
        local ok, data = ServerValidator.SanitizeImport(moduleName, entity)
        if not ok then return respond(false, nil, data) end

        if Database.GetByName(moduleName, data.name) then
            if payload.onConflict == 'rename' then
                data.name = data.name .. '_' .. tostring(math.random(100, 999))
            elseif payload.onConflict == 'update' then
                local existing = Database.GetByName(moduleName, data.name)
                Database.Update(moduleName, existing.id, data, authorOf(src))
                TriggerClientEvent('core_creator:syncModule', -1, moduleName)
                Logger.Log(src, 'import_update', moduleName, existing.id, { name = data.name })
                return respond(true, { id = existing.id }, 'imported')
            else
                return respond(false, nil, 'name_exists')
            end
        end

        local id = Database.Create(moduleName, data, authorOf(src))
        Logger.Log(src, 'import', moduleName, id, { name = data.name })
        TriggerClientEvent('core_creator:syncModule', -1, moduleName)
        return respond(true, { id = id }, 'imported')
    end)

    CoreUtils.Print('Server callbacks registered')
end)

RegisterCommand(Config.Commands.reload, function(src)
    if src > 0 and not Permissions.IsAdmin(src) then
        Permissions.Deny(src, 'reload')
        return
    end
    Database.Invalidate()
    for _, moduleName in ipairs(CoreCreator.ListEnabledModules()) do
        TriggerClientEvent('core_creator:syncModule', -1, moduleName)
    end
    if src > 0 then
        Bridge.Notify(src, _('notify.reloaded'), 'success')
    else
        CoreUtils.Print('Modules reloaded')
    end
    Logger.Log(src, 'reload', 'core', nil, {})
end, true)

RegisterCommand(Config.Commands.debug, function(src)
    if src > 0 and not Permissions.IsAdmin(src) then return end
    Config.Debug = not Config.Debug
    local msg = 'Debug = ' .. tostring(Config.Debug)
    if src > 0 then Bridge.Notify(src, msg, 'inform') else CoreUtils.Print(msg) end
end, true)

AddEventHandler('onResourceStart', function(res)
    if res ~= CoreUtils.ResourceName() then return end
    CoreUtils.Print('Started')
end)

exports('ReloadModule', function(moduleName)
    Database.Invalidate(moduleName)
    TriggerClientEvent('core_creator:syncModule', -1, moduleName)
end)

exports('CreateEntity', function(moduleName, entity, author)
    local ok, data = Validator.ValidateEntity(moduleName, entity, false)
    if not ok then return nil, data end
    return Database.Create(moduleName, data, author or 'api')
end)

exports('DeleteEntity', function(moduleName, id)
    return Database.Delete(moduleName, id)
end)

local function getEntity(moduleName, idOrName)
    return tonumber(idOrName) and Database.GetById(moduleName, idOrName) or Database.GetByName(moduleName, idOrName)
end

exports('GetShop', function(idOrName) return getEntity('shops', idOrName) end)
exports('GetJob', function(idOrName) return getEntity('jobs', idOrName) end)
exports('GetGang', function(idOrName) return getEntity('gangs', idOrName) end)
exports('GetGarage', function(idOrName) return getEntity('garages', idOrName) end)
exports('GetApartment', function(idOrName) return getEntity('apartments', idOrName) end)
exports('GetRobbery', function(idOrName) return getEntity('robberies', idOrName) end)
exports('GetFarm', function(idOrName) return getEntity('farms', idOrName) end)
exports('GetBlip', function(idOrName) return getEntity('blips', idOrName) end)
