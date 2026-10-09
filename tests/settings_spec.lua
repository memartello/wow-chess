local function widget()
    local methods = {}
    function methods:CreateTexture() return widget() end
    function methods:CreateFontString() return widget() end
    function methods:SetSize(width, height) self.width, self.height = width, height end
    function methods:SetScale(scale) self.scale = scale end
    function methods:SetAlpha(alpha) self.alpha = alpha end
    function methods:SetValue(value)
        self.value = value
        if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self, value) end
    end
    function methods:SetWidth(width) self.width = width end
    function methods:GetWidth() return self.width end
    function methods:GetHeight() return self.height end
    function methods:GetCenter() return 100, 100 end
    function methods:GetEffectiveScale() return 1 end
    function methods:GetFrameLevel() return rawget(self, "frameLevel") or 1 end
    function methods:SetFrameLevel(value) self.frameLevel = value end
    function methods:SetText(value) self.text = value end
    function methods:GetText() return self.text end
    function methods:GetStringWidth() return #(self.text or "") * 7 end
    function methods:SetTexture(value) self.texture = value end
    function methods:SetColorTexture(...) self.color = { ... } end
    function methods:SetTexCoord(...) self.texCoord = { ... } end
    function methods:SetParent(parent) self.parent = parent end
    function methods:SetScript(event, callback) self.scripts[event] = callback end
    function methods:ClearAllPoints() self.point = nil end
    function methods:SetPoint(...) self.point = { ... } end
    function methods:CreateAnimationGroup() return widget() end
    function methods:CreateAnimation() return widget() end
    function methods:Play() self.playing = true; self.playCount = (rawget(self, "playCount") or 0) + 1 end
    function methods:Stop() self.playing = false end
    function methods:Show() self.shown = true end
    function methods:Hide() self.shown = false end
    function methods:SetShown(value) self.shown = value end
    function methods:IsShown() return self.shown ~= false end
    function methods:Enable() self.enabled = true end
    function methods:Disable() self.enabled = false end
    function methods:IsEnabled() return self.enabled ~= false end
    return setmetatable({ scripts = {}, shown = true }, {
        __index = function(_, key) return methods[key] or function() end end,
    })
end

UIParent = widget()
UIParent:SetSize(1920, 1080)
Minimap = widget()
Minimap:SetSize(140, 140)
GameTooltip = widget()
local now, cursorX, cursorY = 10, 100, 100
GetTime = function() return now end
GetCursorPosition = function() return cursorX, cursorY end
local sounds = {}
SOUNDKIT = { UI_GROUP_FINDER_RECEIVE_APPLICATION = 47615 }
PlaySound = function(sound) sounds[#sounds + 1] = sound end
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
assert(loadfile("WoWChess/Identity.lua"))("WoWChess", WC)
assert(loadfile("WoWChess/UI.lua"))("WoWChess", WC)
WC.Game.CanUndoBotTurn = function()
    local active = WC.Game.active
    return active and active.mode == "bot" and active.undoTurns and #active.undoTurns > 0 or false
end

assert(WC.Language() == "en", "English client locale")
WC.UI.Initialize()
assert(#WC.UI.main.skinPieces == 9 and #WC.UI.homeContent.skinPieces == 5 and
    WC.UI.main.skinPieces[1].texture == WC.assetRoot .. "panel_dark.png",
    "home frame uses the panel artwork and the banner has a single top border")
assert(#WC.UI.mainNav == 2 and WC.UI.mainNav[1].section == "home" and
    WC.UI.mainNav[2].section == "options" and WC.UI.mainNav[1].button.warcraftTone == "gold" and
    WC.UI.playerRows[1].challenge.warcraftSlices[1].texture == WC.assetRoot .. "button_red.png",
    "navigation shows only Play and Options with Warcraft textures")
assert(WC.UI.boardButtons.square.caption.text == "Alliance" and
    WC.UI.boardButtons.undead.caption.text == "Undead" and
    WC.UI.boardButtons.elves.caption.text == "Elves" and
    WC.UI.pieceButtons.w.basic.caption.text == "Alliance" and
    WC.UI.pieceButtons.b.basic.caption.text == "Horde" and
    WC.UI.pieceButtons.w.human.caption.text == "Humans" and
    WC.UI.pieceButtons.b.orc.caption.text == "Orcs" and
    WC.UI.windowSizeButtons.small.caption.text == "Small" and
    WC.UI.windowSizeButtons.normal.caption.text == "Normal" and
    WC.UI.windowSizeButtons.large.caption.text == "Large" and
    WC.UI.windowSizeButtons.normal.warcraftTone == "gold" and
    WC.UI.soundButton.caption.text == "Turn sound: On" and
    WC.UI.muteWhenOpenButton.caption.text == "Mute while window is open: Off" and
    WC.UI.opacityValue.text == "100%" and
    WC.UI.languageButtons.en.caption.text == WC.L("Inglés") and
    WC.UI.coordinateButton.caption.text == WC.L("Coordenadas") .. ": " .. WC.L("Activadas"),
    "options use active colors without checkbox prefixes")
WC.Network.players = {
    ["alice-realm"] = { name = "Alice-Realm", level = 60, status = "online" },
    ["alice-otherrealm"] = { name = "Alice-OtherRealm", level = 60, status = "online" },
}
WC.UI.RefreshPlayers()
assert(WC.UI.playerRows[1].target == "Alice-OtherRealm" and not WC.UI.playerRows[2]:IsShown(),
    "the discovered list hides our character but keeps another realm's same-named player")
WC.Network.players["alice-otherrealm"] = nil
WC.UI.RefreshPlayers()
assert(WC.UI.emptyPlayers:IsShown() and not WC.UI.playerRows[1]:IsShown() and rawget(WC.UI.playerRows[1], "target") == nil,
    "only our own presence leaves an empty, non-interactive player list")
WC.me = "Alice Brightvale-Realm"
WC.Network.players = {
    ["alice-brightvale-transportrealm"] = { name = "Alice-Brightvale-TransportRealm", level = 60, status = "online" },
    ["alice-dawnvale-transportrealm"] = { name = "Alice-Dawnvale-TransportRealm", level = 55, status = "online" },
}
WC.UI.RefreshPlayers()
assert(WC.UI.playerRows[1].target == "Alice-Dawnvale-TransportRealm" and
    WC.UI.playerRows[1].name.text == "Alice Dawnvale" and not WC.UI.playerRows[2]:IsShown(),
    "the list hides our surname variant and shows another character's full name")
for _, column in ipairs({ "name", "level", "status" }) do
    assert(WC.UI.playerHeaders[column].point[2] == WC.UI.playerRows[1][column].point[2] and
        WC.UI.playerHeaderPanel.point[2] == WC.UI.playerRows[1].point[2],
        "player list header aligns with the " .. column .. " column")
end
assert(rawget(WC.UI.playerList, "skinPieces") == nil and
    #WC.UI.playerHeaderPanel.skinPieces == 9 and
    WC.UI.playerRows[1].fill:IsShown() and not WC.UI.playerRows[2].fill:IsShown() and
    WC.UI.playerRows[1].divider.color[4] == .42 and rawget(WC.UI.playerRows[8], "divider") == nil,
    "player list leaves the parent parchment visible, shades odd rows and separates rows")
WC.me = "Alice-Realm"
WC.Network.players = {}
WC.UI.RefreshPlayers()
assert(#WC.UI.gameFrame.skinPieces == 9 and #WC.UI.selfBar.skinPieces == 9 and
    #WC.UI.opponentBar.skinPieces == 9 and #WC.UI.turnBadge.skinPieces == 9 and
    WC.UI.resignButton.warcraftSlices[1].texture == WC.assetRoot .. "button_red.png",
    "match frame, player sections and actions use the same artwork")
WC.UI.ShowBotSetup()
assert(#WC.UI.botSetup.skinPieces == 9 and
    WC.UI.botSetup.scale == 1 and
    WC.UI.botSetup.difficultyButtons[2].button.warcraftTone == "gold" and
    WC.UI.botSetup.colorButtons[1].button.warcraftTone == "gold",
    "bot setup highlights its initial difficulty and color")
WC.UI.botSetup.difficultyButtons[3].button.scripts.OnClick()
WC.UI.botSetup.colorButtons[2].button.scripts.OnClick()
assert(WC.UI.botSetup.difficultyButtons[3].button.warcraftTone == "gold" and
    WC.UI.botSetup.colorButtons[2].button.warcraftTone == "gold" and
    WC.UI.botSetup.difficultyButtons[2].button.warcraftTone == "dark",
    "bot setup moves the visual selection with the chosen options")
assert(WC.UI.botSetup.difficultyButtons[3].button.caption.text == WC.L("Difícil") and
    WC.UI.botSetup.colorButtons[2].button.caption.text == WC.L("Negras"),
    "bot difficulty and side captions have no checkbox prefixes")
WC.UI.botSetup:Hide()
WC.UI.ShowPromotion("e7", "e8")
assert(#WC.UI.promotion.skinPieces == 9 and #WC.UI.promotion.actionButtons == 4 and
    WC.UI.promotion.scale == 1 and
    WC.UI.promotion.actionButtons[2].warcraftSlices[1].texture == WC.assetRoot .. "button_dark.png",
    "promotion popup uses the shared panel and button artwork")
WC.UI.promotion:Hide()
WC.UI.ShowResult({ won = true, winner = "w", reason = "mate" })
assert(#WC.UI.resultModal.skinPieces == 9 and
    WC.UI.resultModal.scale == 1 and
    WC.UI.resultModal.actionButtons[1].warcraftSlices[1].texture == WC.assetRoot .. "button_red.png",
    "match result popup uses the shared panel and button artwork")
WC.UI.resultModal:Hide()
assert(WC.Theme.Background().id == "square" and WC.Theme.PieceStyle("w").id == "basic" and
    WC.Theme.PieceStyle("b").id == "basic", "new settings default to the supplied theme")
assert(WC.Theme.WindowSize().id == "normal" and WC.UI.main.scale == 1 and WC.UI.gameFrame.scale == 1,
    "window size defaults to normal")
WC.UI.windowSizeButtons.small.scripts.OnClick()
assert(WC.db.settings.windowSize == "small" and WC.UI.main.scale == .85 and
    WC.UI.gameFrame.scale == .85 and WC.UI.botSetup.scale == .85 and
    WC.UI.promotion.scale == .85 and WC.UI.resultModal.scale == .85 and
    WC.UI.windowSizeButtons.small.warcraftTone == "gold", "small size applies to existing windows")
WC.UI.windowSizeButtons.large.scripts.OnClick()
assert(WC.db.settings.windowSize == "large" and WC.UI.main.scale == 1.15 and
    WC.UI.gameFrame.scale == 1.15, "large size is saved and applied")
UIParent:SetSize(1024, 768)
WC.UI.RefreshWindowScale()
assert(WC.UI.main.scale <= (768 - 24) / 850 and
    WC.UI.gameFrame.scale <= (768 - 24) / 850,
    "windows fit the available screen")
UIParent:SetSize(1920, 1080)
WC.UI.windowSizeButtons.normal.scripts.OnClick()
assert(WC.db.settings.windowSize == "normal" and WC.UI.main.scale == 1 and WC.UI.gameFrame.scale == 1 and
    not WC.Theme.SetWindowSize("missing"), "normal size can be restored and invalid sizes are rejected")
WC.UI.opacitySlider:SetValue(55)
assert(WC.db.settings.frameOpacity == .55 and WC.UI.opacityValue.text == "55%" and
    WC.UI.main.skinPieces[1].alpha == .55 and WC.UI.optionsContent.skinPieces[1].alpha == .55 and
    WC.UI.selfBar.skinPieces[1].alpha == .55 and WC.UI.resultModal.skinPieces[1].alpha == .55 and
    WC.UI.homeParchment.alpha == .55, "opacity applies to outer and inner panel artwork")
WC.UI.ShowInvite("Bob-Realm")
assert(WC.UI.invite.skinPieces[1].alpha == .55, "new popups inherit the saved opacity")
WC.UI.HideInvite()
WC.UI.opacitySlider:SetValue(100)
assert(WC.Theme.FrameOpacity() == 1 and not WC.Theme.SetFrameOpacity(.2),
    "opacity can be restored and out-of-range values are rejected")
assert(WC.UI.boardImage.texture == WC.assetRoot .. "board_square.png" and WC.UI.boardFrame.width == 630 and
    WC.UI.boardFrame.height == 630,
    "square board artwork and geometry apply by default")
assert(WC.UI.gameFrame.width == 1010 and WC.UI.boardFrame.point[2] == 12 and
    WC.UI.turnLabel == nil, "match window has no left information column")
assert(WC.UI.resignButton.point[1] == "TOPLEFT" and WC.UI.resignButton.point[3] == -552 and
    WC.UI.resignButton.scripts.OnClick ~= nil, "resign is in the right selected-piece section")
assert(WC.UI.undoButton.caption.text == "Undo turn" and WC.UI.undoButton.point[3] == -604,
    "bot undo action is translated and placed with the match controls")
assert(math.abs(WC.UI.boardFrame.point[3] + 58 + (756 - 630) / 2) < .01,
    "board is vertically centered in the match content")
assert(math.abs(WC.UI.cells[1].frame.point[2] - 77 * 630 / 1024) < .01 and
    math.abs(WC.UI.cells[1].frame.width - 870 * 630 / 1024 / 8) < .01, "square grid aligns with the artwork")
assert(WC.UI.cells[1].frame.piece.width < WC.UI.cells[1].frame.width * 1.05,
    "piece textures fit the squares")
assert(WC.UI.opponentBar.point[1] == "BOTTOMLEFT" and WC.UI.opponentBar.point[2] == WC.UI.boardFrame and
    WC.UI.opponentBar.point[3] == "TOPLEFT" and WC.UI.opponentBar.point[5] == 7 and
    WC.UI.selfBar.point[1] == "TOPLEFT" and WC.UI.selfBar.point[2] == WC.UI.boardFrame and
    WC.UI.selfBar.point[3] == "BOTTOMLEFT" and WC.UI.selfBar.point[5] == -7,
    "player sections sit outside the board artwork with a gap")
assert(WC.Theme.PiecePath("wP") == WC.assetRoot .. "pieces\\basic_white_P.png" and
    WC.Theme.PiecePath("bK") == WC.assetRoot .. "pieces\\basic_black_K.png", "basic piece paths use chess colors")
assert(WC.UI.versionLabel.text == "vtest-build", "home screen displays the addon version")
assert(WC.UI.launcherIcon.texture == WC.assetRoot .. "minimap_icon.png", "minimap button uses the chess artwork")
assert(WC.UI.launcherBorder.texture == "Interface\\Minimap\\MiniMap-TrackingBorder", "minimap button uses the native gold border")
assert(WC.UI.moveGlow.width == WC.UI.launcherBorder.width and WC.UI.moveGlow.height == WC.UI.launcherBorder.height and
    WC.UI.moveGlow.point[2] == WC.UI.launcherBorder and WC.UI.moveBorderGlow.point[2] == WC.UI.launcherBorder,
    "both pulse layers are centered on the native border")
assert(WC.UI.moveIconGlow.texture == WC.UI.launcherIcon.texture and
    WC.UI.moveIconGlow.point[2] == WC.UI.launcherIcon and #WC.UI.moveIconLights == 2 and
    not WC.UI.moveIconGlow:IsShown() and not WC.UI.moveIconLights[1]:IsShown(),
    "the icon's extra light layers start hidden and stay centered")
local launcher = WC.UI.launcher
assert(launcher.point[1] == "CENTER" and launcher.point[2] == Minimap and
    math.abs(launcher.point[4] + 75 / math.sqrt(2)) < .01 and
    math.abs(launcher.point[5] + 75 / math.sqrt(2)) < .01, "button starts on the minimap rim")
launcher.scripts.OnDragStart(launcher)
cursorX, cursorY = 200, 100
launcher.scripts.OnUpdate(launcher)
assert(math.abs(launcher.point[4] - 75) < .01 and math.abs(launcher.point[5]) < .01, "drag reaches the right edge")
cursorX, cursorY = 0, 100
launcher.scripts.OnUpdate(launcher)
assert(math.abs(launcher.point[4] + 75) < .01 and math.abs(launcher.point[5]) < .01, "drag reaches the left edge")
cursorX, cursorY = 100, 0
launcher.scripts.OnUpdate(launcher)
assert(math.abs(launcher.point[4]) < .01 and math.abs(launcher.point[5] + 75) < .01, "drag reaches the bottom edge")
cursorX, cursorY = 100, 200
launcher.scripts.OnDragStop(launcher)
assert(math.abs(launcher.point[4]) < .01 and math.abs(launcher.point[5] - 75) < .01 and
    math.abs(WC.db.settings.minimapAngle - 90) < .01, "drag reaches the top edge and saves its angle")
assert(launcher.scripts.OnUpdate == nil, "drag update stops on release")
launcher.scripts.OnClick(launcher)
assert(WC.UI.main:IsShown(), "drag release does not click the launcher")
assert(WC.L("Arrastrá para mover por el borde del minimapa.") == "Drag to move around the minimap edge.", "drag hint is translated")
WC.UI.SetMainSection("options")
assert(WC.UI.optionsContent:IsShown() and not WC.UI.homeContent:IsShown(), "options page")
assert(WC.UI.mainNav[1].button.warcraftTone == "dark" and WC.UI.mainNav[2].button.warcraftTone == "gold",
    "selected navigation button follows the visible section")
assert(WC.UI.boardButtons.undead.point[2] == 400 and WC.UI.boardButtons.elves.point[2] == 20 and
    WC.UI.boardButtons.elves.point[3] == -185 and
    #WC.Theme.backgrounds == 5 and WC.UI.boardButtons.durotar == nil,
    "five board choices fit in two rows above the piece choices")
assert(WC.UI.pieceButtons.w.basic.point[2] == 20 and
    WC.UI.pieceButtons.w.basic.point[3] == -292 and
    WC.UI.pieceButtons.b.undead.point[2] == 468 and
    WC.UI.pieceButtons.b.undead.point[3] == -361,
    "independent white and black choices fit above the language controls")
for _, choice in ipairs({
    { id = "undead", path = "board_undead.png", gridX = 110, gridY = 110 },
    { id = "elves", path = "board_elves.png", gridX = 112, gridY = 126 },
}) do
    WC.UI.boardButtons[choice.id].scripts.OnClick()
    assert(WC.db.settings.board == choice.id and WC.Theme.Background().id == choice.id and
        WC.Theme.BoardPath() == WC.assetRoot .. choice.path and
        WC.UI.boardImage.texture == WC.assetRoot .. choice.path and
        WC.UI.boardPreview.texture == WC.assetRoot .. choice.path and
        WC.UI.boardFrame.width == 630 and WC.UI.boardFrame.height == 630 and
        WC.UI.boardButtons[choice.id].warcraftTone == "gold",
        choice.id .. " board artwork, preview and saved selection")
    assert(math.abs(WC.UI.cells[1].frame.point[2] - choice.gridX * 630 / 1024) < .01 and
        math.abs(WC.UI.cells[1].frame.point[3] + choice.gridY * 630 / 1024) < .01 and
        math.abs(WC.UI.cells[1].frame.width - 800 * 630 / 1024 / 8) < .01,
        choice.id .. " board grid aligns with its artwork")
end
WC.UI.boardButtons.classic.scripts.OnClick()
assert(WC.db.settings.board == "classic" and not WC.UI.boardImage:IsShown(), "classic board applies")
assert(WC.UI.cells[1].frame.tile:IsShown() and WC.UI.classicPreview:IsShown(), "classic preview")
WC.UI.languageButtons.es.scripts.OnClick()
assert(WC.db.settings.language == "es" and WC.L("Opciones") == "Opciones", "Spanish selection")
assert(WC.UI.boardButtons.undead.caption.text == "No-muertos" and
    WC.UI.boardButtons.square.caption.text == "Alianza" and
    WC.UI.boardButtons.elves.caption.text == "Elfos" and
    WC.UI.pieceButtons.w.basic.caption.text == "Alianza" and
    WC.UI.pieceButtons.b.basic.caption.text == "Horda" and
    WC.UI.windowSizeButtons.small.caption.text == "Pequeño" and
    WC.UI.windowSizeButtons.large.caption.text == "Grande" and
    WC.UI.soundButton.caption.text == "Sonido de turno: Sí" and
    WC.UI.muteWhenOpenButton.caption.text == "Silenciar con ventana abierta: No" and
    WC.UI.pieceButtons.w.human.caption.text == "Humanos" and
    WC.UI.pieceButtons.b.orc.caption.text == "Orcos",
    "new board and piece choices have Spanish labels")
WC.UI.languageButtons.en.scripts.OnClick()
assert(WC.L("Opciones") == "Options", "English selection")
assert(not WC.Theme.SetBackground("durotar") and WC.Theme.Background().id == "classic",
    "removed board cannot be selected")
WC.db.settings.board = "durotar"
assert(WC.Theme.Background().id == "square" and WC.db.settings.board == nil,
    "old Durotar selection migrates to the Alliance default")
local previousFaction = UnitFactionGroup
UnitFactionGroup = function() return "Horde" end
WC.db.settings.board = "durotar"
assert(WC.Theme.Background().id == "horde" and WC.db.settings.board == nil,
    "old Durotar selection migrates to the Horde default")
UnitFactionGroup = previousFaction
WC.UI.RefreshTheme()
WC.UI.RefreshSettings()
assert(not WC.Theme.SetBackground("missing") and WC.Theme.Background().id == "square", "invalid background")
WC.UI.pieceButtons.w.elf.scripts.OnClick()
WC.UI.pieceButtons.b.undead.scripts.OnClick()
assert(WC.db.settings.whitePieces == "elf" and WC.db.settings.blackPieces == "undead" and
    WC.UI.pieceButtons.w.elf.warcraftTone == "gold" and WC.UI.pieceButtons.b.undead.warcraftTone == "gold" and
    WC.Theme.PiecePath("wP") == WC.assetRoot .. "pieces\\elf_light_P.png" and
    WC.Theme.PiecePath("bK") == WC.assetRoot .. "pieces\\undead_black_K.png" and
    WC.UI.previewText.text:find("White: Elves", 1, true) and
    WC.UI.previewText.text:find("Black: Undead", 1, true),
    "white elf and black undead styles are saved independently")
WC.UI.pieceButtons.w.orc.scripts.OnClick()
assert(WC.Theme.PiecePath("wP") == WC.assetRoot .. "pieces\\orc_white_P.png" and
    WC.Theme.PieceStyle("b").id == "undead", "changing white pieces leaves black pieces unchanged")
WC.UI.pieceButtons.b.human.scripts.OnClick()
assert(WC.Theme.PiecePath("bK") == WC.assetRoot .. "pieces\\human_black_K.png" and
    WC.Theme.PieceStyle("w").id == "orc", "changing black pieces leaves white pieces unchanged")
assert(not WC.Theme.SetPieceStyle("w", "missing") and not WC.Theme.SetPieceStyle("x", "human"),
    "invalid side or style is rejected")
WC.db.settings.whitePieces, WC.db.settings.blackPieces, WC.db.settings.pieces = nil, nil, "factions"
assert(WC.Theme.PieceStyle("w").id == "human" and WC.Theme.PieceStyle("b").id == "orc" and
    WC.db.settings.whitePieces == "human" and WC.db.settings.blackPieces == "orc" and
    WC.db.settings.pieces == nil, "saved human and orc preset migrates to independent choices")
WC.db.settings.whitePieces, WC.db.settings.blackPieces, WC.db.settings.pieces = nil, nil, "elves_undead"
assert(WC.Theme.PieceStyle("w").id == "elf" and WC.Theme.PieceStyle("b").id == "undead",
    "saved elf and undead preset migrates to independent choices")
WC.UI.pieceButtons.w.basic.scripts.OnClick()
WC.UI.pieceButtons.b.basic.scripts.OnClick()
assert(WC.Theme.PieceStyle("w").id == "basic" and WC.Theme.PieceStyle("b").id == "basic",
    "basic pieces can be restored independently for both sides")
assert(WC.UI.previewText.text:find("White: Alliance", 1, true) and
    WC.UI.previewText.text:find("Black: Horde", 1, true),
    "basic pieces use side-specific names in the preview")

WC.Game.Remaining = function() return 600 end
WC.Game.active = {
    mode = "bot", opponent = "Bot intermedio", color = "w", white = "Alice-Realm",
    state = WC.Chess.New(), seq = 0,
}
WC.UI.ShowGame()
assert(WC.UI.opponentName.text == "Intermediate bot · Black", "English match labels")
assert(not WC.UI.drawButton:IsShown() and WC.UI.undoButton:IsShown() and
    not WC.UI.undoButton:IsEnabled() and WC.UI.backButton.point[3] == -656,
    "practice mode shows undo disabled until the player has moved")
WC.Game.active.undoTurns = { { state = WC.Game.active.state } }
WC.UI.RefreshGame()
assert(WC.UI.undoButton:IsEnabled(), "undo becomes available after a player turn")
WC.Game.active.undoTurns = nil
WC.Game.active.mode = "peer"
WC.UI.RefreshGame()
assert(WC.UI.drawButton:IsShown() and not WC.UI.undoButton:IsShown() and WC.UI.backButton.point[3] == -656,
    "multiplayer mode shows draw but not undo")
local ownName, opponentName = WC.me, WC.Game.active.opponent
WC.me = "VeryLongCharacterSurnameOfAzeroth-Realm"
WC.Game.active.opponent = "AnotherExtremelyLongOpponentName-Realm"
WC.UI.RefreshGame()
for _, name in ipairs({ WC.UI.selfName, WC.UI.opponentName }) do
    assert(name.text:find("...", 1, true) and name:GetStringWidth() <= name.width - 4 and
        not name.text:find("\n", 1, true), "long player names stay on one line with an ellipsis")
end
assert(WC.UI.selfName.text:sub(-#" · White") == " · White" and
    WC.UI.opponentName.text:sub(-#" · Black") == " · Black",
    "truncation keeps the player color visible")
WC.me, WC.Game.active.opponent = ownName, opponentName
WC.Game.active.mode = "bot"
WC.UI.RefreshGame()
assert(WC.UI.selfBar.border.color[1] == 1 and WC.UI.opponentBar.border.color[1] < 1 and
    WC.UI.turnBadge.parent == WC.UI.selfBar, "starting side has the highlighted player section")
local firstPosition = WC.Game.active.state
WC.Game.active.state = assert(WC.Chess.Move(firstPosition, "e2", "e4"))
WC.Game.active.seq = 1
WC.UI.RefreshGame()
assert(WC.UI.opponentBar.border.color[1] == 1 and WC.UI.selfBar.border.color[1] < 1 and
    WC.UI.turnBadge.parent == WC.UI.opponentBar, "highlight moves to the opponent after a move")
WC.Game.active.state.outcome = { reason = "mate", winner = "w" }
WC.UI.RefreshGame()
assert(WC.UI.selfBar.border.color[1] < 1 and WC.UI.opponentBar.border.color[1] < 1 and
    not WC.UI.turnBadge:IsShown(), "finished games do not highlight a side")
WC.Game.active.state, WC.Game.active.seq = firstPosition, 0
WC.UI.RefreshGame()
assert(WC.UI.cells[1].frame.piece.texture == WC.assetRoot .. "pieces\\basic_black_R.png",
    "active board uses the selected piece set")
assert(WC.UI.gameFrame:IsShown() and not WC.UI.main:IsShown(), "starting a match hides home")
WC.UI.gameCloseButton.scripts.OnClick()
assert(not WC.UI.gameFrame:IsShown() and not WC.UI.main:IsShown(), "match X closes the only open window")
now = now + 1
launcher.scripts.OnClick(launcher)
assert(WC.UI.gameFrame:IsShown() and not WC.UI.main:IsShown(), "minimap opens the active match directly")
launcher.scripts.OnClick(launcher)
assert(not WC.UI.gameFrame:IsShown() and not WC.UI.main:IsShown(), "minimap closes the active match without home")
WC.UI.ShowMain()
assert(WC.UI.main:IsShown() and not WC.UI.gameFrame:IsShown(), "explicit list navigation opens home")
launcher.scripts.OnClick(launcher)
assert(WC.UI.gameFrame:IsShown() and not WC.UI.main:IsShown(), "minimap switches from home to active match")
WC.UI.boardButtons.classic.scripts.OnClick()
assert(WC.UI.cells[1].frame.tile:IsShown() and WC.UI.boardFrame:IsShown(), "board changes during a game")
WC.UI.boardButtons.square.scripts.OnClick()
assert(WC.UI.boardFrame.height == 630 and not WC.UI.cells[1].frame.tile:IsShown(),
    "square board can replace the classic board during a game")
WC.UI.pieceButtons.w.human.scripts.OnClick()
WC.UI.pieceButtons.b.undead.scripts.OnClick()
assert(WC.UI.cells[1].frame.piece.texture == WC.assetRoot .. "pieces\\undead_black_R.png" and
    WC.UI.cells[57].frame.piece.texture == WC.assetRoot .. "pieces\\human_white_R.png",
    "independent piece choices refresh both sides of an active match")
WC.Game.active.color = "b"
WC.UI.RefreshGame()
assert(WC.UI.cells[1].frame.piece.texture == WC.assetRoot .. "pieces\\human_white_R.png" and
    WC.UI.cells[57].frame.piece.texture == WC.assetRoot .. "pieces\\undead_black_R.png",
    "piece appearance follows chess color when the board faces black")
WC.Game.active.color = "w"
WC.UI.RefreshGame()
WC.UI.pieceButtons.b.elf.scripts.OnClick()
assert(WC.UI.cells[1].frame.piece.texture == WC.assetRoot .. "pieces\\elf_dark_R.png" and
    WC.UI.cells[57].frame.piece.texture == WC.assetRoot .. "pieces\\human_white_R.png",
    "changing only black pieces preserves the white appearance")
WC.UI.pieceButtons.w.basic.scripts.OnClick()
WC.UI.pieceButtons.b.basic.scripts.OnClick()
WC.UI.languageButtons.es.scripts.OnClick()
assert(WC.UI.opponentName.text == "Bot intermedio · Negras", "language changes during a game")
assert(WC.UI.boardTurn.text == "Empieza: Alice", "board turn label changes immediately")
WC.Game.active.state = assert(WC.Chess.Move(WC.Game.active.state, "e2", "e4"))
WC.Game.active.state = assert(WC.Chess.Move(WC.Game.active.state, "e7", "e5"))
WC.Game.active.seq = 2
WC.UI.RefreshGame()
local firstRow = WC.UI.moveRows[1]
assert(firstRow.white.moveIndex == 1 and firstRow.black.moveIndex == 2, "white and black moves have separate controls")
local function boardCell(square)
    for _, entry in ipairs(WC.UI.cells) do
        if entry.frame.boardSquare == WC.Chess.Square(square) then return entry.frame end
    end
end
firstRow.white.scripts.OnClick(firstRow.white)
assert(boardCell("e2").moveFrom:IsShown() and boardCell("e4").moveTo:IsShown() and firstRow.white.selection:IsShown(),
    "clicking white's move highlights its origin, destination and history entry")
firstRow.black.scripts.OnClick(firstRow.black)
assert(boardCell("e7").moveFrom:IsShown() and boardCell("e5").moveTo:IsShown() and
    not boardCell("e2").moveFrom:IsShown() and firstRow.black.selection:IsShown() and
    not firstRow.white.selection:IsShown(), "clicking black's move switches the highlighted play")
WC.UI.ClickSquare(WC.Chess.Square("g1"))
assert(not firstRow.black.selection:IsShown() and not boardCell("e7").moveFrom:IsShown(),
    "interacting with the board clears the history highlight")
firstRow.black.scripts.OnClick(firstRow.black)
WC.Game.active.state = assert(WC.Chess.Move(WC.Game.active.state, "g1", "f3"))
WC.Game.active.state = assert(WC.Chess.Move(WC.Game.active.state, "b8", "c6"))
WC.Game.active.seq = 4
WC.UI.RefreshGame()
assert(not firstRow.black.selection:IsShown() and not boardCell("e7").moveFrom:IsShown(),
    "a new move clears a stale history highlight")
local priorState, priorSeq = WC.Game.active.state, WC.Game.active.seq
local captureState = WC.Chess.New()
for _, move in ipairs({ { "e2", "e4" }, { "d7", "d5" }, { "e4", "d5" }, { "d8", "d5" } }) do
    captureState = assert(WC.Chess.Move(captureState, move[1], move[2]))
end
WC.Game.active.state, WC.Game.active.seq = captureState, 4
WC.UI.RefreshGame()
assert(WC.UI.opponentLostIcons[1]:IsShown() and
    WC.UI.opponentLostIcons[1].texture == WC.assetRoot .. "pieces\\basic_black_P.png" and
    WC.UI.selfLostIcons[1]:IsShown() and
    WC.UI.selfLostIcons[1].texture == WC.assetRoot .. "pieces\\basic_white_P.png",
    "both player rows show their own lost pieces")
WC.UI.pieceButtons.w.orc.scripts.OnClick()
WC.UI.pieceButtons.b.human.scripts.OnClick()
assert(WC.UI.opponentLostIcons[1].texture == WC.assetRoot .. "pieces\\human_black_P.png" and
    WC.UI.selfLostIcons[1].texture == WC.assetRoot .. "pieces\\orc_white_P.png",
    "lost pieces follow independent white and black selections")
WC.UI.pieceButtons.w.basic.scripts.OnClick()
WC.UI.pieceButtons.b.basic.scripts.OnClick()
WC.Game.active.state, WC.Game.active.seq = priorState, priorSeq
WC.UI.RefreshGame()
assert(not WC.UI.opponentLostIcons[1]:IsShown() and not WC.UI.selfLostIcons[1]:IsShown(),
    "lost-piece icons clear when there are no captures")
assert(not WC.UI.moveGlow:IsShown() and not WC.UI.moveBorderGlow:IsShown(), "border glows start hidden")
WC.UI.ShowMain()
WC.UI.NotifyOpponentMove()
assert(WC.UI.moveGlow:IsShown() and WC.UI.moveBorderGlow:IsShown() and WC.UI.movePulse.playing and
    WC.UI.moveIconGlow:IsShown() and WC.UI.moveIconPulse.playing and
    WC.UI.moveIconLights[1]:IsShown() and WC.UI.moveIconLights[2]:IsShown() and WC.UI.moveNotice,
    "opponent move lights the icon and pulses the minimap border")
assert(#sounds == 1 and sounds[1] == SOUNDKIT.UI_GROUP_FINDER_RECEIVE_APPLICATION, "one Group Finder alert plays for the move")
WC.UI.NotifyOpponentMove()
assert(WC.UI.movePulse.playCount == 1 and WC.UI.moveIconPulse.playCount == 1 and #sounds == 1,
    "duplicate notification does not restart the light, border pulse or sound")
now = now + 1
WC.UI.launcher.scripts.OnClick(WC.UI.launcher)
assert(WC.UI.gameFrame:IsShown() and not WC.UI.moveGlow:IsShown() and not WC.UI.moveBorderGlow:IsShown() and
    not WC.UI.movePulse.playing and not WC.UI.moveIconGlow:IsShown() and
    not WC.UI.moveIconPulse.playing and not WC.UI.moveIconLights[1]:IsShown(),
    "minimap click opens game and acknowledges both alert effects")
WC.UI.NotifyOpponentMove()
assert(#sounds == 2, "a later move gets its own sound")
launcher.scripts.OnClick(launcher)
assert(WC.UI.gameFrame:IsShown() and not WC.UI.main:IsShown() and not WC.UI.moveNotice,
    "acknowledging a move keeps an already open match on screen")
WC.UI.NotifyOpponentMove()
WC.UI.ClickSquare(WC.Chess.Square("e2"))
assert(not WC.UI.moveGlow:IsShown() and not WC.UI.moveBorderGlow:IsShown() and not WC.UI.movePulse.playing and
    not WC.UI.moveIconGlow:IsShown() and not WC.UI.moveIconPulse.playing,
    "playing clears the border and icon lights")
WC.UI.soundButton.scripts.OnClick()
WC.UI.NotifyOpponentMove()
assert(WC.db.settings.soundsEnabled == false and #sounds == 3 and WC.UI.moveGlow:IsShown() and
    WC.UI.moveIconGlow:IsShown(),
    "muting sounds leaves the visual turn alert active")
WC.UI.ClearMoveNotification()
WC.UI.soundButton.scripts.OnClick()
WC.UI.muteWhenOpenButton.scripts.OnClick()
WC.UI.ShowMain()
WC.UI.NotifyOpponentMove()
assert(WC.db.settings.muteWhenOpen == true and #sounds == 3 and WC.UI.moveGlow:IsShown() and
    WC.UI.moveIconGlow:IsShown(),
    "open addon window suppresses only the sound")
WC.UI.ClearMoveNotification()
WC.UI.main:Hide()
WC.UI.NotifyOpponentMove()
assert(#sounds == 4, "turn sound plays when all addon windows are closed")
WC.UI.ClearMoveNotification()

print("settings_spec: OK")
