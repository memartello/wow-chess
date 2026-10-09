local result1, result2 = 0, nil
local WC = { PREFIX = "WoWChess1", CHANNEL = "WoWChess", VERSION = "1" }
C_ChatInfo = {
    SendAddonMessage = function() return result1, result2 end,
}
GetChannelName = function() return 1 end
assert(loadfile("WoWChess/Network.lua"))("WoWChess", WC)

assert(WC.Network.SendWhisper("Bob-Realm", "1|ACC|123456"), "enum success")
result1, result2 = true, 0
assert(WC.Network.SendWhisper("Bob-Realm", "1|ACC|123456"), "two-return compatibility")
result1, result2 = true, nil
assert(WC.Network.SendWhisper("Bob-Realm", "1|ACC|123456"), "boolean success")
result1, result2 = nil, nil
assert(WC.Network.SendWhisper("Bob-Realm", "1|ACC|123456"), "legacy no-result success")
result1, result2 = 3, nil
assert(not WC.Network.SendWhisper("Bob-Realm", "1|ACC|123456"), "throttled send")
result1, result2 = nil, 3
assert(not WC.Network.SendChannel("1|WHO"), "second return error")

print("network_spec: OK")
