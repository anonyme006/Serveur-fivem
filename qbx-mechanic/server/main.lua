local startedAt = os.time()

local REQUIRED = {
    'ox_lib',
    'ox_target',
    'oxmysql',
    'qbx_core',
}

local function checkDependencies()
    local missing = {}

    for i = 1, #REQUIRED do
        local resource = REQUIRED[i]
        if GetResourceState(resource) ~= 'started' then
            missing[#missing + 1] = resource
        end
    end

    if #missing > 0 then
        print(('[^1qbx-mechanic^0] Dépendances manquantes: %s'):format(table.concat(missing, ', ')))
        return false
    end

    return true
end

local function logStartup()
    local version = GetResourceMetadata(GetCurrentResourceName(), 'version', 0) or '0.0.0'
    print(('[^2qbx-mechanic^0] v%s démarré — framework Qbox'):format(version))

    if Config.Debug then
        print('[^3qbx-mechanic^0] Mode debug activé')
    end
end

local function bootstrap()
    if not checkDependencies() then return end

    Database.Init()
    logStartup()
end

--- Export serveur — vérification job (source de vérité)
---@param source number
---@param minGrade number|nil
---@return boolean
local function isMechanicExport(source, minGrade)
    return Framework.HasMechanicJob(source, nil, minGrade)
end

exports('IsMechanic', isMechanicExport)

exports('GetMechanicJobName', function()
    return Config.Job.name
end)

exports('GetUptime', function()
    return os.time() - startedAt
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    bootstrap()
end)

CreateThread(bootstrap)
