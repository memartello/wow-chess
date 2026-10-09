local now = 100
local sent = {}
local botThinking
local notices, clears = 0, 0
local WC = {
    VERSION = "3", GAME_SECONDS = 600, INVITE_SECONDS = 30,
    me = "Alice-Realm", db = { stats = { wins = 0, losses = 0, draws = 0 } },
    UI = {
        ShowGame = function() end, RefreshGame = function() end,
        RefreshClocks = function() end, ShowResult = function() end,
        SetStatus = function() end, ShowInvite = function() end,
        HideInvite = function() end, ShowDrawOffer = function() end,
        HideDrawOffer = function() end,
        NotifyOpponentMove = function() notices = notices + 1 end,
        ClearMoveNotification = function() clears = clears + 1 end,
    },
}
WC.Name = function(name)
    if not name then return nil end
    return (name:find("-") and name or name .. "-Realm"):lower()
end
WC.ShortName = function(name) return name:match("^[^%-]+") end
WC.Network = {
    BroadcastPresence = function() end,
    SendWhisper = function(target, message) sent[#sent + 1] = { target, message }; return true end,
    SendGame = function(action, game, payload) sent[#sent + 1] = { game.opponent, action .. "|" .. (payload or "") }; return true end,
}
WC.Bot = {
    Start = function(state, callback) botThinking = { state = state, callback = callback } end,
    Stop = function() botThinking = nil end,
}
GetTime = function() return now end
time = function() return 123456 end
UnitFactionGroup = function() return "Alliance" end
GetLocale = function() return "esES" end
C_Timer = { NewTicker = function() end }

assert(loadfile("WoWChess/Locale.lua"))("WoWChess", WC)
assert(loadfile("WoWChess/Chess.lua"))("WoWChess", WC)
assert(loadfile("WoWChess/Game.lua"))("WoWChess", WC)
local game = WC.Game

local ok = game.Challenge("Bob-Realm")
assert(ok and game.outgoing)
local inviteId = game.outgoing.id
game.OnMessage("ACC", { "3", "ACC", inviteId, "Bob-Realm" }, "Bob-Realm")
assert(game.active and game.active.opponent == "Bob-Realm")
assert(not game.active.connected, "clock waits for peer handshake")
game.OnMessage("PING", { "3", "PING", game.active.id, "0" }, "Bob-Realm")
assert(game.active.connected, "peer handshake completes")
game.active.color = "w"
now = now + 2
assert(game.PlayMove(WC.Chess.Square("e2"), WC.Chess.Square("e4")))
assert(game.active.seq == 1 and game.active.remaining.w == 598)
local id = game.active.id
game.OnMessage("MOVE", { "3", "MOVE", id, "2", "e7", "e5", "-", "59900" }, "Bob-Realm")
assert(game.active.seq == 2 and game.active.state.board[WC.Chess.Square("e5")] == "bP")
assert(notices == 1, "opponent move notification")
game.OnMessage("MOVE", { "3", "MOVE", id, "2", "e7", "e5", "-", "59900" }, "Bob-Realm")
assert(game.active.seq == 2 and notices == 1, "duplicates do not notify")
now = now + 21
game.Tick()
assert(not game.active and WC.db.stats.wins == 1, "desconexión")

game.OnMessage("INV", { "3", "INV", "123456999999", "Horde", "Bob-Realm" }, "Bob-Realm")
assert(not game.incoming, "rechazar facción distinta")
game.OnMessage("INV", { "3", "INV", "123456999998", "Alliance", "Bob-Realm" }, "Bob-Realm")
assert(game.incoming)
game.AcceptInvite()
assert(game.incoming.accepted)
game.OnMessage("START", { "3", "START", "123456999998", "123456111111", "Alice-Realm" }, "Bob-Realm")
assert(game.active and game.active.color == "w")
game.OnMessage("PING", { "3", "PING", game.active.id, "0" }, "Bob-Realm")
game.active.remaining.w = 1
now = now + 2
game.Tick()
assert(not game.active and WC.db.stats.losses == 1, "tiempo agotado")

local messagesBeforeBot = #sent
assert(game.StartBot())
assert(game.active.mode == "bot")
if game.active.color == "w" then
    assert(game.PlayMove(WC.Chess.Square("e2"), WC.Chess.Square("e4")))
end
assert(botThinking, "el bot debe recibir el turno")
local firstBotMove = WC.Chess.AllLegalMoves(botThinking.state)[1]
botThinking.callback(firstBotMove)
assert(game.active and game.active.mode == "bot" and game.active.seq >= 1)
assert(notices == 2, "bot move notification")
assert(#sent == messagesBeforeBot, "la práctica no debe enviar mensajes de partida")
game.Resign()
assert(not game.active and WC.db.stats.wins == 1 and WC.db.stats.losses == 1, "la práctica no altera estadísticas PvP")
assert(clears >= 3, "finished games clear notifications")

print("game_spec: OK")
