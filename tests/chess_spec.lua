local WC = {}
assert(loadfile("WoWChess/Chess.lua"))("WoWChess", WC)
local chess = WC.Chess

local function play(state, from, to, promotion)
    local nextState, notation, err = chess.Move(state, from, to, promotion)
    assert(nextState, (from or "?") .. "-" .. (to or "?") .. ": " .. tostring(err))
    assert(notation and notation ~= "")
    return nextState
end

local function empty(turn)
    return { board = {}, turn = turn, rights = {}, ep = nil, halfmove = 0, fullmove = 1, counts = {}, moves = {} }
end

local function seed(state)
    state.counts[chess.Key(state)] = 1
    return state
end

local state = chess.New()
assert(#chess.AllLegalMoves(state) == 20, "posición inicial")
local secondPly = 0
for _, move in ipairs(chess.AllLegalMoves(state)) do
    local nextState = assert(chess.Move(state, move.from, move.to, move.promotion))
    secondPly = secondPly + #chess.AllLegalMoves(nextState)
end
assert(secondPly == 400, "cantidad de posiciones a dos jugadas")
state = play(state, "e2", "e4")
state = play(state, "e7", "e5")
state = play(state, "g1", "f3")
assert(state.board[chess.Square("f3")] == "wN")
assert(#state.moveDetails == #state.moves and state.moveDetails[1].from == chess.Square("e2") and
    state.moveDetails[1].to == chess.Square("e4") and state.moveDetails[2].from == chess.Square("e7") and
    state.moveDetails[2].to == chess.Square("e5"), "history retains each move's squares")

state = chess.New()
state = play(state, "f2", "f3")
state = play(state, "e7", "e5")
state = play(state, "g2", "g4")
state = play(state, "d8", "h4")
assert(state.outcome and state.outcome.reason == "mate" and state.outcome.winner == "b", "mate del loco")

state = chess.New()
state = play(state, "e2", "e4")
state = play(state, "a7", "a6")
state = play(state, "e4", "e5")
state = play(state, "d7", "d5")
state = play(state, "e5", "d6")
assert(state.board[chess.Square("d6")] == "wP" and state.board[chess.Square("d5")] == nil, "al paso")
assert(state.moveDetails[#state.moveDetails].captured == "bP", "en passant records the lost pawn")

state = seed(empty("w"))
state.board[chess.Square("e1")] = "wK"
state.board[chess.Square("h1")] = "wR"
state.board[chess.Square("e8")] = "bK"
state.rights.wK = true
state = seed(state)
state = play(state, "e1", "g1")
assert(state.board[chess.Square("f1")] == "wR" and state.board[chess.Square("g1")] == "wK", "enroque")

state = empty("w")
state.board[chess.Square("e1")] = "wK"
state.board[chess.Square("h8")] = "bK"
state.board[chess.Square("a7")] = "wP"
state = seed(state)
assert(chess.Move(state, "a7", "a8") == nil, "promoción debe elegirse")
state = play(state, "a7", "a8", "N")
assert(state.board[chess.Square("a8")] == "wN", "promoción")

state = empty("b")
state.board[chess.Square("a8")] = "bK"
state.board[chess.Square("c6")] = "wK"
state.board[chess.Square("b6")] = "wQ"
state = seed(state)
assert(chess.Result(state).reason == "ahogado", "ahogado")

state = chess.New()
for _ = 1, 2 do
    state = play(state, "g1", "f3")
    state = play(state, "g8", "f6")
    state = play(state, "f3", "g1")
    state = play(state, "f6", "g8")
end
assert(state.outcome and state.outcome.reason == "triple repetición", "repetición")

print("chess_spec: OK")
