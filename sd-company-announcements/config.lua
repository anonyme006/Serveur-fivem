Config = {}

--- Verbose prints (client + server)
Config.Debug = false

--- SD-Phone custom app registration
Config.App = {
    Identifier  = 'company-announcements',
    Name        = 'Annonces',
    Description = 'Annonces internes de votre entreprise.',
    Developer   = 'SD Company',
    --- true = pré-installée / false = téléchargeable via App Store
    DefaultApp  = true,
}

--- Limite de caractères
Config.Limits = {
    TitleMax   = 150,
    ContentMax = 4000,
}

--- Durée de conservation des annonces archivées (jours). 0 = illimité.
Config.RetentionDays = 0

--- Notifier les membres de l'entreprise lors d'une publication importante/urgente
Config.Notifications = {
    Enabled = true,
    --- Priorités qui déclenchent une notification SD-Phone
    Priorities = {
        important = true,
        urgent    = true,
    },
    Title = 'Nouvelle annonce',
    Body  = 'Une nouvelle annonce %s a été publiée par votre entreprise.',
}

--- Types d'annonce (clé = valeur stockée en BDD)
Config.Types = {
    { value = 'information', label = 'Information', icon = 'ℹ️' },
    { value = 'meeting',     label = 'Réunion',     icon = '📅' },
    { value = 'recruitment', label = 'Recrutement', icon = '👥' },
    { value = 'event',       label = 'Événement',   icon = '🎉' },
    { value = 'urgent',      label = 'Urgent',      icon = '🚨' },
    { value = 'other',       label = 'Autre',       icon = '📌' },
}

--- Priorités
Config.Priorities = {
    { value = 'normal',     label = 'Normale',    badge = 'normal' },
    { value = 'important',  label = 'Importante', badge = 'important' },
    { value = 'urgent',     label = 'Urgente',    badge = 'urgent' },
}

--- Statuts
Config.Statuses = {
    { value = 'draft',     label = 'Brouillon' },
    { value = 'published', label = 'Publiée' },
    { value = 'archived',  label = 'Archivée' },
}

--- Permissions par défaut (appliquées si un grade n'est pas listé dans Companies)
Config.DefaultPermissions = {
    create  = false,
    edit    = false,
    delete  = false,
    publish = false,
}

--- Permissions basées sur le grade ESX (grade = job.grade)
--- Un joueur ne voit / ne touche que les annonces de SON job.
---
--- create  = créer (brouillon)
--- edit    = modifier (auteur OU détenteur de edit)
--- delete  = supprimer
--- publish = publier / archiver
Config.Companies = {
    police = {
        enabled = true,
        label   = 'LSPD',
        grades  = {
            [0] = { create = true,  edit = true,  delete = false, publish = false },
            [1] = { create = true,  edit = true,  delete = false, publish = false },
            [2] = { create = true,  edit = true,  delete = false, publish = true  },
            [3] = { create = true,  edit = true,  delete = true,  publish = true  },
            [4] = { create = true,  edit = true,  delete = true,  publish = true  },
        },
    },
    ambulance = {
        enabled = true,
        label   = 'EMS',
        grades  = {
            [0] = { create = true,  edit = true,  delete = false, publish = false },
            [1] = { create = true,  edit = true,  delete = false, publish = true  },
            [2] = { create = true,  edit = true,  delete = true,  publish = true  },
            [3] = { create = true,  edit = true,  delete = true,  publish = true  },
        },
    },
    mechanic = {
        enabled = true,
        label   = 'Mécano',
        grades  = {
            [0] = { create = true,  edit = true,  delete = false, publish = false },
            [1] = { create = true,  edit = true,  delete = false, publish = true  },
            [2] = { create = true,  edit = true,  delete = true,  publish = true  },
            [3] = { create = true,  edit = true,  delete = true,  publish = true  },
        },
    },
    taxi = {
        enabled = true,
        label   = 'Taxi',
        grades  = {
            [0] = { create = true,  edit = true,  delete = false, publish = false },
            [1] = { create = true,  edit = true,  delete = false, publish = true  },
            [2] = { create = true,  edit = true,  delete = true,  publish = true  },
        },
    },
    burgershot = {
        enabled = true,
        label   = 'Burger Shot',
        grades  = {
            [0] = { create = true,  edit = true,  delete = false, publish = false },
            [1] = { create = true,  edit = true,  delete = false, publish = true  },
            [2] = { create = true,  edit = true,  delete = true,  publish = true  },
            [3] = { create = true,  edit = true,  delete = true,  publish = true  },
        },
    },
    uwucafe = {
        enabled = true,
        label   = 'UwU Café',
        grades  = {
            [0] = { create = true,  edit = true,  delete = false, publish = false },
            [1] = { create = true,  edit = true,  delete = false, publish = true  },
            [2] = { create = true,  edit = true,  delete = true,  publish = true  },
            [3] = { create = true,  edit = true,  delete = true,  publish = true  },
        },
    },
}

--- Fallback grade labels used only if Config.Companies[job].grades[grade] is missing
--- but the company is enabled. Set AllowUnknownGrades = true to grant DefaultPermissions
--- (usually false) or a custom FallbackPermissions.
Config.AllowUnknownGrades = false
Config.FallbackPermissions = {
    create  = true,
    edit    = true,
    delete  = false,
    publish = false,
}

--- Table SQL (auto-créée au démarrage)
Config.TableName = 'sd_company_announcements'