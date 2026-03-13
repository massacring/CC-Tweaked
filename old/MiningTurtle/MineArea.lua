local MassaLib = require('MassaMainLib')
local MiningLib = require('MassaMiningTurtleLib')

local VERTICALS = {
    UP = 1,
    DOWN = 2,
}

local HORIZONTALS = {
    LEFT = 1,
    RIGHT = 2,
}

local x,z,y = -1,0,0

local depth = 1
local width = 1
local height = 1

local verticalDirection = VERTICALS.UP
local horizontalDirection = HORIZONTALS.LEFT

local path = {}

local function tutorial()
    print("How to use the VerticalMining script.")
    sleep(2)
    print("")
    print("[] means required.")
    sleep(2)
    print("<> means optional.")
    sleep(2)
    print("bool means either true or false.")
    sleep(2)
    print("")
    print("Vertical direction can be either 'up' or 'down'.")
    sleep(2)
    print("Horizontal direction can be either 'left' or 'right'.")
    sleep(2)
    print("By default the vertical direction is 'up' and the horizontal direction is 'left'.")
    sleep(3)
    print("")
    print("MineArea [depth: number] [width: number] [height: number] <verticalDirection: text> <horizontalDirection: text>")
    sleep(5)
end

local function addPos(posX, posZ, posY)
    x = x + posX
    z = z + posZ
    y = y + posY
    table.insert(path, { x = x, z = z, y = y })
end

local function loopSlice(layer)
    for i = 1, width, 1 do
        for j = 1, depth-1, 1 do

            local evenWidth = width % 2 -- 1 for even, 0 for odd
            local oddLayer = (layer + 1) % 2 -- 1 for odd, 0 for even

            local startAdditive
            if evenWidth==1 then startAdditive = oddLayer
            else startAdditive = evenWidth end

            local parity = (i % 2 + startAdditive) % 2 == 1

            addPos((parity and 1 or -1),0,0)
        end
        if i == width then break end
        addPos(0,layer%2==1 and 1 or -1,0)
    end
end

local function calculatePath()
    local slices = math.floor(height/3) -- 2
    local leftoverSlice = height % 3 -- 1

    table.insert(path, { x = x, z = z, y = y })
    addPos(1,0,0)
    if slices > 0 then addPos(0,0,1) end

    for i = 1, slices, 1 do
        loopSlice(i)
        if i == slices then break end
        for _ = 1, 3, 1 do
            y = y + 1
            table.insert(path, { x = x, z = z, y = y })
        end
    end

    if slices > 0 then
        for _ = 1, leftoverSlice, 1 do
            addPos(0,0,1)
        end
    end

    if leftoverSlice > 0 then loopSlice(slices+1) end

    if slices > 0 then
        for _ = 1, leftoverSlice, 1 do
            addPos(0,0,-1)
        end
    end

    while y > 0 do
        addPos(0,0,-1)
    end

    while x > 0 do
        addPos(-1,0,0)
    end

    while z > 0 do
        addPos(0,-1,0)
    end

    addPos(-1,0,0)

    --[[
    for _,coords in ipairs(path) do
        print(coords.x .. "," .. coords.z .. "," .. coords.y)
        --sleep(0.25)
    end
    --]]
end

local function relativeTurn(normal)
    if horizontalDirection == HORIZONTALS.LEFT then
        if normal then MiningLib.face(MiningLib.DIRECTIONS.LEFT)
        else MiningLib.face(MiningLib.DIRECTIONS.RIGHT) end
    else
        if normal then MiningLib.face(MiningLib.DIRECTIONS.RIGHT)
        else MiningLib.face(MiningLib.DIRECTIONS.LEFT) end
    end
end

local function relativeElevation(normal)
    if verticalDirection == VERTICALS.UP then
        if normal then MiningLib.digAndMoveUp(true)
        else MiningLib.digAndMoveDown(true) end
    else
        if normal then MiningLib.digAndMoveDown(true)
        else MiningLib.digAndMoveUp(true) end
    end
end

local function navigatePath()
    local oldX, oldZ, oldY
    for _,coords in ipairs(path) do
        local relativeX, relativeZ, relativeY
        if not oldX or not oldZ or not oldY then goto continue end
        relativeX = coords.x - oldX
        relativeZ = coords.z - oldZ
        relativeY = coords.y - oldY

        if x ~= -1 then
            if verticalDirection == VERTICALS.UP then
                if y > 0 then turtle.digDown() end
                if y < height-1 then turtle.digUp() end
            else
                if y > 0 then turtle.digUp() end
                if y < height-1 then turtle.digDown() end
            end
        end

        if relativeX > 0 then
            MiningLib.face(MiningLib.DIRECTIONS.FRONT)
            MiningLib.digAndMoveForward(true)
        elseif relativeX < 0 then
            MiningLib.face(MiningLib.DIRECTIONS.BACK)
            MiningLib.digAndMoveForward(true)
        elseif relativeZ > 0 then
            relativeTurn(true)
            MiningLib.digAndMoveForward(true)
        elseif relativeZ < 0 then
            relativeTurn(false)
            MiningLib.digAndMoveForward(true)
        elseif relativeY > 0 then
            relativeElevation(true)
        elseif relativeY < 0 then
            relativeElevation(false)
        end

        ::continue::
        x,z,y = coords.x, coords.z, coords.y
        oldX = x
        oldZ = z
        oldY = y
    end
end

local function init()
    if arg[1] == "help" then return true end
    depth = tonumber(arg[1]) or error("Depth requires a number argument.", 0)
    width = tonumber(arg[2]) or error("Width requires a number argument.", 0)
    height = tonumber(arg[3]) or error("Height requires a number argument.", 0)
    if depth < 1 then error("Depth must be positive and greater than 0.", 0) end
    if width < 1 then error("Width must be positive and greater than 0.", 0) end
    if height < 1 then error("Height must be positive and greater than 0.", 0) end
    if arg[4] and string.lower(arg[4]) == "down" then verticalDirection = VERTICALS.DOWN
    elseif arg[4] and string.lower(arg[4]) ~= "up" then warn("Vertical direction invalid, selecting 'up' by default.") end
    if arg[5] and string.lower(arg[5]) == "right" then horizontalDirection = HORIZONTALS.RIGHT
    elseif arg[5] and string.lower(arg[5]) ~= "left" then warn("Horizontal direction invalid, selecting 'left' by default.") end
    MiningLib.broadcast("Area size: " .. tostring(depth) .. "x" .. tostring(width) .. "x" .. tostring(height))
    MiningLib.broadcast("Mining " .. (verticalDirection == 1 and 'up' or 'down') .. " and to the " .. (horizontalDirection == 1 and 'left' or 'right') .. ".")

    calculatePath()
    navigatePath()
end

local guide = init()
if guide then tutorial() end