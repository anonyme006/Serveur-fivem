-- Theory exam is primarily NUI-driven.
-- This file exposes helpers for HUD timer sync if needed.

SkyDS = SkyDS or {}
SkyDS.Client = SkyDS.Client or {}

RegisterNetEvent('sky_drivingschool:client:theoryForceClose', function()
    SkyDS.Client.SendNui('theoryForceClose', {})
end)
