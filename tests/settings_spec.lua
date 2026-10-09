local function widget()
    local methods = {}
    function methods:CreateTexture() return widget() end
    function methods:CreateFontString() return widget() end
    function methods:SetSize(width, height) self.width, self.height = width, height end
    function methods:GetWidth() return self.width end
    function methods:GetHeight() return self.height end
    function methods:GetFrameLevel() return rawget(self, "frameLevel") or 1 end
    function methods:SetFrameLevel(value) self.frameLevel = value end
    function methods:SetText(value) self.text = value end
    function methods:GetText() return self.text end
    function methods:SetTexture(value) self.texture = value end
    function methods:SetScript(event, callback) self.scripts[event] = callback end
    function methods:Show() self.shown = true end
    function methods:Hide() self.shown = false end
    function methods:SetShown(value) self.shown = value end
    function methods:IsShown() return self.shown ~= false end
    return setmetatable({ scripts = {}, shown = true }, {
        __index = function(_, key) return methods[key] or function() end end,
    })
end

UIParent = widget()
UIParent:SetSize(1920, 1080)
Minimap = widget()
GameTooltip = widget()
GetLocale = function() return "enUS" end
UnitLevel = function() return 60 end
SetPortraitTexture = function() end
CreateFrame = function() return widget() end

local WC = {
    assetRoot = "Interface\\AddOns\\WoWChess\\assets\\",
    ADDON_VERSION = "test-build",
    me = "Alice-Realm",
    db = { settings = {}, stats = { wins = 0, losses = 0, draws = 0 } },
    Network = { players = {}, AskWho = function() end },
    Game = { active = nil },
    ShortName = function(name) return (name or ""):match("^[^%-]+") end,
}
assert(loadfile("WoWChess/Locale.lua"))("WoWChess", WC)
assert(loadfile("WoWChess/Chess.lua"))("WoWChess", WC)
assert(loadfile("WoWChess/Theme.lua"))("WoWChess", WC)
assert(loadfile("WoWChess/UI.lua"))("WoWChess", WC)

assert(WC.Language() == "en", "English client locale")
WC.UI.Initialize()
assert(WC.UI.versionLabel.text == "vtest-build", "home screen displays the addon version")
WC.UI.SetMainSection("options")
assert(WC.UI.optionsContent:IsShown() and not WC.UI.homeContent:IsShown(), "options page")
WC.UI.boardButtons.classic.scripts.OnClick()
assert(WC.db.settings.board == "classic" and not WC.UI.boardImage:IsShown(), "classic board applies")
assert(WC.UI.cells[1].frame.tile:IsShown() and WC.UI.classicPreview:IsShown(), "classic preview")
WC.UI.languageButtons.es.scripts.OnClick()
assert(WC.db.settings.language == "es" and WC.L("Opciones") == "Opciones", "Spanish selection")
WC.UI.languageButtons.en.scripts.OnClick()
assert(WC.L("Opciones") == "Options", "English selection")
WC.UI.boardButtons.durotar.scripts.OnClick()
assert(WC.db.settings.board == "durotar" and WC.UI.boardImage:IsShown(), "Durotar board applies")
assert(not WC.UI.cells[1].frame.tile:IsShown() and WC.UI.boardPreview:IsShown(), "Durotar preview")
assert(not WC.Theme.SetBackground("missing") and WC.Theme.Background().id == "durotar", "invalid background")

WC.Game.Remaining = function() return 600 end
WC.Game.active = {
    mode = "bot", opponent = "Bot intermedio", color = "w", white = "Alice-Realm",
    state = WC.Chess.New(), seq = 0,
}
WC.UI.ShowGame()
assert(WC.UI.opponentName.text == "Intermediate bot · Black", "English match labels")
WC.UI.boardButtons.classic.scripts.OnClick()
assert(WC.UI.cells[1].frame.tile:IsShown() and WC.UI.boardFrame:IsShown(), "board changes during a game")
WC.UI.languageButtons.es.scripts.OnClick()
assert(WC.UI.opponentName.text == "Bot intermedio · Negras", "language changes during a game")
assert(WC.UI.boardTurn.text == "Empieza: Alice", "board turn label changes immediately")
assert(not WC.UI.moveBadge:IsShown(), "badge starts hidden")
WC.UI.ShowMain()
WC.UI.NotifyOpponentMove()
assert(WC.UI.moveBadge:IsShown() and WC.UI.moveNotice, "opponent move appears on minimap icon")
WC.UI.launcher.scripts.OnClick()
assert(WC.UI.gameFrame:IsShown() and not WC.UI.moveBadge:IsShown(), "minimap click opens game and acknowledges move")
WC.UI.NotifyOpponentMove()
WC.UI.ClickSquare(WC.Chess.Square("e2"))
assert(not WC.UI.moveBadge:IsShown(), "playing clears notification")

print("settings_spec: OK")
