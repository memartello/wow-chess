local _, WC = ...
local Network = { players = {}, channelId = nil, lastJoin = -100, lastPresence = 0 }
WC.Network = Network

local function trace(kind, detail)
    if WC.Log then WC.Log(kind, detail) end
end

local function fields(message)
    local result = {}
    for part in (message .. "|"):gmatch("(.-)|") do result[#result + 1] = part end
    return result
end

local function send(message, chatType, target)
    if not C_ChatInfo or not C_ChatInfo.SendAddonMessage then return false, "API unavailable" end
    local ok, first, second = pcall(C_ChatInfo.SendAddonMessage, WC.PREFIX, message, chatType, target)
    if not ok then return false, "error: " .. tostring(first) end
    local result = first
    if second ~= nil then result = second end
    return result == 0 or result == true or result == nil, tostring(result)
end

function Network.SendWhisper(target, message)
    if not target then return false end
    -- Forever uses a single visible realm for whispers. Its server rejects
    -- the realm suffix that other WoW clients require for a whisper target.
    local address = WC.ShortName(target)
    local ok, result = send(message, "WHISPER", address)
    Network.lastSend = { action = message:match("^[^|]+|([^|]+)") or "?", target = address, ok = ok, at = GetTime() }
    local action, id = message:match("^[^|]+|([^|]+)|([^|]+)")
    trace("SEND", string.format("%s#%s to=%s api=%s %s", action or "?", id and id:sub(-6) or "-", address, result, ok and "accepted" or "failed"))
    return ok
end

function Network.SendGame(action, game, payload)
    if not game or not game.opponent then return false end
    return Network.SendWhisper(game.opponent, WC.VERSION .. "|" .. action .. "|" .. game.id .. "|" .. (payload or ""))
end

function Network.SendChannel(message)
    Network.UpdateChannel()
    if not Network.channelId then return false end
    return send(message, "CHANNEL", tostring(Network.channelId))
end

function Network.UpdateChannel()
    if not GetChannelName then return end
    local id = GetChannelName(WC.CHANNEL)
    Network.channelId = type(id) == "number" and id > 0 and id or nil
end

function Network.Join()
    if not JoinChannelByName or not GetChannelName then return end
    Network.UpdateChannel()
    if Network.channelId then return end
    local now = GetTime()
    if now - Network.lastJoin < 15 then return end
    Network.lastJoin = now
    JoinChannelByName(WC.CHANNEL)
    C_Timer.After(2, function() Network.UpdateChannel(); Network.AskWho() end)
end

function Network.AskWho()
    Network.SendChannel(WC.VERSION .. "|WHO")
end

function Network.BroadcastPresence()
    local name, realm = UnitFullName("player")
    if not name then return end
    WC.RefreshPlayerName()
    local level = math.max(1, math.min(999, UnitLevel("player") or 1))
    local race = (select(2, UnitRace("player")) or "Unknown"):gsub("[^%w]", "")
    local status = WC.Game and WC.Game.active and "busy" or "online"
    local faction = UnitFactionGroup("player") or "Neutral"
    Network.SendChannel(table.concat({ WC.VERSION, "HELLO", tostring(level), race, status, faction, WC.me }, "|"))
    Network.lastPresence = GetTime()
end

function Network.Prune()
    local now, changed = GetTime(), false
    for name, info in pairs(Network.players) do
        if now - info.lastSeen > 75 then Network.players[name] = nil; changed = true end
    end
    if changed and WC.UI and WC.UI.RefreshPlayers then WC.UI.RefreshPlayers() end
end

function Network.Initialize()
    local registered = C_ChatInfo.RegisterAddonMessagePrefix(WC.PREFIX)
    trace("INIT", "prefix=" .. WC.PREFIX .. " registration=" .. tostring(registered))
    Network.Join()
    C_Timer.After(3, function() Network.AskWho(); Network.BroadcastPresence() end)
    C_Timer.NewTicker(5, function()
        Network.Join()
        Network.Prune()
        if GetTime() - Network.lastPresence >= 25 then Network.BroadcastPresence() end
    end)
end

function Network.OnMessage(prefix, message, distribution, sender)
    if prefix ~= WC.PREFIX then
        if type(prefix) == "string" and prefix:match("^WoWChess%d+$") then trace("DROP", "other prefix=" .. prefix) end
        return
    end
    if type(message) ~= "string" or #message > 255 or type(sender) ~= "string" or sender == "" then
        trace("DROP", "invalid addon event")
        return
    end
    if distribution == "CHANNEL" and WC.Name(sender) == WC.Name(WC.me) then return end
    local parts = fields(message)
    if parts[1] ~= WC.VERSION then trace("DROP", "wire version=" .. tostring(parts[1])); return end
    local action = parts[2]
    if distribution == "CHANNEL" then
        if action == "WHO" then
            C_Timer.After(math.random() * 2, function() Network.BroadcastPresence() end)
        elseif action == "HELLO" then
            local level = tonumber(parts[3])
            local race, status, faction, address = parts[4], parts[5], parts[6], parts[7]
            if level and level >= 1 and level <= 999 and race and race:match("^%w+$") and (status == "online" or status == "busy") and faction == UnitFactionGroup("player") then
                if type(address) ~= "string" or #address > 80 or not address:match("^[^|%-]+%-.+$") or
                    WC.ShortName(address):lower() ~= WC.ShortName(sender):lower() then
                    address = sender
                end
                Network.players[WC.Name(sender)] = { name = address, level = level, race = race, status = status, lastSeen = GetTime() }
                trace("PEER", "seen=" .. sender .. " address=" .. address .. " status=" .. status)
                if WC.UI and WC.UI.RefreshPlayers then WC.UI.RefreshPlayers() end
            end
        end
    elseif distribution == "WHISPER" then
        Network.lastWhisper = { action = action or "?", sender = sender, at = GetTime() }
        trace("RECV", string.format("%s#%s from=%s", action or "?", parts[3] and parts[3]:sub(-6) or "-", sender))
        if WC.Game and WC.Game.OnMessage then WC.Game.OnMessage(action, parts, sender) end
    elseif action == "INV" or action == "ACC" or action == "START" then
        trace("DROP", tostring(action) .. " on " .. tostring(distribution))
    end
end
