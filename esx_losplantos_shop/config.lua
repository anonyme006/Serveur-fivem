Config = {}

-- Touche pour ouvrir près d'un magasin (E)
Config.InteractKey = 38 -- E / INPUT_CONTEXT
Config.InteractDistance = 2.0

-- Compte utilisé pour payer : 'money' ou 'bank'
Config.PayAccount = 'money'

-- Quantité max achetable d'un coup
Config.MaxQuantity = 100

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
  Shops :
  - name     = titre magasin (ex: TWENTY FOUR SEVEN)
  - label    = suffixe (ex: MAGASIN) → affiché "NAME - MAGASIN"
  - type     = 'weapon' | 'item'
]]
Config.Shops = {
    {
        id = 'twentyfourseven',
        name = 'TWENTY FOUR SEVEN',
        label = 'MAGASIN',
        blip = {
            sprite = 52,
            color = 2,
            scale = 0.7,
            label = 'Twenty Four Seven',
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
            vector3(1135.8, -982.2, 46.4),
            vector3(-1222.9, -907.0, 12.3),
            vector3(-1487.5, -379.1, 40.1),
            vector3(-2967.8, 391.0, 15.0),
            vector3(1166.0, 2708.9, 38.1),
            vector3(1392.6, 3604.6, 34.9),
            vector3(-48.5, -1757.5, 29.4),
            vector3(-707.5, -914.0, 19.2),
            vector3(1163.4, -323.8, 69.2),
            vector3(-1820.5, 792.5, 138.1),
        },
        items = {
            { type = 'item', name = 'phone',     label = 'Téléphone',       price = 200, image = 'phone.svg' },
            { type = 'item', name = 'umbrella',  label = 'Parapluie',       price = 60,  image = 'umbrella.svg' },
            { type = 'item', name = 'water',     label = 'Bouteille d\'eau', price = 20, image = 'water.svg' },
            { type = 'item', name = 'sandwich',  label = 'Club sandwich',   price = 20,  image = 'sandwich.svg' },
            { type = 'item', name = 'pizza',     label = 'Pizza',           price = 45,  image = 'pizza.svg' },
            { type = 'item', name = 'hotdog',    label = 'Hot Dog',         price = 20,  image = 'hotdog.svg' },
            { type = 'item', name = 'burger',    label = 'Cheeseburger',    price = 35,  image = 'burger.svg' },
            { type = 'item', name = 'beer',      label = 'Bière',           price = 30,  image = 'beer.svg' },
            { type = 'item', name = 'gps',       label = 'GPS',             price = 250, image = 'gps.svg' },
        },
    },
    {
        id = 'ammunation_melee',
        name = 'AMMU-NATION',
        label = 'MAGASIN',
        blip = {
            sprite = 110,
            color = 1,
            scale = 0.7,
            label = 'Ammu-Nation',
        },
        locations = {
            vector3(22.0, -1106.9, 29.8),
            vector3(252.3, -50.0, 69.9),
            vector3(842.4, -1033.4, 28.2),
            vector3(-662.1, -935.3, 21.8),
            vector3(-1306.2, -394.0, 36.7),
            vector3(-330.2, 6083.9, 31.5),
            vector3(1693.4, 3759.5, 34.7),
            vector3(-1117.5, 2698.6, 18.6),
            vector3(2567.6, 294.3, 108.7),
            vector3(-3171.9, 1087.8, 20.8),
        },
        items = {
            { type = 'weapon', name = 'WEAPON_KNUCKLE',     label = 'Poing américain',         price = 777,  image = 'knuckle.svg' },
            { type = 'weapon', name = 'WEAPON_GOLFCLUB',    label = 'Club de golf',            price = 2500, image = 'golfclub.svg' },
            { type = 'weapon', name = 'WEAPON_CROWBAR',     label = 'Pied de biche',           price = 800,  image = 'crowbar.svg' },
            { type = 'weapon', name = 'WEAPON_SWITCHBLADE', label = 'Couteau à cran d\'arrêt', price = 900,  image = 'switchblade.svg' },
            { type = 'weapon', name = 'WEAPON_KNIFE',       label = 'Couteau',                 price = 250,  image = 'knife.svg' },
            { type = 'weapon', name = 'WEAPON_BAT',         label = 'Batte',                   price = 500,  image = 'bat.svg' },
            { type = 'weapon', name = 'WEAPON_MACHETE',     label = 'Machette',                price = 1500, image = 'machete.svg' },
            { type = 'weapon', name = 'WEAPON_FLASHLIGHT',  label = 'Lampe torche',            price = 100,  image = 'flashlight.svg' },
        },
    },
}
