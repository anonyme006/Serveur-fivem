MarloweClothing = MarloweClothing or {}

local savedAppearance = nil

local function notify(message, nType)
    lib.notify({
        title = Config.Label,
        description = message,
        type = nType or 'inform',
    })
end

local function getGender()
    local model = GetEntityModel(cache.ped)
    if model == joaat('mp_f_freemode_01') then
        return 'female'
    end
    return 'male'
end

local function applyOutfit(outfit)
    if Config.ClothingSystem == 'illenium' then
        if GetResourceState('illenium-appearance') == 'started' then
            TriggerEvent('illenium-appearance:client:loadJobOutfit', {
                outfitData = outfit,
            })
            return true
        end
    end

    for component, data in pairs(outfit) do
        local componentId = ({
            ['mask'] = 1,
            ['arms'] = 3,
            ['pants'] = 4,
            ['bag'] = 5,
            ['shoes'] = 6,
            ['accessory'] = 7,
            ['t-shirt'] = 8,
            ['vest'] = 9,
            ['decals'] = 10,
            ['torso2'] = 11,
        })[component]

        if componentId then
            SetPedComponentVariation(cache.ped, componentId, data.item, data.texture, 0)
        end
    end

    return true
end

function MarloweClothing.WearWorkOutfit()
    local gender = getGender()
    local outfit = Config.Outfits.Work[gender]
    if not outfit then
        notify('Tenue de travail non configurée.', 'error')
        return
    end

    if Config.ClothingSystem == 'illenium' and GetResourceState('illenium-appearance') == 'started' then
        TriggerEvent('illenium-appearance:client:getOutfit', function(appearance)
            savedAppearance = appearance
        end)
    end

    applyOutfit(outfit)
    notify('Tenue de travail équipée.', 'success')
end

function MarloweClothing.WearCivilOutfit()
    if Config.ClothingSystem == 'illenium' and GetResourceState('illenium-appearance') == 'started' then
        TriggerEvent('illenium-appearance:client:reloadSkin')
        notify('Tenue civile restaurée.', 'success')
        return
    end

    if savedAppearance then
        applyOutfit(savedAppearance)
        notify('Tenue civile restaurée.', 'success')
        return
    end

    TriggerEvent('qb-clothes:client:CreateFirstCharacter')
    notify('Rechargement de la tenue.', 'inform')
end

CreateThread(function()
    exports.ox_target:addSphereZone({
        coords = Config.Vineyard.WardrobePoint.coords,
        radius = Config.Vineyard.WardrobePoint.radius,
        debug = false,
        options = {
            {
                name = 'marlowe_wardrobe',
                icon = 'fa-solid fa-shirt',
                label = 'Ouvrir le vestiaire',
                canInteract = function()
                    return QBX.PlayerData and QBX.PlayerData.job.name == Config.Job
                end,
                onSelect = function()
                    MarloweMenu.OpenWardrobe()
                end,
                distance = 2.0,
            },
        },
    })
end)
