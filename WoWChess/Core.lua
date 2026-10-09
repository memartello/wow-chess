local addonName, WC = ...
_G.WoWChess = WC

WC.addonName = addonName
WC.assetRoot = "Interface\\AddOns\\" .. addonName .. "\\assets\\"
WC.ADDON_VERSION = "0.3.9-beta"
WC.VERSION = "6"
WC.PREFIX = "WoWChess6"
WC.CHANNEL = "WoWChess"
WC.INVITE_SECONDS = 30
WC.GAME_SECONDS = 600

function WC.Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cffffc44dWoW Chess:|r " .. tostring(message))
end

WC.logEntries = {}
WC.logLive = false
local LOG_LIMIT = 80

function WC.Log(kind, detail)
    local entry = { at = GetTime(), text = tostring(kind) .. " " .. tostring(detail or "") }
    local entries = WC.logEntries
    entries[#entries + 1] = entry
    if #entries > LOG_LIMIT then table.remove(entries, 1) end
    if WC.logLive then WC.Print(string.format("[%.1f] %s", entry.at, entry.text)) end
end

function WC.PrintLog(all)
    local entries = WC.logEntries
    local first = math.max(1, #entries - (all and LOG_LIMIT or 40) + 1)
    WC.Print(string.format("v%s protocol=%s: %d log entries; showing %d", WC.ADDON_VERSION, WC.VERSION, #entries, #entries - first + 1))
    for i = first, #entries do
        WC.Print(string.format("[%.1f] %s", entries[i].at, entries[i].text))
    end
end

local function normalizedRealm(value)
    if type(value) ~= "string" or value == "" then return nil end
    local realm = value:gsub("%s", "")
    return realm ~= "" and realm or nil
end

local function currentRealm()
    return normalizedRealm(GetNormalizedRealmName and GetNormalizedRealmName()) or
        normalizedRealm(GetRealmName and GetRealmName())
end

function WC.Name(name)
    if type(name) ~= "string" or name == "" then return nil end
    local short, realm = name:match("^([^%-]+)%-(.+)$")
    if not short then
        short = name
        realm = currentRealm()
    end
    realm = normalizedRealm(realm)
    return (realm and (short .. "-" .. realm) or short):lower()
end

function WC.ShortName(name)
    return (name or ""):match("^[^%-]+") or name or "?"
end

function WC.PlayerName()
    local name, realm = UnitFullName("player")
    if not name or name == "" then return nil end
    realm = normalizedRealm(realm) or currentRealm()
    return realm and (name .. "-" .. realm) or name
end

function WC.RefreshPlayerName()
    WC.me = WC.PlayerName() or WC.me
    return WC.me
end

WC.events = CreateFrame("Frame")
WC.events:RegisterEvent("ADDON_LOADED")
WC.events:RegisterEvent("PLAYER_LOGIN")
WC.events:RegisterEvent("PLAYER_LOGOUT")
WC.events:RegisterEvent("CHAT_MSG_ADDON")
WC.events:RegisterEvent("CHANNEL_UI_UPDATE")
WC.events:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE")
WC.events:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local loaded = ...
        if loaded ~= addonName then return end
        WoWChessDB = type(WoWChessDB) == "table" and WoWChessDB or {}
        WC.db = WoWChessDB
        WC.db.settings = type(WC.db.settings) == "table" and WC.db.settings or {}
        WC.db.stats = WC.db.stats or { wins = 0, losses = 0, draws = 0 }
        for _, key in ipairs({ "wins", "losses", "draws" }) do
            WC.db.stats[key] = tonumber(WC.db.stats[key]) or 0
        end
    elseif event == "PLAYER_LOGIN" then
        WC.RefreshPlayerName()
        WC.Network.Initialize()
        WC.Game.Initialize()
        WC.UI.Initialize()
    elseif event == "PLAYER_LOGOUT" then
        if WC.Game.active then
            if WC.Game.active.mode ~= "bot" then
                WC.Network.SendGame("QUIT", WC.Game.active, "")
                WC.db.stats.losses = WC.db.stats.losses + 1
            else
                WC.Bot.Stop()
            end
            WC.Game.active = nil
        end
    elseif event == "CHAT_MSG_ADDON" then
        WC.Network.OnMessage(...)
    elseif event == "CHANNEL_UI_UPDATE" or event == "CHAT_MSG_CHANNEL_NOTICE" then
        WC.Network.UpdateChannel()
    end
end)

SLASH_WOWCHESS1 = "/chess"
SLASH_WOWCHESS2 = "/wowchess"
local function statusEvent(event)
    if not event then return "none" end
    local peer = event.target or event.sender
    return tostring(event.action or event.reason or "?") ..
        (peer and ("(" .. peer .. ")") or "") .. "@" .. tostring(math.floor(GetTime() - event.at)) .. "s"
end

SlashCmdList.WOWCHESS = function(command)
    command = type(command) == "string" and command:match("^%s*(.-)%s*$"):lower() or ""
    if command == "log" or command == "log all" then WC.PrintLog(command == "log all"); return end
    if command == "log clear" then WC.logEntries = {}; WC.Print("Log cleared."); return end
    if command == "debug" then
        WC.logLive = not WC.logLive
        WC.Print("Live log " .. (WC.logLive and "on" or "off") .. ".")
        return
    end
    if command == "status" then
        local game, network = WC.Game, WC.Network
        local state = "idle"
        if game.active then state = game.active.connected and "playing" or "connecting"
        elseif game.incoming then state = game.incoming.accepted and "accepted" or "invited"
        elseif game.outgoing then state = game.outgoing.startMessage and "starting" or "challenging" end
        WC.Print("protocol=" .. WC.VERSION .. " state=" .. state)
        WC.Print("sent=" .. statusEvent(network.lastSend) ..
            (network.lastSend and (network.lastSend.ok and "(ok)" or "(failed)") or "") ..
            " received=" .. statusEvent(network.lastWhisper) ..
            " invite=" .. statusEvent(game.lastInvite))
        return
    end
    if WC.UI and WC.UI.Toggle then WC.UI.Toggle() end
end
