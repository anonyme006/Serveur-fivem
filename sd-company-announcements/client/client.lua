local ESX = exports['es_extended']:getSharedObject()

local APP_ID = Config.App.Identifier

local function debugPrint(...)
    if Config.Debug then
        print('[sd-company-announcements:client]', ...)
    end
end

--- Resolve UI path for addCustomApp (same pattern as official sd-phone templates).
---@return string|nil
local function resolveUi()
    local resource = GetCurrentResourceName()
    local uiPage = GetResourceMetadata(resource, 'ui_page', 0)
    if not uiPage or uiPage == '' then return nil end
    if uiPage:find('^https?://') then
        return uiPage
    end
    return resource .. '/' .. uiPage
end

--- Build job gate from config companies (cosmetic icon visibility only).
local function buildJobGate()
    local gate = {}
    for name, cfg in pairs(Config.Companies or {}) do
        if cfg.enabled ~= false then
            gate[name] = 0
        end
    end
    return gate
end

local function triggerCallback(name, cb, ...)
    ESX.TriggerServerCallback(name, cb, ...)
end

local function registerApp()
    if GetResourceState('sd-phone') ~= 'started' then
        debugPrint('sd-phone not started, skip register')
        return
    end

    local resource = GetCurrentResourceName()
    local ok, err = exports['sd-phone']:addCustomApp({
        identifier  = Config.App.Identifier,
        name        = Config.App.Name,
        description = Config.App.Description,
        developer   = Config.App.Developer,
        defaultApp  = Config.App.DefaultApp,
        ui          = resolveUi(),
        icon        = ('https://cfx-nui-%s/web/icon.svg'):format(resource),
        job         = buildJobGate(),
        requires    = {
            check = 'sd-company-announcements.canSeeApp',
        },
        onOpen = function()
            debugPrint('app opened')
        end,
        onClose = function()
            debugPrint('app closed')
        end,
    })

    if ok then
        print(('[sd-company-announcements] registered as "%s"'):format(APP_ID))
    else
        print(('[sd-company-announcements] registration failed: %s'):format(err or 'unknown'))
    end
end

CreateThread(function()
    while GetResourceState('sd-phone') ~= 'started' do
        Wait(500)
    end
    Wait(1000)
    registerApp()
end)

AddEventHandler('onResourceStart', function(startedResource)
    if startedResource ~= 'sd-phone' then return end
    Wait(1000)
    registerApp()
end)

----------------------------------------------------------------
-- NUI callbacks (UI -> client -> server)
----------------------------------------------------------------

local function nuiReply(cb, payload)
    cb(payload or { ok = false })
end

RegisterNUICallback('getBootstrap', function(_, cb)
    triggerCallback('sd-company-announcements:getBootstrap', function(result)
        nuiReply(cb, result)
    end)
end)

RegisterNUICallback('getAnnouncements', function(data, cb)
    local search = data and data.search or ''
    triggerCallback('sd-company-announcements:getAnnouncements', function(result)
        nuiReply(cb, result)
    end, search)
end)

RegisterNUICallback('getAnnouncement', function(data, cb)
    local id = data and data.id
    triggerCallback('sd-company-announcements:getAnnouncement', function(result)
        nuiReply(cb, result)
    end, id)
end)

RegisterNUICallback('createAnnouncement', function(data, cb)
    triggerCallback('sd-company-announcements:createAnnouncement', function(result)
        nuiReply(cb, result)
        if result and result.ok then
            exports['sd-phone']:sendCustomAppMessage(APP_ID, {
                action = 'announcementsChanged',
                data = { reason = 'created' },
            })
        end
    end, data)
end)

RegisterNUICallback('updateAnnouncement', function(data, cb)
    local id = data and data.id
    triggerCallback('sd-company-announcements:updateAnnouncement', function(result)
        nuiReply(cb, result)
        if result and result.ok then
            exports['sd-phone']:sendCustomAppMessage(APP_ID, {
                action = 'announcementsChanged',
                data = { reason = 'updated' },
            })
        end
    end, id, data)
end)

RegisterNUICallback('deleteAnnouncement', function(data, cb)
    local id = data and data.id
    triggerCallback('sd-company-announcements:deleteAnnouncement', function(result)
        nuiReply(cb, result)
        if result and result.ok then
            exports['sd-phone']:sendCustomAppMessage(APP_ID, {
                action = 'announcementsChanged',
                data = { reason = 'deleted' },
            })
        end
    end, id)
end)

RegisterNUICallback('publishAnnouncement', function(data, cb)
    local id = data and data.id
    triggerCallback('sd-company-announcements:publishAnnouncement', function(result)
        nuiReply(cb, result)
        if result and result.ok then
            exports['sd-phone']:sendCustomAppMessage(APP_ID, {
                action = 'announcementsChanged',
                data = { reason = 'published' },
            })
        end
    end, id)
end)

RegisterNUICallback('archiveAnnouncement', function(data, cb)
    local id = data and data.id
    triggerCallback('sd-company-announcements:archiveAnnouncement', function(result)
        nuiReply(cb, result)
        if result and result.ok then
            exports['sd-phone']:sendCustomAppMessage(APP_ID, {
                action = 'announcementsChanged',
                data = { reason = 'archived' },
            })
        end
    end, id)
end)

--- Soft ping: keep NUI awake / acknowledge
RegisterNUICallback('closeApp', function(_, cb)
    nuiReply(cb, { ok = true })
end)

----------------------------------------------------------------
-- Live refresh when a coworker publishes
----------------------------------------------------------------

RegisterNetEvent('sd-company-announcements:client:refresh', function(payload)
    if GetResourceState('sd-phone') ~= 'started' then return end
    exports['sd-phone']:sendCustomAppMessage(APP_ID, {
        action = 'announcementsChanged',
        data = payload or { reason = 'refresh' },
    })
end)