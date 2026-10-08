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
    sides = { w = "human", b = "orc" },
    names = { P = "Peón", R = "Torre", N = "Caballo", B = "Alfil", Q = "Dama", K = "Rey" },
}

function WC.Theme.BoardPath()
    return WC.assetRoot .. WC.Theme.board.path
end

function WC.Theme.PiecePath(piece)
    if not piece then return nil end
    local race = WC.Theme.sides[piece:sub(1, 1)]
    return WC.assetRoot .. "pieces\\" .. race .. "_" .. piece:sub(2, 2) .. ".png"
end
