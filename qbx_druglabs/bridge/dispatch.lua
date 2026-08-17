Bridge = Bridge or {}

---@param data table
--- data = { title, message, coords, code, blip, priority }
function Bridge.SendPoliceAlert(data)
    if not data then return end
    local system = Config.Dispatch or 'none'
    if system == 'none' then
        DrugLabs.Debug('Dispatch disabled:', data.title or data.message)
        return
    end

    local coords = data.coords
    if type(coords) == 'vector3' or type(coords) == 'vector4' then
        coords = { x = coords.x, y = coords.y, z = coords.z }
    end

    local ok, err = pcall(function()
        if system == 'ps-dispatch' then
            exports['ps-dispatch']:CustomAlert({
                message = data.message or data.title or 'Suspicious activity',
                code = data.code or '10-66',
                icon = 'fas fa-flask',
                priority = data.priority or 2,
                coords = coords and vector3(coords.x, coords.y, coords.z) or nil,
                jobs = { 'leo' },
            })
        elseif system == 'cd_dispatch' then
            TriggerClientEvent('cd_dispatch:AddNotification', -1, {
                job_table = { 'police', 'sheriff' },
                coords = coords and vector3(coords.x, coords.y, coords.z) or GetEntityCoords(GetPlayerPed(source or 0)),
                title = data.title or 'Drug Activity',
                message = data.message or 'Suspicious laboratory activity reported.',
                flash = 0,
                unique_id = tostring(math.random(1000000, 9999999)),
                sound = 1,
                blip = {
                    sprite = 499,
                    scale = 1.0,
                    colour = 1,
                    flashes = false,
                    text = data.title or 'Drug Lab',
                    time = 5,
                    radius = 0,
                },
            })
        elseif system == 'qs-dispatch' then
            exports['qs-dispatch']:CreateDispatchCall({
                job = { 'police', 'sheriff' },
                callLocation = coords and vector3(coords.x, coords.y, coords.z) or nil,
                callCode = { code = data.code or '10-66', snippet = data.title or 'Drug Lab' },
                message = data.message or 'Laboratory activity detected.',
                flashes = false,
                image = nil,
                blip = {
                    sprite = 499,
                    scale = 1.0,
                    colour = 1,
                    text = data.title or 'Drug Lab',
                    time = 60,
                },
            })
        elseif system == 'rcore_dispatch' then
            TriggerEvent('rcore_dispatch:server:sendAlert', {
                code = data.code or '10-66',
                default_priority = 'medium',
                coords = coords and vector3(coords.x, coords.y, coords.z) or nil,
                job = { 'police', 'sheriff' },
                text = data.message or data.title or 'Drug laboratory activity',
                type = 'alerts',
                blip = {
                    sprite = 499,
                    colour = 1,
                    scale = 0.8,
                    text = data.title or 'Drug Lab',
                    flashes = false,
                    time = 60,
                },
            })
        elseif system == 'custom' then
            --- Hook for server owners
            TriggerEvent('qbx_druglabs:server:customDispatch', data)
        end
    end)

    if not ok then
        print(('[qbx_druglabs] Dispatch error (%s): %s'):format(system, err))
    end
end

--- Alias matching the design doc
function SendPoliceAlert(data)
    Bridge.SendPoliceAlert(data)
end
