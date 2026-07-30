ImportExport = ImportExport or {}

RegisterCommand(Config.Commands.export, function(src, args)
    if src > 0 and not Permissions.IsAdmin(src) then
        Permissions.Deny(src, 'export')
        return
    end

    local moduleName = args[1]
    local dump = {
        version = 1,
        exported_at = CoreUtils.ISODate(),
        framework = Bridge.Framework,
        modules = {},
    }

    local modules = moduleName and { moduleName } or CoreCreator.ListEnabledModules()
    for i = 1, #modules do
        local m = modules[i]
        dump.modules[m] = Database.GetAll(m)
    end

    local encoded = CoreUtils.SafeJsonEncode(dump)
    local fileName = ('exports/export_%s.json'):format(os.time())
    SaveResourceFile(CoreUtils.ResourceName(), fileName, encoded, -1)

    if src > 0 then
        Bridge.Notify(src, _('success.exported') .. ' → ' .. fileName, 'success')
        TriggerClientEvent('core_creator:client:exportData', src, dump)
    else
        CoreUtils.Print('Exported to', fileName)
    end
    Logger.Log(src, 'export_all', moduleName or 'all', nil, { file = fileName })
end, true)

RegisterCommand(Config.Commands.import, function(src, args)
    if src > 0 and not Permissions.IsAdmin(src) then
        Permissions.Deny(src, 'import')
        return
    end

    local fileName = args[1]
    if not fileName then
        CoreUtils.Print('Usage: /' .. Config.Commands.import .. ' exports/file.json')
        return
    end

    local raw = LoadResourceFile(CoreUtils.ResourceName(), fileName)
    if not raw then
        if src > 0 then Bridge.Notify(src, 'File not found', 'error') end
        return
    end

    local data = CoreUtils.SafeJsonDecode(raw)
    if type(data) ~= 'table' or type(data.modules) ~= 'table' then
        if src > 0 then Bridge.Notify(src, _('error.invalid'), 'error') end
        return
    end

    local imported = 0
    for moduleName, rows in pairs(data.modules) do
        if Config.Modules[moduleName] then
            for i = 1, math.min(#rows, Config.Limits.importBatch) do
                local row = rows[i]
                local ok, entity = Validator.ValidateEntity(moduleName, {
                    name = row.name,
                    label = row.label,
                    coords = row.coords,
                    data = row.data,
                    active = row.active,
                }, false)
                if ok then
                    if Database.GetByName(moduleName, entity.name) then
                        entity.name = entity.name .. '_imp_' .. tostring(math.random(100, 999))
                    end
                    Database.Create(moduleName, entity, src > 0 and Bridge.GetIdentifier(src) or 'console')
                    imported = imported + 1
                end
            end
            TriggerClientEvent('core_creator:syncModule', -1, moduleName)
        end
    end

    if src > 0 then
        Bridge.Notify(src, _('success.imported') .. ' (' .. imported .. ')', 'success')
    else
        CoreUtils.Print('Imported', imported, 'entities')
    end
    Logger.Log(src, 'import_all', nil, nil, { count = imported, file = fileName })
end, true)
