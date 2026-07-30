local blips = {}

local function canSee(data)
    if not data then return true end
    if data.job and data.job ~= '' then
        -- client-side soft filter; server still authoritative for secure systems
        return true
    end
    return true
end

local function rebuild(rows)
    for key, blip in pairs(ClientCore.Entities.blips) do
        if tostring(key):find('^blip_') and DoesBlipExist(blip) then
            RemoveBlip(blip)
            ClientCore.Entities.blips[key] = nil
        end
    end

    blips = rows or {}
    for i = 1, #blips do
        local row = blips[i]
        local data = row.data or {}
        if row.coords and canSee(data) then
            ClientCore.CreateBlip('blip_' .. row.id, row.coords, {
                sprite = data.sprite,
                colour = data.colour,
                scale = data.scale,
                display = data.display,
                shortRange = data.shortRange,
                rotation = data.rotation,
                label = row.label,
            }, row.label)
        end
    end
end

RegisterNetEvent('core_creator:blips:sync', function(rows)
    rebuild(rows)
end)

-- Live preview while editing in NUI
RegisterNUICallback('previewBlip', function(data, cb)
    if data and data.coords then
        ClientCore.CreateBlip('blip_preview', data.coords, data, data.label or 'Preview')
    end
    cb({ ok = true })
end)
