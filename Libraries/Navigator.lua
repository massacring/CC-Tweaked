---Main Object Class
local Object = {}
Object.__index = Object

---Creates a new Object
function Object:new()
end

---Returns an object that extends this one.
---@return table
function Object:extend()
    local object = {}
    for key, value in pairs(self) do
        if key:find("__") == true then
            object[key] = value
        end
    end
    object.__index = object
    object.super = self
    setmetatable(object, self)
    return object
end

---Implements the functions of objects.
---@param ... table
function Object:implement(...)
  for _, object in pairs({...}) do
    for key, value in pairs(object) do
      if self[key] == nil and type(value) == "function" then
        self[key] = value
      end
    end
  end
end

---Overrides the call functionality of the Object to return a new instance of the Object.
---@param ... unknown
---@return table
function Object:__call(...)
    local object = setmetatable({}, self)
---@diagnostic disable-next-line: redundant-parameter
    object:new(...)
    return object
end

local Stack = Object:extend()

function Stack:new()
    self.items = {}
end

function Stack:push(value)
    table.insert(self.items, value)
end

function Stack:pop()
    return table.remove(self.items)
end

function Stack:peek()
    return self.items[#self.items]
end

function Stack:isEmpty()
    return #self.items == 0
end

local Vector3 = Object:extend()

--- Adds two Vector3s together.
--- @param vec1 table
--- @param vec2 table
--- @return table
Vector3.__add = function (vec1, vec2)
    local x = vec1.x + vec2.x or vec1[1] + vec2[1]
    local y = vec1.y + vec2.y or vec1[2] + vec2[2]
    local z = vec1.z + vec2.z or vec1[3] + vec2[3]
    return Vector3(x, y, z)
end

--- Instanciates a new Vector3.
--- Properties must have an x, y and z.
--- @param x number
--- @param y number
--- @param z number
function Vector3:new(x, y, z)
    if(type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number") then
        print("Cannot make Vector3 without 3 numbers.")
        return
    end
    self.x = x
    self.y = y
    self.z = z
end

function Vector3:key()
    return self.x .. "," .. self.y .. "," .. self.z
end

local Navigator = Object:extend()

Navigator.Directions = {
    UP = Vector3(0, 1, 0),
    DOWN = Vector3(0, -1, 0),
    NORTH = Vector3(0, 0, -1),
    EAST = Vector3(1, 0, 0),
    SOUTH = Vector3(0, 0, 1),
    WEST = Vector3(-1, 0, 0),
}

Navigator.DirectionIndexes = {
    [1] = "west",
    [2] = "north",
    [3] = "east",
    [4] = "south"
}

Navigator.directionIndex = 0
Navigator.direction = nil
Navigator.coords = nil
Navigator.turtle = nil
Navigator.isMining = false
Navigator.isCrafting = false

Navigator.hasGPS = gps.locate() ~= nil

--- Establish a Navigator table.
--- @param turtle table
--- @param direction string
--- @param x number | nil
--- @param y number | nil
--- @param z number | nil
function Navigator:new(turtle, direction, x, y, z)
    if turtle == nil then
        print("Could not make new Navigator without turtle.")
        return
    end

    if not Navigator.hasGPS then
        print("Navigator could not establish connection to GPS.")
    end

    if self:loadData() then
        self.turtle = turtle
        goto setup
    end

    if direction == nil then
        print("Could not make new Navigator without direction.")
        return
    end

    if self.hasGPS then
        local gpsData = gps.locate()
        self.coords = Vector3(gpsData.x, gpsData.y, gpsData.z)
    elseif x == nil or y == nil or z == nil then
        print("Establishing a Navigator with no GPS or provided coordinates.")
    else
        self.coords = Vector3(x, y, z)
    end

    self.turtle = turtle
    self:setDirection(direction)

    ::setup::
    local left = self:getEquipped("left")
    local right = self:getEquipped("right")

    self.isMining = (left and left.name == "minecraft:diamond_pickaxe") or (right and right.name == "minecraft:diamond_pickaxe")
    self.isCrafting = (left and left.name == "minecraft:crafting_table") or (right and right.name == "minecraft:crafting_table")
end

--- Returns a bool whether the turtle has an item equipped on the provided side.
--- Also returns the item data if there is any.
--- @param side string
--- @return table|nil
function Navigator:getEquipped(side)
    side = side:lower()
    if side == "left" then
        if self.turtle.getEquippedLeft ~= nil then
            return self.turtle.getEquippedLeft()
        end
        local slot = self:getFirstEmptySlot()
        if slot == 0 then
            return
        end
        self.turtle.select(slot)
        self.turtle.equipLeft()
        local equippedLeft = self.turtle.getItemDetail(slot)
        self.turtle.equipLeft()
        if equippedLeft == nil then
            return
        else
            return equippedLeft
        end
    elseif side == "right" then
        if self.turtle.getEquippedRight ~= nil then
            return self.turtle.getEquippedRight()
        end
        local slot = self:getFirstEmptySlot()
        if slot == 0 then
            return
        end
        self.turtle.select(slot)
        self.turtle.equipRight()
        local equippedRight = self.turtle.getItemDetail(slot)
        self.turtle.equipRight()
        if equippedRight == nil then
            return
        else
            return equippedRight
        end
    end
end

--- Returns a table containing keys of indexes and values of item data.
--- The indexes are numerical but not ordered, meaning there may be gaps.
--- Returns an empty table if no items are found.
--- @return table
function Navigator:getInventory()
    local inventory = {}
    for i = 1, 16 do
        local item = self.turtle.getItemDetail(i)
        if item ~= nil then
            inventory[i] = item
        end
    end
    return inventory
end

--- Finds the first index of an empty slot, or 0 if no match is found.
--- Returns a number, or 0 and a string reason for failure.
--- @return number
--- @return string|nil
function Navigator:getFirstEmptySlot()
    local inventory = self:getInventory()
    for i = 1, 16 do
        if inventory[i] == nil then
            return i
        end
    end
    return 0, "No empty slots found."
end

--- Finds the first index of the provided item id, or 0 if no match is found.
--- Returns a number, or 0 and a string reason for failure.
--- @param id string
--- @return number
--- @return string|nil
function Navigator:findItem(id)
    local inventory = self:getInventory()
    for index, itemData in pairs(inventory) do
        if itemData.name == id then
            return index
        end
    end
    return 0, "No match found."
end

--- Saves Navigator data to a json file.
function Navigator:saveData()
    local file = fs.open("navData.json", "w")
    local data = {
        coords = self.coords,
        direction = self.direction,
        directionIndex = self.directionIndex
    }

    file.write(textutils.serializeJSON(data))
    file.close()
end

--- Saves Navigator history to a txt file.
--- @param action string
function Navigator:saveHistory(action)
    local fileName = "history.txt"
    local exists = fs.exists(fileName)

    if exists then action = "," .. action end

    local file = fs.open(fileName, "a")

    file.write(action)

    file.close()
end

--- Loads Navigator data from a json file.
--- Returns true if it succeeds.
--- Returns false and a string reason if it fails.
--- @return boolean
--- @return string|nil
function Navigator:loadData()
    local fileName = "navData.json"
    if not fs.exists(fileName) then
        return false, "File not found."
    end
    local file = fs.open(fileName, "r")
    local content = file.readAll()
    file.close()

    local data = textutils.unserializeJSON(content)
    if data == nil then return false end
    if data.direction == nil then
        return false, "Invalid direction."
    end
    if data.coords ~= nil then
        self.coords = Vector3(data.coords.x, data.coords.y, data.coords.z)
    end
    self:setDirection(data.direction)
    if data.directionIndex ~= nil then
        self.directionIndex = data.directionIndex
    end
    return true
end

--- Checks if the fuel level can support movement.
--- @param amount number|nil
--- @return boolean
function Navigator:checkFuel(amount)
    amount = amount or 1
    if type(amount) ~= "number" then amount = 1 end
    local fuelLevel = self.turtle.getFuelLevel()
    if type(fuelLevel) == "string" then
        return true
    end
    return fuelLevel >= amount
end

--- Gets the current coordinates of the turtle.
--- Attempts to use GPS if available.
--- @return table | nil
function Navigator:getCoords()
    if self.hasGPS then
        return gps.locate()
    else
        return self.coords or nil
    end
end

--- Gets a direction table based on the provided string.
--- Returns a Vector3 representing the direction, or a string reason why it couldn't. 
--- @param direction string
--- @return table | string
function Navigator:getDirectionByName(direction)
    if type(direction) ~= "string" then
        return "Cannot get direction from non-string."
    end
    direction = direction:lower()
    if direction == "up" then
        return self.Directions.UP
    elseif direction == "down" then
        return self.Directions.DOWN
    elseif direction == "north" then
        return self.Directions.NORTH
    elseif direction == "east" then
        return self.Directions.EAST
    elseif direction == "south" then
        return self.Directions.SOUTH
    elseif direction == "west" then
        return self.Directions.WEST
    else
        return "String does not match any direction."
    end
end

--- Gets the directional index based on the provided string.
--- Returns a number on success, and a string reason on failure.
--- @param direction string
--- @return number|string
function Navigator:getIndexFromName(direction)
    if type(direction) ~= "string" then
        return "Direction must be a string."
    end
    direction = direction:lower()
    for i, dir in ipairs(self.DirectionIndexes) do
        if dir == direction:lower() then
            return i
        end
    end
    return "No such direction."
end

-- Gets the directional index to one side of the current one.
--- Direction is a string and must be either "left" or "right".
--- Returns the directional index, or a string reason who it failed.
--- @param side string
--- @return number|string
function Navigator:getSideIndex(side)
    if type(side) ~= "string" then
        return "Direction must be a string."
    end
    side = side:lower()
    local directionIndex = 0
    if side == "left" then
        directionIndex = self.directionIndex - 1
        if directionIndex < 1 then
            directionIndex = directionIndex + 4
        end
        return directionIndex
    elseif side == "right" then
        directionIndex = self.directionIndex + 1
        if directionIndex > 4 then
            directionIndex = directionIndex - 4
        end
        return directionIndex
    else
        return "Direction must be either 'left' or 'right'."
    end
end

--- Gets the directional index opposite the provided one (current by default).
--- @param directionIndex number|nil
--- @return number
function Navigator:getOppositeIndex(directionIndex)
    directionIndex = directionIndex or self.directionIndex
    return (directionIndex + 1) % 4 + 1
end

--- Gets the direction opposite the provided one (current by default).
--- Upon failure, returns nil, and a string reason for the failure.
--- @param direction string|nil
--- @return string|nil
--- @return string|nil
function Navigator:getOppositeDirection(direction)
    direction = direction or self.direction
    if type(direction) ~= "string" then
        return "Direction must be a string."
    end
    direction = direction:lower()

    if direction == "up" then
        return "down"
    elseif direction == "down" then
        return "up"
    else
        local directionIndex = self:getIndexFromName(direction)
        if type(directionIndex) == "string" then
            return nil, directionIndex
        end
        local oppositeIndex = self:getOppositeIndex(directionIndex)
        return self.DirectionIndexes[oppositeIndex]
    end
end

--- Gets a stack of directions that the filter applies to.
--- Filter is a table containing a whitelist of IDs, tags and mod types.
--- Also returns a string reason upon failure.
--- @param filter table
--- @return table
--- @return string|nil
function Navigator:getValidDirections(filter)
    local validDirections = {}

    local directions = {
        [1] = self.DirectionIndexes[self.directionIndex],        -- Forward
        [2] = self.DirectionIndexes[self:getSideIndex("left")],  -- Left
        [3] = self.DirectionIndexes[self:getOppositeIndex()],    -- Back
        [4] = self.DirectionIndexes[self:getSideIndex("right")], -- Right
        [5] = "up",
        [6] = "down"
    }

    for index, checkDirection in ipairs(directions) do
        local inspect
        if index == 1 then
            inspect = self.turtle.inspect
        elseif checkDirection ~= "up" and checkDirection ~= "down" then
            local success, message = self:faceDirection(checkDirection)
            if not success then
                return {}, "Failed to turn: " .. message
            end
            inspect = self.turtle.inspect
        elseif checkDirection == "up" then
            inspect = self.turtle.inspectUp
        elseif checkDirection == "down" then
            inspect = self.turtle.inspectDown
        else
            return {}, "Impossible state."
        end

        local _, blockData = inspect()
        local success, _ = self:filter(filter, blockData)

        if success then
            validDirections[#validDirections+1] = checkDirection
        end
    end
    return validDirections
end

--- Sets the direction of the Navigator.
--- Returns true if it succeeds.
--- Returns false and a string reason if it fails.
--- @param direction string
--- @return boolean
--- @return string|nil
function Navigator:setDirection(direction)
    if type(direction) ~= "string" then
        return false, "Direction must be a string."
    end
    direction = direction:lower()
    if direction == "north" then
        self.direction = "north"
        self.directionIndex = 2
    elseif direction == "east" then
        self.direction = "east"
        self.directionIndex = 3
    elseif direction == "south" then
        self.direction = "south"
        self.directionIndex = 4
    elseif direction == "west" then
        self.direction = "west"
        self.directionIndex = 1
    else
        return false, "String does not match any direction."
    end
    return true
end

--- Turns the Navigator to the provided side.
--- Side is a string and must be either "left" or "right".
--- @param side string
--- @return boolean
--- @return string|nil
function Navigator:turn(side)
    if type(side) ~= "string" then
        return false, "Direction must be a string."
    end
    side = side:lower()
    local success = false
    local message = nil
    if side == "left" then
        success, message = self.turtle.turnLeft()
        if success then
            self:saveHistory(self.direction .. ":" .. "left")
        else
            return success, message
        end
    elseif side == "right" then
        success, message = self.turtle.turnRight()
        if success then
            self:saveHistory(self.direction .. ":" .. "right")
        else
            return success, message
        end
    else
        return false, "Direction must be either 'left' or 'right'."
    end
    local result = self:getSideIndex(side)
    if type(result) == "string" then
        return false, result
    end
    self.directionIndex = result
    local directionFromIndex = self.DirectionIndexes[result]
    self:setDirection(directionFromIndex)
    if success then self:saveData() end
    return success, message
end

--- Turns the Navigator in the provided direction.
--- Direction is a string and must be a cardinal direction.
--- @param direction string
--- @return boolean
--- @return string|nil
function Navigator:faceDirection(direction)
    if type(direction) ~= "string" then
        return false, "Direction must be a string."
    end
    direction = direction:lower()
    local targetIndex = self:getIndexFromName(direction)
    if not targetIndex then
        return false, "Failed to get directional index."
    end

    local currentIndex = self.directionIndex
    local indexDifference = targetIndex - currentIndex

    -- Wrap difference into range -2 to 2
    if indexDifference > 2 then
        indexDifference = indexDifference - 4
    elseif indexDifference < -2 then
        indexDifference = indexDifference + 4
    end

    local success = true
    local message
    if indexDifference > 0 then
        for _ = 1, indexDifference do
            success, message = self:turn("right")
        end
    elseif indexDifference < 0 then
        for _ = 1, -indexDifference do
            success, message = self:turn("left")
        end
    end
    return success, message
end

--- Filter is a table containing a whitelist of IDs, tags and mod types.
--- Data is a table containing a mod, name, and tags.
--- @param filter table
--- @param data table
--- @return boolean
--- @return string|nil
function Navigator:filter(filter, data)
    if filter == nil or type(filter) ~= "table" then return false, "Invalid filter." end
    if data == nil or type(data) ~= "table" then return false, "Invalid itemData." end
    local result = true
    local message
    for k, _ in pairs(filter) do
        if type(k) ~= "string" or (k ~= "id" and k ~= "tag" and k ~= "mod") then
            return false, "Filter contains incorrect keys."
        end
    end
    if filter.id then
        if not filter.id[data.name] then
            result = false
            message = "Not in id whitelist."
            goto tag
        end
        return true
    end
    ::tag::
    if filter.tag then
        for _, tag in pairs(filter.tag) do
            if not data.tags[tag] then
                result = false
                message = "Not in tag whitelist."
                goto mod
            end
        end
        return true
    end
    ::mod::
    if filter.mod then
        local mod = data.name:sub(1, data.name:find(":") - 1)
        if not filter.mod[mod] then
            result = false
            message = "Not in mod whitelist."
            goto result
        end
        return true
    end
    ::result::
    return result, message
end

--- Finds a path from startPos to endPos, going along the coordinates provided in validPositions.
--- Returns nil if no path can be traced.
--- @param startPos table
--- @param endPos table
--- @param validPositions table
--- @return table|nil
function Navigator:findPath(startPos, endPos, validPositions)

    local queue = {startPos}
    local cameFrom = {}
    local visited = {}

    local startPosKey = startPos:key()
    local endPosKey = endPos:key()

    visited[startPosKey] = true

    while #queue > 0 do
        local current = table.remove(queue, 1)

        if current:key() == endPosKey then
            break
        end

        for direction, coordDiffference in pairs(self.Directions) do
            local neighbour = current + coordDiffference
            local neighbourKey = neighbour:key()

            if validPositions[neighbourKey] and not visited[neighbourKey] then
                visited[neighbourKey] = true
                cameFrom[neighbourKey] = {
                    previous = current,
                    direction = direction
                }
                table.insert(queue, neighbour)
            end
        end
    end

    -- Reconstruct path
    local path = {}
    local currentKey = endPosKey

    if not cameFrom[currentKey] then
        return nil
    end

    while currentKey ~= startPosKey do
        local data = cameFrom[currentKey]
        if data.direction:lower() ~= "up" and data.direction:lower() ~= "down" then
            table.insert(path, 1, "forward")
        end
        table.insert(path, 1, data.direction)
        currentKey = data.previous:key()
    end

    return path
end

--- Attempts to place in the provided direction.
--- Direction must be 'up', 'forward', or 'down'.
--- Filter is a table containing a whitelist of items IDs, item tags, and mod type.
--- @param direction string
--- @param slot number|nil
--- @param text string|nil
--- @return boolean
--- @return string|nil
function Navigator:place(direction, slot, text)
    if direction == nil or type(direction) ~= "string" then
        return false, "Direction must be a string."
    end

    local place
    if direction == "up" then
        place = self.turtle.placeUp
    elseif direction == "forward" then
        place = self.turtle.place
    elseif direction == "down" then
        place = self.turtle.placeDown
    else
        return false, "Invalid direction."
    end

    if slot ~= nil and type(slot) == "number" and slot <= 16 and slot >= 1 then
        self.turtle.select(slot)
    end

    place(text)

    return true
end

--- Attempts to break the block in the provided direction.
--- Direction must be 'up', 'forward', or 'down'.
--- Filter is a table containing a whitelist of block IDs, block tags, and mod type.
--- @param direction string
--- @param filter table|nil
--- @return boolean
--- @return string|nil
function Navigator:dig(direction, filter)
    if not self.isMining then
        return false, "Not a mining turtle."
    end
    if direction == nil or type(direction) ~= "string" then
        return false, "Direction must be a string."
    end

    local detect, dig, inspect

    if direction == "up" then
        detect = self.turtle.detectUp
        dig = self.turtle.digUp
        inspect = self.turtle.inspectUp
    elseif direction == "forward" then
        detect = self.turtle.detect
        dig = self.turtle.dig
        inspect = self.turtle.inspect
    elseif direction == "down" then
        detect = self.turtle.detectDown
        dig = self.turtle.digDown
        inspect = self.turtle.inspectDown
    else
        return false, "Invalid direction."
    end

    while detect() do
        if filter then
            local _, itemData = inspect()
            local success, message = self:filter(filter, itemData)
            if not success then
                return success, message
            end
        end
        local success, message = dig()
        if not success and not message:find("Nothing to dig here") then
            return success, message
        end
    end
    return true
end

-- Moves the Navigator in the provided direction.
--- BreakBlock determines if it should break blocks as it moves or not.
--- Filter is a table containing a whitelist of block IDs, block tags, and mod type.
--- @param breakBlock boolean|nil
--- @param filter table|nil
--- @return boolean
--- @return string|nil
function Navigator:move(direction, breakBlock, filter)
    if not self:checkFuel() then
        return false, "Not enough fuel to move."
    end

    local detect, move
    local currentDirection = self.direction:upper()
    local vectorDirection = self.Directions[currentDirection]

    if direction == "up" then
        detect = self.turtle.detectUp
        move = self.turtle.up
        vectorDirection = self.Directions.UP
    elseif direction == "forward" then
        detect = self.turtle.detect
        move = self.turtle.forward
    elseif direction == "down" then
        detect = self.turtle.detectDown
        move = self.turtle.down
        vectorDirection = self.Directions.DOWN
    elseif direction == "back" then
        local oppositeIndex = self:getOppositeIndex()
        vectorDirection = self.DirectionIndexes[oppositeIndex]
        breakBlock = false
        move = self.turtle.back
    else
        return false, "Invalid direction."
    end

    if breakBlock and detect() then
        local success, message = self:dig(direction, filter)
        if not success then
            return success, message
        end
    end

    local success, message = move()
    if success == true then
        self.coords = self.coords + vectorDirection
        self:saveHistory(self.direction .. ":" .. direction)
        self:saveData()
    end
    return success, message
end

--- Computes several moves based on a list of instructions.
--- BreakBlock determines if it should break blocks as it moves or not.
--- Filter is a table containing a whitelist of block IDs, block tags, and mod type.
--- @param instructions table
--- @param breakBlock boolean|nil
--- @param filter table|nil
--- @return boolean
--- @return string|nil
function Navigator:compute(instructions, breakBlock, filter)
    if type(instructions) ~= "table" then
        return false, "Instructions must be a table."
    end

    local moveInstructions = {
        FORWARD = true,
        BACK = true,
        UP = true,
        DOWN = true,
    }

    local moveAmount = 0
    for index, instruction in pairs(instructions) do
        if type(instruction) ~= "string" then
            return false, "Instruction '" .. index .. "' was not a string."
        end

        if moveInstructions[instruction:upper()] then moveAmount = moveAmount + 1 end
    end

    if not self:checkFuel(moveAmount) then
        return false, "Not enough fuel to complete instructions."
    end

    for index, instruction in pairs(instructions) do
        instruction = instruction:lower()
        local success, message

        if moveInstructions[instruction:upper()] then
            success, message = self:move(instruction, breakBlock, filter)
        elseif instruction == "left" then
            success, message = self:turn("left")
        elseif instruction == "right" then
            success, message = self:turn("right")
        elseif instruction == "north" then
            success, message = self:faceDirection("north")
        elseif instruction == "east" then
            success, message = self:faceDirection("east")
        elseif instruction == "south" then
            success, message = self:faceDirection("south")
        elseif instruction == "west" then
            success, message = self:faceDirection("west")
        end

        if success == false then
            return success, "Instruction '" .. index .. "' failed: " ..message
        end
    end
    return true
end

--- Mines all connected blocks in the direction.
--- Filter is a table containing a whitelist of block IDs, block tags, and mod type.
--- @param filter table
--- @return boolean
--- @return string|nil
function Navigator:vein(filter)
    if not self.isMining then
        return false, "Not a mining turtle."
    end

    local function backtrack(previousDirections)
        local previousDirection = previousDirections:pop()

        if previousDirection == "up" then
            local success, message = self:move("down", true)
            if not success then
                return success, "Failed to move: " .. message
            end
        elseif previousDirection == "down" then
            local success, message = self:move("up", true)
            if not success then
                return success, "Failed to move: " .. message
            end
        else
            local oppositePreviousDirection, reason = self:getOppositeDirection(previousDirection)
            if oppositePreviousDirection == nil then
                return false, "Failed to get index: " .. reason
            end
            local success, message = self:faceDirection(oppositePreviousDirection)
            if not success then
                return success, "Failed to turn: " .. message
            end
            success, message = self:move("forward", true)
            if not success then
                return success, "Failed to move: " .. message
            end
        end
        return true
    end

    local function checkDirectionsToVisit(directionsToVisit)
        if directionsToVisit == nil or next(directionsToVisit) == nil then return false end
        for _, validDirections in pairs(directionsToVisit) do
            if validDirections ~= nil and next(validDirections) ~= nil then return true end
        end
        return false
    end

    local function step(directionsToVisit, previousDirections, visitedCoords)
        -- Get valid directions for current coordinates.
        local validDirections = directionsToVisit[self:getCoords():key()]

        if validDirections == nil or next(validDirections) == nil then
            -- Backtrack if there are no valid directions.
            if not checkDirectionsToVisit(directionsToVisit) or (previousDirections == nil or previousDirections:isEmpty()) then
                -- There is nowhere to move to.
                return false, "Nowhere to move." -- Acts as a break.
            end
            local success, message = backtrack(previousDirections)
            if not success then
                return success, "Failed to backtrack: " .. message
            end
            return true -- Acts as a continue.
        end

        -- Pop the latest direction from those valid directions.
        local nextDirection = table.remove(validDirections)

        -- Move in the direction.
        if nextDirection == "up" then
            local success, message = self:move(nextDirection, true)
            if not success then
                return success, "Failed to move: " .. message
            end
        elseif nextDirection == "down" then
            local success, message = self:move(nextDirection, true)
            if not success then
                return success, "Failed to move: " .. message
            end
        else
            local success, message = self:faceDirection(nextDirection)
            if not success then
                return success, "Failed to turn: " .. message
            end
            success, message = self:move("forward", true)
            if not success then
                return success, "Failed to move: " .. message
            end
        end

        previousDirections:push(nextDirection)

        local currentCoords = self:getCoords()
        if currentCoords == nil then
            return false, "Invalid coordinates."
        end
        local currentCoordsKey = currentCoords:key()

        if directionsToVisit[currentCoordsKey] == nil then
            -- Updates visitedCoords with the current position, if it hasn't already been visited.
            visitedCoords[currentCoordsKey] = true

            -- Updates directionsToVisit with the valid directions of the current position.
            directionsToVisit[currentCoordsKey] = self:getValidDirections(filter)

            -- Check if any neighbour is in directionsToVisit.
            -- If any are, remove the direction leading to the current position from them.
            for direction, coordDifference in pairs(self.Directions) do
                local neighbourPosition = currentCoords + coordDifference
                local neighbourValidDirections = directionsToVisit[neighbourPosition:key()]
                if neighbourValidDirections ~= nil and next(neighbourValidDirections) ~= nil then
                    local oppositeDirection, reason = self:getOppositeDirection(direction)
                    if oppositeDirection == nil then
                        print(direction)
                        return false, "Failed to get index: " .. reason
                    end
                    for i, v in ipairs(neighbourValidDirections) do
                        if v == oppositeDirection then
                            table.remove(neighbourValidDirections, i)
                            break
                        end
                    end
                end
            end
        end
        return true
    end

    local initialCoords = self:getCoords()
    if initialCoords == nil then
        return false, "Cannot get coordinates."
    end
    local initialCoordsKey = initialCoords:key()

    local filteredInitialDirections = self:getValidDirections(filter)
    local directionsToVisit = { [initialCoordsKey] = filteredInitialDirections }

    local previousDirections = Stack()
    local visitedCoords = { [initialCoordsKey] = true }

    while initialCoordsKey ~= self:getCoords():key() or (directionsToVisit[initialCoordsKey] ~= nil or next(directionsToVisit[initialCoordsKey]) ~= nil) do -- TODO: set actual statement
        -- Steps through one execution of the mining algorithm.
        -- Wrapped in a function to avoid goto continues.
        local success, message = step(directionsToVisit, previousDirections, visitedCoords)
        if not success then
            if message == "Nowhere to move." then
                break
            end
            return success, message
        end
    end

    -- Calculate and move through the most optimal path back to the starting location.
    -- By default, only paths through positions that have been previously visited.
    local currentCoords = self:getCoords()
    if currentCoords == nil then
        return false, "Cannot get coordinates."
    end
    local path = self:findPath(currentCoords, initialCoords, visitedCoords)
    if path == nil then
        return false, "Cannot trace back to starting position."
    end
    local success, message = self:compute(path)
    if not success then
        return success, "Failed to move back to starting position: " .. message
    end

    local oppositeDirection = self:getOppositeDirection()
    if oppositeDirection ~= nil then
        self:faceDirection(oppositeDirection)
    end

    return true
end

--- Mines a strip with the provided properties.
--- properties.depth is how deep the strip goes.
--- properties.offset is the offset between each repeating strip.
--- properties.height is the height of the strip (1-3).
--- properties.direction is the cardinal direction the strip should start in. Defaults to the facing direction.
--- propagates.repeats is how many strips should be made (1 strip goes back and fourth once).
--- propagates.side is which side (left/right) the strips should repeat towards. Alternates if nil.
--- propagates.mainFilter is the filter to apply when mining the strips.
--- propagates.veinFilter is the filter that decides what blocks to vein mine while going through the strips.
--- @param properties table
--- @return boolean
--- @return string|nil
function Navigator:tunnel(properties)
    setmetatable(properties, {__index={
        depth = 32, -- at least 1
        offset = 3, -- at least 1
        height = 2,  -- at least 1, at most 3
        direction = self.direction, -- cardinal (north/south/west/east)
        repeats = 8, -- at least 1
        side = nil, -- nil/left/right
        mainFilter = nil, -- nil/table
        veinFilter = nil, -- nil/table
    }})
    local depth = math.max(properties.depth, 1)
    local offset = math.max(properties.offset, 1)
    local height = math.max(math.min(properties.height, 3), 1)
    local originalDirection = self.direction
    local direction = properties.direction
    local backDirection, reason = self:getOppositeDirection(direction)
    if backDirection == nil then
        return false, "Could not get opposite direction: " .. reason
    end
    local repeats = math.max(properties.repeats, 1)
    local side = properties.side
    local alternate = false
    local mainSide, secondarySide
    if side == nil then
        alternate = true
        mainSide = self.DirectionIndexes[self:getSideIndex("left")]
        secondarySide = self.DirectionIndexes[self:getSideIndex("right")]
    else
        mainSide = self.DirectionIndexes[self:getSideIndex(side)]
        local failMessage
        secondarySide, failMessage = self:getOppositeDirection(mainSide)
        if secondarySide == nil then
            return false, "Could not get opposite side: " .. failMessage
        end
    end
    local mainFilter = properties.mainFilter
    local veinFilter = properties.veinFilter

    local function move()
        local inspects = { self.turtle.inspect, self.turtle.inspectUp, self.turtle.inspectDown }
        local success, message
        for _, inspect in ipairs(inspects) do
            local _, data = inspect()
            if self:filter(veinFilter, data) then
                success, message = self:vein(veinFilter)
                if not success then
                    return success, "Failed vein mining: " .. message
                end
                break
            end
        end
        if height > 1 then
            success, message = self:dig("up", mainFilter)
            if not success then
                print("Failed digging up: " .. message)
            end
        end
        if height == 3 then
            success, message = self:dig("down", mainFilter)
            if not success then
                print("Failed digging down: " .. message)
            end
        end
        success, message = self:move("forward", true, mainFilter)
        if not success then
            return success, "Failed to move forward: " .. message
        end
        return true
    end

    local function calculateFuel()
        local total = 0
        if height == 3 then
            total = total + 2
        end
        for strip = 1, repeats do
            total = total + offset * (alternate and (strip-1) or 0)
            total = total + depth
            total = total + offset
            total = total + depth
            total = total + offset * ((alternate or strip == repeats) and strip or 1)
        end
        return self:checkFuel(total), total
    end

    local enoughFuel, required = calculateFuel()
    if not enoughFuel then
        return false, string.format("Not enough fuel: (%d/%d)", self.turtle.getFuelLevel(), required)
    end

    if height == 3 then
        local success, message = self:move("up", true, mainFilter)
        if not success then
            return success, "Failed to move up: " .. message
        end
    end

    for strip = 1, repeats do
        if alternate and not (strip == 1) then
            if strip % 2 == 1 then
                self:faceDirection(mainSide)
            else
                self:faceDirection(secondarySide)
            end
        end
        for _ = 1, offset * (alternate and (strip-1) or 0) do
            local success, message = move()
            if not success then
                return success, "Failed to move: " .. message
            end
        end
        self:faceDirection(direction)
        for _ = 1, depth do
            local success, message = move()
            if not success then
                return success, "Failed to move: " .. message
            end
        end
        if (not alternate) or strip % 2 == 1 then
            self:faceDirection(mainSide)
        else
            self:faceDirection(secondarySide)
        end
        for _ = 1, offset do
            local success, message = move()
            if not success then
                return success, "Failed to move: " .. message
            end
        end
        self:faceDirection(backDirection)
        for _ = 1, depth do
            local success, message = move()
            if not success then
                return success, "Failed to move: " .. message
            end
        end
        if (not alternate and strip ~= repeats) or strip % 2 == 0 then
            self:faceDirection(mainSide)
        else
            self:faceDirection(secondarySide)
        end
        for _ = 1, offset * ((alternate or strip == repeats) and strip or 1) do
            local success, message = move()
            if not success then
                return success, "Failed to move: " .. message
            end
        end
    end
    if not alternate then
        for _ = 1, repeats - 1 do
            local success, message = move()
            if not success then
                return success, "Failed to move: " .. message
            end
        end
    end
    self:faceDirection(originalDirection)
    if height == 3 then
        local success, message = self:move("down", true)
        if not success then
            return success, "Failed to move: " .. message
        end
    end
    return true
end

--- Mines an area with the provided properties.
--- properties.depth is how deep the area is.
--- properties.width is how wide the area is.
--- properties.height is how high the area is.
--- properties.direction is the cardinal direction the area should start in. Defaults to the facing direction.
--- properties.vertical is the vertical direction to mine in.
--- properties.horizontal is the horizontal direction to mine in.
--- propagates.filter is the filter to apply when mining the area.
--- @param properties table
--- @return boolean
--- @return string|nil
function Navigator:area(properties)
    setmetatable(properties, {__index={
        depth = 3, -- at least 1
        width = 3, -- at least 1
        height = 3,  -- at least 1
        direction = self.direction, -- cardinal (north/south/west/east)
        vertical = "up", -- up/down
        horizontal = "left", -- left/right
        filter = nil, -- nil/table
    }})
    local depth = math.max(properties.depth, 1)
    local width = math.max(properties.width, 1)
    local height = math.max(properties.height, 1)

    local originalDirection = self.direction
    local direction = properties.direction
    local oppositeDirection, reason = self:getOppositeDirection(direction)
    if oppositeDirection == nil then
        return false, "Could not get opposite direction: " .. reason
    end

    local vertical = properties.vertical
    local oppositeVertical
    if vertical == "up" then
        oppositeVertical = "down"
    elseif vertical == "down" then
        oppositeVertical = "up"
    else
        return false, "Invalid vertical direction."
    end

    local horizontal = properties.horizontal
    local oppositeHorizontal
    if horizontal == "left" then
        oppositeHorizontal = "right"
    elseif horizontal == "right" then
        oppositeHorizontal = "left"
    else
        return false, "Invalid horizontal direction."
    end

    local filter = properties.filter

    local success, message

    local slices = math.floor(height/3)
    local leftoverSlice = height % 3

    local fuelRequired = (width * depth * 3 * slices) + (width * depth * leftoverSlice)
    if not self:checkFuel(fuelRequired) then
        return false, string.format("Not enough fuel: (%d/%d)", self.turtle.getFuelLevel(), fuelRequired)
    end

    -- if horizontalParity is odd and verticalParity is odd, we end at far width and far depth
    -- if horizontalParity is odd and verticalParity is even, we end at close width and close depth
    -- if horizontalParity is even and verticalParity is odd, we end at far width and close depth
    -- if horizontalParity is even and verticalParity is even, we end at close width and close depth

    -- h-odd  + v-odd  = w-far   + d-far
    -- h-odd  + v-even = w-close + d-close
    -- h-even + v-odd  = w-far   + d-close
    -- h-even + v-even = w-close + d-close

    local verticalParity = (slices + (leftoverSlice > 0 and 1 or 0)) % 2
    local horizontalParity = width % 2

    local function moveSlice()
        success, message = self:move("forward", true, filter)
        if not success then
            return false, "Failed to move: " .. message
        end
        success, message = self:dig(vertical, filter)
        if not success then
            print("Failed to mine a block: " .. message)
        end
        success, message = self:dig(oppositeVertical, filter)
        if not success then
            print("Failed to mine a block: " .. message)
        end
        return true
    end

    local function backtrack()
        for _ = 1, (slices*3 - 3) + (leftoverSlice > 0 and 1 or 0) + 1 do
            success, message = self:move(oppositeVertical)
            if not success then
                return false, message
            end
        end

        if verticalParity == 1 then
            if horizontalParity == 0 then
                self:turn(horizontal)
            else
                self:turn(oppositeHorizontal)
            end
            for _ = 1, width-1 do
                success, message = self:move("forward")
                if not success then
                    return false, message
                end
            end
        end

        self:faceDirection(oppositeDirection)
        for _ = 1, ((verticalParity == 0 or horizontalParity == 0) and 1 or depth) do
            success, message = self:move("forward")
            if not success then
                return false, message
            end
        end
        return true
    end

    self:faceDirection(direction)

    if (height == 1 and width == 1 and depth == 1) then
        success, message = self:dig("forward", filter)
        if not success then
            return success, "Failed to dig area: " .. message
        end
        self:faceDirection(originalDirection)
        return false, "Is this a joke to you?"
    end

    for slice = 1, slices do
        local sliceParity = slice % 2
        if slice == 1 then
            success, message = self:move(vertical, true, filter)
            if not success then
                return false, "Failed to move: " .. message
            end
            success, message = moveSlice()
            if not success then
                return false, message
            end
        end
        for i = 1, width do
            local widthParity = i % 2
            for _ = 1, depth-1 do
                success, message = moveSlice()
                if not success then
                    return false, message
                end
            end

            local parity = (widthParity + (horizontalParity == 0 and (sliceParity + 1) or 0)) % 2 == 1

            if i ~= width then
                if parity then
                    self:turn(horizontal)
                else
                    self:turn(oppositeHorizontal)
                end

                success, message = moveSlice()
                if not success then
                    return false, message
                end

                if parity then
                    self:turn(horizontal)
                else
                    self:turn(oppositeHorizontal)
                end
            end
        end
        if slice ~= slices then
            for _ = 1, 3 do
                success, message = self:move(vertical, true, filter)
                if not success then
                    return false, "Failed to move: " .. message
                end
            end
            success, message = self:dig(vertical, filter)
            if not success then
                print("Failed to mine a block: " .. message)
            end
            self:turn(horizontal)
            self:turn(horizontal)
        end
    end

    if leftoverSlice > 0 then
        for _ = 1, 2 do
            success, message = self:move(vertical, true, filter)
            if not success then
                return false, "Failed to move: " .. message
            end
            if leftoverSlice == 2 then
                success, message = self:dig(vertical, filter)
                if not success then
                    print("Failed to mine a block: " .. message)
                end
            end
        end
        self:turn(horizontal)
        self:turn(horizontal)
        for i = 1, width do
            for _ = 1, depth-1 do
                success, message = self:move("forward", true, filter)
                if not success then
                    return false, "Failed to move: " .. message
                end
                if leftoverSlice == 2 then
                    success, message = self:dig(vertical, filter)
                    if not success then
                        print("Failed to mine a block: " .. message)
                    end
                end
            end

            local parity = horizontalParity == 1 or verticalParity == 1

            if i ~= width then
                if parity then
                    self:turn(horizontal)
                else
                    self:turn(oppositeHorizontal)
                end

                success, message = self:move("forward", true, filter)
                if not success then
                    return false, "Failed to move: " .. message
                end
                if leftoverSlice == 2 then
                    success, message = self:dig(vertical, filter)
                    if not success then
                        print("Failed to mine a block: " .. message)
                    end
                end

                if parity then
                    self:turn(horizontal)
                else
                    self:turn(oppositeHorizontal)
                end
            end
        end
    end

    success, message = backtrack()
    if not success then
        return false, "Failed to backtrack: " .. message
    end

    self:faceDirection(originalDirection)

    return true
end

--- Mines a staircase with the provided properties.
--- properties.depth is how many steps the staircase will dig.
--- properties.size is how tall the staircase is at any given point.
--- properties.direction is the direction to start digging the staircase.
--- properties.vertical is whether to go up or down.
--- properties.replace is whether to place a block below as the staircase is being dug.
--- properties.replaceItem is the item id of the block to replace the bottom with.
--- properties.filter is the filter to apply whem digging the staircase.
function Navigator:staircase(properties)
    setmetatable(properties, {__index={
        depth = 16, -- at least 1
        size = 3, -- 3-5
        direction = self.direction, -- cardinal (north/south/west/east)
        vertical = "up", -- up/down
        replace = false,
        id = "minecraft:cobblestone",
        filter = nil, -- nil/table
    }})

    print("Digging staricase.")

    local depth = properties.depth
    local size = properties.size
    local direction = properties.direction
    local oppositeDirection = self:getOppositeDirection(direction)
    local vertical = properties.vertical
    local oppositeVertical, reason = self:getOppositeDirection(vertical)
    local replace = properties.replace
    local id = properties.id
    local filter = properties.filter

    if depth == nil or type(depth) ~= "number" then
        return false, "Invalid depth provided."
    end
    depth = math.max(depth, 1)

    if size == nil or type(size) ~= "number" then
        return false, "Invalid size provided."
    end
    size = math.max(size, 3)
    size = math.min(size, 5)

    if size == 5 then
        depth = math.ceil((depth+1)/2)
    end
    if size > 3 then
        depth = depth - 1
    end

    if direction == nil or type(direction) ~= "string"
    or (direction ~= "north" and direction ~= "south" and direction ~= "west" and direction ~= "east") then
        return false, "Invalid direction provided."
    end

    if oppositeDirection == nil then
        return false, "Could not get opposite direction: " .. reason
    end

    if vertical == nil or type(vertical) ~= "string" or (vertical ~= "up" and vertical ~= "down") then
        return false, "Invalid vertical direction provided."
    end

    if oppositeVertical == nil then
        return false, "Could not get opposite direction: " .. reason
    end

    if replace == nil or type(replace) ~= "boolean" then
        replace = false
    end

    if id == nil or type(id) ~= "string" then
        return false, "Invalid id provided."
    end

    if filter ~= nil and type(filter) ~= "table" then
        return false, "Invalid filter provided."
    end

    local fuelRequired = depth * 4
    if size == 5 then
        fuelRequired = fuelRequired + 2
    end
    if not self:checkFuel(fuelRequired) then
        return false, string.format("Not enough fuel: (%d/%d)", self.turtle.getFuelLevel(), fuelRequired)
    end

    do
        local success, message = self:faceDirection(direction)
        if not success then
            return success, "Invalid direction: " .. message
        end
    end

    local function move(dir)
        if dir == nil or type(dir) ~= "string" or (dir ~= "up" and dir ~= "down" and dir ~= "forward") then
            return false, "Invalid direction."
        end
        local digDirections = {}
        table.insert(digDirections, "up")
        table.insert(digDirections, "forward")
        if size > 3 then
            table.insert(digDirections, "down")
        end
        for _, digDirection in ipairs(digDirections) do
            local success, message = self:dig(digDirection, filter)
            if not success then
                print("Could not break block: " .. message)
            end
        end
        do
            local success, message = self:move(dir, true, filter)
            if not success then
                return success, message
            end
        end
        return true
    end

    local function replaceBlock(dir)
        if dir == nil or type(dir) ~= "string" or (dir ~= "down" and dir ~= "forward") then
            return false, "Invalid direction."
        end
        local slot = self:findItem(id)
        if slot == 0 then
            return false, "Item not found."
        end
        if replace and slot > 0 then
            do
                local success, message = self:dig(dir, filter)
                if not success then
                    return false, message
                end
            end
            do
                local success, message = self:place(dir, slot)
                if not success then
                    return false, message
                end
            end
        end
        return true
    end

    local function slice()
        do
            local success, message = move("forward")
            if not success then
                return false, "Could not move: " .. message
            end
        end
        if size == 5 then
            local success, message = move("forward")
            if not success then
                return false, "Could not move: " .. message
            end
        end
        do
            local success, message = move(vertical)
            if not success then
                return false, "Could not move: " .. message
            end
        end
        if size == 5 then
            local success, message = move(vertical)
            if not success then
                return false, "Could not move: " .. message
            end
        end
        return true
    end

    local function reverseSlice()
        do
            local success, message = self:move(oppositeVertical, true, filter)
            if not success then
                return false, message
            end
        end
        do
            local success, message = self:move("forward", true, filter)
            if not success then
                return false, message
            end
        end
        if replace then
            local success, message = replaceBlock("down")
            if not success then
                print("Failed to replace block: " .. message)
            end
        end
        return true
    end

    local function digStaircase()
        if size > 3 then
            do
                local success, message = self:dig("up", filter)
                if not success then
                    return false, message
                end
            end
            do
                local success, message = self:move("forward", true, filter)
                if not success then
                    return false, message
                end
            end
        end

        for _ = 1, depth do
            local success, message = slice()
            if not success then
                return false, message
            end
        end
        return true
    end

    local function reverse()
        do
            local success, message = self:dig("forward", filter)
            if not success then
                return false, message
            end
        end
        if size == 4 then
            local success, message = self:move(vertical, true, filter)
            if not success then
                return false, message
            end
        end
        if size < 5 then
            local success, message = self:dig("forward", filter)
            if not success then
                return false, message
            end
        end

        self:faceDirection(oppositeDirection)

        if size == 5 then
            local success, message = self:move("forward", true, filter)
            if not success then
                return false, message
            end
        end

        if replace then
            local success, message = replaceBlock("down")
            if not success then
                print("Failed to replace block: " .. message)
            end
        end

        if size == 5 then
            depth = depth * 2
        end
        if size == 4 then
            depth = depth + 1
        end

        for _ = 1, depth do
            local success, message = reverseSlice()
            if not success then
                return false, message
            end
        end
        return true
    end

    do
        local success, message = digStaircase()
        if not success then
            return false, "Failed to dig staircase: " .. message
        end
    end

    do
        local success, message = reverse()
        if not success then
            return false, "Failed to reverse: " .. message
        end
    end

    return true
end

--- Gets error data for the current state of the navigator, including computer id, label, and coordinates.
--- @return string
function Navigator:errData()
    local id = os.getComputerID() or "N/A"
    local label = os.getComputerLabel() or "Unlabeled"

    local currentCoords = self:getCoords():key() or "N/A"

    return ("%s|%s@(%s)"):format(id, label, currentCoords)
end

--- Factory method to create a navigator with the provided arguments.
--- @param direction string
--- @param x number|nil
--- @param y number|nil
--- @param z number|nil
--- @param useCoords boolean|nil
--- @return table
local function createNavigator(direction, x, y, z, useCoords)
    local myNav
    if x == nil or y == nil or z == nil then
        print("Missing coordinates.")
        useCoords = false
    elseif type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number" then
        print("Incorrecct coordinates provided.")
        useCoords = false
    end

    if useCoords then
        myNav = Navigator(turtle, direction, x, y, z)
    else
        myNav = Navigator(turtle, direction)
    end
    return myNav
end

local function getFilter(arguments)
    local filter = {}
    local types = { "id", "tag", "mod" }
    for _, type in ipairs(types) do
        if arguments[type] then
            local values = {}
            for str in string.gmatch(arguments[type], "([^"..",".."]+)") do
                values[str] = true
            end
            filter[type] = values
        end
    end
    return filter
end

--- Sets up the navigator and runs methods based on arguments.
--- Returns a Navigator upon success, or a string reason why it failed.
--- @param arguments any
--- @return table|string
local function setup(arguments)
    if arguments == nil then
        return "Invalid arguments."
    end

    if arguments.h or arguments.help then
        local help = arguments.h or arguments.help
        if help == true then
            print("Please request help with --help=<option>. Option may be:")
            print("1. init")
            print("2. vein")
            print("3. tunnel")
            print("4. area")
            print("4. staircase")
            print("5. filter")
        elseif help == "init" then
            print("Init (-i | --init) arguments:")
            print("--direction (north/east/south/west)")
            print("-x (number|optional)")
            print("-y (number|optional)")
            print("-z (number|optional)")
            print("Uses GPS if x, y, or z are not provided.")
            print("Example: -i --direction=north -x71 -y67 -z-42")
        elseif help == "vein" then
            print("Vein (-v | --vein) has no requirements, but does nothing without filter.")
            print("Example: -v -f --tag=minecraft:logs")
        elseif help == "tunnel" then
            print("Tunnel (-t | --tunnel) arguments:")
            print("--depth | -d (number)")
            print("--offset | -o (number)")
            print("--height | -h (number)")
            print("--direction (north/east/south/west)")
            print("--repeats | -r (number)")
            print("--side (left/right)")
            print("All tunnel arguments are optional.")
            print("Example: -t -d32 -o3 -h2 -r8 -f --tag=c:ores")
        elseif help == "area" then
            print("Area (-a | --area) arguments:")
            print("--depth | -d (number)")
            print("--width | -w (number)")
            print("--height | -h (number)")
            print("--vertical (up/down)")
            print("--horizontal (left/right)")
            print("--direction (north/east/south/west)")
            print("All area arguments are optional.")
            print("Example: -a -d18 -w18 -h9 --vertical=up --horizontal=right")
        elseif help == "staircase" then
            print("case (-c | --staircase) arguments:")
            print("--depth | -d (number)")
            print("--size | -s (number, 3-5)")
            print("--direction (north/east/south/west)")
            print("--vertical (up/down)")
            print("--replace | -r (boolean)")
            print("--id (string)")
            print("All staircase arguments are optional.")
            print("Example: -c -d16 -s4 --vertical=up -r --id=minecraft:netherrack")
        elseif help == "filter" then
            print("Filter (-f | --filter) arguments:")
            print("--id (block-id)")
            print("--tag (block tag)")
            print("--mod (mod id)")
            print("Example: -f --id=minecraft:stone,minecraft:sandstone --tag=minecraft:logs,c:ores --mod=minecraft,computercraft")
        end
    end

    local direction

    local x
    local y
    local z

    local useCoords = true

    if arguments.i or arguments.init then
        direction = arguments.direction
        x = tonumber(arguments.x)
        y = tonumber(arguments.y)
        z = tonumber(arguments.z)
    end
    local filter = {}
    if arguments.f or arguments.filter then
        local types = getFilter(arguments)
        for type, values in pairs(types) do
            filter[type] = values
        end
    end
    local properties
    if arguments.v or arguments.vein then
        properties = filter
    elseif arguments.t or arguments.tunnel then
        properties = {
            depth = tonumber(arguments.d or arguments.depth),
            offset = tonumber(arguments.o or arguments.offset),
            height = tonumber(arguments.h or arguments.height),
            direction = arguments.direction,
            repeats = tonumber(arguments.r or arguments.repeats),
            side = arguments.side,
            veinFilter = filter
        }
    elseif arguments.a or arguments.area then
        properties = {
            depth = tonumber(arguments.d or arguments.depth),
            width = tonumber(arguments.w or arguments.width),
            height = tonumber(arguments.h or arguments.height),
            vertical = arguments.vertical,
            horizontal = arguments.horizontal,
            direction = arguments.direction,
            filter = filter
        }
    elseif arguments.c or arguments.staircase then
        properties = {
            depth = tonumber(arguments.d or arguments.depth),
            size = tonumber(arguments.s or arguments.size),
            direction = arguments.direction,
            vertical = arguments.vertical,
            replace = arguments.r or arguments.replace,
            id = arguments.id,
            filter = filter
        }
    end

    local myNav = createNavigator(direction, x, y, z, useCoords)
    if properties ~= nil then
        local success, message
        if arguments.v or arguments.vein then
            success, message = myNav:vein(properties)
        elseif arguments.t or arguments.tunnel then
            success, message = myNav:tunnel(properties)
        elseif arguments.a or arguments.area then
            success, message = myNav:area(properties)
        elseif arguments.c or arguments.staircase then
            success, message = myNav:staircase(properties)
        end
        if not success then
            return "Failed to run: " .. message
        end
    end

    return myNav
end

return { Navigator = Navigator, Vector3 = Vector3, Stack = Stack, setup = setup }
