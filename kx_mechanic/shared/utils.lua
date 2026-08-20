Utils = {}

local ITEM_LABELS = {
    engine_part = 'Pièce moteur',
    brake_part = 'Pièce freins',
    transmission_part = 'Pièce transmission',
    suspension_part = 'Pièce suspension',
    clutch_part = 'Pièce embrayage',
    repair_kit = 'Kit de réparation',
    tire = 'Pneu',
    oil = 'Huile moteur',
    battery = 'Batterie',
    radiator = 'Radiateur',
    spark_plug = 'Bougie',
    cleaning_kit = 'Kit nettoyage',
    body_kit = 'Kit carrosserie',
}

function Utils.Debug(...)
    if not Config.Debug then return end
    print(('[kx_mechanic] %s'):format(table.concat({ ... }, ' ')))
end

function Utils.NormalizePlate(plate)
    if not plate then return nil end
    return (tostring(plate):gsub('%s+', ''):upper())
end

function Utils.Clamp(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end

function Utils.Round(value, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(value * mult + 0.5) / mult
end

function Utils.Percent(value, max)
    max = max or 100.0
    if max <= 0 then return 0 end
    return Utils.Clamp(Utils.Round((value / max) * 100, 0), 0, 100)
end

function Utils.HealthBar(percent)
    percent = Utils.Clamp(percent or 0, 0, 100)
    local filled = math.floor(percent / 10)
    local empty = 10 - filled
    return string.rep('█', filled) .. string.rep('░', empty)
end

function Utils.GetService(serviceId)
    for i = 1, #Config.Services do
        if Config.Services[i].id == serviceId then
            return Config.Services[i]
        end
    end
    return nil
end

function Utils.GetServicePrice(serviceId)
    return Config.Prices[serviceId] or 0
end

function Utils.GetServiceDuration(serviceId)
    return Config.RepairTimes[serviceId] or 5000
end

function Utils.GetRequiredItems(serviceId)
    return Config.RequiredItems[serviceId] or {}
end

function Utils.GetItemLabel(item)
    return ITEM_LABELS[item] or item
end

function Utils.FormatMoney(amount)
    amount = tonumber(amount) or 0
    local formatted = tostring(math.floor(amount))
    while true do
        local k
        formatted, k = formatted:gsub('^(-?%d+)(%d%d%d)', '%1 %2')
        if k == 0 then break end
    end
    return formatted .. '$'
end

function Utils.HasPermission(grade, permission)
    local required = Config.Permissions[permission]
    if required == nil then return false end
    return (tonumber(grade) or 0) >= required
end

function Utils.IsBossGrade(grade)
    grade = tonumber(grade) or 0
    for i = 1, #Config.BossGrades do
        if Config.BossGrades[i] == grade then
            return true
        end
    end
    return false
end

function Utils.DeepCopy(original)
    if type(original) ~= 'table' then return original end
    local copy = {}
    for key, value in pairs(original) do
        copy[key] = Utils.DeepCopy(value)
    end
    return copy
end

function Utils.MergeDefaults(data)
    local result = Utils.DeepCopy(Config.DefaultVehicleData)
    if type(data) ~= 'table' then return result end

    for key, value in pairs(data) do
        if type(value) == 'table' and type(result[key]) == 'table' then
            for nestedKey, nestedValue in pairs(value) do
                result[key][nestedKey] = nestedValue
            end
        else
            result[key] = value
        end
    end

    return result
end

function Utils.DecodeJson(value, fallback)
    if type(value) == 'table' then return value end
    if type(value) ~= 'string' or value == '' then
        return fallback or {}
    end

    local ok, decoded = pcall(json.decode, value)
    if ok and type(decoded) == 'table' then
        return decoded
    end

    return fallback or {}
end

function Utils.EncodeJson(value)
    return json.encode(value or {})
end

function Utils.GenerateNumber(prefix)
    return ('%s-%s-%s'):format(
        prefix or 'KX',
        os.date('%Y%m%d'),
        tostring(math.random(100000, 999999))
    )
end

function Utils.GetCategoryServices(categoryId)
    local list = {}
    for i = 1, #Config.Services do
        if Config.Services[i].category == categoryId then
            list[#list + 1] = Config.Services[i]
        end
    end
    return list
end

function Utils.BuildServicePayload(serviceId)
    local service = Utils.GetService(serviceId)
    if not service then return nil end

    local required = Utils.GetRequiredItems(serviceId)
    local materials = {}
    for i = 1, #required do
        materials[#materials + 1] = {
            item = required[i].item,
            count = required[i].count,
            label = Utils.GetItemLabel(required[i].item),
        }
    end

    return {
        id = service.id,
        category = service.category,
        label = service.label,
        description = service.description,
        icon = service.icon,
        price = Utils.GetServicePrice(serviceId),
        duration = Utils.GetServiceDuration(serviceId),
        materials = materials,
    }
end

function Utils.GetOrderProduct(item)
    for i = 1, #Config.OrderCatalog do
        if Config.OrderCatalog[i].item == item then
            return Config.OrderCatalog[i]
        end
    end
    return nil
end

function Utils.GetSupplier(supplierId)
    for i = 1, #Config.Suppliers do
        if Config.Suppliers[i].id == supplierId then
            return Config.Suppliers[i]
        end
    end
    return nil
end

function Utils.StatusLabel(status)
    local map = {
        pending = 'EN ATTENTE',
        preparing = 'EN PRÉPARATION',
        shipping = 'EN LIVRAISON',
        delivered = 'LIVRÉE',
        cancelled = 'ANNULÉE',
        paid = 'PAYÉE',
        declined = 'REFUSÉE',
    }
    return map[status] or tostring(status):upper()
end

function Utils.Notify(source, message, nType, duration)
    if IsDuplicityVersion() then
        TriggerClientEvent('ox_lib:notify', source, {
            title = Config.JobLabel,
            description = message,
            type = nType or 'inform',
            duration = duration or 5000,
        })
    else
        lib.notify({
            title = Config.JobLabel,
            description = message,
            type = nType or 'inform',
            duration = duration or 5000,
        })
    end
end