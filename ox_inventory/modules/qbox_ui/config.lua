---@class OxInventoryQboxUiConfig
---@field ShowHealth boolean
---@field ShowHunger boolean
---@field ShowThirst boolean
---@field StatusUpdateInterval number

local defaults = {
    ShowHealth = true,
    ShowHunger = true,
    ShowThirst = true,
    StatusUpdateInterval = 500,
}

local ui = type(shared) == 'table' and shared.ui
local cfg = ui and type(ui.qboxUi) == 'table' and ui.qboxUi or {}

return {
    ShowHealth = cfg.showHealth ~= false,
    ShowHunger = cfg.showHunger ~= false,
    ShowThirst = cfg.showThirst ~= false,
    StatusUpdateInterval = tonumber(cfg.statusUpdateInterval) or defaults.StatusUpdateInterval,
}
