local _, WC = ...

-- Visual choices are independent of chess colors and player factions.
WC.Theme = {
    board = {
        path = "board_durotar.png",
        imageWidth = 378, imageHeight = 505,
        textureWidth = 512, textureHeight = 512,
        gridX = 66, gridY = 139, gridSize = 262,
        zoom = 1.18,
    },
    backgrounds = {
        { id = "durotar", name = "Durotar", path = "board_durotar.png" },
        { id = "classic", name = "Clásico" },
    },
    sides = { w = "human", b = "orc" },
    names = { P = "Peón", R = "Torre", N = "Caballo", B = "Alfil", Q = "Dama", K = "Rey" },
}

function WC.Theme.Background()
    local id = WC.db and WC.db.settings and WC.db.settings.board or "durotar"
    for _, background in ipairs(WC.Theme.backgrounds) do
        if background.id == id then return background end
    end
    return WC.Theme.backgrounds[1]
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

function WC.Theme.PiecePath(piece)
    if not piece then return nil end
    local race = WC.Theme.sides[piece:sub(1, 1)]
    return WC.assetRoot .. "pieces\\" .. race .. "_" .. piece:sub(2, 2) .. ".png"
end
