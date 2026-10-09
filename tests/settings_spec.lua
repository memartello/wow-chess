local function widget()
    local methods = {}
    function methods:CreateTexture() return widget() end
    function methods:CreateFontString() return widget() end
    function methods:SetSize(width, height) self.width, self.height = width, height end
    function methods:GetWidth() return self.width end
    function methods:GetHeight() return self.height end
    function methods:GetCenter() return 100, 100 end
    function methods:GetEffectiveScale() return 1 end
    function methods:GetFrameLevel() return rawget(self, "frameLevel") or 1 end
    function methods:SetFrameLevel(value) self.frameLevel = value end
    function methods:SetText(value) self.text = value end
    function methods:GetText() return self.text end
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

assert(WC.Language() == "en", "English client locale")
WC.UI.Initialize()
assert(#WC.UI.main.skinPieces == 9 and #WC.UI.homeContent.skinPieces == 5 and
    WC.UI.main.skinPieces[1].texture == WC.assetRoot .. "panel_dark.png",
    "home frame uses the panel artwork and the banner has a single top border")
assert(#WC.UI.mainNav == 2 and WC.UI.mainNav[1].section == "home" and
    WC.UI.mainNav[2].section == "options" and WC.UI.mainNav[1].button.warcraftTone == "gold" and
    WC.UI.playerRows[1].challenge.warcraftSlices[1].texture == WC.assetRoot .. "button_red.png",
    "navigation shows only Play and Options with Warcraft textures")
assert(WC.UI.boardButtons.square.caption.text == WC.L("Cuadrado") and
    WC.UI.boardButtons.undead.caption.text == "Undead" and
    WC.UI.boardButtons.elves.caption.text == "Elves" and
    WC.UI.pieceButtons.basic.caption.text == WC.L("Piezas básicas") and
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
    WC.UI.promotion.actionButtons[2].warcraftSlices[1].texture == WC.assetRoot .. "button_dark.png",
    "promotion popup uses the shared panel and button artwork")
WC.UI.promotion:Hide()
WC.UI.ShowResult({ won = true, winner = "w", reason = "mate" })
assert(#WC.UI.resultModal.skinPieces == 9 and
    WC.UI.resultModal.actionButtons[1].warcraftSlices[1].texture == WC.assetRoot .. "button_red.png",
    "match result popup uses the shared panel and button artwork")
WC.UI.resultModal:Hide()
assert(WC.Theme.Background().id == "square" and WC.Theme.PieceSet().id == "basic", "new settings default to the supplied theme")
assert(WC.UI.boardImage.texture == WC.assetRoot .. "board_square.png" and WC.UI.boardFrame.width == 630 and
    WC.UI.boardFrame.height == 630,
    "square board artwork and geometry apply by default")
assert(WC.UI.gameFrame.width == 1010 and WC.UI.boardFrame.point[2] == 12 and
    WC.UI.turnLabel == nil, "match window has no left information column")
assert(WC.UI.resignButton.point[1] == "TOPLEFT" and WC.UI.resignButton.point[3] == -552 and
    WC.UI.resignButton.scripts.OnClick ~= nil, "resign is in the right selected-piece section")
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
    WC.UI.boardButtons.elves.point[3] == -185,
    "six board choices fit in two rows above the piece choices")
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
    WC.UI.boardButtons.elves.caption.text == "Elfos", "new boards have Spanish labels")
WC.UI.languageButtons.en.scripts.OnClick()
assert(WC.L("Opciones") == "Options", "English selection")
WC.UI.boardButtons.durotar.scripts.OnClick()
assert(WC.db.settings.board == "durotar" and WC.UI.boardImage:IsShown(), "Durotar board applies")
assert(not WC.UI.cells[1].frame.tile:IsShown() and WC.UI.boardPreview:IsShown(), "Durotar preview")
assert(WC.UI.boardFrame.height == 630 and WC.UI.boardFrame.width == 560 and
    WC.UI.boardImage.texCoord[2] < 1 and WC.UI.boardImage.texCoord[3] > 0,
    "Durotar fits the separate player sections without changing grid scale")
assert(not WC.Theme.SetBackground("missing") and WC.Theme.Background().id == "durotar", "invalid background")
WC.UI.pieceButtons.factions.scripts.OnClick()
assert(WC.db.settings.pieces == "factions" and WC.Theme.PiecePath("wP") == WC.assetRoot .. "pieces\\human_P.png",
    "faction pieces remain selectable")
assert(not WC.Theme.SetPieceSet("missing") and WC.Theme.PieceSet().id == "factions", "invalid piece set")
WC.UI.pieceButtons.basic.scripts.OnClick()
assert(WC.Theme.PieceSet().id == "basic" and WC.UI.previewText.text:find("Basic pieces", 1, true),
    "basic pieces can be restored independently of the board")

WC.Game.Remaining = function() return 600 end
WC.Game.active = {
    mode = "bot", opponent = "Bot intermedio", color = "w", white = "Alice-Realm",
    state = WC.Chess.New(), seq = 0,
}
WC.UI.ShowGame()
assert(WC.UI.opponentName.text == "Intermediate bot · Black", "English match labels")
assert(not WC.UI.drawButton:IsShown() and WC.UI.backButton.point[3] == -604,
    "practice mode packs the remaining right-panel actions together")
WC.Game.active.mode = "peer"
WC.UI.RefreshGame()
assert(WC.UI.drawButton:IsShown() and WC.UI.backButton.point[3] == -656,
    "multiplayer mode shows draw and back actions in the right panel")
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
WC.UI.pieceButtons.factions.scripts.OnClick()
assert(WC.UI.cells[1].frame.piece.texture == WC.assetRoot .. "pieces\\orc_R.png",
    "changing piece sets refreshes an active match")
WC.UI.pieceButtons.basic.scripts.OnClick()
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
WC.UI.pieceButtons.factions.scripts.OnClick()
assert(WC.UI.opponentLostIcons[1].texture == WC.assetRoot .. "pieces\\orc_P.png" and
    WC.UI.selfLostIcons[1].texture == WC.assetRoot .. "pieces\\human_P.png",
    "lost pieces follow the selected piece set")
WC.UI.pieceButtons.basic.scripts.OnClick()
WC.Game.active.state, WC.Game.active.seq = priorState, priorSeq
WC.UI.RefreshGame()
assert(not WC.UI.opponentLostIcons[1]:IsShown() and not WC.UI.selfLostIcons[1]:IsShown(),
    "lost-piece icons clear when there are no captures")
assert(not WC.UI.moveGlow:IsShown() and not WC.UI.moveBorderGlow:IsShown(), "border glows start hidden")
WC.UI.ShowMain()
WC.UI.NotifyOpponentMove()
assert(WC.UI.moveGlow:IsShown() and WC.UI.moveBorderGlow:IsShown() and WC.UI.movePulse.playing and WC.UI.moveNotice, "opponent move pulses the minimap border")
assert(#sounds == 1 and sounds[1] == SOUNDKIT.UI_GROUP_FINDER_RECEIVE_APPLICATION, "one Group Finder alert plays for the move")
WC.UI.NotifyOpponentMove()
assert(WC.UI.movePulse.playCount == 1 and #sounds == 1, "duplicate notification does not restart the pulse or sound")
now = now + 1
WC.UI.launcher.scripts.OnClick(WC.UI.launcher)
assert(WC.UI.gameFrame:IsShown() and not WC.UI.moveGlow:IsShown() and not WC.UI.moveBorderGlow:IsShown() and not WC.UI.movePulse.playing, "minimap click opens game and acknowledges move")
WC.UI.NotifyOpponentMove()
assert(#sounds == 2, "a later move gets its own sound")
launcher.scripts.OnClick(launcher)
assert(WC.UI.gameFrame:IsShown() and not WC.UI.main:IsShown() and not WC.UI.moveNotice,
    "acknowledging a move keeps an already open match on screen")
WC.UI.NotifyOpponentMove()
WC.UI.ClickSquare(WC.Chess.Square("e2"))
assert(not WC.UI.moveGlow:IsShown() and not WC.UI.moveBorderGlow:IsShown() and not WC.UI.movePulse.playing, "playing clears notification")

print("settings_spec: OK")
