local _, WC = ...
local Game = { active = nil, incoming = nil, outgoing = nil, lastResult = nil }
WC.Game = Game

local function trace(kind, detail)
    if WC.Log then WC.Log(kind, detail) end
end
local function shortId(id)
    return type(id) == "string" and id:sub(-6) or "-"
end
local function opposite(color) return color == "w" and "b" or "w" end
local function same(a, b)
    if not WC.Name(a) or not WC.Name(b) then return false end
    if a:find("-", 1, true) and b:find("-", 1, true) then
        return WC.Name(a) == WC.Name(b)
    end
    return WC.ShortName(a):lower() == WC.ShortName(b):lower()
end
local function sameShort(a, b)
    return WC.Name(a) and WC.Name(b) and WC.ShortName(a):lower() == WC.ShortName(b):lower()
end
local function declaredPeer(value, sender)
    if type(value) ~= "string" or value == "" or #value > 80 or value:find("|", 1, true) then return nil end
    -- The addon event's sender is supplied by the server. A stale or incorrect
    -- locally reported name must not prevent that character from inviting us.
    if not sameShort(value, sender) then return sender, true end
    if not value:match("^[^%-]+%-.+$") and sender:match("^[^%-]+%-.+$") then return sender end
    return value
end
local function markInvite(reason, id, sender)
    Game.lastInvite = { reason = reason, at = GetTime() }
    trace("INV", reason .. "#" .. shortId(id) .. " from=" .. tostring(sender))
end
local function newId() return tostring(time()) .. tostring(math.random(100000, 999999)) end
local function validId(value) return type(value) == "string" and #value >= 6 and #value <= 32 and value:match("^%d+$") end

function Game.Remaining(game, color)
    local value = game.remaining[color]
    if game.state.turn == color and (game.mode == "bot" or game.connected) then
        value = value - (GetTime() - game.turnStarted)
    end
    return math.max(0, value)
end

local function charge(game)
    local color = game.state.turn
    game.remaining[color] = Game.Remaining(game, color)
    game.turnStarted = GetTime()
end

function Game.Finish(reason, winner)
    local game = Game.active
    if not game then return end
    Game.active = nil
    if WC.UI then WC.UI.ClearMoveNotification() end
    if game.mode == "bot" then WC.Bot.Stop() end
    Game.lastResult = { reason = reason, winner = winner, won = winner == game.color, opponent = game.opponent, state = game.state }
    if game.mode ~= "bot" then
        if winner == game.color then
            WC.db.stats.wins = WC.db.stats.wins + 1
        elseif winner == nil then
            WC.db.stats.draws = WC.db.stats.draws + 1
        else
            WC.db.stats.losses = WC.db.stats.losses + 1
        end
    end
    WC.Network.BroadcastPresence()
    if WC.UI then WC.UI.ShowResult(Game.lastResult) end
end

local function abortConnection()
    local game = Game.active
    trace("STATE", "connection failed#" .. shortId(game and game.id))
    Game.active = nil
    if game and game.mode ~= "bot" then WC.Network.SendGame("CANCEL", game, "") end
    WC.UI.ClearMoveNotification()
    WC.Network.BroadcastPresence()
    WC.UI.ShowMain()
    WC.UI.SetStatus("No se pudo conectar con el rival.")
end

local function startBotTurn(game)
    if not game or game.mode ~= "bot" or game.state.turn == game.color then return end
    WC.UI.SetStatus("El bot está pensando...")
    local id, seq = game.id, game.seq
    WC.Bot.Start(game.state, function(move)
        if Game.active and Game.active.id == id and Game.active.seq == seq then Game.BotMove(move) end
    end)
end

function Game.StartBot()
    if Game.active or Game.incoming or Game.outgoing then
        return false, "Ya tenés una partida o invitación pendiente."
    end
    local color = math.random(2) == 1 and "w" or "b"
    if WC.RefreshPlayerName then WC.RefreshPlayerName() end
    local opponent = "Bot intermedio"
    Game.lastResult = nil
    Game.active = {
        id = newId(), mode = "bot", opponent = opponent,
        white = color == "w" and WC.me or opponent, color = color,
        state = WC.Chess.New(), remaining = { w = WC.GAME_SECONDS, b = WC.GAME_SECONDS },
        turnStarted = GetTime(), seq = 0,
    }
    WC.Network.BroadcastPresence()
    WC.UI.SetStatus("")
    WC.UI.ShowGame()
    startBotTurn(Game.active)
    return true
end

function Game.BotMove(move)
    local game = Game.active
    if not game or game.mode ~= "bot" or game.state.turn == game.color or not move then return end
    charge(game)
    if game.remaining[game.state.turn] <= 0 then
        Game.Finish("tiempo", game.color)
        return
    end
    local nextState = WC.Chess.Move(game.state, move.from, move.to, move.promotion)
    if not nextState then
        WC.Print(WC.L("El bot intentó una jugada ilegal."))
        Game.Finish("error del bot", game.color)
        return
    end
    game.state = nextState
    game.seq = game.seq + 1
    game.turnStarted = GetTime()
    WC.UI.SetStatus("")
    WC.UI.RefreshGame()
    WC.UI.NotifyOpponentMove()
    if nextState.outcome then Game.Finish(nextState.outcome.reason, nextState.outcome.winner) end
end

local function start(opponent, peerSender, id, whiteRole, localRole, inviteId, startMessage)
    if WC.RefreshPlayerName then WC.RefreshPlayerName() end
    local color = whiteRole == localRole and "w" or "b"
    Game.incoming, Game.outgoing, Game.lastResult = nil, nil, nil
    Game.active = {
        id = id, opponent = opponent, peerSender = peerSender,
        inviteId = inviteId, startMessage = startMessage,
        white = color == "w" and WC.me or opponent, color = color,
        state = WC.Chess.New(), remaining = { w = WC.GAME_SECONDS, b = WC.GAME_SECONDS },
        turnStarted = GetTime(), lastPeer = GetTime(), lastPing = GetTime(),
        lastStart = GetTime(), connectExpires = GetTime() + WC.INVITE_SECONDS,
        connected = false, seq = 0,
    }
    trace("STATE", "board#" .. shortId(id) .. " peer=" .. tostring(opponent) .. " waiting for PING")
    WC.Network.BroadcastPresence()
    WC.UI.ShowGame()
    WC.UI.SetStatus("Conectando con el rival...")
    WC.Network.SendGame("PING", Game.active, "0")
end

function Game.Challenge(target)
    target = type(target) == "string" and target:match("^%s*(.-)%s*$") or ""
    if WC.RefreshPlayerName then WC.RefreshPlayerName() end
    if target == "" then return false, "Escribí el nombre del personaje." end
    if same(target, WC.me) then return false, "No podés desafiarte a vos mismo." end
    if Game.active or Game.incoming or Game.outgoing then return false, "Ya tenés una partida o invitación pendiente." end
    local invitation = { id = newId(), opponent = target, expires = GetTime() + WC.INVITE_SECONDS, retryAt = GetTime() + 2 }
    trace("STATE", "challenge#" .. shortId(invitation.id) .. " target=" .. target)
    invitation.message = WC.VERSION .. "|INV|" .. invitation.id .. "|" .. (UnitFactionGroup("player") or "Neutral") .. "|" .. WC.me
    if not WC.Network.SendWhisper(target, invitation.message) then
        return false, "No se pudo enviar el reto. Revisá el nombre y la conexión."
    end
    Game.outgoing = invitation
    WC.UI.SetStatus(string.format(WC.L("Reto enviado a %s. Esperando respuesta..."), WC.ShortName(target)))
    return true
end

function Game.AcceptInvite()
    local invite = Game.incoming
    if not invite or invite.expires < GetTime() then return end
    if WC.RefreshPlayerName then WC.RefreshPlayerName() end
    invite.accepted = true
    trace("STATE", "accepted#" .. shortId(invite.id) .. " peer=" .. invite.opponent)
    invite.expires = GetTime() + WC.INVITE_SECONDS
    invite.retryAt = GetTime() + 2
    local sent = WC.Network.SendWhisper(invite.opponent, WC.VERSION .. "|ACC|" .. invite.id .. "|" .. WC.me)
    if Game.active then return end
    WC.UI.HideInvite()
    WC.UI.SetStatus(sent and "Reto aceptado. Preparando partida..." or "Reintentando conexión con el rival...")
end

function Game.DeclineInvite()
    local invite = Game.incoming
    if not invite then return end
    WC.Network.SendWhisper(invite.opponent, WC.VERSION .. "|DEC|" .. invite.id .. "|declined")
    Game.incoming = nil
    WC.UI.HideInvite()
end

function Game.PlayMove(from, to, promotion)
    local game = Game.active
    if not game or game.state.turn ~= game.color then return false, "No es tu turno." end
    if game.mode ~= "bot" and not game.connected then return false, "Esperando conexión con el rival." end
    charge(game)
    if game.remaining[game.color] <= 0 then
        if game.mode ~= "bot" then WC.Network.SendGame("TIMEOUT", game, "") end
        Game.Finish("tiempo", opposite(game.color))
        return false, "Se agotó tu tiempo."
    end
    local nextState, notation, err = WC.Chess.Move(game.state, from, to, promotion)
    if not nextState then return false, err end
    if game.mode ~= "bot" then
        local payload = table.concat({ tostring(game.seq + 1), WC.Chess.Name(from), WC.Chess.Name(to), promotion or "-", tostring(math.floor(game.remaining[game.color] * 100 + .5)) }, "|")
        if not WC.Network.SendGame("MOVE", game, payload) then return false, "No se pudo enviar la jugada." end
    end
    game.state = nextState
    game.seq = game.seq + 1
    game.turnStarted = GetTime()
    WC.UI.RefreshGame()
    if nextState.outcome then Game.Finish(nextState.outcome.reason, nextState.outcome.winner) end
    if Game.active and game.mode == "bot" then startBotTurn(game) end
    return true, notation
end

function Game.Resign()
    local game = Game.active
    if not game then return end
    if game.mode ~= "bot" and not game.connected then abortConnection(); return end
    if game.mode ~= "bot" then WC.Network.SendGame("RESIGN", game, "") end
    Game.Finish("rendición", opposite(game.color))
end

function Game.OfferDraw()
    local game = Game.active
    if not game or game.mode == "bot" or game.drawOffered then return end
    game.drawOffered = true
    WC.Network.SendGame("DRAW", game, "")
    WC.UI.SetStatus("Oferta de tablas enviada.")
end

function Game.AcceptDraw()
    local game = Game.active
    if not game or not game.drawReceived then return end
    WC.Network.SendGame("DRAWACC", game, "")
    Game.Finish("tablas acordadas", nil)
end

function Game.DeclineDraw()
    local game = Game.active
    if not game or not game.drawReceived then return end
    game.drawReceived = nil
    WC.Network.SendGame("DRAWDEC", game, "")
    WC.UI.HideDrawOffer()
end

function Game.Tick()
    local now = GetTime()
    if Game.outgoing then
        local outgoing = Game.outgoing
        if now >= outgoing.expires then
            trace("TIMEOUT", (outgoing.startMessage and "start#" or "challenge#") .. shortId(outgoing.id))
            Game.outgoing = nil
            WC.UI.SetStatus(outgoing.startMessage and "No se pudo conectar con el rival." or "El reto venció sin respuesta.")
        elseif now >= outgoing.retryAt then
            outgoing.retryAt = now + 2
            if not outgoing.startMessage then
                WC.Network.SendWhisper(outgoing.opponent, outgoing.message)
            elseif WC.Network.SendWhisper(outgoing.opponent, outgoing.startMessage) then
                start(outgoing.opponent, outgoing.peerSender, outgoing.gameId, outgoing.whiteRole, "c", outgoing.id, outgoing.startMessage)
            end
        end
    end
    if Game.incoming then
        local incoming = Game.incoming
        if now >= incoming.expires then
            trace("TIMEOUT", (incoming.accepted and "accepted#" or "invite#") .. shortId(incoming.id))
            Game.incoming = nil
            WC.UI.HideInvite()
            WC.UI.SetStatus(incoming.accepted and "No se pudo conectar con el rival." or "La invitación venció.")
        elseif incoming.accepted and now >= incoming.retryAt then
            incoming.retryAt = now + 2
            WC.Network.SendWhisper(incoming.opponent, WC.VERSION .. "|ACC|" .. incoming.id .. "|" .. WC.me)
        end
    end
    local game = Game.active
    if not game then return end
    if game.mode ~= "bot" then
        if not game.connected then
            if now >= game.connectExpires then abortConnection(); return end
            if game.startMessage and now - game.lastStart >= 2 then
                WC.Network.SendWhisper(game.opponent, game.startMessage)
                game.lastStart = now
            end
            if now - game.lastPing >= 2 then
                WC.Network.SendGame("PING", game, tostring(game.seq))
                game.lastPing = now
            end
            WC.UI.RefreshClocks()
            return
        end
        if now - game.lastPeer >= 20 then
            Game.Finish("desconexión", game.color)
            return
        end
        if now - game.lastPing >= 5 then
            WC.Network.SendGame("PING", game, tostring(game.seq))
            game.lastPing = now
        end
    end
    if Game.Remaining(game, game.state.turn) <= 0 then
        local loser = game.state.turn
        if game.mode ~= "bot" then WC.Network.SendGame("TIMEOUT", game, loser) end
        Game.Finish("tiempo", opposite(loser))
        return
    end
    WC.UI.RefreshClocks()
end

function Game.Initialize()
    C_Timer.NewTicker(.25, Game.Tick)
end

function Game.OnMessage(action, parts, sender)
    local id = parts[3]
    if not validId(id) then trace("DROP", tostring(action) .. " invalid id from=" .. tostring(sender)); return end
    local active = Game.active
    if active and active.mode ~= "bot" and active.inviteId == id and same(active.peerSender, sender) then
        if action == "ACC" and active.startMessage and not active.connected and
            WC.Name(declaredPeer(parts[4], sender)) == WC.Name(active.opponent) then
            trace("STATE", "duplicate ACC#" .. shortId(id) .. "; resending START")
            WC.Network.SendWhisper(active.opponent, active.startMessage)
            return
        elseif action == "START" and parts[4] == active.id then
            WC.Network.SendGame("PING", active, tostring(active.seq))
            return
        end
    end
    if action == "INV" then
        local peer, mismatchedClaim = declaredPeer(parts[5], sender)
        if not peer then markInvite("invalid-name", id, sender); return end
        if mismatchedClaim then trace("INV", "name-mismatch#" .. shortId(id) .. " claimed=" .. tostring(parts[5]) .. " sender=" .. sender .. "; using sender") end
        if parts[4] ~= UnitFactionGroup("player") then
            markInvite("different-faction", id, sender)
            WC.Network.SendWhisper(peer, WC.VERSION .. "|DEC|" .. id .. "|faction")
            return
        end
        if Game.active or Game.outgoing or (Game.incoming and not (Game.incoming.id == id and
            WC.Name(Game.incoming.opponent) == WC.Name(peer) and same(Game.incoming.peerSender, sender))) then
            markInvite("busy", id, sender)
            WC.Network.SendWhisper(peer, WC.VERSION .. "|DEC|" .. id .. "|busy")
            return
        end
        if Game.incoming and Game.incoming.id == id then
            markInvite(Game.incoming.accepted and "accepted-retry" or "popup", id, sender)
            if Game.incoming.accepted then WC.Network.SendWhisper(peer, WC.VERSION .. "|ACC|" .. id .. "|" .. WC.me) end
            return
        end
        markInvite("popup", id, sender)
        Game.incoming = { id = id, opponent = peer, peerSender = sender, expires = GetTime() + WC.INVITE_SECONDS }
        WC.UI.ShowInvite(sender)
        trace("UI", "accept popup created#" .. shortId(id))
        return
    end
    if action == "DEC" and Game.outgoing and Game.outgoing.id == id and same(Game.outgoing.opponent, sender) then
        trace("STATE", "declined#" .. shortId(id) .. " reason=" .. tostring(parts[4]))
        Game.outgoing = nil
        WC.UI.SetStatus(parts[4] == "busy" and "Ese personaje ya está ocupado." or "El reto fue rechazado.")
        return
    end
    local peer, mismatchedClaim
    if action == "ACC" then peer, mismatchedClaim = declaredPeer(parts[4], sender) end
    if mismatchedClaim then trace("ACC", "name-mismatch#" .. shortId(id) .. " claimed=" .. tostring(parts[4]) .. " sender=" .. sender .. "; using sender") end
    if peer and Game.outgoing and Game.outgoing.id == id and
        (same(Game.outgoing.opponent, peer) or same(Game.outgoing.opponent, sender)) then
        trace("STATE", "ACC accepted#" .. shortId(id) .. " from=" .. tostring(sender))
        local outgoing = Game.outgoing
        outgoing.opponent = peer
        outgoing.peerSender = sender
        if not outgoing.startMessage then
            outgoing.whiteRole = math.random(2) == 1 and "c" or "i"
            outgoing.gameId = newId()
            outgoing.startMessage = WC.VERSION .. "|START|" .. id .. "|" .. outgoing.gameId .. "|" .. outgoing.whiteRole
            outgoing.expires = GetTime() + WC.INVITE_SECONDS
        end
        outgoing.retryAt = GetTime() + 2
        if WC.Network.SendWhisper(peer, outgoing.startMessage) then
            start(peer, sender, outgoing.gameId, outgoing.whiteRole, "c", id, outgoing.startMessage)
        else
            WC.UI.SetStatus("Reintentando conexión con el rival...")
        end
        return
    end
    if action == "START" and Game.incoming and Game.incoming.accepted and Game.incoming.id == id and same(Game.incoming.peerSender, sender) then
        local gameId, whiteRole = parts[4], parts[5]
        if validId(gameId) and (whiteRole == "c" or whiteRole == "i") then
            trace("STATE", "START accepted#" .. shortId(id) .. " game#" .. shortId(gameId))
            start(Game.incoming.opponent, Game.incoming.peerSender, gameId, whiteRole, "i", id)
        else
            trace("DROP", "START invalid game id or white#" .. shortId(id))
        end
        return
    end
    local game = Game.active
    if not game or game.id ~= id or not same(game.peerSender, sender) then
        trace("DROP", tostring(action) .. "#" .. shortId(id) .. " unexpected state/id/sender")
        return
    end
    game.lastPeer = GetTime()
    if action == "CANCEL" and game.seq == 0 then abortConnection(); return end
    if action == "PING" and not game.connected then
        trace("STATE", "connected#" .. shortId(id) .. " from=" .. tostring(sender))
        game.connected = true
        game.turnStarted = GetTime()
        WC.UI.SetStatus("")
        WC.Network.SendGame("PING", game, tostring(game.seq))
    end
    if action == "PING" then return end
    if action == "MOVE" then
        local seq, from, to, promotion, centiseconds = tonumber(parts[4]), parts[5], parts[6], parts[7], tonumber(parts[8])
        if not seq or seq <= game.seq then return end
        if seq ~= game.seq + 1 or game.state.turn == game.color or not centiseconds or centiseconds < 0 or centiseconds > WC.GAME_SECONDS * 100 then
            WC.UI.SetStatus("Jugada fuera de secuencia; la partida necesita revisión.")
            return
        end
        if promotion == "-" then promotion = nil end
        local nextState = WC.Chess.Move(game.state, from, to, promotion)
        if not nextState then WC.UI.SetStatus("El rival envió una jugada ilegal."); return end
        local remoteColor = opposite(game.color)
        local reported = centiseconds / 100
        if reported > game.remaining[remoteColor] + 1 then WC.UI.SetStatus("Reloj del rival inconsistente."); return end
        if not game.connected then
            game.connected = true
            game.turnStarted = GetTime()
            WC.UI.SetStatus("")
        end
        game.remaining[remoteColor] = reported
        game.state = nextState
        game.seq = seq
        game.turnStarted = GetTime()
        WC.UI.RefreshGame()
        WC.UI.NotifyOpponentMove()
        if nextState.outcome then Game.Finish(nextState.outcome.reason, nextState.outcome.winner) end
    elseif action == "RESIGN" or action == "QUIT" then
        Game.Finish(action == "QUIT" and "desconexión" or "rendición", game.color)
    elseif action == "TIMEOUT" then
        if parts[4] == opposite(game.color) or Game.Remaining(game, opposite(game.color)) <= 1 then Game.Finish("tiempo", game.color) end
    elseif action == "DRAW" then
        game.drawReceived = true
        WC.UI.ShowDrawOffer()
    elseif action == "DRAWACC" and game.drawOffered then
        Game.Finish("tablas acordadas", nil)
    elseif action == "DRAWDEC" then
        game.drawOffered = nil
        WC.UI.SetStatus("El rival rechazó las tablas.")
    end
end
