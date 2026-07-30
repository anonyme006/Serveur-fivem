local previewEntities = {}

local function clearPreview()
    for i = 1, #previewEntities do
        local ent = previewEntities[i]
        if ent and DoesEntityExist(ent) then
            DeleteEntity(ent)
        end
    end
    previewEntities = {}
end

AddEventHandler('core_creator:preview:clear', clearPreview)

AddEventHandler('core_creator:preview:show', function(data)
    clearPreview()
    if type(data) ~= 'table' then return end
    local coords = data.coords
    if not coords then
        local c = GetEntityCoords(PlayerPedId())
        coords = { x = c.x + 2.0, y = c.y, z = c.z, w = 0.0 }
    end

    if data.type == 'blip' then
        local key = 'preview_blip'
        ClientCore.CreateBlip(key, coords, data.blip or {}, data.label or 'Preview')
        return
    end

    if data.model then
        local hash = joaat(data.model)
        RequestModel(hash)
        local t = GetGameTimer() + 4000
        while not HasModelLoaded(hash) and GetGameTimer() < t do Wait(10) end
        if not HasModelLoaded(hash) then return end

        local ent
        if IsModelAVehicle(hash) then
            ent = CreateVehicle(hash, coords.x, coords.y, coords.z, coords.w or 0.0, false, false)
            SetVehicleOnGroundProperly(ent)
        elseif IsModelAPed(hash) then
            ent = CreatePed(0, hash, coords.x, coords.y, coords.z - 1.0, coords.w or 0.0, false, true)
            FreezeEntityPosition(ent, true)
            SetEntityInvincible(ent, true)
        else
            ent = CreateObject(hash, coords.x, coords.y, coords.z, false, false, false)
            FreezeEntityPosition(ent, true)
        end
        SetEntityAlpha(ent, 200, false)
        SetEntityCollision(ent, false, false)
        previewEntities[#previewEntities + 1] = ent
        SetModelAsNoLongerNeeded(hash)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res == CoreUtils.ResourceName() then clearPreview() end
end)
