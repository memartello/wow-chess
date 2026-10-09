local _, WC = ...

-- Visual choices are independent of chess colors and player factions.
WC.Theme = {
    windowSizes = {
        { id = "small", name = "Pequeño", scale = .85 },
        { id = "normal", name = "Normal", scale = 1 },
        { id = "large", name = "Grande", scale = 1.15 },
    },
    backgrounds = {
        { id = "square", name = "Alianza", path = "board_square.png", boardWidth = 630,
            board = { imageWidth = 1024, imageHeight = 1024, textureWidth = 1024, textureHeight = 1024,
                gridX = 77, gridY = 77, gridSize = 870 } },
        { id = "horde", name = "Horda", path = "board_horde.png", boardWidth = 630,
            board = { imageWidth = 1024, imageHeight = 1024, textureWidth = 1024, textureHeight = 1024,
                gridX = 110, gridY = 96, gridSize = 806, zoom = 1.08 } },
        { id = "undead", name = "No-muertos", path = "board_undead.png", boardWidth = 630,
            board = { imageWidth = 1024, imageHeight = 1024, textureWidth = 1024, textureHeight = 1024,
                gridX = 110, gridY = 110, gridSize = 800 } },
        { id = "elves", name = "Elfos", path = "board_elves.png", boardWidth = 630,
            board = { imageWidth = 1024, imageHeight = 1024, textureWidth = 1024, textureHeight = 1024,
                gridX = 112, gridY = 126, gridSize = 800 } },
        { id = "classic", name = "Clásico",
            board = { imageWidth = 378, imageHeight = 505, textureWidth = 512, textureHeight = 512,
                gridX = 66, gridY = 139, gridSize = 262, zoom = 1.18 } },
    },
    pieceStyles = {
        { id = "basic", name = "Básicas", sideNames = { w = "Alianza", b = "Horda" },
            sides = { w = "basic_white", b = "basic_black" } },
        { id = "human", name = "Humanos", sides = { w = "human_white", b = "human_black" } },
        { id = "orc", name = "Orcos", sides = { w = "orc_white", b = "orc_black" } },
        { id = "elf", name = "Elfos", sides = { w = "elf_light", b = "elf_dark" } },
        { id = "undead", name = "No-muertos", sides = { w = "undead_white", b = "undead_black" } },
    },
    legacyPieceSets = {
        basic = { w = "basic", b = "basic" },
        factions = { w = "human", b = "orc" },
        elves_undead = { w = "elf", b = "undead" },
        elven = { w = "elf", b = "elf" },
    },
    names = { P = "Peón", R = "Torre", N = "Caballo", B = "Alfil", Q = "Dama", K = "Rey" },
}

function WC.Theme.DefaultBackgroundId()
    local faction = UnitFactionGroup and UnitFactionGroup("player")
    return faction == "Horde" and "horde" or "square"
end

function WC.Theme.Background()
    local id = WC.db and WC.db.settings and WC.db.settings.board
    if not id then id = WC.Theme.DefaultBackgroundId() end
    for _, background in ipairs(WC.Theme.backgrounds) do
        if background.id == id then return background end
    end
    if WC.db and WC.db.settings then WC.db.settings.board = nil end
    local fallback = WC.Theme.DefaultBackgroundId()
    for _, background in ipairs(WC.Theme.backgrounds) do
        if background.id == fallback then return background end
    end
    return WC.Theme.backgrounds[1]
end

function WC.Theme.Board()
    return WC.Theme.Background().board
end

function WC.Theme.SetBackground(id)
    for _, background in ipairs(WC.Theme.backgrounds) do
        if background.id == id then
            WC.db.settings.board = id
            return true
        end
    end
    return false
end

function WC.Theme.BoardPath()
    local path = WC.Theme.Background().path
    return path and WC.assetRoot .. path or nil
end

local function migratePieces()
    local settings = WC.db and WC.db.settings
    if not settings or not settings.pieces then return end
    local pair = WC.Theme.legacyPieceSets[settings.pieces]
    if pair then
        if not settings.whitePieces then settings.whitePieces = pair.w end
        if not settings.blackPieces then settings.blackPieces = pair.b end
    end
    settings.pieces = nil
end

function WC.Theme.PieceStyle(color)
    if color ~= "w" and color ~= "b" then return nil end
    migratePieces()
    local settings = WC.db and WC.db.settings
    local id = settings and settings[color == "w" and "whitePieces" or "blackPieces"]
    for _, style in ipairs(WC.Theme.pieceStyles) do
        if style.id == id then return style end
    end
    return WC.Theme.pieceStyles[1]
end

function WC.Theme.PieceStyleName(style, color)
    return style.sideNames and style.sideNames[color] or style.name
end

function WC.Theme.WindowSize()
    local id = WC.db and WC.db.settings and WC.db.settings.windowSize
    for _, size in ipairs(WC.Theme.windowSizes) do
        if size.id == id then return size end
    end
    return WC.Theme.windowSizes[2]
end

function WC.Theme.SetWindowSize(id)
    for _, size in ipairs(WC.Theme.windowSizes) do
        if size.id == id then
            WC.db.settings.windowSize = id
            return true
        end
    end
    return false
end

function WC.Theme.FrameOpacity()
    local value = WC.db and WC.db.settings and tonumber(WC.db.settings.frameOpacity)
    return value and value >= .4 and value <= 1 and value or 1
end

function WC.Theme.SetFrameOpacity(value)
    value = tonumber(value)
    if not value or value < .4 or value > 1 then return false end
    WC.db.settings.frameOpacity = value
    return true
end

function WC.Theme.SetPieceStyle(color, id)
    if color ~= "w" and color ~= "b" then return false end
    migratePieces()
    for _, style in ipairs(WC.Theme.pieceStyles) do
        if style.id == id then
            WC.db.settings[color == "w" and "whitePieces" or "blackPieces"] = id
            return true
        end
    end
    return false
end

function WC.Theme.CoordinatesEnabled()
    return not (WC.db and WC.db.settings and WC.db.settings.coordinates == false)
end

function WC.Theme.SetCoordinatesEnabled(enabled)
    WC.db.settings.coordinates = not not enabled
    return true
end

function WC.Theme.PiecePath(piece)
    if not piece then return nil end
    local color = piece:sub(1, 1)
    local style = WC.Theme.PieceStyle(color)
    local side = style and style.sides[color]
    return side and WC.assetRoot .. "pieces\\" .. side .. "_" .. piece:sub(2, 2) .. ".png" or nil
end
