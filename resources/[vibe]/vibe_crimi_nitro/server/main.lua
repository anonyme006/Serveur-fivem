lib.callback.register('vibe_crimi_nitro:server:use', function(source)
    local count = exports.ox_inventory:GetItemCount(source, Config.Item) or 0
    if count < 1 then return false end
    exports.ox_inventory:RemoveItem(source, Config.Item, 1)
    return true
end)
