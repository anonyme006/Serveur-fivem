--[[--------------------------------------------------------------------------
    core_garage — entreprise (historique / grades)
---------------------------------------------------------------------------]]

lib.callback.register('core_garage:getCompanyInfo', function(source, garageName)
    local garage = GarageDB.GetGarage(garageName)
    if not garage or (garage.type ~= 'company' and garage.type ~= 'job') then
        return nil
    end

    local ok = GarageSecurity.CanAccessGarage(source, garage)
    if not ok then return nil end

    local company = GarageDB.companies[garage.job] and GarageDB.companies[garage.job][garageName]
    local outCount = 0
    if garage.job then
        outCount = MySQL.scalar.await(
            'SELECT COUNT(*) FROM garage_vehicles WHERE company = ? AND stored = 0 AND impound = 0',
            { garage.job }
        ) or 0
    end

    return {
        job = garage.job,
        label = company and company.label or garage.label,
        maxOut = company and company.max_out or 5,
        outCount = outCount,
        minGradeOut = company and company.min_grade_out or 0,
        minGradeStore = company and company.min_grade_store or 0,
        minGradeManage = company and company.min_grade_manage or 2,
        shared = company and (company.shared == 1) or true,
    }
end)

--- Attacher un véhicule à une entreprise (admin / boss)
lib.callback.register('core_garage:assignCompanyVehicle', function(source, plate, job)
    if not GarageSecurity.IsAdmin(source) then
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return { ok = false } end
        local pjob = xPlayer.getJob()
        if not pjob or pjob.name ~= job or (pjob.grade_name ~= 'boss' and (pjob.grade or 0) < 3) then
            return { ok = false, error = 'no_permission' }
        end
    end

    plate = GarageUtils.NormalizePlate(plate)
    local updated = MySQL.update.await(
        'UPDATE garage_vehicles SET company = ? WHERE plate = ?',
        { job, plate }
    )
    return { ok = updated and updated > 0 }
end)
