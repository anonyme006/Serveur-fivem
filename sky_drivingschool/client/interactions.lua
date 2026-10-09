SkyDS = SkyDS or {}

local useTarget = (Config.Interaction == 'ox_target' or Config.Interaction == 'both')
    and GetResourceState('ox_target') == 'started'
local useMarker = Config.Interaction == 'marker' or Config.Interaction == 'both' or not useTarget

local function openSchool(schoolId)
    if SkyDS.Client.IsNuiOpen and SkyDS.Client.IsNuiOpen() then return end
    local result = lib.callback.await('sky_drivingschool:server:openSchool', false, schoolId)
    if not result or not result.ok then
        SkyDS.Client.Notify(result and result.error or L('invalid_school'), 'error')
        return
    end
    SkyDS.Client.OpenNui('home', result.data)
end

CreateThread(function()
    if not useTarget then return end
    Wait(500)
    for _, school in ipairs(Config.Schools or {}) do
        local ped = SkyDS.Client.GetPeds()[school.id]
        if ped and DoesEntityExist(ped) then
            exports.ox_target:addLocalEntity(ped, {
                {
                    name = 'sky_ds_open_' .. school.id,
                    icon = 'fa-solid fa-id-card',
                    label = L('open_school'),
                    distance = Config.TargetDistance or 2.5,
                    onSelect = function()
                        openSchool(school.id)
                    end,
                },
            })
        else
            -- Zone fallback at reception
            local c = school.reception
            exports.ox_target:addSphereZone({
                name = 'sky_ds_zone_' .. school.id,
                coords = vec3(c.x, c.y, c.z),
                radius = Config.TargetDistance or 2.5,
                debug = Config.Debug,
                options = {
                    {
                        name = 'sky_ds_open_zone_' .. school.id,
                        icon = 'fa-solid fa-id-card',
                        label = L('open_school'),
                        onSelect = function()
                            openSchool(school.id)
                        end,
                    },
                },
            })
        end
    end
end)

-- Marker / key press fallback (event-driven proximity, no tight always-on loops when far)
CreateThread(function()
    if not useMarker then return end
    local marker = Config.Marker or {}
    local showingHint = false
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local nearInteract = false
        for _, school in ipairs(Config.Schools or {}) do
            local c = school.reception
            local dist = #(coords - vec3(c.x, c.y, c.z))
            local drawDist = Config.MarkerDrawDistance or 25.0
            if dist < drawDist then
                sleep = 0
                DrawMarker(
                    marker.type or 1,
                    c.x, c.y, c.z - 1.0,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    (marker.scale and marker.scale.x) or 0.9,
                    (marker.scale and marker.scale.y) or 0.9,
                    (marker.scale and marker.scale.z) or 0.6,
                    (marker.color and marker.color.r) or 30,
                    (marker.color and marker.color.g) or 90,
                    (marker.color and marker.color.b) or 171,
                    (marker.color and marker.color.a) or 160,
                    marker.bobUpAndDown or false,
                    marker.faceCamera or false,
                    2,
                    marker.rotate or false,
                    nil, nil, false
                )
                if dist < (Config.MarkerInteractDistance or 2.0) then
                    nearInteract = true
                    if not showingHint then
                        lib.showTextUI(L('interact_hint'))
                        showingHint = true
                    end
                    if IsControlJustReleased(0, 38) then -- E
                        lib.hideTextUI()
                        showingHint = false
                        openSchool(school.id)
                    end
                end
            end
        end
        if not nearInteract and showingHint then
            lib.hideTextUI()
            showingHint = false
        end
        Wait(sleep)
    end
end)

RegisterNetEvent('sky_drivingschool:client:openSchool', function(schoolId)
    openSchool(schoolId or (Config.Schools[1] and Config.Schools[1].id))
end)
