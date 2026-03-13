local TurtleLib = require('MassaTurtleLib')
local MiningLib = require('MassaMiningTurtleLib')

local DIRECTIONS = {
    LEFT = 1,
    RIGHT = 2,
}

local x,z = -1,0

local depth = 1
local width = 1

local direction = DIRECTIONS.LEFT

local path = {}

local function tutorial()
    print("How to use the Prepfarm script.")
    sleep(2)
    print("")
    print("[] means required.")
    print("<> means optional.")
    print("bool means either true or false.")
    sleep(2)
    print("")
    print("Direction can be either 'left' or 'right'.")
    sleep(2)
    print("By default the direction is 'left'.")
    sleep(3)
    print("")
    print("PrepFarm [depth: number] [width: number] <horizontalDirection: text>")
    sleep(5)
end

local function addPos(posX, posZ)
    x = x + posX
    z = z + posZ
    table.insert(path, { x = x, z = z })
end

local function loopSlice()
    for i = 1, width, 1 do
        local parity = i % 2 == 1
        for _ = 1, depth-1, 1 do

            addPos((parity and 1 or -1),0)
        end
        if i == width then break end
        addPos(0,1)
    end
end

local function calculatePath()
    table.insert(path, { x = x, z = z })
    addPos(1,0)

    loopSlice()

    while x > 0 do
        addPos(-1,0)
    end

    while z > 0 do
        addPos(0,-1)
    end

    addPos(-1,0)

    --[[
    for _,coords in ipairs(path) do
        print(coords.x .. "," .. coords.z)
        sleep(0.25)
    end
    --]]
end

local function relativeTurn(normal)
    if direction == DIRECTIONS.LEFT then
        if normal then MiningLib.face(MiningLib.DIRECTIONS.LEFT)
        else MiningLib.face(MiningLib.DIRECTIONS.RIGHT) end
    else
        if normal then MiningLib.face(MiningLib.DIRECTIONS.RIGHT)
        else MiningLib.face(MiningLib.DIRECTIONS.LEFT) end
    end
end

local function navigatePath()
    local oldX, oldZ
    for _,coords in ipairs(path) do
        local relativeX, relativeZ
        local has_block, data
        if not oldX or not oldZ then goto continue end
        relativeX = coords.x - oldX
        relativeZ = coords.z - oldZ

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
        end

        has_block, data = turtle.inspectDown()
        if has_block and data.tags["terralith:soil"] then goto continue end
        turtle.digDown()
        turtle.select(TurtleLib.getItemIndex("minecraft:dirt"))
        turtle.placeDown()

        ::continue::
        x,z = coords.x, coords.z
        oldX = x
        oldZ = z
    end
end

local function init()
    if arg[1] == "help" then return true end
    depth = tonumber(arg[1]) or error("Depth requires a number argument.", 0)
    width = tonumber(arg[2]) or error("Width requires a number argument.", 0)
    if depth < 1 then error("Depth must be positive and greater than 0.", 0) end
    if width < 1 then error("Width must be positive and greater than 0.", 0) end
    if arg[3] and string.lower(arg[3]) == "right" then direction = DIRECTIONS.RIGHT
    elseif arg[3] and string.lower(arg[3]) ~= "left" then warn("direction invalid, selecting 'left' by default.") end
    MiningLib.broadcast("Area size: " .. tostring(depth) .. "x" .. tostring(width))
    MiningLib.broadcast("Prepping to the " .. (direction == 1 and 'left' or 'right') .. ".")

    calculatePath()
    navigatePath()
end

local guide = init()
if guide then tutorial() end