local addonName, WC = ...
_G.WoWChess = WC

WC.addonName = addonName
WC.assetRoot = "Interface\\AddOns\\" .. addonName .. "\\assets\\"
WC.VERSION = "3"
WC.PREFIX = "WoWChess3"
WC.CHANNEL = "WoWChess"
WC.INVITE_SECONDS = 30
WC.GAME_SECONDS = 600

function WC.Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cffffc44dWoW Chess:|r " .. tostring(message))
end

function WC.Name(name)
    if type(name) ~= "string" or name == "" then return nil end
    local short, realm = name:match("^([^%-]+)%-(.+)$")
    if not short then
        short = name
        realm = GetNormalizedRealmName and GetNormalizedRealmName() or GetRealmName()
    end
    realm = (realm or ""):gsub("%s", "")
    return (short .. "-" .. realm):lower()
end

function WC.ShortName(name)
    return (name or ""):match("^[^%-]+") or name or "?"
end

function WC.PlayerName()
    local name, realm = UnitFullName("player")
    return name .. "-" .. ((realm and realm ~= "" and realm) or (GetNormalizedRealmName and GetNormalizedRealmName()) or GetRealmName())
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
        WC.me = WC.PlayerName()
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
SlashCmdList.WOWCHESS = function()
    if WC.UI and WC.UI.Toggle then WC.UI.Toggle() end
end
