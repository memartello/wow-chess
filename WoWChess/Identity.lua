local _, WC = ...

-- Forever shows a first name and surname with either a space or a hyphen.
-- Channel events may append a backend realm, which can differ from UnitFullName.
-- This comparison is only for suppressing our own presence, never for
-- authenticating an opponent or choosing a whisper target.
local function nameParts(value)
    if type(value) ~= "string" then return nil end
    local parts = {}
    for part in value:gmatch("[^%s%-]+") do
        parts[#parts + 1] = part
    end
    return #parts > 0 and parts or nil
end

function WC.IsOwnPresence(value)
    local own, candidate = nameParts(WC.me), nameParts(value)
    if not own or not candidate or own[1]:lower() ~= candidate[1]:lower() then return false end
    if own[2] or candidate[2] then
        return own[2] ~= nil and candidate[2] ~= nil and own[2]:lower() == candidate[2]:lower()
    end
    return true
end

function WC.DiscoveryDisplayName(value)
    local parts = nameParts(value)
    if not parts then return "?" end
    if parts[2] then return parts[1] .. " " .. parts[2] end
    return parts[1]
end
