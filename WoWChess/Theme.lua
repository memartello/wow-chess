local _, WC = ...

-- Visual choices are independent of chess colors and player factions.
WC.Theme = {
    backgrounds = {
        { id = "square", name = "Cuadrado", path = "board_square.png", boardWidth = 630,
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
        { id = "durotar", name = "Durotar", path = "board_durotar.png",
            board = { imageWidth = 378, imageHeight = 505, textureWidth = 512, textureHeight = 512,
                gridX = 66, gridY = 139, gridSize = 262, zoom = 1.18 } },
        { id = "classic", name = "Clásico",
            board = { imageWidth = 378, imageHeight = 505, textureWidth = 512, textureHeight = 512,
                gridX = 66, gridY = 139, gridSize = 262, zoom = 1.18 } },
    },
    pieceSets = {
        { id = "basic", name = "Piezas básicas", sides = { w = "basic_white", b = "basic_black" } },
        { id = "factions", name = "Humanos y orcos", sides = { w = "human", b = "orc" } },
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

function WC.Theme.PieceSet()
    local id = WC.db and WC.db.settings and WC.db.settings.pieces or "basic"
    for _, set in ipairs(WC.Theme.pieceSets) do
        if set.id == id then return set end
    end
    return WC.Theme.pieceSets[1]
end

function WC.Theme.SetPieceSet(id)
    for _, set in ipairs(WC.Theme.pieceSets) do
        if set.id == id then
            WC.db.settings.pieces = id
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
    local side = WC.Theme.PieceSet().sides[piece:sub(1, 1)]
    return side and WC.assetRoot .. "pieces\\" .. side .. "_" .. piece:sub(2, 2) .. ".png" or nil
end
