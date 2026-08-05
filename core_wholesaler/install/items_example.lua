--[[
    Exemple d'items ox_inventory pour core_wholesaler.
    À fusionner dans ox_inventory/data/items.lua (ou votre système d'items).
    Adaptez labels / poids / stacks selon votre serveur.
]]

--[[
return {
    -- Alimentation
    ['water']        = { label = 'Eau', weight = 200, stack = true },
    ['soda']         = { label = 'Soda', weight = 250, stack = true },
    ['bread']        = { label = 'Pain', weight = 150, stack = true },
    ['meat']         = { label = 'Viande', weight = 300, stack = true },
    ['fruit']        = { label = 'Fruits', weight = 200, stack = true },
    ['vegetable']    = { label = 'Légumes', weight = 200, stack = true },
    ['flour']        = { label = 'Farine', weight = 500, stack = true },
    ['sugar']        = { label = 'Sucre', weight = 400, stack = true },
    ['coffee_beans'] = { label = 'Café', weight = 200, stack = true },
    ['milk']         = { label = 'Lait', weight = 500, stack = true },

    -- Restaurant
    ['ingredients']  = { label = 'Ingrédients', weight = 400, stack = true },
    ['drinks_crate'] = { label = 'Caisse de boissons', weight = 2000, stack = true },
    ['packaging']    = { label = 'Emballages', weight = 100, stack = true },

    -- Mécano
    ['tyre']         = { label = 'Pneu', weight = 5000, stack = true },
    ['engine_part']  = { label = 'Moteur', weight = 15000, stack = false },
    ['brakes']       = { label = 'Freins', weight = 3000, stack = true },
    ['car_battery']  = { label = 'Batterie', weight = 8000, stack = true },
    ['repairkit']    = { label = 'Kit réparation', weight = 2500, stack = true },
    ['engine_oil']   = { label = 'Huile moteur', weight = 1000, stack = true },

    -- EMS
    ['medicine']     = { label = 'Médicaments', weight = 100, stack = true },
    ['bandage']      = { label = 'Bandage', weight = 50, stack = true },
    ['medikit']      = { label = 'Kit médical', weight = 500, stack = true },
    ['defibrillator']= { label = 'Défibrillateur', weight = 3000, stack = false },
    ['iv_bag']       = { label = 'Perfusion', weight = 400, stack = true },

    -- Police
    ['cone']         = { label = 'Cône', weight = 500, stack = true },
    ['barrier']      = { label = 'Barrière', weight = 2000, stack = true },
    ['flashlight']   = { label = 'Lampe', weight = 300, stack = true },
    ['armor']        = { label = 'Gilet', weight = 3000, stack = true },
    -- ammo-9 / ammo-rifle : déjà présents dans ox_inventory standard

    -- Station-service
    ['fuel_tank']    = { label = 'Cuve', weight = 20000, stack = false },
    ['fuel_pump']    = { label = 'Pompe', weight = 15000, stack = false },
    ['ox_fuel_part'] = { label = 'Pièce ox_fuel', weight = 2000, stack = true },
    ['fuel_canister']= { label = 'Bidon carburant', weight = 5000, stack = true },

    -- Chantier
    ['wood']         = { label = 'Bois', weight = 2000, stack = true },
    ['metal']        = { label = 'Métal', weight = 3000, stack = true },
    ['concrete']     = { label = 'Béton', weight = 5000, stack = true },
    ['tools']        = { label = 'Outils', weight = 2500, stack = true },
}
]]
