Locales = {}

local function currentSet()
    return Locales[Config.Locale] or Locales.en
end

function L(key, ...)
    local set = currentSet()
    local text = set[key] or Locales.en[key] or key
    if select('#', ...) > 0 then
        return text:format(...)
    end
    return text
end

function LocaleStrings(prefix)
    local out = {}
    for key, value in pairs(currentSet()) do
        if key:sub(1, #prefix) == prefix then
            out[key:sub(#prefix + 1)] = value
        end
    end
    return out
end
