---@class OxInventoryQboxUiConfig
---@field AccentColor string
---@field ShowHunger boolean
---@field ShowThirst boolean
---@field ShowHealth boolean
---@field ShowArmor boolean
---@field ShowCharacter boolean
---@field EnableClothingSlots boolean
---@field EnableCharacterRotation boolean
---@field EnableCharacterZoom boolean
---@field CharacterBackground string
---@field CharacterPedSlot number
---@field StatusUpdateInterval number

Config = {
    AccentColor = '#d946ef',
    ShowHunger = true,
    ShowThirst = true,
    ShowHealth = true,
    ShowArmor = true,
    ShowCharacter = true,
    EnableClothingSlots = true,
    EnableCharacterRotation = true,
    EnableCharacterZoom = true,
    --- 'transparent' | 'dark'
    CharacterBackground = 'dark',
    --- Pause menu ped slot (0-3). 2 = center-ish on most resolutions.
    CharacterPedSlot = 2,
    --- ms between health/armor checks while inventory is open (hunger/thirst use state bags)
    StatusUpdateInterval = 500,
}

return Config
