SkyDS = SkyDS or {}

RegisterNetEvent('sky_drivingschool:client:showLicenseCard', function(categoryId)
    local result = lib.callback.await('sky_drivingschool:server:getLicenseCard', false, categoryId)
    if not result or not result.ok then
        SkyDS.Client.Notify(result and result.error or 'Unable to load license card.', 'error')
        return
    end
    SkyDS.Client.OpenNui('licenseCard', result)
end)

-- Optional ox_inventory item use hook (item must call this event or export)
RegisterNetEvent('sky_drivingschool:client:useLicenseItem', function(categoryId)
    TriggerEvent('sky_drivingschool:client:showLicenseCard', categoryId)
end)

exports('ShowLicenseCard', function(categoryId)
    TriggerEvent('sky_drivingschool:client:showLicenseCard', categoryId)
end)

--- ox_inventory item use: client.export = 'sky_drivingschool.useLicenseItem'
exports('useLicenseItem', function(data, slot)
    local meta = slot and slot.metadata or (data and data.metadata) or {}
    TriggerEvent('sky_drivingschool:client:showLicenseCard', meta.category)
end)
