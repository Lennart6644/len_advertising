local ESX = exports['es_extended']:getSharedObject()

local isOpen = false
local activeMode = nil
local activeJob = nil

local function notify(message)
    ESX.ShowNotification(message)
end

local function openUI(payload)
    if isOpen then return end
    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', data = payload })
end

local function closeUI()
    isOpen = false
    activeMode = nil
    activeJob = nil
    SetNuiFocus(false, false)
end

local function baseUIData(mode)
    return {
        mode = mode,
        strings = LocaleStrings('ui_'),
        pricing = Config.Pricing,
        theme = Config.Theme,
    }
end

RegisterCommand(Config.Commands.job, function(_, args)
    local job = ESX.GetPlayerData().job
    local isAdmin = job.name == Config.Permissions.adminJob
    local jobName = job.name

    if isAdmin and Config.Permissions.adminCanSpoofJob and args[1] then
        jobName = args[1]
    end

    local ad = Config.JobAds[jobName]
    if not ad then
        notify(L('job_not_found'))
        return
    end

    if not isAdmin and (job.name ~= jobName or job.grade < ad.minRank) then
        notify(L('no_permission'))
        return
    end

    activeMode = 'job'
    activeJob = jobName

    local data = baseUIData('job')
    data.title = Config.Label(ad.label)
    data.icon = ad.icon
    data.color = ad.color
    data.minTime = 5
    data.maxTime = ad.maxTime
    data.defaultTime = math.min(ad.defaultTime, ad.maxTime)
    data.maxChars = ad.maxChars
    data.minChars = Config.Message.minChars
    data.allowImportant = ad.allowImportant
    openUI(data)
end, false)

if Config.Private.enabled then
    RegisterCommand(Config.Commands.private, function()
        activeMode = 'private'

        local data = baseUIData('private')
        data.title = L('private_title')
        data.icon = Config.Private.icon
        data.color = Config.Private.color
        data.vipColor = Config.Private.vipColor
        data.minTime = Config.Private.minTime
        data.maxTime = Config.Private.maxTime
        data.defaultTime = Config.Private.defaultTime
        data.maxChars = Config.Private.maxChars
        data.minChars = Config.Message.minChars
        data.allowImportant = Config.Private.vipEnabled
        openUI(data)
    end, false)
end

RegisterNUICallback('close', function(_, cb)
    closeUI()
    cb('ok')
end)

RegisterNUICallback('submit', function(data, cb)
    cb('ok')
    local mode = activeMode
    local jobName = activeJob
    closeUI()

    local payload = {
        message = data.message,
        time = data.time,
        important = data.important,
    }

    if mode == 'job' then
        payload.jobName = jobName
        TriggerServerEvent('len_advertising:server:sendJobAd', payload)
    elseif mode == 'private' then
        TriggerServerEvent('len_advertising:server:sendPrivateAd', payload)
    end
end)

RegisterNetEvent('len_advertising:client:showNotify', function(data)
    data.theme = Config.Theme
    data.maxVisible = Config.Notifications.maxVisible
    data.fadeOut = Config.Notifications.fadeOut

    SendNUIMessage({ action = 'notify', data = data })

    if data.effect then
        SendNUIMessage({
            action = 'adminFx',
            data = {
                duration = data.duration,
                color = Config.AdminEffects.color,
                strength = Config.AdminEffects.strength,
            },
        })
    end

    if data.playSound then
        TriggerEvent(Config.Sound.event, Config.Sound.name, Config.Sound.volume)
    end
end)

RegisterNetEvent('len_advertising:client:notify', function(message)
    notify(message)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        SetNuiFocus(false, false)
    end
end)
