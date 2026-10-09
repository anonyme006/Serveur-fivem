SkyDS = SkyDS or {}

RegisterNetEvent('sky_drivingschool:client:openAdmin', function()
    local result = lib.callback.await('sky_drivingschool:server:adminDashboard', false)
    if not result or not result.ok then
        SkyDS.Client.Notify(result and result.error or L('no_permission'), 'error')
        return
    end
    SkyDS.Client.OpenNui('admin', result)
end)
