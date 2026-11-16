local _, addon = ...

addon.Locales = { enUS = {}, enGB = {} }
addon.Localization = {}
local Localization = addon.Localization

-- Select by client language, never by realm, profile or saved preferences.
-- Missing keys and unknown locales always retain the English source text.
addon.L = setmetatable({}, {
    __index = function(_, key)
        local locale = GetLocale and GetLocale() or "enUS"
        local dictionary = addon.Locales[locale]
        return dictionary and dictionary[key] or key
    end,
})

function Localization.ButtonText(button, label, reservedWidth)
    button:SetText(label)
    local font = button.GetFontString and button:GetFontString()
    if not font or not font.GetFont or not font.GetStringWidth then
        return
    end
    if not button.waylaidBaseFont then
        button.waylaidBaseFont = { font:GetFont() }
    end
    local face, size, flags = unpack(button.waylaidBaseFont)
    if not face or not size then
        return
    end
    font:SetFont(face, size, flags)
    font:SetWordWrap(false)
    local available = math.max(1, button:GetWidth() - 12 - (reservedWidth or 0))
    local width = font:GetStringWidth()
    if width > available then
        font:SetFont(face, math.max(9, size * available / width), flags)
    end
end
