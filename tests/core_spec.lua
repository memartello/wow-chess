CreateFrame = function()
    return { RegisterEvent = function() end, SetScript = function() end }
end
SlashCmdList = {}
UnitFullName = function() return "Alice", "" end
GetNormalizedRealmName = function() return "" end
GetRealmName = function() return "Test Realm" end

local WC = {}
assert(loadfile("WoWChess/Core.lua"))("WoWChess", WC)
assert(WC.PlayerName() == "Alice-TestRealm", "empty normalized realm falls back to the realm name")
assert(WC.Name("Bob") == "bob-testrealm", "short names use the normalized fallback realm")
assert(WC.Name("Bob-Other Realm") == "bob-otherrealm", "explicit realms normalize spaces")
local toc = assert(io.open("WoWChess/WoWChess_Camelot.toc", "r"))
local metadata = toc:read("*a")
toc:close()
assert(metadata:match("## Version: ([^\r\n]+)") == WC.ADDON_VERSION, "displayed version matches the toc")

print("core_spec: OK")
