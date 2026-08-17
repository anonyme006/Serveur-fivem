Bridge = Bridge or {}

---@param source number|nil
---@param data table|{description:string, type?:string, title?:string, duration?:number}
function Bridge.Notify(source, data)
    if type(data) == 'string' then
        data = { description = data, type = 'inform' }
    end

    if IsDuplicityVersion() then
        if not source then return end
        TriggerClientEvent('ox_lib:notify', source, {
            title = data.title or 'Drug Labs',
            description = data.description or data.message or '',
            type = data.type or 'inform',
            duration = data.duration or 5000,
        })
        return
    end

    lib.notify({
        title = data.title or 'Drug Labs',
        description = data.description or data.message or '',
        type = data.type or 'inform',
        duration = data.duration or 5000,
    })
end
