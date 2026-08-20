--[[
    Pulse Phone — Configuration centrale
    Ne jamais faire confiance aux valeurs envoyées par la NUI.
]]

Config = {}

Config.Debug = false
Config.Locale = 'fr'
Config.ResourceName = 'pulse-phone'

-- Ouverture
Config.OpenKey = 'F1' -- touche lib.keymap / RegisterKeyMapping
Config.OpenCommand = 'phone'
Config.RequireItem = true
Config.PhoneItem = 'phone'

-- UI
Config.DefaultWallpaper = 'ocean'
Config.DefaultTheme = 'dark' -- dark | light
Config.PhonePosition = { x = 0.82, y = 0.55 } -- ratio écran (draggable)
Config.Animations = {
    openMs = 280,
    closeMs = 220,
}

Config.Colors = {
    accent = '#0D9488', -- teal
    accentSoft = '#14B8A6',
    danger = '#E11D48',
    warning = '#F59E0B',
    success = '#22C55E',
    surface = '#0F172A',
    surfaceElevated = '#1E293B',
    text = '#F8FAFC',
    textMuted = '#94A3B8',
}

Config.Wallpapers = {
    ocean = { label = 'Océan', css = 'var(--wallpaper-ocean)' },
    dusk = { label = 'Crépuscule', css = 'var(--wallpaper-dusk)' },
    forest = { label = 'Forêt', css = 'var(--wallpaper-forest)' },
    grit = { label = 'Asphalte', css = 'var(--wallpaper-grit)' },
}

-- Sons (désactivables)
Config.Sounds = {
    enabled = true,
    volume = 0.45,
    incomingCall = 'sounds/ring.ogg',
    notification = 'sounds/notify.ogg',
    sms = 'sounds/sms.ogg',
    company = 'sounds/company.ogg',
    callAccept = 'sounds/accept.ogg',
    callDecline = 'sounds/decline.ogg',
}

-- Notifications
Config.Notifications = {
    maxVisible = 5,
    defaultDuration = 5000,
}

-- Apps activées (false = masquée)
Config.Apps = {
    phone = true,
    contacts = true,
    messages = true,
    services = true,
    bank = true,
    wallet = true,
    garage = true,
    marketplace = true,
    gps = true,
    settings = true,
    companyManage = true, -- visible seulement si permissions serveur
}

-- Cooldowns (ms) anti-spam
Config.Cooldowns = {
    openPhone = 400,
    sendMessage = 800,
    startCall = 1200,
    serviceRequest = 5000,
    bankTransfer = 2000,
    marketplaceCreate = 3000,
}

-- Numéros
Config.PhoneNumber = {
    length = 7,
    prefix = '', -- ex: '555'
}

-- Entreprises (job Qbox)
Config.Companies = {
    police = {
        id = 'police',
        label = 'Police',
        job = 'police',
        minGrade = 0,
        manageGrade = 3,
        category = 'public',
        description = 'Forces de l\'ordre et urgences.',
        number = '911',
        location = 'Mission Row',
        icon = 'POL',
        iconColor = '#1D4ED8',
        canCall = true,
        blip = { sprite = 60, color = 29 },
        coords = { x = 428.2, y = -981.0, z = 30.7 },
        autoStatus = true,
    },
    ambulance = {
        id = 'ambulance',
        label = 'EMS',
        job = 'ambulance',
        minGrade = 0,
        manageGrade = 3,
        category = 'public',
        description = 'Services médicaux d\'urgence.',
        number = '912',
        location = 'Pillbox Hill',
        icon = 'EMS',
        iconColor = '#DC2626',
        canCall = true,
        blip = { sprite = 61, color = 1 },
        coords = { x = 298.6, y = -584.5, z = 43.3 },
        autoStatus = true,
    },
    mechanic = {
        id = 'mechanic',
        label = 'LS Customs',
        job = 'mechanic',
        minGrade = 0,
        manageGrade = 2,
        category = 'service',
        description = 'Réparation et dépannage véhicules.',
        number = '5551001',
        location = 'La Mesa',
        icon = 'MEC',
        iconColor = '#EA580C',
        canCall = true,
        blip = { sprite = 446, color = 5 },
        coords = { x = 732.0, y = -1088.7, z = 22.2 },
        autoStatus = true,
    },
    taxi = {
        id = 'taxi',
        label = 'Taxi',
        job = 'taxi',
        minGrade = 0,
        manageGrade = 2,
        category = 'service',
        description = 'Transport de personnes.',
        number = '5551002',
        location = 'Downtown',
        icon = 'TAX',
        iconColor = '#CA8A04',
        canCall = true,
        blip = { sprite = 198, color = 5 },
        coords = { x = 895.3, y = -179.3, z = 74.7 },
        autoStatus = true,
    },
    burgershot = {
        id = 'burgershot',
        label = 'Burger Shot',
        job = 'burgershot',
        minGrade = 0,
        manageGrade = 2,
        category = 'food',
        description = 'Fast-food emblématique de Los Santos.',
        number = '5552001',
        location = 'Vespucci',
        icon = 'BS',
        iconColor = '#BE123C',
        canCall = false,
        blip = { sprite = 106, color = 1 },
        coords = { x = -1193.0, y = -892.0, z = 14.0 },
        autoStatus = true,
    },
}

Config.CompanyStatus = {
    open = { label = 'Ouvert', color = '#22C55E' },
    busy = { label = 'Occupé', color = '#F59E0B' },
    closed = { label = 'Fermé', color = '#E11D48' },
}

-- Statut auto selon employés on duty
Config.CompanyAutoStatus = {
    closedBelow = 1,
    busyAt = 1,
    openAt = 2,
}

-- Solde société : renewed | qb-management | qbx_management | phone_db
Config.CompanyBanking = {
    provider = 'auto', -- auto tente les exports connus puis phone_db
}

Config.Cooldowns.sendCompanyMessage = 800
Config.Cooldowns.toggleDuty = 1500

-- Banque
Config.Bank = {
    maxTransfer = 500000,
    minTransfer = 1,
}

-- Marketplace
Config.Marketplace = {
    categories = { 'vehicles', 'realty', 'items', 'services', 'jobs' },
    maxListingsPerPlayer = 10,
}

-- Garage adapter: 'qbx' | 'custom'
Config.Garage = {
    provider = 'qbx',
}

-- Debug print helper is in utils.lua
