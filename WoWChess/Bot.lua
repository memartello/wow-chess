local _, WC = ...
local Chess = WC.Chess
local Bot = { job = nil }
WC.Bot = Bot

local VALUE = { P = 100, N = 320, B = 335, R = 500, Q = 900, K = 0 }
local INF, MATE = 1000000, 100000

local function pieceValue(piece)
    return piece and VALUE[piece:sub(2, 2)] or 0
end

local function evaluate(state)
    local score = 0
    local totalMaterial = 0
    for square = 1, 64 do
        local piece = state.board[square]
        if piece then totalMaterial = totalMaterial + pieceValue(piece) end
    end
    local endgame = totalMaterial < 2600
    for square = 1, 64 do
        local piece = state.board[square]
        if piece then
            local color, kind = piece:sub(1, 1), piece:sub(2, 2)
            local file = ((square - 1) % 8) + 1
            local rank = math.floor((square - 1) / 8) + 1
            local relativeRank = color == "w" and rank or 9 - rank
            local center = (3.5 - math.abs(file - 4.5)) + (3.5 - math.abs(rank - 4.5))
            local positional = 0
            if kind == "P" then positional = (relativeRank - 2) * 8 + center * 3
            elseif kind == "N" then positional = center * 11
            elseif kind == "B" then positional = center * 6
            elseif kind == "R" then positional = (relativeRank == 7 and 18 or 0) + center * 2
            elseif kind == "Q" then positional = center * 2
            elseif kind == "K" then positional = endgame and center * 9 or -center * 8 end
            local value = VALUE[kind] + positional
            score = score + (color == state.turn and value or -value)
        end
    end
    return score
end

local function movePriority(state, move)
    local attacker = state.board[move.from]
    local victim = state.board[move.to]
    if move.special == "ep" then victim = "wP" end
    local score = victim and (10000 + pieceValue(victim) * 10 - pieceValue(attacker)) or 0
    if move.promotion then score = score + pieceValue("w" .. move.promotion) * 10 end
    if move.special == "castleK" or move.special == "castleQ" then score = score + 25 end
    return score
end

local function ordered(state, moves)
    table.sort(moves, function(a, b) return movePriority(state, a) > movePriority(state, b) end)
    return moves
end

local function checkpoint(context)
    context.nodes = context.nodes + 1
    if context.nodes % 8 == 0 then coroutine.yield() end
    if GetTime() >= context.deadline then return false end
    return true
end

local function quiescence(state, alpha, beta, ply, remaining, context)
    if not checkpoint(context) then return nil end
    if state.halfmove >= 100 then return 0 end
    local inCheck = Chess.InCheck(state, state.turn)
    local stand = evaluate(state)
    if not inCheck then
        if stand >= beta then return beta end
        if stand > alpha then alpha = stand end
        if remaining <= 0 then return alpha end
    elseif remaining < -1 then
        return stand
    end
    local moves = Chess.AllLegalMoves(state)
    if #moves == 0 then return inCheck and (-MATE + ply) or 0 end
    ordered(state, moves)
    for _, move in ipairs(moves) do
        if inCheck or state.board[move.to] or move.special == "ep" or move.promotion then
            local score = quiescence(Chess.Simulate(state, move), -beta, -alpha, ply + 1, remaining - 1, context)
            if score == nil then return nil end
            score = -score
            if score >= beta then return beta end
            if score > alpha then alpha = score end
        end
    end
    return alpha
end

local function search(state, depth, alpha, beta, ply, context)
    if not checkpoint(context) then return nil end
    if state.halfmove >= 100 then return 0 end
    if depth == 0 then return quiescence(state, alpha, beta, ply, 2, context) end
    local moves = Chess.AllLegalMoves(state)
    if #moves == 0 then return Chess.InCheck(state, state.turn) and (-MATE + ply) or 0 end
    ordered(state, moves)
    for _, move in ipairs(moves) do
        local score = search(Chess.Simulate(state, move), depth - 1, -beta, -alpha, ply + 1, context)
        if score == nil then return nil end
        score = -score
        if score >= beta then return beta end
        if score > alpha then alpha = score end
    end
    return alpha
end

-- Run inside a coroutine. Only fully completed search depths replace the move.
function Bot.Choose(state, maxDepth, seconds)
    local moves = ordered(state, Chess.AllLegalMoves(state))
    if #moves == 0 then return nil end
    if #moves == 1 then return moves[1] end
    local context = { nodes = 0, deadline = GetTime() + (seconds or 3) }
    local best = moves[1]
    for depth = 1, maxDepth or 3 do
        local scoreBest, moveBest = -INF, nil
        for _, move in ipairs(moves) do
            local score = search(Chess.Simulate(state, move), depth - 1, -INF, INF, 1, context)
            if score == nil then return best end
            score = -score
            if score > scoreBest then scoreBest, moveBest = score, move end
        end
        best = moveBest or best
        for i, move in ipairs(moves) do
            if move == best then table.remove(moves, i); table.insert(moves, 1, move); break end
        end
        if scoreBest >= MATE - 100 or GetTime() >= context.deadline then break end
    end
    return best
end

function Bot.Stop()
    Bot.job = nil
    if Bot.frame then Bot.frame:SetScript("OnUpdate", nil) end
end

function Bot.Start(state, callback, difficulty)
    Bot.Stop()
    local fallback = Chess.AllLegalMoves(state)[1]
    if not fallback then callback(nil); return end
    if not Bot.frame then Bot.frame = CreateFrame("Frame") end
    local settings = {
        easy = { depth = 2, seconds = 1 },
        intermediate = { depth = 4, seconds = 4 },
        hard = { depth = 5, seconds = 6 },
    }
    local level = settings[difficulty] or settings.intermediate
    local job = { co = coroutine.create(function() return Bot.Choose(state, level.depth, level.seconds) end), callback = callback }
    Bot.job = job
    Bot.frame:SetScript("OnUpdate", function()
        if Bot.job ~= job then return end
        local clock = debugprofilestop or function() return GetTime() * 1000 end
        local sliceStart = clock()
        for _ = 1, 12 do
            local ok, move = coroutine.resume(job.co)
            if not ok then
                WC.Print(WC.L("Error del bot: ") .. tostring(move))
                Bot.Stop()
                job.callback(fallback)
                return
            end
            if coroutine.status(job.co) == "dead" then
                Bot.Stop()
                job.callback(move or fallback)
                return
            end
            if clock() - sliceStart >= 4 then return end
        end
    end)
end
