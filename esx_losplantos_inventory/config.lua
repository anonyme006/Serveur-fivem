Config = {}

-- Touche d'ouverture (F2 par défaut)
Config.OpenKey = 'F2'

-- Poids max (kg) — aligné avec ESX Legacy weight system si disponible
Config.MaxWeight = 60

-- Fermer avec ESC / Backspace
Config.CloseKeys = { 177, 200 } -- BACKSPACE, ESC

-- Afficher les items à quantité 0
Config.ShowEmptyItems = false

-- Mapping nom d'item -> fichier icône (dans html/img/)
-- Si absent, utilise html/img/default.svg
Config.ItemImages = {
    phone = 'phone.svg',
    telephone = 'phone.svg',
    umbrella = 'umbrella.svg',
    parapluie = 'umbrella.svg',
    compass = 'compass.svg',
    boussole = 'compass.svg',
    gps = 'gps.svg',
    jus_multivitamine = 'juice.svg',
    juice = 'juice.svg',
    binoculaires = 'binoculars.svg',
    jumelles = 'binoculars.svg',
    binoculars = 'binoculars.svg',
    cheeseburger = 'burger.svg',
    burger = 'burger.svg',
    finger_shokobite = 'snack.svg',
    snack = 'snack.svg',
    poulet_barquette = 'chicken.svg',
    chicken = 'chicken.svg',
    bread = 'burger.svg',
    water = 'juice.svg',
    money = 'default.svg',
    black_money = 'default.svg',
}

-- Labels FR de secours si l'item n'a pas de label ESX
Config.ItemLabels = {
    phone = 'Téléphone',
    telephone = 'Téléphone',
    umbrella = 'Parapluie',
    parapluie = 'Parapluie',
    compass = 'Boussole',
    boussole = 'Boussole',
    gps = 'GPS',
    jus_multivitamine = 'Bouteille de Jus Multivitaminé',
    binoculaires = 'Jumelles',
    jumelles = 'Jumelles',
    binoculars = 'Jumelles',
    cheeseburger = 'Cheeseburger',
    finger_shokobite = 'Finger Shokobite',
    poulet_barquette = 'Poulet en barquette',
}
