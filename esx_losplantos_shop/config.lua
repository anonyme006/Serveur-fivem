Config = {}

-- Touche pour ouvrir près d'un magasin (E)
Config.InteractKey = 38 -- E / INPUT_CONTEXT
Config.InteractDistance = 2.0

-- Compte utilisé pour payer : 'money' ou 'bank'
Config.PayAccount = 'money'

-- Afficher un blip sur la carte
Config.ShowBlips = true

-- Marker au sol
Config.ShowMarker = true
Config.Marker = {
    type = 1,
    size = vector3(1.2, 1.2, 0.5),
    color = { r = 140, g = 40, b = 200, a = 120 },
    bobUpAndDown = false,
    faceCamera = false,
    rotate = false,
}

--[[
  Shops : chaque magasin a un label (barre violette), des coords et une liste d'items.
  type = 'weapon' | 'item'
  name = hash arme (WEAPON_…) ou nom item ESX
  label = texte affiché
  price = prix en $
  image = fichier dans html/img/ (optionnel)
]]
Config.Shops = {
    {
        id = 'ammunation_melee',
        label = 'MAGASIN',
        blip = {
            sprite = 110,
            color = 1,
            scale = 0.7,
            label = 'Ammu-Nation',
        },
        locations = {
            vector3(22.0, -1106.9, 29.8),       -- Ammu-Nation Legion
            vector3(252.3, -50.0, 69.9),        -- Ammu-Nation Hawick
            vector3(842.4, -1033.4, 28.2),      -- Ammu-Nation La Mesa
            vector3(-662.1, -935.3, 21.8),      -- Ammu-Nation Little Seoul
            vector3(-1306.2, -394.0, 36.7),     -- Ammu-Nation Morningwood
            vector3(-330.2, 6083.9, 31.5),      -- Ammu-Nation Paleto
            vector3(1693.4, 3759.5, 34.7),      -- Ammu-Nation Sandy
            vector3(-1117.5, 2698.6, 18.6),     -- Ammu-Nation Route 68
            vector3(2567.6, 294.3, 108.7),      -- Ammu-Nation Tataviam
            vector3(-3171.9, 1087.8, 20.8),     -- Ammu-Nation Chumash
        },
        items = {
            { type = 'weapon', name = 'WEAPON_KNUCKLE',      label = 'Poing américain',       price = 777,  image = 'knuckle.svg' },
            { type = 'weapon', name = 'WEAPON_GOLFCLUB',     label = 'Club de golf',          price = 2500, image = 'golfclub.svg' },
            { type = 'weapon', name = 'WEAPON_CROWBAR',      label = 'Pied de biche',         price = 800,  image = 'crowbar.svg' },
            { type = 'weapon', name = 'WEAPON_SWITCHBLADE',  label = 'Couteau à cran d\'arrêt', price = 900, image = 'switchblade.svg' },
            { type = 'weapon', name = 'WEAPON_KNIFE',        label = 'Couteau',               price = 250,  image = 'knife.svg' },
            { type = 'weapon', name = 'WEAPON_BAT',          label = 'Batte',                 price = 500,  image = 'bat.svg' },
            { type = 'weapon', name = 'WEAPON_MACHETE',      label = 'Machette',              price = 1500, image = 'machete.svg' },
            { type = 'weapon', name = 'WEAPON_FLASHLIGHT',   label = 'Lampe torche',          price = 100,  image = 'flashlight.svg' },
        },
    },
    {
        id = 'superette',
        label = 'MAGASIN',
        blip = {
            sprite = 52,
            color = 2,
            scale = 0.7,
            label = 'Supérette',
        },
        locations = {
            vector3(25.7, -1347.3, 29.5),
            vector3(-3038.9, 585.9, 7.9),
            vector3(-3241.9, 1001.4, 12.8),
            vector3(1728.7, 6414.4, 35.0),
            vector3(1698.0, 4924.4, 42.1),
            vector3(1961.5, 3740.3, 32.3),
            vector3(547.8, 2671.7, 42.2),
            vector3(2678.9, 3280.6, 55.2),
            vector3(2557.4, 382.2, 108.6),
            vector3(373.9, 325.8, 103.6),
        },
        items = {
            { type = 'item', name = 'bread',  label = 'Pain',  price = 15,  image = 'bread.svg' },
            { type = 'item', name = 'water',  label = 'Eau',   price = 10,  image = 'water.svg' },
            { type = 'item', name = 'burger', label = 'Burger', price = 35, image = 'burger.svg' },
            { type = 'item', name = 'phone',  label = 'Téléphone', price = 500, image = 'phone.svg' },
        },
    },
}

-- Format prix : espace milliers (2 500)
Config.PriceLocale = 'fr-FR'
