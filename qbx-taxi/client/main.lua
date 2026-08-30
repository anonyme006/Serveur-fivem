local staticBlips = {}

local function createStaticBlips()
    for _, blip in pairs(staticBlips) do
        TaxiClient.RemoveBlip(blip)
    end

    staticBlips = {}

    if Config.Blips.headquarters.enabled then
        staticBlips.headquarters = TaxiClient.CreateBlip(
            Config.Locations.headquarters.coords,
            Config.Blips.headquarters,
            Config.Blips.headquarters.label
        )
    end

    if Config.Blips.garage.enabled then
        staticBlips.garage = TaxiClient.CreateBlip(
            Config.Locations.garage.coords,
            Config.Blips.garage,
            Config.Blips.garage.label
        )
    end

    TaxiClient.State.blips = staticBlips
end

local function setReady(isReady)
    TaxiClient.State.ready = isReady
    LocalPlayer.state:set('qbx_taxi_ready', isReady, false)
end

local function onPlayerLoaded()
    if not TaxiClient.IsLoggedIn() then return end

    setReady(true)
    createStaticBlips()

    Taxi.Debug('Joueur chargé (%s)', TaxiClient.GetJobName() or 'unknown')

    if TaxiClient.IsTaxiEmployee() and Config.Debug.enabled then
        TaxiClient.NotifyKey('resourceReady', 'success')
    end
end

local function onPlayerUnload()
    setReady(false)

    for _, blip in pairs(staticBlips) do
        TaxiClient.RemoveBlip(blip)
    end

    staticBlips = {}
    TaxiClient.State.blips = {}
end

local function validateDependencies()
    local missing = {}

    if not Taxi.IsOxLibReady() then
        missing[#missing + 1] = 'ox_lib'
    end

    if not Taxi.IsQboxReady() then
        missing[#missing + 1] = 'qbx_core'
    end

    if #missing > 0 then
        lib.print.error(('[qbx-taxi] Dépendances manquantes : %s'):format(table.concat(missing, ', ')))
        return false
    end

    if Config.Duty.useGlobalDuty and not Taxi.IsDutySystemReady() then
        lib.print.warn('[qbx-taxi] qbx-duty n\'est pas démarré — l\'intégration duty sera disponible à l\'étape 3.')
    end

    return true
end

CreateThread(function()
    Wait(Config.Times.startupDelay)

    if not validateDependencies() then
        return
    end

    if LocalPlayer.state.isLoggedIn then
        onPlayerLoaded()
    end

    Taxi.Debug('Client initialisé')
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', onPlayerLoaded)
RegisterNetEvent('QBCore:Client:OnPlayerUnload', onPlayerUnload)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    Taxi.Debug('Job mis à jour : %s (grade %s)', job.name, job.grade.level)
end)

RegisterNetEvent('QBCore:Client:SetDuty', function(onDuty)
    Taxi.Debug('Duty Qbox : %s', onDuty and 'ON' or 'OFF')
end)

if Config.Debug.enabled and Config.Debug.command then
    RegisterCommand(Config.Debug.command, function()
        lib.print.info('[qbx-taxi:debug]', {
            ready = TaxiClient.State.ready,
            job = TaxiClient.GetJobName(),
            grade = TaxiClient.GetJobGrade(),
            taxi = TaxiClient.IsTaxiEmployee(),
            dutyResource = Config.Duty.resource,
            dutyStarted = Taxi.IsDutySystemReady(),
        })
    end, false)
end

exports('IsTaxiEmployee', TaxiClient.IsTaxiEmployee)
exports('GetJobGrade', TaxiClient.GetJobGrade)
exports('HasJobPermission', TaxiClient.HasJobPermission)
exports('GetPublicConfig', Taxi.GetPublicConfig)
