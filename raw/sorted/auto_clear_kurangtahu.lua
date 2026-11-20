--[[
    Simple Auto Clear World
    Created by @_kurangtahu_
]]

JANGAN_BREAK = {
    "My First World Lock",
    "World Lock",
    "Bedrock",
    "Blank",
    "Main Door"
}

SKIP_BREAK = {}
for _, val in pairs(JANGAN_BREAK) do
    SKIP_BREAK[findItemID(val)] = true
end

function punchTile(x, y)
    local player = getLocal()
    sendPacketRaw(false, {
        type = 3,
        value = 18,
        x = player.posX,
        y = player.posY,
        px = x,
        py = y
    })
end

function breakTile(x, y, id)
    while true do
        local player = getLocal()
        if math.abs(player.posX // 32 - x) <= 2 and math.abs(player.posY // 32 - y - 1) <= 2 then break end
        if FindPath(x, y - 1) then return end
        randomSleep(100, 300)
    end
    
    while true do
        local tile = getTile(x, y)
        if tile.fg ~= id and tile.bg ~= id then break end
        punchTile(x, y)
        randomSleep(50, 200)
    end
end

function startClear()
    for _, tile in pairs(getTiles()) do
        if not SKIP_BREAK[tile.fg] then
            breakTile(tile.x, tile.y, tile.fg)
        end
        if not SKIP_BREAK[tile.bg] and getTile(tile.x, tile.y).fg == 0 then
            breakTile(tile.x, tile.y, tile.bg)
        end
    end
end

LogToConsole("`4[ `c@_kurangtahu_`4] `1Simple Auto Clear World")
editToggle("ModFly", true)
startClear()