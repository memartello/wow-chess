CreateFrame = function()
    return { RegisterEvent = function() end, SetScript = function() end }
end
SlashCmdList = {}
UnitFullName = function() return "Alice", "" end
GetNormalizedRealmName = function() return "" end
GetRealmName = function() return "Test Realm" end
GetTime = function() return 12.5 end
local chat = {}
DEFAULT_CHAT_FRAME = { AddMessage = function(_, message) chat[#chat + 1] = message end }

local WC = {}
assert(loadfile("WoWChess/Core.lua"))("WoWChess", WC)
assert(WC.PlayerName() == "Alice-TestRealm", "empty normalized realm falls back to the realm name")
WC.me = "Stale-TestRealm"
assert(WC.RefreshPlayerName() == "Alice-TestRealm" and WC.me == "Alice-TestRealm", "refresh replaces a stale login name")
assert(WC.Name("Bob") == "bob-testrealm", "short names use the normalized fallback realm")
assert(WC.Name("Bob-Other Realm") == "bob-otherrealm", "explicit realms normalize spaces")
local toc = assert(io.open("WoWChess/WoWChess_Camelot.toc", "r"))
local metadata = toc:read("*a")
toc:close()
assert(metadata:match("## Version: ([^\r\n]+)") == WC.ADDON_VERSION, "displayed version matches the toc")
WC.Log("SEND", "INV#123456 to=Bob api=0 accepted")
assert(#WC.logEntries == 1, "trace records a send")
SlashCmdList.WOWCHESS("log")
assert(chat[#chat]:find("INV#123456", 1, true), "log command prints the trace")
SlashCmdList.WOWCHESS("log clear")
assert(#WC.logEntries == 0, "log can be cleared before a test")

print("core_spec: OK")
