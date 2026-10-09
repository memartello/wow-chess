local _, WC = ...
local UI = { selected = nil, legal = {}, cells = {}, playerRows = {}, localized = {}, mainSection = "home", moveNotice = false }
WC.UI = UI

local GOLD = { .98, .77, .31, 1 }
local MUTED = { .73, .68, .60, 1 }
local PANEL = { .075, .065, .06, .96 }
local RED = { .40, .075, .055, 1 }
local GAME_WIDTH, GAME_HEIGHT = 1160, 850

local function colorTexture(parent, layer, r, g, b, a)
    local texture = parent:CreateTexture(nil, layer or "BACKGROUND")
    texture:SetColorTexture(r, g, b, a)
    return texture
end

local function box(parent, width, height)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(width, height)
    local border = colorTexture(frame, "BACKGROUND", .55, .38, .18, 1)
    border:SetAllPoints()
    local fill = colorTexture(frame, "BACKGROUND", unpack(PANEL))
    fill:SetPoint("TOPLEFT", 2, -2)
    fill:SetPoint("BOTTOMRIGHT", -2, 2)
    return frame
end

local function label(parent, text, size, color, justify)
    local fs = parent:CreateFontString(nil, "OVERLAY", size == "large" and "GameFontNormalLarge" or "GameFontNormal")
    fs:SetText(WC.L(text or ""))
    fs:SetTextColor(unpack(color or GOLD))
    fs:SetJustifyH(justify or "LEFT")
    if text and text ~= "" then UI.localized[#UI.localized + 1] = { font = fs, key = text } end
    return fs
end

local function button(parent, text, width, height, onClick, disabled)
    local frame = CreateFrame("Button", nil, parent)
    frame:SetSize(width, height)
    local bg = colorTexture(frame, "BACKGROUND", disabled and .16 or RED[1], disabled and .14 or RED[2], disabled and .12 or RED[3], 1)
    bg:SetAllPoints()
    local title = label(frame, text, nil, disabled and MUTED or GOLD, "CENTER")
    title:SetAllPoints()
    frame:SetScript("OnClick", disabled and nil or onClick)
    frame:SetScript("OnEnter", function(self)
        if not disabled then bg:SetColorTexture(.59, .15, .08, 1) end
        if disabled then GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText(WC.L("Próximamente")); GameTooltip:Show() end
        if self.tooltip then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.tooltip())
            GameTooltip:Show()
        end
    end)
    frame:SetScript("OnLeave", function()
        bg:SetColorTexture(disabled and .16 or RED[1], disabled and .14 or RED[2], disabled and .12 or RED[3], 1)
        GameTooltip:Hide()
    end)
    frame.SetCaption = function(_, caption) title:SetText(caption) end
    return frame
end

local function titlebar(frame, text, close)
    local title = label(frame, text, "large")
    title:SetPoint("TOPLEFT", 18, -13)
    button(frame, "X", 28, 26, close):SetPoint("TOPRIGHT", -10, -9)
    local line = colorTexture(frame, "ARTWORK", .55, .38, .18, 1)
    line:SetPoint("TOPLEFT", 8, -43)
    line:SetPoint("TOPRIGHT", -8, -43)
    line:SetHeight(1)
end

function UI.SetStatus(message)
    local translated = WC.L(message or "")
    if UI.mainStatus then UI.mainStatus:SetText(translated) end
    if UI.gameStatus then UI.gameStatus:SetText(translated) end
end

function UI.NotifyOpponentMove()
    local game = WC.Game.active
    if not game or game.state.outcome or game.state.turn ~= game.color then return end
    UI.moveNotice = true
    if UI.moveBadge then UI.moveBadge:Show() end
end

function UI.ClearMoveNotification()
    UI.moveNotice = false
    if UI.moveBadge then UI.moveBadge:Hide() end
end

function UI.SetMainSection(section)
    UI.mainSection = section == "options" and "options" or "home"
    if UI.homeContent then UI.homeContent:SetShown(UI.mainSection == "home") end
    if UI.optionsContent then UI.optionsContent:SetShown(UI.mainSection == "options") end
    if UI.mainSection == "options" then UI.RefreshSettings() end
end

local function checkerColor(texture, row, col)
    if (row + col) % 2 == 0 then
        texture:SetColorTexture(.76, .60, .39, 1)
    else
        texture:SetColorTexture(.36, .23, .16, 1)
    end
end

local function checkerPreview(parent, width, top)
    local preview = CreateFrame("Frame", nil, parent)
    preview:SetSize(width, width)
    preview:SetPoint("TOP", 0, top)
    local cell = width / 8
    for row = 1, 8 do
        for col = 1, 8 do
            local tile = colorTexture(preview, "ARTWORK", 1, 1, 1, 1)
            checkerColor(tile, row, col)
            tile:SetSize(cell, cell)
            tile:SetPoint("TOPLEFT", (col - 1) * cell, -(row - 1) * cell)
        end
    end
    return preview
end

local function makeMain()
    local main = box(UIParent, 1040, 660)
    main:SetPoint("CENTER")
    main:SetFrameStrata("DIALOG")
    main:SetMovable(true)
    main:EnableMouse(true)
    main:RegisterForDrag("LeftButton")
    main:SetScript("OnDragStart", main.StartMoving)
    main:SetScript("OnDragStop", main.StopMovingOrSizing)
    titlebar(main, "WoW Chess", function() main:Hide() end)
    UI.main = main

    local sidebar = box(main, 174, 580)
    sidebar:SetPoint("TOPLEFT", 12, -56)
    local menus = { "Jugar", "Jugadores", "Torneos", "Aspectos", "Historial", "Opciones" }
    for i, text in ipairs(menus) do
        local enabled = i <= 2 or i == 6
        button(sidebar, text, 150, 48, function()
            UI.SetMainSection(i == 6 and "options" or "home")
            if i == 2 and UI.nameInput then UI.nameInput:SetFocus() end
        end, not enabled):SetPoint("TOPLEFT", 12, -14 - (i - 1) * 59)
    end

    local content = box(main, 600, 580)
    content:SetPoint("TOPLEFT", 195, -56)
    UI.homeContent = content
    local banner = box(content, 576, 132)
    banner:SetPoint("TOPLEFT", 12, -12)
    local bannerImage = banner:CreateTexture(nil, "ARTWORK")
    bannerImage:SetTexture(WC.assetRoot .. "home_banner.png")
    bannerImage:SetTexCoord(0, 590 / 1024, 0, 136 / 256)
    bannerImage:SetPoint("TOPLEFT", 3, -3)
    bannerImage:SetPoint("BOTTOMRIGHT", -3, 3)
    local caption = colorTexture(banner, "OVERLAY", .025, .02, .015, .88)
    caption:SetPoint("BOTTOMLEFT", 3, 3)
    caption:SetPoint("BOTTOMRIGHT", -3, 3)
    caption:SetHeight(49)
    local bannerTitle = label(banner, "Desafiá jugadores de Azeroth", "large")
    bannerTitle:SetPoint("BOTTOMLEFT", 16, 27)
    local bannerText = label(banner, "Ajedrez en tiempo real dentro de WoW: Forever.", nil, MUTED)
    bannerText:SetPoint("BOTTOMLEFT", 16, 8)

    local quick = button(content, "Practicar\nBot intermedio", 176, 60, function()
        local ok, err = WC.Game.StartBot()
        if not ok then UI.SetStatus(err) end
    end)
    quick:SetPoint("TOPLEFT", 12, -154)
    local direct = box(content, 184, 60)
    direct:SetPoint("TOPLEFT", 207, -154)
    local directTitle = label(direct, "Desafiar por nombre", nil)
    directTitle:SetPoint("TOPLEFT", 8, -4)
    local input = CreateFrame("EditBox", nil, direct, "InputBoxTemplate")
    input:SetSize(158, 22)
    input:SetPoint("BOTTOM", 0, 5)
    input:SetAutoFocus(false)
    input:SetMaxLetters(48)
    input:SetScript("OnEnterPressed", function(self)
        local ok, err = WC.Game.Challenge(self:GetText())
        if not ok then UI.SetStatus(err) end
        self:ClearFocus()
    end)
    UI.nameInput = input
    button(content, "Crear partida\nPróximamente", 176, 60, nil, true):SetPoint("TOPLEFT", 410, -154)

    local section = label(content, "Jugadores disponibles", "large")
    section:SetPoint("TOPLEFT", 17, -232)
    button(content, "Actualizar", 92, 28, function() WC.Network.AskWho(); UI.SetStatus("Buscando jugadores...") end):SetPoint("TOPRIGHT", -17, -225)
    local header = label(content, "Personaje                             Nivel     Estado", nil, MUTED)
    header:SetPoint("TOPLEFT", 17, -267)
    for i = 1, 8 do
        local row = box(content, 566, 35)
        row:SetPoint("TOPLEFT", 17, -289 - (i - 1) * 36)
        row.name = label(row, "", nil)
        row.name:SetPoint("LEFT", 10, 0)
        row.name:SetWidth(260)
        row.level = label(row, "", nil, MUTED)
        row.level:SetPoint("LEFT", 287, 0)
        row.level:SetWidth(40)
        row.status = label(row, "", nil, MUTED)
        row.status:SetPoint("LEFT", 350, 0)
        row.status:SetWidth(95)
        row.challenge = button(row, "Retar", 85, 27, function()
            if row.target then
                local ok, err = WC.Game.Challenge(row.target)
                if not ok then UI.SetStatus(err) end
            end
        end)
        row.challenge:SetPoint("RIGHT", -4, 0)
        UI.playerRows[i] = row
    end
    local empty = label(content, "Buscando usuarios del addon en el canal...", nil, MUTED)
    empty:SetPoint("TOPLEFT", 20, -308)
    UI.emptyPlayers = empty

    local right = box(main, 224, 580)
    right:SetPoint("TOPRIGHT", -12, -56)
    local profileTitle = label(right, "Tu perfil", "large")
    profileTitle:SetPoint("TOPLEFT", 12, -14)
    local portrait = right:CreateTexture(nil, "ARTWORK")
    portrait:SetSize(52, 52)
    portrait:SetPoint("TOPLEFT", 13, -45)
    SetPortraitTexture(portrait, "player")
    local ownName = label(right, WC.ShortName(WC.me), nil)
    ownName:SetPoint("TOPLEFT", 76, -53)
    UI.levelLabel = label(right, "", nil, MUTED)
    UI.levelLabel:SetPoint("TOPLEFT", 76, -75)
    UI.stats = label(right, "", nil, MUTED)
    UI.stats:SetPoint("TOPLEFT", 13, -116)
    UI.stats:SetWidth(195)
    UI.stats:SetJustifyH("LEFT")
    local activeTitle = label(right, "Partida activa", "large")
    activeTitle:SetPoint("TOPLEFT", 12, -180)
    UI.activeButton = button(right, "Volver a partida", 196, 38, function() UI.ShowGame() end)
    UI.activeButton:SetPoint("TOPLEFT", 13, -214)
    local previewTitle = label(right, "Tablero inicial", "large")
    previewTitle:SetPoint("TOPLEFT", 12, -306)
    local preview = right:CreateTexture(nil, "ARTWORK")
    preview:SetTexture(WC.assetRoot .. WC.Theme.board.path)
    preview:SetTexCoord(0, WC.Theme.board.imageWidth / WC.Theme.board.textureWidth,
        0, WC.Theme.board.imageHeight / WC.Theme.board.textureHeight)
    preview:SetSize(142, 190)
    preview:SetPoint("TOP", 0, -344)
    UI.boardPreview = preview
    UI.classicPreview = checkerPreview(right, 142, -367)
    UI.previewText = label(right, "", nil, MUTED, "CENTER")
    UI.previewText:SetPoint("BOTTOM", 0, 15)

    local options = box(main, 600, 580)
    options:SetPoint("TOPLEFT", 195, -56)
    UI.optionsContent = options
    local optionsTitle = label(options, "Opciones", "large")
    optionsTitle:SetPoint("TOPLEFT", 20, -22)
    local boardTitle = label(options, "Tablero", "large")
    boardTitle:SetPoint("TOPLEFT", 20, -82)
    local boardHint = label(options, "Elegí el fondo del tablero.", nil, MUTED)
    boardHint:SetPoint("TOPLEFT", 20, -114)
    UI.boardButtons = {}
    for i, background in ipairs(WC.Theme.backgrounds) do
        local choice = button(options, background.name, 254, 54, function()
            WC.Theme.SetBackground(background.id)
            UI.RefreshTheme()
            UI.RefreshSettings()
        end)
        choice:SetPoint("TOPLEFT", 20 + (i - 1) * 274, -155)
        UI.boardButtons[background.id] = choice
    end
    local languageTitle = label(options, "Idioma", "large")
    languageTitle:SetPoint("TOPLEFT", 20, -258)
    local languageHint = label(options, "Elegí el idioma de la interfaz.", nil, MUTED)
    languageHint:SetPoint("TOPLEFT", 20, -290)
    UI.languageButtons = {}
    for i, choice in ipairs({ { "es", "Español" }, { "en", "Inglés" } }) do
        local language = choice[1]
        local selection = button(options, choice[2], 254, 54, function()
            WC.SetLanguage(language)
            UI.RefreshLanguage()
        end)
        selection:SetPoint("TOPLEFT", 20 + (i - 1) * 274, -331)
        UI.languageButtons[language] = selection
    end
    local applyHint = label(options, "Los cambios se aplican de inmediato.", nil, MUTED)
    applyHint:SetPoint("TOPLEFT", 20, -423)
    options:Hide()

    UI.mainStatus = label(main, "", nil, MUTED)
    UI.mainStatus:SetPoint("BOTTOMLEFT", 19, 9)
    UI.mainStatus:SetWidth(990)
    UI.RefreshTheme()
    UI.RefreshSettings()
    main:Hide()
end

local function squareAt(row, col, color)
    local file = color == "w" and col or 9 - col
    local rank = color == "w" and 9 - row or row
    return (rank - 1) * 8 + file
end

local function fitGameFrame(frame)
    local width, height = UIParent:GetWidth() - 24, UIParent:GetHeight() - 24
    if width > 0 and height > 0 then
        frame:SetScale(math.min(1, width / GAME_WIDTH, height / GAME_HEIGHT))
    end
end

local function makeGame()
    local frame = box(UIParent, GAME_WIDTH, GAME_HEIGHT)
    frame:SetPoint("CENTER")
    fitGameFrame(frame)
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    titlebar(frame, "WoW Chess · Partida", function() frame:Hide(); UI.ShowMain() end)
    UI.gameFrame = frame

    local left = box(frame, 208, 756)
    left:SetPoint("TOPLEFT", 12, -58)
    UI.opponentName = label(left, "", "large")
    UI.opponentName:SetPoint("TOPLEFT", 13, -20)
    UI.opponentName:SetWidth(182)
    UI.opponentClock = label(left, "10:00", "large")
    UI.opponentClock:SetPoint("TOPLEFT", 13, -52)
    UI.selfName = label(left, "", "large")
    UI.selfName:SetPoint("TOPLEFT", 13, -112)
    UI.selfName:SetWidth(182)
    UI.selfClock = label(left, "10:00", "large")
    UI.selfClock:SetPoint("TOPLEFT", 13, -144)
    UI.turnLabel = label(left, "", nil)
    UI.turnLabel:SetPoint("TOPLEFT", 13, -207)
    UI.turnLabel:SetWidth(182)
    UI.startLabel = label(left, "", nil, MUTED)
    UI.startLabel:SetPoint("TOPLEFT", 13, -242)
    UI.startLabel:SetWidth(182)
    UI.drawButton = button(left, "Ofrecer tablas", 180, 40, function() WC.Game.OfferDraw() end)
    UI.drawButton:SetPoint("BOTTOMLEFT", 13, 112)
    button(left, "Rendirse", 180, 40, function() WC.Game.Resign() end):SetPoint("BOTTOMLEFT", 13, 60)
    button(left, "Volver a la lista", 180, 38, function() frame:Hide(); UI.ShowMain() end):SetPoint("BOTTOMLEFT", 13, 12)

    local board = WC.Theme.board
    local boardWidth = 560
    local zoom = board.zoom or 1
    local cropX = board.imageWidth * (1 - 1 / zoom) / 2
    local cropY = board.imageHeight * (1 - 1 / zoom) / 2
    local scale = boardWidth * zoom / board.imageWidth
    local boardFrame = CreateFrame("Frame", nil, frame)
    boardFrame:SetSize(boardWidth, board.imageHeight * boardWidth / board.imageWidth)
    boardFrame:SetPoint("TOPLEFT", 232, -58)
    UI.boardFrame = boardFrame
    local boardImage = boardFrame:CreateTexture(nil, "BACKGROUND")
    boardImage:SetAllPoints()
    boardImage:SetTexture(WC.assetRoot .. board.path)
    boardImage:SetTexCoord(cropX / board.textureWidth, (board.imageWidth - cropX) / board.textureWidth,
        cropY / board.textureHeight, (board.imageHeight - cropY) / board.textureHeight)
    UI.boardImage = boardImage
    UI.classicBackground = colorTexture(boardFrame, "BACKGROUND", .16, .10, .08, 1)
    UI.classicBackground:SetAllPoints()
    local turnBadge = box(boardFrame, 242, 30)
    turnBadge:SetPoint("TOP", 0, -100)
    UI.boardTurn = label(turnBadge, "", nil, GOLD, "CENTER")
    UI.boardTurn:SetAllPoints()
    local cell = board.gridSize * scale / 8
    for row = 1, 8 do
        for col = 1, 8 do
            local square = CreateFrame("Button", nil, boardFrame)
            square:SetSize(cell, cell)
            square:SetPoint("TOPLEFT", (board.gridX - cropX) * scale + (col - 1) * cell,
                -((board.gridY - cropY) * scale + (row - 1) * cell))
            local tile = colorTexture(square, "BACKGROUND", 1, 1, 1, 1)
            checkerColor(tile, row, col)
            tile:SetAllPoints()
            local highlight = colorTexture(square, "ARTWORK", 1, .77, .12, .36)
            highlight:SetAllPoints()
            highlight:Hide()
            local dot = colorTexture(square, "OVERLAY", 1, .88, .33, .60)
            dot:SetSize(15, 15)
            dot:SetPoint("CENTER")
            dot:Hide()
            local piece = square:CreateTexture(nil, "OVERLAY")
            piece:SetSize(cell * 1.28, cell * 1.28)
            piece:SetPoint("CENTER")
            square.tile, square.highlight, square.dot, square.piece = tile, highlight, dot, piece
            square:SetScript("OnClick", function() UI.ClickSquare(square.boardSquare) end)
            UI.cells[#UI.cells + 1] = { frame = square, row = row, col = col }
        end
    end

    local right = box(frame, 332, 756)
    right:SetPoint("TOPRIGHT", -12, -58)
    local historyTitle = label(right, "Movimientos", "large")
    historyTitle:SetPoint("TOPLEFT", 14, -15)
    UI.moveLines = {}
    for i = 1, 12 do
        local line = label(right, "", nil, MUTED)
        line:SetPoint("TOPLEFT", 18, -47 - (i - 1) * 26)
        line:SetWidth(296)
        UI.moveLines[i] = line
    end
    local separator = colorTexture(right, "ARTWORK", .50, .36, .18, 1)
    separator:SetPoint("TOPLEFT", 10, -373)
    separator:SetPoint("TOPRIGHT", -10, -373)
    separator:SetHeight(1)
    local selectedTitle = label(right, "Pieza seleccionada", "large")
    selectedTitle:SetPoint("TOPLEFT", 14, -390)
    UI.selectedPiece = label(right, "Ninguna", nil, MUTED)
    UI.selectedPiece:SetPoint("TOPLEFT", 16, -430)
    UI.selectedPiece:SetWidth(300)
    local hint = label(right, "Elegí una pieza y luego una casilla marcada.", nil, MUTED)
    hint:SetPoint("TOPLEFT", 16, -485)
    hint:SetWidth(300)
    hint:SetWordWrap(true)
    UI.gameStatus = label(frame, "", nil, MUTED)
    UI.gameStatus:SetPoint("BOTTOMLEFT", 18, 10)
    UI.gameStatus:SetWidth(1124)
    UI.RefreshTheme()
    frame:Hide()
end

function UI.RefreshSettings()
    if UI.boardButtons then
        local selected = WC.Theme.Background().id
        for _, background in ipairs(WC.Theme.backgrounds) do
            UI.boardButtons[background.id]:SetCaption((selected == background.id and "[x] " or "") .. WC.L(background.name))
        end
    end
    if UI.languageButtons then
        for _, language in ipairs({ { "es", "Español" }, { "en", "Inglés" } }) do
            UI.languageButtons[language[1]]:SetCaption((WC.Language() == language[1] and "[x] " or "") .. WC.L(language[2]))
        end
    end
end

function UI.RefreshTheme()
    local background = WC.Theme.Background()
    local path = WC.Theme.BoardPath()
    local plain = not path
    if UI.boardImage then
        if path then UI.boardImage:SetTexture(path) end
        UI.boardImage:SetShown(not plain)
    end
    if UI.classicBackground then UI.classicBackground:SetShown(plain) end
    for _, entry in ipairs(UI.cells) do entry.frame.tile:SetShown(plain) end
    if UI.boardPreview then
        if path then UI.boardPreview:SetTexture(path) end
        UI.boardPreview:SetShown(not plain)
    end
    if UI.classicPreview then UI.classicPreview:SetShown(plain) end
    if UI.previewText then
        UI.previewText:SetText(WC.L(background.name) .. " · " .. WC.L("Humanos y orcos"))
    end
end

function UI.RefreshLanguage()
    for _, entry in ipairs(UI.localized) do entry.font:SetText(WC.L(entry.key)) end
    if UI.levelLabel then UI.levelLabel:SetText(WC.L("Nivel") .. " " .. tostring(UnitLevel("player") or "?")) end
    UI.RefreshTheme()
    UI.RefreshSettings()
    UI.RefreshPlayers()
    if WC.Game.active then UI.RefreshGame() end
    if UI.selected and WC.Game.active then
        local piece = WC.Game.active.state.board[UI.selected]
        if piece then UI.selectedPiece:SetText(WC.L(WC.Theme.names[piece:sub(2, 2)]) .. " · " .. WC.Chess.Name(UI.selected)) end
    end
    UI.SetStatus("")
end

local function modal(title, message, actions)
    local frame = box(UIParent, 380, 154)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    local heading = label(frame, title, "large")
    heading:SetPoint("TOP", 0, -18)
    local content = label(frame, message, nil, MUTED, "CENTER")
    content:SetPoint("TOP", 0, -55)
    content:SetWidth(345)
    for i, action in ipairs(actions) do
        local width = math.floor(344 / #actions) - 8
        local left = 18 + (i - 1) * (344 / #actions)
        button(frame, action[1], width, 34, function() frame:Hide(); action[2]() end):SetPoint("BOTTOMLEFT", left, 13)
    end
    return frame
end

function UI.ShowInvite(sender)
    UI.HideInvite()
    UI.invite = modal("Invitación de ajedrez", string.format(WC.L("%s te desafía a una partida de 10 minutos."), WC.ShortName(sender)), {
        { "Aceptar", WC.Game.AcceptInvite }, { "Rechazar", WC.Game.DeclineInvite },
    })
end

function UI.HideInvite()
    if UI.invite then UI.invite:Hide(); UI.invite = nil end
end

function UI.ShowDrawOffer()
    UI.HideDrawOffer()
    UI.draw = modal("Oferta de tablas", "Tu rival propone terminar la partida en tablas.", {
        { "Aceptar", WC.Game.AcceptDraw }, { "Rechazar", WC.Game.DeclineDraw },
    })
end

function UI.HideDrawOffer()
    if UI.draw then UI.draw:Hide(); UI.draw = nil end
end

function UI.ShowPromotion(from, to)
    if UI.promotion then UI.promotion:Hide() end
    UI.promotion = modal("Promoción", "Elegí la pieza nueva para tu peón.", {
        { "Dama", function() UI.SubmitMove(from, to, "Q") end },
        { "Torre", function() UI.SubmitMove(from, to, "R") end },
        { "Alfil", function() UI.SubmitMove(from, to, "B") end },
        { "Caballo", function() UI.SubmitMove(from, to, "N") end },
    })
end

function UI.RefreshPlayers()
    if not UI.main then return end
    local players = {}
    for _, info in pairs(WC.Network.players) do players[#players + 1] = info end
    table.sort(players, function(a, b) return a.name:lower() < b.name:lower() end)
    UI.emptyPlayers:SetShown(#players == 0)
    for i, row in ipairs(UI.playerRows) do
        local info = players[i]
        row:SetShown(info ~= nil)
        if info then
            row.target = info.name
            row.name:SetText(WC.ShortName(info.name))
            row.level:SetText(tostring(info.level))
            row.status:SetText(WC.L(info.status == "busy" and "En partida" or "Disponible"))
            row.challenge:SetShown(info.status ~= "busy")
        end
    end
    local stats = WC.db and WC.db.stats or { wins = 0, losses = 0, draws = 0 }
    UI.stats:SetText(string.format(WC.L("Victorias: %d\nDerrotas: %d\nTablas: %d"), stats.wins, stats.losses, stats.draws))
    UI.activeButton:SetShown(WC.Game.active ~= nil)
end

local function clockText(value)
    local seconds = math.max(0, math.ceil(value))
    return string.format("%02d:%02d", math.floor(seconds / 60), seconds % 60)
end

function UI.RefreshClocks()
    local game = WC.Game.active
    if not game or not UI.gameFrame:IsShown() then return end
    UI.selfClock:SetText(clockText(WC.Game.Remaining(game, game.color)))
    UI.opponentClock:SetText(clockText(WC.Game.Remaining(game, game.color == "w" and "b" or "w")))
end

function UI.RefreshBoard()
    local game = WC.Game.active
    if not game then return end
    for _, entry in ipairs(UI.cells) do
        local cell = entry.frame
        local square = squareAt(entry.row, entry.col, game.color)
        cell.boardSquare = square
        local piece = game.state.board[square]
        if piece then cell.piece:SetTexture(WC.Theme.PiecePath(piece)); cell.piece:Show()
        else cell.piece:Hide() end
        cell.highlight:SetShown(UI.selected == square)
        cell.dot:Hide()
        for _, move in ipairs(UI.legal) do
            if move.to == square then cell.dot:Show(); break end
        end
    end
end

function UI.RefreshGame()
    local game = WC.Game.active
    if not game then return end
    UI.drawButton:SetShown(game.mode ~= "bot")
    local function displayName(name)
        return WC.ShortName(game.mode == "bot" and name == game.opponent and WC.L(name) or name)
    end
    UI.selfName:SetText(WC.ShortName(WC.me) .. WC.L(game.color == "w" and " · Blancas" or " · Negras"))
    UI.opponentName:SetText(displayName(game.opponent) .. WC.L(game.color == "w" and " · Negras" or " · Blancas"))
    UI.startLabel:SetText(string.format(WC.L("Empieza: %s"), displayName(game.white)))
    local current = game.state.turn == game.color and WC.me or game.opponent
    UI.turnLabel:SetText(string.format(WC.L("> Turno de: %s"), displayName(current)))
    UI.boardTurn:SetText(string.format(WC.L(game.seq == 0 and "Empieza: %s" or "Turno: %s"), displayName(current)))
    UI.RefreshClocks()
    UI.RefreshBoard()
    local moves = game.state.moves
    local first = math.max(1, math.ceil(#moves / 2) - 11)
    for i, line in ipairs(UI.moveLines) do
        local pair = first + i - 1
        local white, black = moves[pair * 2 - 1], moves[pair * 2]
        line:SetText(white and (tostring(pair) .. ".  " .. white .. (black and "       " .. black or "")) or "")
    end
end

function UI.SubmitMove(from, to, promotion)
    local ok, err = WC.Game.PlayMove(from, to, promotion)
    if not ok then UI.SetStatus(err) end
    UI.selected, UI.legal = nil, {}
    UI.selectedPiece:SetText(WC.L("Ninguna"))
    UI.RefreshBoard()
end

function UI.ClickSquare(square)
    local game = WC.Game.active
    if not game or game.state.turn ~= game.color then return end
    UI.ClearMoveNotification()
    local piece = game.state.board[square]
    if UI.selected then
        for _, move in ipairs(UI.legal) do
            if move.to == square then
                if move.promotion then UI.ShowPromotion(UI.selected, square)
                else UI.SubmitMove(UI.selected, square) end
                return
            end
        end
    end
    if piece and piece:sub(1, 1) == game.color then
        UI.selected = square
        UI.legal = WC.Chess.LegalMoves(game.state, square)
        UI.selectedPiece:SetText(WC.L(WC.Theme.names[piece:sub(2, 2)]) .. " · " .. WC.Chess.Name(square))
    else
        UI.selected, UI.legal = nil, {}
        UI.selectedPiece:SetText(WC.L("Ninguna"))
    end
    UI.RefreshBoard()
end

function UI.ShowMain()
    UI.RefreshPlayers()
    UI.gameFrame:Hide()
    UI.SetMainSection(UI.mainSection)
    UI.main:Show()
end

function UI.ShowGame()
    if not WC.Game.active then return end
    UI.ClearMoveNotification()
    fitGameFrame(UI.gameFrame)
    UI.selected, UI.legal = nil, {}
    UI.main:Hide()
    UI.gameFrame:Show()
    UI.RefreshGame()
end

function UI.ShowResult(result)
    UI.HideDrawOffer()
    UI.selected, UI.legal = nil, {}
    local title = result.winner == nil and "Tablas" or (result.won and "Ganaste" or "Perdiste")
    if UI.resultModal then UI.resultModal:Hide() end
    UI.resultModal = modal(title, string.format(WC.L("Resultado: %s."), WC.L(result.reason)), {
        { "Volver", function() UI.gameFrame:Hide(); UI.ShowMain() end },
    })
    UI.RefreshPlayers()
end

function UI.Toggle()
    if UI.moveNotice and WC.Game.active then UI.ShowGame(); return end
    if UI.gameFrame and UI.gameFrame:IsShown() then UI.gameFrame:Hide(); return end
    if UI.main and UI.main:IsShown() then UI.main:Hide(); return end
    UI.ShowMain()
end

function UI.Initialize()
    makeMain()
    makeGame()
    UI.RefreshLanguage()
    local launcher = button(Minimap or UIParent, "C", 28, 28, UI.Toggle)
    launcher:SetPoint("BOTTOMLEFT", Minimap or UIParent, "BOTTOMLEFT", -6, -6)
    launcher:SetFrameStrata("MEDIUM")
    launcher.tooltip = function()
        return WC.L(UI.moveNotice and "Tu turno: el rival movió." or "Abrir WoW Chess")
    end
    UI.launcher = launcher
    local badge = box(launcher, 18, 18)
    badge:SetPoint("TOPRIGHT", 6, 6)
    badge:SetFrameLevel(launcher:GetFrameLevel() + 1)
    local symbol = label(badge, "!", nil, GOLD, "CENTER")
    symbol:SetAllPoints()
    UI.moveBadge = badge
    badge:SetShown(UI.moveNotice)
    UI.RefreshPlayers()
    UI.ShowMain()
end
