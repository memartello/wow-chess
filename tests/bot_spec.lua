local WC = { Print = function(message) error(message) end }
GetTime = os.clock
CreateFrame = function()
    local frame = {}
    function frame:SetScript(_, callback) self.update = callback end
    return frame
end

assert(loadfile("WoWChess/Locale.lua"))("WoWChess", WC)
assert(loadfile("WoWChess/Chess.lua"))("WoWChess", WC)
assert(loadfile("WoWChess/Bot.lua"))("WoWChess", WC)
local chess, bot = WC.Chess, WC.Bot

local state = chess.New()
state = assert(chess.Move(state, "f2", "f3"))
state = assert(chess.Move(state, "e7", "e5"))
state = assert(chess.Move(state, "g2", "g4"))

local co = coroutine.create(function() return bot.Choose(state, 2, 10) end)
local chosen
repeat
    local ok, result = coroutine.resume(co)
    assert(ok, result)
    if coroutine.status(co) == "dead" then chosen = result end
until coroutine.status(co) == "dead"
assert(chess.Name(chosen.from) == "d8" and chess.Name(chosen.to) == "h4", "el bot debe encontrar mate en uno")

local asyncMove
bot.Start(state, function(move) asyncMove = move end)
for _ = 1, 1000 do
    if asyncMove then break end
    assert(bot.frame.update, "búsqueda activa")
    bot.frame.update()
end
assert(asyncMove and chess.Name(asyncMove.from) == "d8" and chess.Name(asyncMove.to) == "h4", "búsqueda por cuadros")
assert(bot.frame.update == nil, "la búsqueda debe limpiar su actualización")

print("bot_spec: OK")
