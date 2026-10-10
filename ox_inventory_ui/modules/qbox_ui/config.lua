---@class OxInventoryQboxUiConfig
---@field AccentColor string
---@field ShowHealth boolean
---@field ShowHunger boolean
---@field ShowThirst boolean
---@field ShowArmor boolean
---@field ShowCharacter boolean
---@field ShowClothing boolean
---@field EnableCharacterRotation boolean
---@field EnableCharacterZoom boolean
---@field CharacterBackground string
---@field CharacterPedSlot number
---@field StatusUpdateInterval number

Config = {
    AccentColor = '#d4af37',
    ShowHealth = true,
    ShowHunger = true,
    ShowThirst = true,
    ShowArmor = true,
    ShowCharacter = true,
    ShowClothing = true,
    EnableCharacterRotation = true,
    EnableCharacterZoom = true,
    --- 'transparent' | 'dark'
    CharacterBackground = 'dark',
    CharacterPedSlot = 2,
    --- Filet de secours santé/armure (faim/soif = state bags qbx_core)
    StatusUpdateInterval = 500,
}

return Config
