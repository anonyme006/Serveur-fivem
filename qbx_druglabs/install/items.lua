-- ox_inventory item definitions for qbx_druglabs
-- Copy these entries into ox_inventory/data/items.lua (do not overwrite blindly).

return {
    ['empty_bag'] = { label = 'Empty Bag', weight = 10, stack = true, close = true },
    ['empty_bottle'] = { label = 'Empty Bottle', weight = 50, stack = true, close = true },
    ['empty_tray'] = { label = 'Empty Tray', weight = 200, stack = true, close = true },
    ['packaging'] = { label = 'Packaging', weight = 20, stack = true, close = true },
    ['respirator_mask'] = { label = 'Respirator Mask', weight = 200, stack = false, close = true },

    ['weed_seed'] = { label = 'Weed Seed', weight = 5, stack = true, close = true },
    ['weed_bud'] = { label = 'Weed Bud', weight = 15, stack = true, close = true },
    ['weed_1g'] = { label = 'Weed 1g', weight = 1, stack = true, close = true },
    ['weed_5g'] = { label = 'Weed 5g', weight = 5, stack = true, close = true },
    ['weed_10g'] = { label = 'Weed 10g', weight = 10, stack = true, close = true },
    ['plant_water'] = { label = 'Plant Water', weight = 100, stack = true, close = true },
    ['plant_nutrient'] = { label = 'Plant Nutrients', weight = 100, stack = true, close = true },
    ['plant_spray'] = { label = 'Plant Spray', weight = 80, stack = true, close = true },

    ['powdered_milk'] = { label = 'Powdered Milk', weight = 200, stack = true, close = true },
    ['coke_pile'] = { label = 'Cocaine Pile', weight = 50, stack = true, close = true },
    ['cut_coke'] = { label = 'Cut Cocaine', weight = 10, stack = true, close = true },
    ['coke_1g'] = { label = 'Cocaine 1g', weight = 1, stack = true, close = true },
    ['coke_5g'] = { label = 'Cocaine 5g', weight = 5, stack = true, close = true },
    ['coke_10g'] = { label = 'Cocaine 10g', weight = 10, stack = true, close = true },

    ['ammonia'] = { label = 'Ammonia', weight = 200, stack = true, close = true },
    ['sulfuric_acid'] = { label = 'Sulfuric Acid', weight = 200, stack = true, close = true },
    ['hydrochloric_acid'] = { label = 'Hydrochloric Acid', weight = 200, stack = true, close = true },
    ['lithium'] = { label = 'Lithium', weight = 50, stack = true, close = true },
    ['phosphorus'] = { label = 'Phosphorus', weight = 50, stack = true, close = true },
    ['meth_mixture'] = { label = 'Meth Mixture', weight = 100, stack = true, close = true },
    ['meth_beaker'] = { label = 'Meth Beaker', weight = 150, stack = true, close = true },
    ['meth_tray'] = { label = 'Meth Tray', weight = 250, stack = true, close = true },
    ['meth_crystal'] = { label = 'Meth Crystal', weight = 10, stack = true, close = true },
    ['meth_1g'] = { label = 'Meth 1g', weight = 1, stack = true, close = true },
    ['meth_5g'] = { label = 'Meth 5g', weight = 5, stack = true, close = true },
    ['meth_10g'] = { label = 'Meth 10g', weight = 10, stack = true, close = true },

    ['acid_mix'] = { label = 'Acid Mix', weight = 150, stack = true, close = true },
    ['acid_bottle'] = { label = 'Acid Bottle', weight = 200, stack = true, close = true },
    ['acid_package'] = { label = 'Acid Package', weight = 220, stack = true, close = true },
}
