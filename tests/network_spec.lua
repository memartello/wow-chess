local result1, result2, lastTarget = 0, nil, nil
GetTime = function() return 100 end
local WC = { PREFIX = "WoWChess1", CHANNEL = "WoWChess", VERSION = "1" }
local logs = {}
WC.Log = function(kind, detail) logs[#logs + 1] = kind .. " " .. detail end
WC.me = "Alice-Realm"
WC.Name = function(name) return name and (name:find("-", 1, true) and name or name .. "-Realm"):lower() end
WC.ShortName = function(name) return name:match("^[^%-]+") end
UnitFactionGroup = function() return "Alliance" end
C_ChatInfo = {
    SendAddonMessage = function(_, _, _, target) lastTarget = target; return result1, result2 end,
}
GetChannelName = function() return 1 end
assert(loadfile("WoWChess/Network.lua"))("WoWChess", WC)

assert(WC.Network.SendWhisper("Bob-Realm", "1|ACC|123456"), "enum success")
assert(lastTarget == "Bob", "Forever whispers omit the realm suffix")
assert(WC.Network.SendWhisper("John Zombie-Realm", "1|PING|123456"), "two-part character name")
assert(lastTarget == "John Zombie", "keep the full character name before the realm suffix")
result1, result2 = true, 0
assert(WC.Network.SendWhisper("Bob-Realm", "1|ACC|123456"), "two-return compatibility")
result1, result2 = true, nil
assert(WC.Network.SendWhisper("Bob-Realm", "1|ACC|123456"), "boolean success")
result1, result2 = nil, nil
assert(WC.Network.SendWhisper("Bob-Realm", "1|ACC|123456"), "legacy no-result success")
result1, result2 = 3, nil
assert(not WC.Network.SendWhisper("Bob-Realm", "1|ACC|123456"), "throttled send")
assert(logs[#logs]:find("api=3 failed", 1, true), "trace records the API rejection")
result1, result2 = nil, 3
assert(not WC.Network.SendChannel("1|WHO"), "second return error")

local received = 0
WC.Game = { OnMessage = function() received = received + 1 end }
WC.Network.OnMessage(WC.PREFIX, "1|INV|123456|Alliance|Alice-OtherRealm", "WHISPER", "Alice")
assert(received == 1, "a direct invitation from a same-named connected-realm player reaches the game")
assert(logs[#logs]:find("RECV INV#123456", 1, true), "trace records incoming invitations")

WC.Network.OnMessage(WC.PREFIX, "1|HELLO|60|Orc|online|Alliance|Bob-ActualRealm", "CHANNEL", "Bob-TransportRealm")
assert(WC.Network.players["bob-transportrealm"].name == "Bob-ActualRealm", "player list uses the advertised reply address")
WC.Network.OnMessage(WC.PREFIX, "1|HELLO|60|Orc|online|Alliance|Mallory-OtherRealm", "CHANNEL", "Bob-TransportRealm")
assert(WC.Network.players["bob-transportrealm"].name == "Bob-TransportRealm", "reject an address with a different character name")

print("network_spec: OK")
