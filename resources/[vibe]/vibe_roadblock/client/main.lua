local placed = {}

local function placeProp(model)
    local coords = GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, 1.5, 0.0)
    local heading = GetEntityHeading(cache.ped)
    lib.requestModel(model)
    local obj = CreateObject(model, coords.x, coords.y, coords.z, true, true, false)
    SetEntityHeading(obj, heading)
    PlaceObjectOnGroundProperly(obj)
    FreezeEntityPosition(obj, true)
    placed[#placed+1] = obj
    SetModelAsNoLongerNeeded(model)
end

RegisterCommand('barrage', function()
    if not exports.vibe_api:IsPolice(true) then return end
    if #placed >= Config.MaxProps then
        exports.vibe_api:Notify('Barrage', 'Limite atteinte. /clearbarrage', 'error')
        return
    end
    local options = {}
    for _, p in ipairs(Config.Props) do
        options[#options+1] = {
            title = p.label,
            onSelect = function() placeProp(p.model) end,
        }
    end
    lib.registerContext({ id = 'vibe_roadblock', title = 'Barrage', options = options })
    lib.showContext('vibe_roadblock')
end, false)

RegisterCommand('clearbarrage', function()
    for _, obj in ipairs(placed) do
        if DoesEntityExist(obj) then DeleteEntity(obj) end
    end
    placed = {}
    exports.vibe_api:Notify('Barrage', 'Props retirés.', 'success')
end, false)
