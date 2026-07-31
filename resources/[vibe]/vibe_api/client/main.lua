function VibeNotify(title, description, nType)
    lib.notify({ title = title or 'Vibe', description = description or '', type = nType or 'inform' })
end

function VibeGetCitizenId()
    return lib.callback.await('vibe_api:server:getCitizenId', false)
end

function VibeGetJob()
    return lib.callback.await('vibe_api:server:getJob', false)
end

function VibeIsPolice(requireDuty)
    return lib.callback.await('vibe_api:server:isPolice', false, requireDuty)
end

exports('Notify', VibeNotify)
exports('GetCitizenId', VibeGetCitizenId)
exports('GetJob', VibeGetJob)
exports('IsPolice', VibeIsPolice)
