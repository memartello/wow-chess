local now = 100
GetTime = function() return now end
time = function() return 123456 end
GetLocale = function() return "esES" end
UnitFactionGroup = function() return "Alliance" end
C_Timer = { NewTicker = function() end }

local function fields(message)
    local parts = {}
    for part in (message .. "|"):gmatch("(.-)|") do parts[#parts + 1] = part end
    return parts
end

local function scenario(failAccept, dropStart, shortChallenge, shortSenders, senderRealmAlias)
    now = 100
    local clients, queue = {}, {}
    local function client(name)
        local WC = {
            VERSION = "4", GAME_SECONDS = 600, INVITE_SECONDS = 30,
            me = name, db = { stats = { wins = 0, losses = 0, draws = 0 } },
            Bot = { Stop = function() end },
            ShortName = function(value) return value:match("^[^%-]+") end,
            Name = function(value)
                if not value then return nil end
                if not value:find("-", 1, true) then value = value .. "-Realm" end
                return value:lower()
            end,
        }
        WC.UI = {
            SetStatus = function(message) WC.status = message end,
            ShowInvite = function() WC.inviteShown = true end, HideInvite = function() end,
            ShowGame = function() WC.shown = true end,
            ShowMain = function() WC.shown = false end,
            RefreshGame = function() end, RefreshClocks = function() end,
            ClearMoveNotification = function() end, NotifyOpponentMove = function() end,
        }
        WC.Network = {
            BroadcastPresence = function() end,
            SendWhisper = function(target, message)
                local action = fields(message)[2]
                if action == "ACC" and failAccept then failAccept = false; return false end
                if action == "START" and dropStart then
                    if dropStart ~= "all" then dropStart = false end
                    return true
                end
                queue[#queue + 1] = { sender = name, target = target, message = message }
                return true
            end,
        }
        WC.Network.SendGame = function(action, game, payload)
            return WC.Network.SendWhisper(game.opponent, WC.VERSION .. "|" .. action .. "|" .. game.id .. "|" .. (payload or ""))
        end
        assert(loadfile("WoWChess/Locale.lua"))("WoWChess", WC)
        assert(loadfile("WoWChess/Chess.lua"))("WoWChess", WC)
        assert(loadfile("WoWChess/Game.lua"))("WoWChess", WC)
        clients[name] = WC
        return WC
    end
    local alice, bob = client("Alice-Realm"), client(shortChallenge and "Bob-ConnectedRealm" or "Bob-Realm")
    local function flush()
        local count = 0
        while #queue > 0 do
            count = count + 1
            assert(count < 100, "handshake message loop")
            local message = table.remove(queue, 1)
            local target = clients[message.target] or (message.target == "Bob" and bob)
            assert(target, "message target exists")
            local parts = fields(message.message)
            local sender = message.sender
            if shortSenders then sender = sender:match("^[^%-]+") end
            if senderRealmAlias then sender = sender:match("^[^%-]+") .. "-TransportRealm" end
            target.Game.OnMessage(parts[2], parts, sender)
        end
    end
    assert(alice.Game.Challenge(shortChallenge and "Bob" or bob.me))
    flush()
    assert(bob.Game.incoming and bob.inviteShown, "invitation popup delivered")
    if not shortChallenge then
        alice.Game.OnMessage("ACC", { "4", "ACC", alice.Game.outgoing.id, "Bob-OtherRealm" }, "Bob-OtherRealm")
        assert(not alice.Game.outgoing.startMessage, "an explicit realm rejects a different sender")
    end
    bob.Game.AcceptInvite()
    flush()
    if dropStart == "all" then
        now = now + 31
        alice.Game.Tick()
        bob.Game.Tick()
        assert(not alice.Game.active and not bob.Game.active and not bob.Game.incoming, "failed handshake ends on both clients")
        assert(alice.db.stats.wins == 0 and bob.db.stats.losses == 0, "connection failure is not a game result")
        return
    end
    for _ = 1, 3 do
        if alice.Game.active and bob.Game.active and alice.Game.active.connected and bob.Game.active.connected then break end
        now = now + 2.1
        alice.Game.Tick()
        bob.Game.Tick()
        flush()
    end
    assert(alice.Game.active and bob.Game.active, "both clients enter the game")
    assert(alice.Game.active.connected and bob.Game.active.connected, "both clients confirm connection")
    assert(alice.Game.active.id == bob.Game.active.id, "same game id")
    assert(alice.Game.active.color ~= bob.Game.active.color, "opposite colors")
    assert(alice.Game.active.opponent == bob.me, "challenger uses the full responding name")
    assert(bob.Game.active.opponent == alice.me, "acceptor uses the full challenger name")
end

scenario(false, false)
scenario(true, false)
scenario(false, true)
scenario(false, "all")
scenario(false, false, true)
scenario(false, false, true, true)
scenario(false, false, false, true)
scenario(true, true, true, true)
scenario(false, false, false, false, true)

print("handshake_spec: OK")
