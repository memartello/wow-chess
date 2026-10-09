local now = 100
local sent = {}
local botThinking
local notices, clears = 0, 0
local WC = {
    VERSION = "6", GAME_SECONDS = 600, INVITE_SECONDS = 30,
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
game.OnMessage("ACC", { "6", "ACC", inviteId, "Bob-Realm" }, "Bob-Realm")
assert(game.active and game.active.opponent == "Bob-Realm")
assert(not game.active.connected, "clock waits for peer handshake")
game.OnMessage("PING", { "6", "PING", game.active.id, "0" }, "Bob-Realm")
assert(game.active.connected, "peer handshake completes")
game.active.color = "w"
now = now + 2
assert(game.PlayMove(WC.Chess.Square("e2"), WC.Chess.Square("e4")))
assert(game.active.seq == 1 and game.active.remaining.w == 598)
local id = game.active.id
game.OnMessage("MOVE", { "6", "MOVE", id, "2", "e7", "e5", "-", "59900" }, "Bob-Realm")
assert(game.active.seq == 2 and game.active.state.board[WC.Chess.Square("e5")] == "bP")
assert(notices == 1, "opponent move notification")
game.OnMessage("MOVE", { "6", "MOVE", id, "2", "e7", "e5", "-", "59900" }, "Bob-Realm")
assert(game.active.seq == 2 and notices == 1, "duplicates do not notify")
assert(not game.CanUndoBotTurn() and not game.UndoBotTurn(), "peer games cannot be rewound")
now = now + 21
game.Tick()
assert(not game.active and WC.db.stats.wins == 1, "desconexión")

game.OnMessage("INV", { "6", "INV", "123456999997", "Alliance", "Bob" }, "Bob-Realm")
assert(game.incoming and game.incoming.opponent == "Bob-Realm", "short declarations use the full event sender")
game.DeclineInvite()

game.OnMessage("INV", { "6", "INV", "123456999999", "Horde", "Bob-Realm" }, "Bob-Realm")
assert(not game.incoming, "rechazar facción distinta")
game.OnMessage("INV", { "6", "INV", "123456999998", "Alliance", "Bob-Realm" }, "Bob-Realm")
assert(game.incoming)
game.AcceptInvite()
assert(game.incoming.accepted)
game.OnMessage("START", { "6", "START", "123456999998", "123456111111", "i" }, "Bob-Realm")
assert(game.active and game.active.color == "w")
game.OnMessage("PING", { "6", "PING", game.active.id, "0" }, "Bob-Realm")
game.active.remaining.w = 1
now = now + 2
game.Tick()
assert(not game.active and WC.db.stats.losses == 1, "tiempo agotado")

local messagesBeforeBot = #sent
assert(game.StartBot("intermediate", "w"))
assert(game.active.mode == "bot" and not game.CanUndoBotTurn())
local initialState = game.active.state
now = now + 2
assert(game.PlayMove(WC.Chess.Square("e2"), WC.Chess.Square("e4")))
assert(botThinking, "el bot debe recibir el turno")
local firstBotMove = WC.Chess.AllLegalMoves(botThinking.state)[1]
local staleCallback = botThinking.callback
assert(game.CanUndoBotTurn() and game.UndoBotTurn(), "undo stops a pending bot turn")
assert(game.active.state == initialState and game.active.seq == 0 and
    game.active.remaining.w == 598 and game.active.remaining.b == 600 and
    not game.CanUndoBotTurn(), "undo restores the position and both clocks")
staleCallback(firstBotMove)
assert(game.active.seq == 0, "an interrupted bot search cannot move after undo")
assert(game.PlayMove(WC.Chess.Square("e2"), WC.Chess.Square("e4")))
staleCallback(firstBotMove)
assert(game.active.seq == 1, "an old callback stays invalid after replaying the same move number")
botThinking.callback(firstBotMove)
assert(game.active and game.active.mode == "bot" and game.active.seq == 2)
assert(notices == 2, "bot move notification")
assert(game.UndoBotTurn() and game.active.state == initialState and game.active.seq == 0 and
    game.active.state.turn == "w" and game.active.remaining.w == 598,
    "undo after the bot reply takes back the full turn")
assert(#sent == messagesBeforeBot, "la práctica no debe enviar mensajes de partida")
game.Resign()
assert(not game.active and WC.db.stats.wins == 1 and WC.db.stats.losses == 1, "la práctica no altera estadísticas PvP")
assert(game.StartBot("easy", "b"))
assert(not game.CanUndoBotTurn(), "the bot's opening move cannot be undone before the player moves")
local opening = WC.Chess.AllLegalMoves(botThinking.state)[1]
botThinking.callback(opening)
local beforeBlackMove = game.active.state
assert(beforeBlackMove.turn == "b" and not game.CanUndoBotTurn())
local blackMove = WC.Chess.AllLegalMoves(beforeBlackMove)[1]
assert(game.PlayMove(blackMove.from, blackMove.to, blackMove.promotion))
assert(game.UndoBotTurn() and game.active.state == beforeBlackMove and game.active.seq == 1 and
    game.active.state.turn == "b", "undo as black keeps the bot's opening move")
game.Resign()
assert(clears >= 3, "finished games clear notifications")

print("game_spec: OK")
