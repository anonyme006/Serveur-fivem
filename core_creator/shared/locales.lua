Locales = Locales or {}
CurrentLocale = CurrentLocale or {}

local function loadLocaleFile(lang)
    local raw = LoadResourceFile(CoreUtils.ResourceName(), ('locales/%s.json'):format(lang))
    if not raw then return nil end
    return CoreUtils.SafeJsonDecode(raw)
end

function Locales.Load(lang)
    lang = lang or Config.Locale or 'en'
    local data = loadLocaleFile(lang)
    if not data and lang ~= 'en' then
        data = loadLocaleFile('en')
    end
    CurrentLocale = data or {}
    return CurrentLocale
end

function Locales.T(key, replacements)
    local value = CurrentLocale[key] or key
    if type(replacements) == 'table' then
        for k, v in pairs(replacements) do
            value = value:gsub('{' .. k .. '}', tostring(v))
        end
    end
    return value
end

-- shorthand
function _(key, replacements)
    return Locales.T(key, replacements)
end

CreateThread(function()
    Locales.Load(Config.Locale)
end)
