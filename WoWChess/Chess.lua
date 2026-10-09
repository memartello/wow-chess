local _, WC = ...
local Chess = {}
WC.Chess = Chess

local files = "abcdefgh"
local function side(piece) return piece and piece:sub(1, 1) end
local function kind(piece) return piece and piece:sub(2, 2) end
local function other(color) return color == "w" and "b" or "w" end
local function index(file, rank) return (rank - 1) * 8 + file end
local function coords(square) return ((square - 1) % 8) + 1, math.floor((square - 1) / 8) + 1 end
local function valid(file, rank) return file >= 1 and file <= 8 and rank >= 1 and rank <= 8 end

function Chess.Square(name)
    if type(name) ~= "string" or not name:match("^[a-h][1-8]$") then return nil end
    return index(files:find(name:sub(1, 1), 1, true), tonumber(name:sub(2, 2)))
end

function Chess.Name(square)
    local file, rank = coords(square)
    return files:sub(file, file) .. tostring(rank)
end

local function copy(state, light)
    local result = {
        board = {}, turn = state.turn, rights = {}, ep = state.ep,
        halfmove = state.halfmove, fullmove = state.fullmove,
        counts = light and state.counts or {}, moves = light and state.moves or {},
        moveDetails = light and state.moveDetails or {}, outcome = state.outcome,
    }
    for i = 1, 64 do result.board[i] = state.board[i] end
    for key, value in pairs(state.rights) do result.rights[key] = value end
    if not light then
        for key, value in pairs(state.counts) do result.counts[key] = value end
        for i, value in ipairs(state.moves) do result.moves[i] = value end
        for i, value in ipairs(state.moveDetails or {}) do result.moveDetails[i] = value end
    end
    return result
end

function Chess.Key(state)
    local board = {}
    for i = 1, 64 do board[i] = state.board[i] or ".." end
    local rights = ""
    for _, key in ipairs({ "wK", "wQ", "bK", "bQ" }) do
        if state.rights[key] then rights = rights .. key end
    end
    return table.concat(board) .. state.turn .. rights .. (state.ep and Chess.Name(state.ep) or "-")
end

function Chess.New()
    local state = { board = {}, turn = "w", rights = { wK = true, wQ = true, bK = true, bQ = true }, halfmove = 0, fullmove = 1, counts = {}, moves = {}, moveDetails = {} }
    local back = { "R", "N", "B", "Q", "K", "B", "N", "R" }
    for file = 1, 8 do
        state.board[index(file, 1)] = "w" .. back[file]
        state.board[index(file, 2)] = "wP"
        state.board[index(file, 7)] = "bP"
        state.board[index(file, 8)] = "b" .. back[file]
    end
    state.counts[Chess.Key(state)] = 1
    return state
end

function Chess.Attacked(state, square, by)
    local board = state.board
    local file, rank = coords(square)
    local pawnRank = rank + (by == "w" and -1 or 1)
    for _, df in ipairs({ -1, 1 }) do
        if valid(file + df, pawnRank) and board[index(file + df, pawnRank)] == by .. "P" then return true end
    end
    for _, offset in ipairs({ { 1, 2 }, { 2, 1 }, { -1, 2 }, { -2, 1 }, { 1, -2 }, { 2, -1 }, { -1, -2 }, { -2, -1 } }) do
        local f, r = file + offset[1], rank + offset[2]
        if valid(f, r) and board[index(f, r)] == by .. "N" then return true end
    end
    for df = -1, 1 do
        for dr = -1, 1 do
            if (df ~= 0 or dr ~= 0) and valid(file + df, rank + dr) and board[index(file + df, rank + dr)] == by .. "K" then return true end
        end
    end
    for df = -1, 1 do
        for dr = -1, 1 do
            if df ~= 0 or dr ~= 0 then
                local diagonal = df ~= 0 and dr ~= 0
                local f, r = file + df, rank + dr
                while valid(f, r) do
                    local piece = board[index(f, r)]
                    if piece then
                        if side(piece) == by and (kind(piece) == "Q" or kind(piece) == (diagonal and "B" or "R")) then return true end
                        break
                    end
                    f, r = f + df, r + dr
                end
            end
        end
    end
    return false
end

function Chess.InCheck(state, color)
    for square = 1, 64 do
        if state.board[square] == color .. "K" then return Chess.Attacked(state, square, other(color)) end
    end
    return true
end

local function add(moves, from, to, promotion, special)
    moves[#moves + 1] = { from = from, to = to, promotion = promotion, special = special }
end

local function addPawn(moves, from, to, promotionRank, special)
    local _, rank = coords(to)
    if rank == promotionRank then
        for _, piece in ipairs({ "Q", "R", "B", "N" }) do add(moves, from, to, piece, special) end
    else
        add(moves, from, to, nil, special)
    end
end

function Chess.PseudoMoves(state, from)
    local board, piece = state.board, state.board[from]
    local moves = {}
    if not piece or side(piece) ~= state.turn then return moves end
    local color, pieceKind = side(piece), kind(piece)
    local file, rank = coords(from)
    local function step(df, dr)
        local f, r = file + df, rank + dr
        if valid(f, r) then
            local to = index(f, r)
            if not board[to] or (side(board[to]) ~= color and kind(board[to]) ~= "K") then add(moves, from, to) end
        end
    end
    if pieceKind == "P" then
        local dir, home, final = color == "w" and 1 or -1, color == "w" and 2 or 7, color == "w" and 8 or 1
        local ahead = index(file, rank + dir)
        if not board[ahead] then
            addPawn(moves, from, ahead, final)
            if rank == home and not board[index(file, rank + 2 * dir)] then add(moves, from, index(file, rank + 2 * dir)) end
        end
        for _, df in ipairs({ -1, 1 }) do
            if valid(file + df, rank + dir) then
                local to = index(file + df, rank + dir)
                if board[to] and side(board[to]) ~= color and kind(board[to]) ~= "K" then
                    addPawn(moves, from, to, final)
                elseif state.ep == to and board[index(file + df, rank)] == other(color) .. "P" then
                    add(moves, from, to, nil, "ep")
                end
            end
        end
    elseif pieceKind == "N" then
        for _, offset in ipairs({ { 1, 2 }, { 2, 1 }, { -1, 2 }, { -2, 1 }, { 1, -2 }, { 2, -1 }, { -1, -2 }, { -2, -1 } }) do step(offset[1], offset[2]) end
    elseif pieceKind == "K" then
        for df = -1, 1 do for dr = -1, 1 do if df ~= 0 or dr ~= 0 then step(df, dr) end end end
        local home = color == "w" and 1 or 8
        if from == index(5, home) and not Chess.InCheck(state, color) then
            if state.rights[color .. "K"] and board[index(8, home)] == color .. "R" and not board[index(6, home)] and not board[index(7, home)] and not Chess.Attacked(state, index(6, home), other(color)) and not Chess.Attacked(state, index(7, home), other(color)) then
                add(moves, from, index(7, home), nil, "castleK")
            end
            if state.rights[color .. "Q"] and board[index(1, home)] == color .. "R" and not board[index(2, home)] and not board[index(3, home)] and not board[index(4, home)] and not Chess.Attacked(state, index(4, home), other(color)) and not Chess.Attacked(state, index(3, home), other(color)) then
                add(moves, from, index(3, home), nil, "castleQ")
            end
        end
    else
        for df = -1, 1 do
            for dr = -1, 1 do
                if (df ~= 0 or dr ~= 0) and (pieceKind == "Q" or (pieceKind == "B" and df ~= 0 and dr ~= 0) or (pieceKind == "R" and (df == 0 or dr == 0))) then
                    local f, r = file + df, rank + dr
                    while valid(f, r) do
                        local to = index(f, r)
                        if board[to] then
                            if side(board[to]) ~= color and kind(board[to]) ~= "K" then add(moves, from, to) end
                            break
                        end
                        add(moves, from, to)
                        f, r = f + df, r + dr
                    end
                end
            end
        end
    end
    return moves
end

local function applyUnchecked(state, move, light)
    local nextState = copy(state, light)
    local board = nextState.board
    local piece, captured = board[move.from], board[move.to]
    local color, pieceKind = side(piece), kind(piece)
    local fromFile, fromRank = coords(move.from)
    local toFile, toRank = coords(move.to)
    board[move.from] = nil
    board[move.to] = move.promotion and color .. move.promotion or piece
    if move.special == "ep" then
        local victim = index(toFile, fromRank)
        captured = board[victim]
        board[victim] = nil
    elseif move.special == "castleK" then
        board[index(6, fromRank)] = board[index(8, fromRank)]
        board[index(8, fromRank)] = nil
    elseif move.special == "castleQ" then
        board[index(4, fromRank)] = board[index(1, fromRank)]
        board[index(1, fromRank)] = nil
    end
    if pieceKind == "K" then
        nextState.rights[color .. "K"] = nil
        nextState.rights[color .. "Q"] = nil
    elseif pieceKind == "R" then
        if move.from == index(1, 1) then nextState.rights.wQ = nil end
        if move.from == index(8, 1) then nextState.rights.wK = nil end
        if move.from == index(1, 8) then nextState.rights.bQ = nil end
        if move.from == index(8, 8) then nextState.rights.bK = nil end
    end
    if move.to == index(1, 1) then nextState.rights.wQ = nil end
    if move.to == index(8, 1) then nextState.rights.wK = nil end
    if move.to == index(1, 8) then nextState.rights.bQ = nil end
    if move.to == index(8, 8) then nextState.rights.bK = nil end
    nextState.ep = pieceKind == "P" and math.abs(toRank - fromRank) == 2 and index(fromFile, (fromRank + toRank) / 2) or nil
    nextState.halfmove = (pieceKind == "P" or captured) and 0 or state.halfmove + 1
    nextState.fullmove = state.fullmove + (color == "b" and 1 or 0)
    nextState.turn = other(color)
    nextState.outcome = nil
    return nextState, captured
end

function Chess.LegalMoves(state, from)
    local legal = {}
    if state.outcome then return legal end
    for _, move in ipairs(Chess.PseudoMoves(state, from)) do
        local candidate = applyUnchecked(state, move, true)
        if not Chess.InCheck(candidate, state.turn) then legal[#legal + 1] = move end
    end
    return legal
end

-- Search-only transition for already legal moves. It skips SAN, result detection,
-- and copying the move/repetition history; callers must not mutate those tables.
function Chess.Simulate(state, move)
    return applyUnchecked(state, move, true)
end

function Chess.AllLegalMoves(state)
    local all = {}
    for square = 1, 64 do
        if side(state.board[square]) == state.turn then
            for _, move in ipairs(Chess.LegalMoves(state, square)) do all[#all + 1] = move end
        end
    end
    return all
end

local function insufficient(state)
    local minor = {}
    for square = 1, 64 do
        local piece = state.board[square]
        if piece and kind(piece) ~= "K" then
            if kind(piece) ~= "B" and kind(piece) ~= "N" then return false end
            minor[#minor + 1] = { piece = piece, square = square }
        end
    end
    if #minor <= 1 then return true end
    if #minor == 2 and kind(minor[1].piece) == "B" and kind(minor[2].piece) == "B" and side(minor[1].piece) ~= side(minor[2].piece) then
        local f1, r1 = coords(minor[1].square)
        local f2, r2 = coords(minor[2].square)
        return (f1 + r1) % 2 == (f2 + r2) % 2
    end
    return false
end

function Chess.Result(state)
    if #Chess.AllLegalMoves(state) == 0 then
        if Chess.InCheck(state, state.turn) then return { reason = "mate", winner = other(state.turn) } end
        return { reason = "ahogado" }
    end
    if insufficient(state) then return { reason = "material insuficiente" } end
    if state.halfmove >= 100 then return { reason = "50 movimientos" } end
    if (state.counts[Chess.Key(state)] or 0) >= 3 then return { reason = "triple repetición" } end
end

local function san(state, move, candidate, captured)
    local piece = state.board[move.from]
    local pieceKind = kind(piece)
    if move.special == "castleK" then return "O-O" end
    if move.special == "castleQ" then return "O-O-O" end
    local notation = pieceKind == "P" and "" or pieceKind
    local fromFile, fromRank = coords(move.from)
    if pieceKind ~= "P" then
        local conflict, sameFile, sameRank = false, false, false
        for square = 1, 64 do
            if square ~= move.from and state.board[square] == piece then
                for _, alternate in ipairs(Chess.LegalMoves(state, square)) do
                    if alternate.to == move.to then
                        conflict = true
                        local file, rank = coords(square)
                        if file == fromFile then sameFile = true end
                        if rank == fromRank then sameRank = true end
                    end
                end
            end
        end
        if conflict then
            if not sameFile then notation = notation .. files:sub(fromFile, fromFile)
            elseif not sameRank then notation = notation .. tostring(fromRank)
            else notation = notation .. files:sub(fromFile, fromFile) .. tostring(fromRank) end
        end
    elseif captured then
        notation = files:sub(fromFile, fromFile)
    end
    if captured then notation = notation .. "x" end
    notation = notation .. Chess.Name(move.to)
    if move.promotion then notation = notation .. "=" .. move.promotion end
    if Chess.InCheck(candidate, candidate.turn) then
        local probe = copy(candidate)
        notation = notation .. (#Chess.AllLegalMoves(probe) == 0 and "#" or "+")
    end
    return notation
end

function Chess.Move(state, from, to, promotion)
    if not state or state.outcome then return nil, nil, "Partida terminada" end
    from = type(from) == "string" and Chess.Square(from) or from
    to = type(to) == "string" and Chess.Square(to) or to
    if type(from) ~= "number" or type(to) ~= "number" or from < 1 or from > 64 or to < 1 or to > 64 then return nil, nil, "Casilla inválida" end
    local selected
    for _, move in ipairs(Chess.LegalMoves(state, from)) do
        if move.to == to and move.promotion == promotion then selected = move break end
    end
    if not selected then return nil, nil, "Jugada ilegal" end
    local nextState, captured = applyUnchecked(state, selected)
    local notation = san(state, selected, nextState, captured)
    nextState.moves[#nextState.moves + 1] = notation
    nextState.moveDetails[#nextState.moveDetails + 1] = { from = selected.from, to = selected.to, captured = captured }
    local key = Chess.Key(nextState)
    nextState.counts[key] = (nextState.counts[key] or 0) + 1
    nextState.outcome = Chess.Result(nextState)
    return nextState, notation, nil
end
