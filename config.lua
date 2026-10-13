Config = {}

Config.Locale = 'en'
Config.Debug = false

Config.Commands = {
    job = 'jobad',
    private = 'ad',
}

Config.Permissions = {
    adminJob = 'admin',
    adminCanSpoofJob = true,
}

Config.Message = {
    minChars = 2,
}

Config.Private = {
    enabled = true,
    maxChars = 150,
    minTime = 5,
    maxTime = 30,
    defaultTime = 10,
    vipEnabled = true,
    cooldown = 60,
    position = 'bottom-right',
    importantPosition = 'top-center',
    style = 'glass',
    sound = true,
    icon = 'bullhorn',
    color = '#ff8c00',
    vipColor = '#ffb703',
}

Config.Pricing = {
    enabled = true,
    currency = '$',
    base = 500,
    perSecond = 25,
    charThreshold = 25,
    charExtra = 250,
    vip = 1500,
}

Config.Billing = {
    enabled = true,
    table = 'billing',
    sender = 'society_news',
    targetType = 'society',
}

Config.Sound = {
    enabled = false,
    event = 'InteractSound_CL:PlayOnOne',
    name = 'advertising',
    volume = 0.5,
}

Config.AdminEffects = {
    enabled = true,
    color = '#ff0000',
    strength = 0.25,
}

Config.Notifications = {
    maxVisible = 4,
    fadeOut = 400,
}

Config.Theme = {
    glassOpacity = 0.78,
    borderRadius = 20,
    animationSpeed = 400,
    font = "'Inter', 'Segoe UI', Arial, sans-serif",
}

function Config.Label(text)
    return text[Config.Locale] or text.en or text.de
end

Config.JobDefaults = {
    minRank = 1,
    maxTime = 30,
    maxChars = 300,
    defaultTime = 10,
    icon = 'bullhorn',
    color = '#ffffff',
    style = 'sharp',
    position = 'bottom-right',
    importantPosition = 'top-center',
    allowImportant = false,
    important = false,
    sound = true,
}

Config.JobAds = {
    admin = {
        label = { de = 'Administration', en = 'Administration' },
        icon = 'gear',
        color = '#E74C3C',
        minRank = 0,
        maxTime = 300,
        important = true,
        allowImportant = true,
    },
    police = {
        label = { de = 'Polizeidepartement', en = 'Police Department' },
        icon = 'handcuffs',
        color = '#2980B9',
        maxTime = 90,
        allowImportant = true,
    },
    ambulance = {
        label = { de = 'Rettungsdienst', en = 'Emergency Medical Service' },
        icon = 'heart-pulse',
        color = '#C0392B',
        maxTime = 60,
        allowImportant = true,
    },
    fire = {
        label = { de = 'Feuerwehr', en = 'Fire Department' },
        icon = 'fire',
        color = '#E67E22',
        maxTime = 60,
        allowImportant = true,
    },
    mechanic = {
        label = { de = 'Mechaniker', en = 'Mechanic' },
        icon = 'wrench',
        color = '#D35400',
        maxTime = 30,
    },
}

for _, ad in pairs(Config.JobAds) do
    for key, value in pairs(Config.JobDefaults) do
        if ad[key] == nil then
            ad[key] = value
        end
    end
end
