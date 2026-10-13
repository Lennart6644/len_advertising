ESX = nil
local cooldowns = {}

CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Wait(100)
    end
end)

local function notifyPlayer(src, message)
    TriggerClientEvent('len_advertising:client:notify', src, message)
end

local function trim(value)
    return (tostring(value or ''):match('^%s*(.-)%s*$'))
end

local function clamp(value, min, max)
    value = math.floor(tonumber(value) or min)
    if value < min then return min end
    if value > max then return max end
    return value
end

local function validateMessage(message, minChars, maxChars)
    local length = utf8.len(message) or #message
    if length < minChars then
        return nil, L('message_too_short', minChars)
    end
    if length > maxChars then
        return nil, L('message_too_long', maxChars)
    end
    return length
end

local function calculatePrice(duration, length, vip)
    local p = Config.Pricing
    local total = p.base + duration * p.perSecond
    if length >= p.charThreshold then
        total = total + p.charExtra
    end
    if vip then
        total = total + p.vip
    end
    return total
end

local function canPostJob(xPlayer, jobName)
    local ad = Config.JobAds[jobName]
    if not ad then return false end
    local job = xPlayer.job
    if job.name == Config.Permissions.adminJob then return true end
    return job.name == jobName and job.grade >= ad.minRank
end

local function broadcast(data)
    TriggerClientEvent('len_advertising:client:showNotify', -1, data)
end

local function chargePlayer(src, xPlayer, price)
    if not Config.Billing.enabled then return end

    MySQL.Async.execute(
        ('INSERT INTO %s (identifier, sender, target_type, target, label, amount) VALUES (@identifier, @sender, @target_type, @target, @label, @amount)'):format(Config.Billing.table),
        {
            ['@identifier'] = 'none',
            ['@sender'] = Config.Billing.sender,
            ['@target_type'] = Config.Billing.targetType,
            ['@target'] = xPlayer.identifier,
            ['@label'] = L('billing_label'),
            ['@amount'] = price,
        }
    )

    TriggerClientEvent(
        'esx:showAdvancedNotification',
        src,
        'Bank',
        L('billing_title'),
        L('billing_message', Config.Pricing.currency .. price),
        'CHAR_BANK_MAZE',
        1
    )
end

RegisterNetEvent('len_advertising:server:sendJobAd', function(payload)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or type(payload) ~= 'table' then return end

    local jobName = payload.jobName
    local ad = Config.JobAds[jobName]
    if not ad or not canPostJob(xPlayer, jobName) then
        notifyPlayer(src, L('no_permission'))
        return
    end

    local message = trim(payload.message)
    local _, err = validateMessage(message, Config.Message.minChars, ad.maxChars)
    if err then
        notifyPlayer(src, err)
        return
    end

    local duration = clamp(payload.time, 1, ad.maxTime)
    local important = ad.important or (ad.allowImportant and payload.important == true)
    local isAdmin = jobName == Config.Permissions.adminJob

    broadcast({
        mode = 'job',
        title = Config.Label(ad.label),
        message = message,
        duration = duration * 1000,
        color = ad.color,
        icon = ad.icon,
        style = ad.style,
        important = important,
        position = important and ad.importantPosition or ad.position,
        playSound = Config.Sound.enabled and ad.sound and important,
        effect = isAdmin and Config.AdminEffects.enabled,
        jobName = jobName,
    })

    if Config.Debug then
        print(('[len_advertising] job ad by %s (%s)'):format(xPlayer.identifier, jobName))
    end
end)

RegisterNetEvent('len_advertising:server:sendPrivateAd', function(payload)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local cfg = Config.Private
    if not xPlayer or not cfg.enabled or type(payload) ~= 'table' then return end

    local now = os.time()
    local last = cooldowns[src]
    if last and now - last < cfg.cooldown then
        notifyPlayer(src, L('cooldown', math.ceil(cfg.cooldown - (now - last))))
        return
    end

    local message = trim(payload.message)
    local length, err = validateMessage(message, Config.Message.minChars, cfg.maxChars)
    if err then
        notifyPlayer(src, err)
        return
    end

    local duration = clamp(payload.time, cfg.minTime, cfg.maxTime)
    local vip = cfg.vipEnabled and payload.important == true
    local price = calculatePrice(duration, length, vip)

    if Config.Pricing.enabled then
        chargePlayer(src, xPlayer, price)
    end

    cooldowns[src] = now

    broadcast({
        mode = 'private',
        title = L('private_title'),
        message = message,
        duration = duration * 1000,
        color = vip and cfg.vipColor or cfg.color,
        icon = cfg.icon,
        style = cfg.style,
        important = vip,
        position = vip and cfg.importantPosition or cfg.position,
        playSound = Config.Sound.enabled and cfg.sound and vip,
    })

    if Config.Debug then
        print(('[len_advertising] private ad by %s, price %d'):format(xPlayer.identifier, price))
    end
end)

AddEventHandler('playerDropped', function()
    cooldowns[source] = nil
end)
