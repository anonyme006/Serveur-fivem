function RerollNotify(title, description, nType)
    lib.notify({ title = title or 'Reroll', description = description or '', type = nType or 'inform' })
end

function RerollGetCitizenId()
    return lib.callback.await('rr_api:server:getCitizenId', false)
end

function RerollGetJob()
    return lib.callback.await('rr_api:server:getJob', false)
end

function RerollIsPolice(requireDuty)
    return lib.callback.await('rr_api:server:isPolice', false, requireDuty)
end

exports('Notify', RerollNotify)
exports('GetCitizenId', RerollGetCitizenId)
exports('GetJob', RerollGetJob)
exports('IsPolice', RerollIsPolice)
