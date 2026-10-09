local _, WC = ...
local UI = { selected = nil, legal = {}, cells = {}, playerRows = {}, localized = {}, mainSection = "home", moveNotice = false }
WC.UI = UI

local GOLD = { .98, .77, .31, 1 }
local MUTED = { .73, .68, .60, 1 }
local INK = { .20, .12, .055, 1 }
local PANEL = { .075, .065, .06, .96 }
local RED = { .40, .075, .055, 1 }
local GAME_WIDTH, GAME_HEIGHT = 1010, 850
local HOME_PANEL = "panel_dark.png"
local HOME_BUTTONS = { red = "button_red.png", gold = "button_gold.png", dark = "button_dark.png" }

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
    frame.border, frame.fill = border, fill
    return frame
end

-- The source art is kept in power-of-two textures for the Forever client.
-- Split the frame into nine pieces so corners retain their shape at any size.
local function skinPanel(frame, center, cap, layer, openTop)
    frame.border:Hide()
    frame.fill:Hide()
    cap = cap or 18
    local source = { 0, 30 / 512, (386 - 30) / 512, 386 / 512 }
    local vertical = { 0, 30 / 512, (378 - 30) / 512, 378 / 512 }
    local pieces = {}
    for row = 1, 3 do
        for col = 1, 3 do
            if (center or row ~= 2 or col ~= 2) and (not openTop or row ~= 1) then
                local part = frame:CreateTexture(nil, layer or "BORDER")
                part:SetTexture(WC.assetRoot .. HOME_PANEL)
                part:SetTexCoord(source[col], source[col + 1], vertical[row], vertical[row + 1])
                if row == 1 then part:SetPoint("TOP", 0, 0); part:SetHeight(cap)
                elseif row == 3 then part:SetPoint("BOTTOM", 0, 0); part:SetHeight(cap)
                else part:SetPoint("TOP", 0, openTop and 0 or -cap); part:SetPoint("BOTTOM", 0, cap) end
                if col == 1 then part:SetPoint("LEFT", 0, 0); part:SetWidth(cap)
                elseif col == 3 then part:SetPoint("RIGHT", 0, 0); part:SetWidth(cap)
                else part:SetPoint("LEFT", cap, 0); part:SetPoint("RIGHT", -cap, 0) end
                pieces[#pieces + 1] = part
            end
        end
    end
    frame.skinPieces = pieces
end

local function setButtonTone(frame, tone)
    frame.warcraftTone = tone
    for _, part in ipairs(frame.warcraftSlices or {}) do
        part:SetTexture(WC.assetRoot .. HOME_BUTTONS[tone])
    end
    if frame.caption then
        if frame.disabled then frame.caption:SetTextColor(unpack(MUTED))
        elseif tone == "gold" then frame.caption:SetTextColor(.16, .09, .025, 1)
        else frame.caption:SetTextColor(unpack(GOLD)) end
    end
end

-- Three slices preserve the metal end caps when a button is narrow or wide.
local function skinButton(frame, tone)
    frame.background:Hide()
    local cap = math.min(25, math.floor(frame:GetHeight() * .38))
    local source = { 0, 54 / 512, (314 - 54) / 512, 314 / 512 }
    local pieces = {}
    for i = 1, 3 do
        local part = frame:CreateTexture(nil, "BACKGROUND")
        part:SetTexCoord(source[i], source[i + 1], 0, 70 / 128)
        part:SetPoint("TOP", 0, 0)
        part:SetPoint("BOTTOM", 0, 0)
        if i == 1 then part:SetPoint("LEFT", 0, 0); part:SetWidth(cap)
        elseif i == 3 then part:SetPoint("RIGHT", 0, 0); part:SetWidth(cap)
        else part:SetPoint("LEFT", cap, 0); part:SetPoint("RIGHT", -cap, 0) end
        pieces[i] = part
    end
    frame.warcraftSlices = pieces
    frame.warcraftBase = tone or "red"
    setButtonTone(frame, frame.warcraftBase)
    return frame
end

local function label(parent, text, size, color, justify)
    local template = size == "large" and "GameFontNormalLarge" or
        (size == "small" and "GameFontNormalSmall" or "GameFontNormal")
    local fs = parent:CreateFontString(nil, "OVERLAY", template)
    fs:SetText(WC.L(text or ""))
    fs:SetTextColor(unpack(color or GOLD))
    fs:SetJustifyH(justify or "LEFT")
    if text and text ~= "" then UI.localized[#UI.localized + 1] = { font = fs, key = text } end
    return fs
end

local function button(parent, text, width, height, onClick, disabled)
    local frame = CreateFrame("Button", nil, parent)
    frame:SetSize(width, height)
    frame.disabled = disabled
    local bg = colorTexture(frame, "BACKGROUND", disabled and .16 or RED[1], disabled and .14 or RED[2], disabled and .12 or RED[3], 1)
    bg:SetAllPoints()
    frame.background = bg
    local title = label(frame, text, nil, disabled and MUTED or GOLD, "CENTER")
    title:SetAllPoints()
    frame:SetScript("OnClick", disabled and nil or onClick)
    frame:SetScript("OnEnter", function(self)
        if self.warcraftSlices then
            if not disabled then setButtonTone(self, "gold") end
        elseif not disabled then bg:SetColorTexture(.59, .15, .08, 1) end
        if disabled then GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText(WC.L("Próximamente")); GameTooltip:Show() end
        if self.tooltip then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.tooltip())
            GameTooltip:Show()
        end
    end)
    frame:SetScript("OnLeave", function()
        if frame.warcraftSlices then setButtonTone(frame, frame.warcraftBase)
        else bg:SetColorTexture(disabled and .16 or RED[1], disabled and .14 or RED[2], disabled and .12 or RED[3], 1) end
        GameTooltip:Hide()
    end)
    frame.SetCaption = function(_, caption) title:SetText(caption) end
    frame.caption = title
    return frame
end

local function addIcon(frame, asset, size, inset)
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(WC.assetRoot .. asset)
    icon:SetSize(size, size)
    icon:SetPoint("LEFT", inset, 0)
    frame.caption:ClearAllPoints()
    frame.caption:SetPoint("LEFT", icon, "RIGHT", 4, 0)
    frame.caption:SetPoint("RIGHT", -7, 0)
    frame.caption:SetJustifyH("CENTER")
    return icon
end

local function historyButton(parent, x, y, width)
    local control = CreateFrame("Button", nil, parent)
    control:SetSize(width, 22)
    control:SetPoint("TOPLEFT", x, y)
    local selection = colorTexture(control, "BACKGROUND", .78, .53, .18, .38)
    selection:SetAllPoints()
    selection:Hide()
    local caption = label(control, "", nil, MUTED)
    caption:SetAllPoints()
    caption:SetJustifyV("MIDDLE")
    control.caption, control.selection = caption, selection
    control:SetScript("OnEnter", function(self)
        if self.moveIndex then self.caption:SetTextColor(unpack(GOLD)) end
    end)
    control:SetScript("OnLeave", function(self)
        self.caption:SetTextColor(unpack(self.moveIndex and UI.highlightedMove == self.moveIndex and GOLD or MUTED))
    end)
    control:SetScript("OnClick", function(self) UI.SelectHistoryMove(self.moveIndex) end)
    return control
end

local function titlebar(frame, text, close)
    local title = label(frame, text, "large")
    title:SetPoint("TOPLEFT", 18, -13)
    local closeButton = button(frame, "X", 28, 26, close)
    closeButton:SetPoint("TOPRIGHT", -10, -9)
    skinButton(closeButton, "red")
    local line = colorTexture(frame, "ARTWORK", .55, .38, .18, 1)
    line:SetPoint("TOPLEFT", 8, -43)
    line:SetPoint("TOPRIGHT", -8, -43)
    line:SetHeight(1)
    return closeButton
end

function UI.SetStatus(message)
    local translated = WC.L(message or "")
    if UI.mainStatus then UI.mainStatus:SetText(translated) end
    if UI.gameStatus then UI.gameStatus:SetText(translated) end
end

function UI.RefreshProfilePortrait()
    if UI.profilePortrait and SetPortraitTexture then
        SetPortraitTexture(UI.profilePortrait, "player")
    end
end

function UI.NotifyOpponentMove()
    local game = WC.Game.active
    if not game or game.state.outcome or game.state.turn ~= game.color or UI.moveNotice then return end
    UI.moveNotice = true
    if PlaySound then pcall(PlaySound, SOUNDKIT and SOUNDKIT.UI_GROUP_FINDER_RECEIVE_APPLICATION or 47615) end
    if UI.moveBorderGlow then UI.moveBorderGlow:Show() end
    if UI.moveGlow then UI.moveGlow:Show() end
    if UI.movePulse then UI.movePulse:Play() end
end

function UI.ClearMoveNotification()
    UI.moveNotice = false
    if UI.movePulse then UI.movePulse:Stop() end
    if UI.moveGlow then UI.moveGlow:Hide() end
    if UI.moveBorderGlow then UI.moveBorderGlow:Hide() end
end

function UI.SetMainSection(section)
    UI.mainSection = section == "options" and "options" or "home"
    if UI.homeContent then UI.homeContent:SetShown(UI.mainSection == "home") end
    if UI.optionsContent then UI.optionsContent:SetShown(UI.mainSection == "options") end
    for _, entry in ipairs(UI.mainNav or {}) do
        entry.button.warcraftBase = entry.section == UI.mainSection and "gold" or "dark"
        setButtonTone(entry.button, entry.button.warcraftBase)
    end
    if UI.mainSection == "options" then UI.RefreshSettings() end
end

local function isOwnDiscovery(info, sender)
    return WC.IsOwnPresence(info.name) or WC.IsOwnPresence(sender)
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
    local main = box(UIParent, 1040, 700)
    skinPanel(main, true, 24)
    main:SetPoint("CENTER")
    main:SetFrameStrata("DIALOG")
    main:SetMovable(true)
    main:EnableMouse(true)
    main:RegisterForDrag("LeftButton")
    main:SetScript("OnDragStart", main.StartMoving)
    main:SetScript("OnDragStop", main.StopMovingOrSizing)
    titlebar(main, "WoW Chess", function() main:Hide() end)
    UI.main = main

    local sidebar = box(main, 174, 620)
    sidebar:SetPoint("TOPLEFT", 12, -56)
    skinPanel(sidebar, true, 17)
    local menus = {
        { text = "Jugar", section = "home", enabled = true, icon = "icon_quick_match.png" },
        { text = "Opciones", section = "options", enabled = true, icon = "icon_settings.png" },
    }
    UI.mainNav = {}
    for i, item in ipairs(menus) do
        local menu = item
        local menuButton = button(sidebar, menu.text, 150, 48, function()
            if menu.section then UI.SetMainSection(menu.section) end
        end, not menu.enabled)
        menuButton:SetPoint("TOPLEFT", 12, -14 - (i - 1) * 59)
        skinButton(menuButton, menu.enabled and (menu.section == "home" and "gold" or "dark") or "dark")
        addIcon(menuButton, menu.icon, 26, 12)
        UI.mainNav[#UI.mainNav + 1] = { button = menuButton, section = menu.section }
    end

    local content = box(main, 600, 620)
    content:SetPoint("TOPLEFT", 195, -56)
    content.fill:Hide()
    local parchment = content:CreateTexture(nil, "BACKGROUND")
    parchment:SetTexture(WC.assetRoot .. "home_parchment.png")
    parchment:SetPoint("TOPLEFT", 2, -152)
    parchment:SetPoint("BOTTOMRIGHT", -2, 2)
    UI.homeParchment = parchment
    UI.homeContent = content
    skinPanel(content, false, 10, "OVERLAY", true)
    local banner = box(content, 600, 136)
    banner:SetPoint("TOPLEFT", 0, -12)
    local bannerImage = banner:CreateTexture(nil, "ARTWORK")
    bannerImage:SetTexture(WC.assetRoot .. "home_banner.png")
    bannerImage:SetTexCoord(0, 590 / 1024, 0, 136 / 256)
    bannerImage:SetSize(594, 130)
    bannerImage:SetPoint("TOPLEFT", 3, -3)
    local caption = colorTexture(banner, "OVERLAY", .025, .02, .015, .88)
    caption:SetPoint("BOTTOMLEFT", 3, 3)
    caption:SetPoint("BOTTOMRIGHT", -3, 3)
    caption:SetHeight(72)
    local bannerTitle = label(banner, "Desafiá jugadores de Azeroth", "large")
    bannerTitle:SetPoint("BOTTOMLEFT", 16, 44)
    local bannerText = label(banner, "Ajedrez en tiempo real dentro de WoW: Forever.", nil, MUTED)
    bannerText:SetPoint("BOTTOMLEFT", 16, 20)
    skinPanel(banner, false, 13, "OVERLAY")

    local quick = button(content, "Jugar con bot", 176, 60, function() UI.ShowBotSetup() end)
    quick:SetPoint("TOPLEFT", 12, -160)
    skinButton(quick, "red")
    addIcon(quick, "icon_bot.png", 36, 14)
    local direct = box(content, 184, 60)
    direct:SetPoint("TOPLEFT", 207, -160)
    skinPanel(direct, true, 10)
    local directTitle = label(direct, "Nombre completo", nil)
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
    local quickMatch = button(content, "Partida rápida", 176, 60, function()
        local available = {}
        for sender, player in pairs(WC.Network.players) do
            if player.status ~= "busy" and not isOwnDiscovery(player, sender) then
                available[#available + 1] = player
            end
        end
        if #available == 0 then
            UI.SetStatus("No hay jugadores disponibles para partida rápida.")
            return
        end
        local target = available[math.random(#available)].name
        local ok, err = WC.Game.Challenge(target)
        if not ok then UI.SetStatus(err) end
    end)
    quickMatch:SetPoint("TOPLEFT", 410, -160)
    skinButton(quickMatch, "red")
    addIcon(quickMatch, "icon_quick_match.png", 36, 14)

    local section = label(content, "Jugadores disponibles", "large")
    section:SetPoint("TOPLEFT", 17, -238)
    local refresh = button(content, "", 32, 30, function()
        WC.Network.AskWho()
        UI.SetStatus("Buscando jugadores...")
    end)
    refresh:SetPoint("TOPRIGHT", -17, -230)
    skinButton(refresh, "dark")
    local refreshIcon = refresh:CreateTexture(nil, "ARTWORK")
    refreshIcon:SetTexture("Interface\\Buttons\\UI-RefreshButton")
    refreshIcon:SetSize(22, 22)
    refreshIcon:SetPoint("CENTER")
    refresh.tooltip = function() return WC.L("Actualizar") end
    UI.refreshPlayersButton = refresh
    local playerList = CreateFrame("Frame", nil, content)
    playerList:SetSize(568, 340)
    playerList:SetPoint("TOPLEFT", 16, -265)
    UI.playerList = playerList
    local headerPanel = box(playerList, 566, 27)
    headerPanel:SetPoint("TOPLEFT", 1, -23)
    skinPanel(headerPanel, true, 8)
    UI.playerHeaderPanel = headerPanel
    local columns = { name = 10, level = 287, status = 350 }
    UI.playerHeaders = {}
    for _, entry in ipairs({ { "name", "Personaje", 260 }, { "level", "Nivel", 40 }, { "status", "Estado", 95 } }) do
        local key, text, width = entry[1], entry[2], entry[3]
        local header = label(headerPanel, text, nil, GOLD, key == "level" and "CENTER" or "LEFT")
        header:SetPoint("LEFT", columns[key], 0)
        header:SetWidth(width)
        UI.playerHeaders[key] = header
    end
    for i = 1, 8 do
        local row = box(playerList, 566, 31)
        row.border:Hide()
        row.fill:SetColorTexture(.25, .14, .055, .32)
        if i % 2 == 0 then row.fill:Hide() end
        row:SetPoint("TOPLEFT", 1, -52 - (i - 1) * 33)
        row.name = label(row, "", nil, INK)
        row.name:SetPoint("LEFT", columns.name, 0)
        row.name:SetWidth(260)
        row.name:SetWordWrap(false)
        row.level = label(row, "", nil, INK)
        row.level:SetPoint("LEFT", columns.level, 0)
        row.level:SetWidth(40)
        row.level:SetJustifyH("CENTER")
        row.status = label(row, "", nil, INK)
        row.status:SetPoint("LEFT", columns.status, 0)
        row.status:SetWidth(95)
        row.challenge = button(row, "Retar", 85, 25, function()
            if row.target then
                local ok, err = WC.Game.Challenge(row.target)
                if not ok then UI.SetStatus(err) end
            end
        end)
        row.challenge:SetPoint("RIGHT", -4, 0)
        skinButton(row.challenge, "red")
        if i < 8 then
            local divider = colorTexture(row, "ARTWORK", .27, .18, .10, .42)
            divider:SetPoint("BOTTOMLEFT", 6, -1)
            divider:SetPoint("BOTTOMRIGHT", -6, -1)
            divider:SetHeight(1)
            row.divider = divider
        end
        UI.playerRows[i] = row
    end
    local empty = label(playerList, "Buscando usuarios del addon en el canal...", nil, INK)
    empty:SetPoint("TOPLEFT", 12, -60)
    UI.emptyPlayers = empty

    local right = box(main, 224, 620)
    right:SetPoint("TOPRIGHT", -12, -56)
    skinPanel(right, true, 17)
    local profileTitle = label(right, "Tu perfil", "large")
    profileTitle:SetPoint("TOPLEFT", 12, -14)
    local portraitFrame = box(right, 62, 62)
    portraitFrame:SetPoint("TOPLEFT", 8, -42)
    portraitFrame.fill:SetColorTexture(.025, .02, .015, 1)
    local portrait = portraitFrame:CreateTexture(nil, "ARTWORK")
    portrait:SetPoint("TOPLEFT", 3, -3)
    portrait:SetPoint("BOTTOMRIGHT", -3, 3)
    UI.profilePortrait = portrait
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
    skinButton(UI.activeButton, "red")
    local previewTitle = label(right, "Tablero inicial", "large")
    previewTitle:SetPoint("TOPLEFT", 12, -306)
    local preview = right:CreateTexture(nil, "ARTWORK")
    preview:SetSize(142, 190)
    preview:SetPoint("TOP", 0, -344)
    UI.boardPreview = preview
    UI.classicPreview = checkerPreview(right, 142, -367)
    UI.previewText = label(right, "", nil, MUTED, "CENTER")
    UI.previewText:SetPoint("BOTTOM", 0, 15)
    for _, top in ipairs({ 164, 291 }) do
        local rule = colorTexture(right, "ARTWORK", .68, .43, .17, .75)
        rule:SetPoint("TOPLEFT", 13, -top)
        rule:SetPoint("TOPRIGHT", -13, -top)
        rule:SetHeight(1)
    end

    local options = box(main, 600, 620)
    options:SetPoint("TOPLEFT", 195, -56)
    skinPanel(options, true, 17)
    UI.optionsContent = options
    local optionsTitle = label(options, "Opciones", "large")
    optionsTitle:SetPoint("TOPLEFT", 20, -22)
    local boardTitle = label(options, "Tablero", "large")
    boardTitle:SetPoint("TOPLEFT", 20, -82)
    local boardHint = label(options, "Elegí el fondo del tablero.", nil, MUTED)
    boardHint:SetPoint("TOPLEFT", 20, -114)
    UI.boardButtons = {}
    for i, background in ipairs(WC.Theme.backgrounds) do
        local choice = button(options, background.name, 180, 44, function()
            WC.Theme.SetBackground(background.id)
            UI.RefreshTheme()
            UI.RefreshSettings()
        end)
        local column, row = (i - 1) % 3, math.floor((i - 1) / 3)
        choice:SetPoint("TOPLEFT", 20 + column * 190, -135 - row * 50)
        skinButton(choice, "dark")
        UI.boardButtons[background.id] = choice
    end
    local piecesTitle = label(options, "Piezas", "large")
    piecesTitle:SetPoint("TOPLEFT", 20, -247)
    local piecesHint = label(options, "Elegí el aspecto de las piezas.", nil, MUTED)
    piecesHint:SetPoint("TOPLEFT", 20, -277)
    UI.pieceButtons = {}
    for i, set in ipairs(WC.Theme.pieceSets) do
        local choice = button(options, set.name, 254, 48, function()
            WC.Theme.SetPieceSet(set.id)
            UI.RefreshTheme()
            UI.RefreshSettings()
        end)
        choice:SetPoint("TOPLEFT", 20 + (i - 1) * 274, -308)
        skinButton(choice, "dark")
        UI.pieceButtons[set.id] = choice
    end
    local languageTitle = label(options, "Idioma", "large")
    languageTitle:SetPoint("TOPLEFT", 20, -380)
    local languageHint = label(options, "Elegí el idioma de la interfaz.", nil, MUTED)
    languageHint:SetPoint("TOPLEFT", 20, -410)
    UI.languageButtons = {}
    for i, choice in ipairs({ { "es", "Español" }, { "en", "Inglés" } }) do
        local language = choice[1]
        local selection = button(options, choice[2], 254, 54, function()
            WC.SetLanguage(language)
            UI.RefreshLanguage()
        end)
        selection:SetPoint("TOPLEFT", 20 + (i - 1) * 274, -441)
        skinButton(selection, "dark")
        UI.languageButtons[language] = selection
    end
    local coordinateTitle = label(options, "Coordenadas del tablero", "large")
    coordinateTitle:SetPoint("TOPLEFT", 20, -502)
    UI.coordinateButton = button(options, "", 254, 42, function()
        WC.Theme.SetCoordinatesEnabled(not WC.Theme.CoordinatesEnabled())
        UI.RefreshCoordinates()
        UI.RefreshSettings()
    end)
    UI.coordinateButton:SetPoint("TOPLEFT", 20, -529)
    skinButton(UI.coordinateButton, "dark")
    local applyHint = label(options, "Los cambios se aplican de inmediato.", nil, MUTED)
    applyHint:SetPoint("TOPLEFT", 20, -574)
    options:Hide()

    UI.mainStatus = label(main, "", nil, MUTED)
    UI.mainStatus:SetPoint("BOTTOMLEFT", 19, 9)
    UI.mainStatus:SetWidth(840)
    UI.versionLabel = label(main, "v" .. WC.ADDON_VERSION, nil, MUTED, "RIGHT")
    UI.versionLabel:SetPoint("BOTTOMRIGHT", -19, 9)
    UI.versionLabel:SetWidth(150)
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
    skinPanel(frame, true, 24)
    frame:SetPoint("CENTER")
    fitGameFrame(frame)
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    UI.gameCloseButton = titlebar(frame, "WoW Chess · Partida", function() UI.CloseGame() end)
    UI.gameFrame = frame

    local boardFrame = CreateFrame("Frame", nil, frame)
    UI.boardFrame = boardFrame
    local boardImage = boardFrame:CreateTexture(nil, "BACKGROUND")
    boardImage:SetAllPoints()
    UI.boardImage = boardImage
    UI.classicBackground = colorTexture(boardFrame, "BACKGROUND", .16, .10, .08, 1)
    UI.classicBackground:SetAllPoints()
    local function playerBar()
        local bar = box(frame, 630, 56)
        skinPanel(bar, true, 10)
        local glow = {}
        local function glowEdge(point, relativePoint, x, y, axis, thickness, alpha)
            local edge = bar:CreateTexture(nil, "ARTWORK")
            edge:SetColorTexture(1, .78, .24, alpha)
            edge:SetPoint(point, bar, relativePoint, x, y)
            if axis == "horizontal" then
                edge:SetPoint(point == "TOPLEFT" and "TOPRIGHT" or "BOTTOMRIGHT", bar,
                    point == "TOPLEFT" and "TOPRIGHT" or "BOTTOMRIGHT", -x, y)
                edge:SetHeight(thickness)
            else
                edge:SetPoint(point == "TOPLEFT" and "BOTTOMLEFT" or "BOTTOMRIGHT", bar,
                    point == "TOPLEFT" and "BOTTOMLEFT" or "BOTTOMRIGHT", x, -y)
                edge:SetWidth(thickness)
            end
            edge:Hide()
            glow[#glow + 1] = edge
        end
        -- Soft gold light is built from translucent strips around the edge only.
        glowEdge("TOPLEFT", "TOPLEFT", -2, 2, "horizontal", 3, .16)
        glowEdge("BOTTOMLEFT", "BOTTOMLEFT", -2, -2, "horizontal", 3, .16)
        glowEdge("TOPLEFT", "TOPLEFT", -2, 2, "vertical", 3, .16)
        glowEdge("TOPRIGHT", "TOPRIGHT", 2, 2, "vertical", 3, .16)
        glowEdge("TOPLEFT", "TOPLEFT", 0, 0, "horizontal", 2, .28)
        glowEdge("BOTTOMLEFT", "BOTTOMLEFT", 0, 0, "horizontal", 2, .28)
        glowEdge("TOPLEFT", "TOPLEFT", 0, 0, "vertical", 2, .28)
        glowEdge("TOPRIGHT", "TOPRIGHT", 0, 0, "vertical", 2, .28)
        bar.glow = glow
        local name = label(bar, "", "large")
        name:SetPoint("TOPLEFT", 12, -6)
        name:SetWidth(188)
        local clock = label(bar, "10:00", "large", GOLD, "RIGHT")
        clock:SetPoint("TOPRIGHT", -12, -6)
        clock:SetWidth(90)
        local missing = label(bar, "Piezas perdidas:", nil, MUTED)
        missing:SetPoint("TOPLEFT", 12, -32)
        local icons = {}
        for i = 1, 15 do
            local icon = bar:CreateTexture(nil, "ARTWORK")
            icon:SetSize(24, 24)
            icon:SetPoint("TOPLEFT", 130 + (i - 1) * 27, -29)
            icon:Hide()
            icons[i] = icon
        end
        return bar, name, clock, icons
    end
    UI.opponentBar, UI.opponentName, UI.opponentClock, UI.opponentLostIcons = playerBar()
    UI.selfBar, UI.selfName, UI.selfClock, UI.selfLostIcons = playerBar()
    local turnBadge = box(UI.opponentBar, 160, 26)
    skinPanel(turnBadge, true, 8)
    UI.turnBadge = turnBadge
    turnBadge:SetPoint("TOP", 0, -3)
    UI.boardTurn = label(turnBadge, "", nil, GOLD, "CENTER")
    UI.boardTurn:SetAllPoints()
    for row = 1, 8 do
        for col = 1, 8 do
            local square = CreateFrame("Button", nil, boardFrame)
            local tile = colorTexture(square, "BACKGROUND", 1, 1, 1, 1)
            checkerColor(tile, row, col)
            tile:SetAllPoints()
            local highlight = colorTexture(square, "ARTWORK", 1, .77, .12, .36)
            highlight:SetAllPoints()
            highlight:Hide()
            local moveFrom = colorTexture(square, "ARTWORK", 1, .66, .16, .42)
            moveFrom:SetAllPoints()
            moveFrom:Hide()
            local moveTo = colorTexture(square, "ARTWORK", .53, .90, .32, .52)
            moveTo:SetAllPoints()
            moveTo:Hide()
            local dot = colorTexture(square, "OVERLAY", 1, .88, .33, .60)
            dot:SetSize(15, 15)
            dot:SetPoint("CENTER")
            dot:Hide()
            local piece = square:CreateTexture(nil, "OVERLAY")
            piece:SetPoint("CENTER")
            square.tile, square.highlight, square.moveFrom, square.moveTo, square.dot, square.piece =
                tile, highlight, moveFrom, moveTo, dot, piece
            square:SetScript("OnClick", function() UI.ClickSquare(square.boardSquare) end)
            UI.cells[#UI.cells + 1] = { frame = square, row = row, col = col }
        end
    end
    UI.coordinateLabels = {}
    for row = 1, 8 do
        local square = UI.cells[(row - 1) * 8 + 1].frame
        local rank = label(square, "", "small", GOLD, "CENTER")
        rank:SetSize(20, 18)
        if rank.SetShadowColor then rank:SetShadowColor(0, 0, 0, 1); rank:SetShadowOffset(1, -1) end
        UI.coordinateLabels[#UI.coordinateLabels + 1] = { font = rank, square = square, axis = "rank", position = row }
    end
    for col = 1, 8 do
        local square = UI.cells[56 + col].frame
        local file = label(square, "", "small", GOLD, "CENTER")
        file:SetSize(20, 18)
        if file.SetShadowColor then file:SetShadowColor(0, 0, 0, 1); file:SetShadowOffset(1, -1) end
        UI.coordinateLabels[#UI.coordinateLabels + 1] = { font = file, square = square, axis = "file", position = col }
    end

    local right = box(frame, 332, 756)
    right:SetPoint("TOPRIGHT", -12, -58)
    skinPanel(right, true, 17)
    local historyTitle = label(right, "Movimientos", "large")
    historyTitle:SetPoint("TOPLEFT", 14, -15)
    UI.moveRows = {}
    for i = 1, 12 do
        local y = -47 - (i - 1) * 26
        local white = historyButton(right, 53, y, 116)
        local black = historyButton(right, 177, y, 116)
        local number = label(right, "", nil, MUTED)
        number:SetSize(32, 22)
        number:SetPoint("RIGHT", white, "LEFT", -4, 0)
        number:SetJustifyH("RIGHT")
        number:SetJustifyV("MIDDLE")
        UI.moveRows[i] = {
            number = number,
            white = white,
            black = black,
        }
    end
    local separator = colorTexture(right, "ARTWORK", .50, .36, .18, 1)
    separator:SetPoint("TOPLEFT", 10, -373)
    separator:SetPoint("TOPRIGHT", -10, -373)
    separator:SetHeight(1)
    local actionsSeparator = colorTexture(right, "ARTWORK", .50, .36, .18, 1)
    actionsSeparator:SetPoint("TOPLEFT", 10, -535)
    actionsSeparator:SetPoint("TOPRIGHT", -10, -535)
    actionsSeparator:SetHeight(1)
    local selectedTitle = label(right, "Pieza seleccionada", "large")
    selectedTitle:SetPoint("TOPLEFT", 14, -390)
    UI.selectedPiece = label(right, "Ninguna", nil, MUTED)
    UI.selectedPiece:SetPoint("TOPLEFT", 16, -430)
    UI.selectedPiece:SetWidth(300)
    UI.startLabel = label(right, "", nil, MUTED)
    UI.startLabel:SetPoint("TOPLEFT", 16, -463)
    UI.startLabel:SetWidth(300)
    local hint = label(right, "Elegí una pieza y luego una casilla marcada.", nil, MUTED)
    hint:SetPoint("TOPLEFT", 16, -495)
    hint:SetWidth(300)
    hint:SetWordWrap(true)
    UI.resignButton = button(right, "Rendirse", 300, 40, function() WC.Game.Resign() end)
    UI.resignButton:SetPoint("TOPLEFT", 16, -552)
    skinButton(UI.resignButton, "red")
    UI.drawButton = button(right, "Ofrecer tablas", 300, 40, function() WC.Game.OfferDraw() end)
    UI.drawButton:SetPoint("TOPLEFT", 16, -604)
    skinButton(UI.drawButton, "dark")
    UI.backButton = button(right, "Volver a la lista", 300, 38, function() frame:Hide(); UI.ShowMain() end)
    UI.backButton:SetPoint("TOPLEFT", 16, -656)
    skinButton(UI.backButton, "dark")
    UI.gameStatus = label(frame, "", nil, MUTED)
    UI.gameStatus:SetPoint("BOTTOMLEFT", 18, 10)
    UI.gameStatus:SetWidth(974)
    UI.RefreshTheme()
    frame:Hide()
end

function UI.RefreshSettings()
    if UI.boardButtons then
        local selected = WC.Theme.Background().id
        for _, background in ipairs(WC.Theme.backgrounds) do
            local choice = UI.boardButtons[background.id]
            choice:SetCaption(WC.L(background.name))
            choice.warcraftBase = selected == background.id and "gold" or "dark"
            setButtonTone(choice, choice.warcraftBase)
        end
    end
    if UI.pieceButtons then
        local selected = WC.Theme.PieceSet().id
        for _, set in ipairs(WC.Theme.pieceSets) do
            local choice = UI.pieceButtons[set.id]
            choice:SetCaption(WC.L(set.name))
            choice.warcraftBase = selected == set.id and "gold" or "dark"
            setButtonTone(choice, choice.warcraftBase)
        end
    end
    if UI.languageButtons then
        for _, language in ipairs({ { "es", "Español" }, { "en", "Inglés" } }) do
            local choice = UI.languageButtons[language[1]]
            choice:SetCaption(WC.L(language[2]))
            choice.warcraftBase = WC.Language() == language[1] and "gold" or "dark"
            setButtonTone(choice, choice.warcraftBase)
        end
    end
    if UI.coordinateButton then
        local enabled = WC.Theme.CoordinatesEnabled()
        local state = enabled and "Activadas" or "Desactivadas"
        UI.coordinateButton:SetCaption(WC.L("Coordenadas") .. ": " .. WC.L(state))
        UI.coordinateButton.warcraftBase = enabled and "gold" or "dark"
        setButtonTone(UI.coordinateButton, UI.coordinateButton.warcraftBase)
    end
end

function UI.RefreshCoordinates()
    if not UI.coordinateLabels or not UI.boardFrame then return end
    local game = WC.Game.active
    local enabled = game ~= nil and WC.Theme.CoordinatesEnabled()
    local color = game and game.color or "w"
    for _, entry in ipairs(UI.coordinateLabels) do
        local font = entry.font
        font:ClearAllPoints()
        if entry.axis == "rank" then
            local rank = color == "w" and 9 - entry.position or entry.position
            font:SetText(tostring(rank))
            font:SetPoint("TOPLEFT", entry.square, "TOPLEFT", 4, -4)
        else
            local file = color == "w" and entry.position or 9 - entry.position
            font:SetText(string.char(96 + file))
            font:SetPoint("BOTTOMRIGHT", entry.square, "BOTTOMRIGHT", -4, 4)
        end
        font:SetShown(enabled)
    end
end

function UI.RefreshTheme()
    local background = WC.Theme.Background()
    local board = WC.Theme.Board()
    local path = WC.Theme.BoardPath()
    local plain = not path
    local boardWidth = background.boardWidth or 560
    local boardHeight = 630
    local zoom = board.zoom or 1
    local cropX = board.imageWidth * (1 - 1 / zoom) / 2
    local scale = boardWidth * zoom / board.imageWidth
    local cropY = (board.imageHeight - boardHeight / scale) / 2
    local gridX, gridY = (board.gridX - cropX) * scale, (board.gridY - cropY) * scale
    local cell = board.gridSize * scale / 8
    if UI.boardFrame then
        UI.boardFrame:SetSize(boardWidth, boardHeight)
        UI.boardFrame:ClearAllPoints()
        UI.boardFrame:SetPoint("TOPLEFT", 12 + (630 - boardWidth) / 2,
            -(58 + (756 - boardHeight) / 2))
        UI.boardImage:SetTexCoord(cropX / board.textureWidth, (board.imageWidth - cropX) / board.textureWidth,
            cropY / board.textureHeight, (board.imageHeight - cropY) / board.textureHeight)
        UI.opponentBar:SetWidth(boardWidth)
        UI.opponentBar:ClearAllPoints()
        UI.opponentBar:SetPoint("BOTTOMLEFT", UI.boardFrame, "TOPLEFT", 0, 7)
        UI.selfBar:SetWidth(boardWidth)
        UI.selfBar:ClearAllPoints()
        UI.selfBar:SetPoint("TOPLEFT", UI.boardFrame, "BOTTOMLEFT", 0, -7)
        for _, entry in ipairs(UI.cells) do
            local square = entry.frame
            square:SetSize(cell, cell)
            square:ClearAllPoints()
            square:SetPoint("TOPLEFT", gridX + (entry.col - 1) * cell, -(gridY + (entry.row - 1) * cell))
            square.piece:SetSize(cell * 1.04, cell * 1.04)
        end
    end
    if UI.boardImage then
        if path then UI.boardImage:SetTexture(path) end
        UI.boardImage:SetShown(not plain)
    end
    if UI.classicBackground then UI.classicBackground:SetShown(plain) end
    for _, entry in ipairs(UI.cells) do entry.frame.tile:SetShown(plain) end
    if UI.boardPreview then
        if path then
            UI.boardPreview:SetTexture(path)
            UI.boardPreview:SetTexCoord(0, board.imageWidth / board.textureWidth,
                0, board.imageHeight / board.textureHeight)
            UI.boardPreview:SetSize(142, 142 * board.imageHeight / board.imageWidth)
        end
        UI.boardPreview:SetShown(not plain)
    end
    if UI.classicPreview then UI.classicPreview:SetShown(plain) end
    if UI.previewText then
        UI.previewText:SetText(WC.L(background.name) .. " · " .. WC.L(WC.Theme.PieceSet().name))
    end
    UI.RefreshCoordinates()
    if WC.Game.active and UI.cells[1] then UI.RefreshGame() end
end

function UI.RefreshLanguage()
    for _, entry in ipairs(UI.localized) do entry.font:SetText(WC.L(entry.key)) end
    if UI.levelLabel then UI.levelLabel:SetText(WC.L("Nivel") .. " " .. tostring(UnitLevel("player") or "?")) end
    UI.RefreshTheme()
    UI.RefreshSettings()
    UI.RefreshPlayers()
    if UI.botSetup and UI.botSetup:IsShown() then UI.RefreshBotSetup() end
    if WC.Game.active then UI.RefreshGame() end
    if UI.selected and WC.Game.active then
        local piece = WC.Game.active.state.board[UI.selected]
        if piece then UI.selectedPiece:SetText(WC.L(WC.Theme.names[piece:sub(2, 2)]) .. " · " .. WC.Chess.Name(UI.selected)) end
    end
    UI.SetStatus("")
end

local function modal(title, message, actions)
    local frame = box(UIParent, 380, 154)
    skinPanel(frame, true, 16)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    local heading = label(frame, title, "large")
    heading:SetPoint("TOP", 0, -18)
    local content = label(frame, message, nil, MUTED, "CENTER")
    content:SetPoint("TOP", 0, -55)
    content:SetWidth(345)
    local rule = colorTexture(frame, "ARTWORK", .68, .43, .17, .75)
    rule:SetPoint("TOPLEFT", 17, -45)
    rule:SetPoint("TOPRIGHT", -17, -45)
    rule:SetHeight(1)
    frame.actionButtons = {}
    for i, action in ipairs(actions) do
        local width = math.floor(344 / #actions) - 8
        local left = 18 + (i - 1) * (344 / #actions)
        local choice = button(frame, action[1], width, 34, function() frame:Hide(); action[2]() end)
        choice:SetPoint("BOTTOMLEFT", left, 13)
        skinButton(choice, i == 1 and "red" or "dark")
        frame.actionButtons[i] = choice
    end
    return frame
end

function UI.RefreshBotSetup()
    local setup = UI.botSetup
    if not setup then return end
    for _, option in ipairs(setup.difficultyButtons) do
        option.button:SetCaption(WC.L(option.label))
        option.button.warcraftBase = setup.difficulty == option.value and "gold" or "dark"
        setButtonTone(option.button, option.button.warcraftBase)
    end
    for _, option in ipairs(setup.colorButtons) do
        option.button:SetCaption(WC.L(option.label))
        option.button.warcraftBase = setup.color == option.value and "gold" or "dark"
        setButtonTone(option.button, option.button.warcraftBase)
    end
end

function UI.ShowBotSetup()
    if UI.botSetup then
        UI.botSetup:Show()
        UI.RefreshBotSetup()
        return
    end
    local frame = box(UIParent, 430, 240)
    skinPanel(frame, true, 17)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    UI.botSetup = frame
    local title = label(frame, "Configurar partida contra bot", "large", GOLD, "CENTER")
    title:SetPoint("TOP", 0, -16)
    local difficultyTitle = label(frame, "Elegí la dificultad.", nil, MUTED, "CENTER")
    difficultyTitle:SetPoint("TOP", 0, -50)
    frame.difficulty = "intermediate"
    frame.color = "w"
    frame.difficultyButtons = {}
    for i, option in ipairs({
        { value = "easy", label = "Fácil" },
        { value = "intermediate", label = "Intermedio" },
        { value = "hard", label = "Difícil" },
    }) do
        local choice = button(frame, option.label, 124, 34, function()
            frame.difficulty = option.value
            UI.RefreshBotSetup()
        end)
        choice:SetPoint("TOPLEFT", 20 + (i - 1) * 133, -71)
        skinButton(choice, "dark")
        frame.difficultyButtons[#frame.difficultyButtons + 1] = { button = choice, value = option.value, label = option.label }
    end
    local colorTitle = label(frame, "Elegí tu color.", nil, MUTED, "CENTER")
    colorTitle:SetPoint("TOP", 0, -120)
    frame.colorButtons = {}
    for i, option in ipairs({
        { value = "w", label = "Blancas" },
        { value = "b", label = "Negras" },
    }) do
        local choice = button(frame, option.label, 176, 34, function()
            frame.color = option.value
            UI.RefreshBotSetup()
        end)
        choice:SetPoint("TOPLEFT", 27 + (i - 1) * 190, -142)
        skinButton(choice, "dark")
        frame.colorButtons[#frame.colorButtons + 1] = { button = choice, value = option.value, label = option.label }
    end
    local start = button(frame, "Empezar partida", 176, 36, function()
        frame:Hide()
        local ok, err = WC.Game.StartBot(frame.difficulty, frame.color)
        if not ok then UI.SetStatus(err) end
    end)
    start:SetPoint("BOTTOMLEFT", 27, 12)
    skinButton(start, "red")
    local cancel = button(frame, "Cancelar", 176, 36, function() frame:Hide() end)
    cancel:SetPoint("BOTTOMRIGHT", -27, 12)
    skinButton(cancel, "dark")
    UI.RefreshBotSetup()
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
    for sender, info in pairs(WC.Network.players) do
        if not isOwnDiscovery(info, sender) then players[#players + 1] = info end
    end
    table.sort(players, function(a, b) return a.name:lower() < b.name:lower() end)
    UI.emptyPlayers:SetShown(#players == 0)
    for i, row in ipairs(UI.playerRows) do
        local info = players[i]
        row:SetShown(info ~= nil)
        if info then
            row.target = info.name
            row.name:SetText(WC.DiscoveryDisplayName(info.name))
            row.level:SetText(tostring(info.level))
            row.status:SetText(WC.L(info.status == "busy" and "En partida" or "Disponible"))
            row.challenge:SetShown(info.status ~= "busy")
        else
            row.target = nil
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
    local move = UI.highlightedMove and game.state.moveDetails and game.state.moveDetails[UI.highlightedMove]
    for _, entry in ipairs(UI.cells) do
        local cell = entry.frame
        local square = squareAt(entry.row, entry.col, game.color)
        cell.boardSquare = square
        local piece = game.state.board[square]
        if piece then cell.piece:SetTexture(WC.Theme.PiecePath(piece)); cell.piece:Show()
        else cell.piece:Hide() end
        cell.highlight:SetShown(UI.selected == square)
        cell.moveFrom:SetShown(move ~= nil and move.from == square)
        cell.moveTo:SetShown(move ~= nil and move.to == square)
        cell.dot:Hide()
        for _, move in ipairs(UI.legal) do
            if move.to == square then cell.dot:Show(); break end
        end
    end
end

local function refreshLostPieces(game)
    local lost = { w = {}, b = {} }
    for _, move in ipairs(game.state.moveDetails or {}) do
        local captured = move.captured
        if captured and lost[captured:sub(1, 1)] then
            local pieces = lost[captured:sub(1, 1)]
            pieces[#pieces + 1] = captured
        end
    end
    local opponentColor = game.color == "w" and "b" or "w"
    for _, row in ipairs({ { UI.opponentLostIcons, lost[opponentColor] }, { UI.selfLostIcons, lost[game.color] } }) do
        for i, icon in ipairs(row[1]) do
            local piece = row[2][i]
            if piece then icon:SetTexture(WC.Theme.PiecePath(piece)); icon:Show()
            else icon:Hide() end
        end
    end
end

local function highlightPlayerBar(bar, name, clock, active)
    if active then
        bar.border:SetColorTexture(1, .82, .24, 1)
        for _, edge in ipairs(bar.glow) do edge:Show() end
    else
        bar.border:SetColorTexture(.55, .38, .18, 1)
        for _, edge in ipairs(bar.glow) do edge:Hide() end
    end
    bar.fill:SetColorTexture(unpack(PANEL))
    name:SetTextColor(unpack(active and GOLD or MUTED))
    clock:SetTextColor(unpack(active and GOLD or MUTED))
end

function UI.RefreshGame()
    local game = WC.Game.active
    if not game then return end
    if UI.highlightedMove and (UI.highlightedGameId ~= game.id or UI.highlightedAtSeq ~= game.seq) then
        UI.highlightedMove = nil
    end
    UI.drawButton:SetShown(game.mode ~= "bot")
    UI.backButton:ClearAllPoints()
    UI.backButton:SetPoint("TOPLEFT", 16, game.mode == "bot" and -604 or -656)
    local function displayName(name)
        return WC.ShortName(game.mode == "bot" and name == game.opponent and WC.L(name) or name)
    end
    UI.selfName:SetText(WC.ShortName(WC.me) .. WC.L(game.color == "w" and " · Blancas" or " · Negras"))
    UI.opponentName:SetText(displayName(game.opponent) .. WC.L(game.color == "w" and " · Negras" or " · Blancas"))
    UI.startLabel:SetText(string.format(WC.L("Empieza: %s"), displayName(game.white)))
    local current = game.state.turn == game.color and WC.me or game.opponent
    UI.boardTurn:SetText(string.format(WC.L(game.seq == 0 and "Empieza: %s" or "Turno: %s"), displayName(current)))
    local activeColor = not game.state.outcome and game.state.turn or nil
    local selfTurn = activeColor == game.color
    local opponentTurn = activeColor ~= nil and not selfTurn
    highlightPlayerBar(UI.selfBar, UI.selfName, UI.selfClock, selfTurn)
    highlightPlayerBar(UI.opponentBar, UI.opponentName, UI.opponentClock, opponentTurn)
    if activeColor then
        local activeBar = selfTurn and UI.selfBar or UI.opponentBar
        UI.turnBadge:SetParent(activeBar)
        UI.turnBadge:ClearAllPoints()
        UI.turnBadge:SetPoint("TOP", activeBar, "TOP", 0, -3)
    end
    UI.turnBadge:SetShown(activeColor ~= nil)
    UI.RefreshClocks()
    UI.RefreshBoard()
    UI.RefreshCoordinates()
    refreshLostPieces(game)
    local moves = game.state.moves
    local first = math.max(1, math.ceil(#moves / 2) - 11)
    for i, row in ipairs(UI.moveRows) do
        local pair = first + i - 1
        local white, black = moves[pair * 2 - 1], moves[pair * 2]
        row.number:SetText(white and (tostring(pair) .. ".") or "")
        for _, entry in ipairs({ { row.white, white, pair * 2 - 1 }, { row.black, black, pair * 2 } }) do
            local control, notation, index = entry[1], entry[2], entry[3]
            control.moveIndex = notation and index or nil
            control:SetShown(notation ~= nil)
            control.caption:SetText(notation or "")
            control.caption:SetTextColor(unpack(UI.highlightedMove == index and GOLD or MUTED))
            control.selection:SetShown(UI.highlightedMove == index and notation ~= nil)
        end
    end
end

function UI.SelectHistoryMove(index)
    local game = WC.Game.active
    if not game or not index or not game.state.moveDetails or not game.state.moveDetails[index] then return end
    UI.highlightedMove = index
    UI.highlightedGameId = game.id
    UI.highlightedAtSeq = game.seq
    UI.selected, UI.legal = nil, {}
    UI.selectedPiece:SetText(WC.L("Ninguna"))
    UI.RefreshGame()
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
    UI.highlightedMove = nil
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
    UI.RefreshGame()
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

function UI.CloseGame()
    UI.gameFrame:Hide()
    UI.main:Hide()
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
    if WC.Game.active then
        if UI.moveNotice then UI.ShowGame(); return end
        if UI.gameFrame:IsShown() and not UI.main:IsShown() then UI.CloseGame()
        else UI.ShowGame() end
        return
    end
    if UI.gameFrame and UI.gameFrame:IsShown() then UI.gameFrame:Hide(); return end
    if UI.main and UI.main:IsShown() then UI.main:Hide(); return end
    UI.ShowMain()
end

local function positionLauncher(angle)
    local minimap = Minimap or UIParent
    local x, y = math.cos(math.rad(angle)), math.sin(math.rad(angle))
    local width, height = minimap:GetWidth() / 2 + 5, minimap:GetHeight() / 2 + 5
    if GetMinimapShape and GetMinimapShape() == "SQUARE" then
        local edge = math.max(math.abs(x), math.abs(y))
        x, y = x / edge, y / edge
    end
    UI.launcher:ClearAllPoints()
    UI.launcher:SetPoint("CENTER", minimap, "CENTER", x * width, y * height)
end

local function cursorMinimapAngle()
    local minimap = Minimap or UIParent
    local centerX, centerY = minimap:GetCenter()
    local cursorX, cursorY = GetCursorPosition()
    local scale = minimap:GetEffectiveScale()
    if not centerX or not centerY or not scale or scale <= 0 then return nil end
    local dx, dy = cursorX / scale - centerX, cursorY / scale - centerY
    if dx == 0 and dy == 0 then return nil end
    return math.deg(math.atan2(dy, dx)) % 360
end

function UI.Initialize()
    makeMain()
    UI.RefreshProfilePortrait()
    makeGame()
    UI.RefreshLanguage()
    local launcher = CreateFrame("Button", nil, Minimap or UIParent)
    launcher:SetSize(31, 31)
    launcher:SetFrameStrata("MEDIUM")
    UI.launcher = launcher
    local savedAngle = WC.db and WC.db.settings and tonumber(WC.db.settings.minimapAngle)
    UI.minimapAngle = savedAngle and savedAngle >= 0 and savedAngle < 360 and savedAngle or 225
    positionLauncher(UI.minimapAngle)
    local background = launcher:CreateTexture(nil, "BACKGROUND")
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    background:SetSize(20, 20)
    background:SetPoint("TOPLEFT", 7, -5)
    local icon = launcher:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(WC.assetRoot .. "minimap_icon.png")
    icon:SetSize(17, 17)
    icon:SetPoint("TOPLEFT", 7, -6)
    local border = launcher:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT")
    local borderGlow = launcher:CreateTexture(nil, "OVERLAY", nil, 1)
    borderGlow:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    borderGlow:SetSize(53, 53)
    borderGlow:SetPoint("TOPLEFT", border, "TOPLEFT")
    borderGlow:SetBlendMode("ADD")
    borderGlow:SetAlpha(.42)
    borderGlow:Hide()
    local glow = launcher:CreateTexture(nil, "OVERLAY", nil, 2)
    glow:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    glow:SetSize(53, 53)
    glow:SetPoint("TOPLEFT", border, "TOPLEFT")
    glow:SetBlendMode("ADD")
    glow:SetVertexColor(1, .78, .32)
    glow:Hide()
    local pulse = glow:CreateAnimationGroup()
    pulse:SetLooping("REPEAT")
    local brighten = pulse:CreateAnimation("Alpha")
    brighten:SetOrder(1)
    brighten:SetDuration(.45)
    brighten:SetFromAlpha(.06)
    brighten:SetToAlpha(1)
    local dim = pulse:CreateAnimation("Alpha")
    dim:SetOrder(2)
    dim:SetDuration(.55)
    dim:SetFromAlpha(1)
    dim:SetToAlpha(.06)
    launcher:RegisterForDrag("LeftButton")
    launcher:SetScript("OnDragStart", function(self)
        self.dragging = true
        GameTooltip:Hide()
        self:SetScript("OnUpdate", function()
            local angle = cursorMinimapAngle()
            if angle then UI.minimapAngle = angle; positionLauncher(angle) end
        end)
    end)
    launcher:SetScript("OnDragStop", function(self)
        local angle = cursorMinimapAngle()
        if angle then UI.minimapAngle = angle; positionLauncher(angle) end
        self:SetScript("OnUpdate", nil)
        self.dragging = false
        self.dragEnded = GetTime()
        WC.db.settings.minimapAngle = UI.minimapAngle
    end)
    launcher:SetScript("OnClick", function(self)
        if self.dragging or (self.dragEnded and GetTime() - self.dragEnded < .2) then return end
        UI.Toggle()
    end)
    launcher:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.tooltip())
        GameTooltip:AddLine(WC.L("Arrastrá para mover por el borde del minimapa."), .8, .7, .5, true)
        GameTooltip:Show()
    end)
    launcher:SetScript("OnLeave", function() GameTooltip:Hide() end)
    launcher.tooltip = function()
        return WC.L(UI.moveNotice and "Tu turno: el rival movió." or "Abrir WoW Chess")
    end
    UI.launcherIcon = icon
    UI.launcherBorder = border
    UI.moveBorderGlow = borderGlow
    UI.moveGlow = glow
    UI.movePulse = pulse
    UI.RefreshPlayers()
    UI.ShowMain()
end
