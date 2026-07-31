CreateThread(function()
    if Config.Debug then
        print('[vibe_api] client prêt')
    end
end)

--- Helper partagé côté client
---@return string|nil
function VibeGetCitizenId()
    return lib.callback.await('vibe_api:server:getCitizenId', false)
end

exports('GetCitizenId', VibeGetCitizenId)
