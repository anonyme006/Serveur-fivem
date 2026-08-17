NuiTemp = {
    pending = nil,
}

--- Opens the furnace temperature minigame. Returns { temperature = number } or nil if cancelled.
function NuiTemp.Open()
    local p = promise.new()
    NuiTemp.pending = p
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openFurnace',
        data = {
            targetMin = Config.Meth.furnaceTargetMin,
            targetMax = Config.Meth.furnaceTargetMax,
            overheat = Config.Meth.furnaceOverheat,
            underheat = Config.Meth.furnaceUnderheat,
        },
    })
    return Citizen.Await(p)
end

RegisterNUICallback('furnaceResult', function(data, cb)
    cb(1)
    SetNuiFocus(false, false)
    if NuiTemp.pending then
        NuiTemp.pending:resolve(data and data.cancelled and nil or data)
        NuiTemp.pending = nil
    end
end)

RegisterNUICallback('close', function(_, cb)
    cb(1)
    SetNuiFocus(false, false)
    if NuiTemp.pending then
        NuiTemp.pending:resolve(nil)
        NuiTemp.pending = nil
    end
end)

-- ESC safety
CreateThread(function()
    while true do
        if NuiTemp.pending then
            Wait(0)
            if IsControlJustReleased(0, 322) then -- ESC
                SetNuiFocus(false, false)
                SendNUIMessage({ action = 'close' })
                if NuiTemp.pending then
                    NuiTemp.pending:resolve(nil)
                    NuiTemp.pending = nil
                end
            end
        else
            Wait(500)
        end
    end
end)
