--[[--------------------------------------------------------------------------
    qbx_policejob — Configuration générale (PHASE 1)
    Framework : qbx_core | ox_lib | ox_target | ox_inventory | oxmysql
---------------------------------------------------------------------------]]

Config = Config or {}

Config.Debug = false
Config.UseTarget = true
Config.UseOxInventory = true
Config.UseOxLib = true
Config.Locale = 'fr'

--- Préfixe des events/callbacks internes (ne pas changer après mise en prod)
Config.ResourceName = 'qbx_policejob'

--[[--------------------------------------------------------------------------
    Intégrations serveur existantes (détectées sur les branches du dépôt)
    Ne remplace aucun système sans accord — activer / adapter ici.
---------------------------------------------------------------------------]]
Config.Integrations = {
    --- Duty externe (qbx-duty / qbx_ressources) — PHASE 2 pourra s'y brancher
    externalDuty = {
        enabled = false,
        resource = 'qbx_ressources', -- ou 'qbx-duty'
    },
    --- Garage / fourrière existant
    --- Note : core_garage sur une branche est ESX — ne pas forcer ici.
    garage = {
        enabled = false,
        resource = 'qbx_garages', -- adapter : 'qbx_garages' | 'rp_garages' | 'core_garage'
        --- Event / export fourrière (PHASE 7+)
        impoundEvent = nil, -- ex: 'qbx_garages:server:impound'
        impoundExport = nil, -- ex: { resource = 'qbx_garages', name = 'ImpoundVehicle' }
    },
    --- Apparence / vestiaire
    appearance = {
        enabled = true,
        resource = 'illenium-appearance', -- server.cfg référence illenium-appearance
    },
    --- Téléphone (numéro joueur)
    phone = {
        --- 'qbx' = PlayerData.charinfo.phone | 'pulse-phone' | 'npwd' | 'custom'
        provider = 'qbx',
        resource = 'pulse-phone',
    },
    --- Véhicules joueur (scan plaque)
    vehicles = {
        --- Table SQL typique Qbox : player_vehicles
        table = 'player_vehicles',
        ownerColumn = 'citizenid',
        plateColumn = 'plate',
        vehicleColumn = 'vehicle',
    },
    --- Permis à points (qbx_licenses + PATCH_qbx_idcard)
    --- Ressource : branche cursor/qbx-licenses-points-6165 (PR #43)
    licenses = {
        enabled = true,
        resource = 'qbx_licenses',
        --- Ouvrir le menu natif qbx_licenses (export OpenPlayerLicenseMenu)
        useNativeMenu = true,
        --- Afficher les points dans les infos joueur police
        showInPlayerInfo = true,
        --- Appliquer automatiquement les points liés aux amendes (Config.Fines.*.licensePoints)
        autoRemoveOnFine = true,
        --- Type de permis par défaut si une amende ne précise pas licenseType
        defaultLicenseType = 'driver',
        --- Patch optionnel qbx_idcard : voir install/PATCH_qbx_idcard.md
        idcardPatch = true,
    },
}

--[[--------------------------------------------------------------------------
    Commandes (activées progressivement par phase)
---------------------------------------------------------------------------]]
Config.Commands = {
    duty = 'duty',
    menu = 'policemenu',
    emergency = '911',
    pdChat = { 'pd', 'police' },
    code1080 = '1080',
    code1080Cancel = '1080cancel',
    gsr = 'gsr',
    impound = 'impound',
    --- Gestion permis à points (joueur proche) — bridge qbx_licenses
    licenses = 'permis',
}

--[[--------------------------------------------------------------------------
    Touches (enregistrements ox_lib / RegisterKeyMapping en phases suivantes)
---------------------------------------------------------------------------]]
Config.Keys = {
    menu = 'F6',
    tackle = 'G',
    softCuff = nil,
}

--[[--------------------------------------------------------------------------
    Distances & anti-cheat (validées serveur)
---------------------------------------------------------------------------]]
Config.Distances = {
    interaction = 2.5,
    target = 2.0,
    vehicle = 4.0,
    duty = 3.0,
    object = 3.0,
    maxServer = 8.0,
}

--[[--------------------------------------------------------------------------
    Cooldowns (secondes)
---------------------------------------------------------------------------]]
Config.Cooldowns = {
    duty = 3,
    emergency = 30,
    pdChat = 2,
    code1080 = 60,
    gsr = 10,
    tackle = 10,
    impound = 15,
    lockpick = 20,
    search = 5,
}

--[[--------------------------------------------------------------------------
    Duty (PHASE 2) — stub de config pour ne pas bloquer l'architecture
---------------------------------------------------------------------------]]
Config.Duty = {
    enabled = true,
    requireZone = true,
    commandEnabled = true,
    notify = true,
}

--[[--------------------------------------------------------------------------
    Menottes / escort / fouille (PHASE 3–5)
---------------------------------------------------------------------------]]
Config.Handcuffs = {
    enabled = true,
    item = 'handcuffs',
    requireItem = true,
    frontCuff = true,
    rearCuff = true,
    maxDistance = 2.5,
}

Config.Escort = {
    enabled = true,
    requireCuffed = true,
}

Config.Search = {
    enabled = true,
    requireCuffed = true,
    allowHandsUp = true,
    allowDead = true,
    openOxInventory = true,
}

--[[--------------------------------------------------------------------------
    GSR / Taser / Tackle
---------------------------------------------------------------------------]]
Config.GSRDuration = 15 * 60 -- secondes
Config.GSRCleanerItem = 'gsr_cleaner'

Config.Taser = {
    enabled = true,
    incapacitationTime = 5000,
    screenEffect = true,
    shake = true,
}

Config.Tackle = {
    enabled = true,
    cooldown = 10,
    ragdollTime = 3000,
    requireSprint = true,
    maxDistance = 2.0,
}

--[[--------------------------------------------------------------------------
    Code 1080
---------------------------------------------------------------------------]]
Config.Code1080 = {
    enabled = true,
    approvalDelay = 10, -- secondes avant approbation
    nearbyRadius = 80.0,
    minGrade = 0,
}

--[[--------------------------------------------------------------------------
    Headbag
---------------------------------------------------------------------------]]
Config.Headbag = {
    enabled = true,
    item = 'headbag',
    requireCuffedOrHandsUp = true,
}

--[[--------------------------------------------------------------------------
    Notifications
---------------------------------------------------------------------------]]
Config.Notify = {
    position = 'top-right',
    duration = 5000,
}
