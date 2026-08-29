---@class OxInventoryQboxUiConfig
---@field AccentColor string
---@field ShowHealth boolean
---@field ShowHunger boolean
---@field ShowThirst boolean
---@field ShowArmor boolean
---@field ShowRemoveOutfit boolean
---@field StatusUpdateInterval number

local defaults = {
    AccentColor = '#d4af37',
    ShowHealth = true,
    ShowHunger = true,
    ShowThirst = true,
    ShowArmor = true,
    ShowRemoveOutfit = true,
    StatusUpdateInterval = 500,
}

local ui = type(shared) == 'table' and shared.ui
local cfg = ui and type(ui.qboxUi) == 'table' and ui.qboxUi or {}

return {
    AccentColor = type(cfg.accentColor) == 'string' and cfg.accentColor or defaults.AccentColor,
    ShowHealth = cfg.showHealth ~= false,
    ShowHunger = cfg.showHunger ~= false,
    ShowThirst = cfg.showThirst ~= false,
    ShowArmor = cfg.showArmor ~= false,
    ShowRemoveOutfit = cfg.showRemoveOutfit ~= false,
    StatusUpdateInterval = tonumber(cfg.statusUpdateInterval) or defaults.StatusUpdateInterval,
}
