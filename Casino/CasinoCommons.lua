--- VARIABLES ---
local STD = {}
local Button = {}
local Buttons = {}
local Score = {}
local Credit = {}
local Credits = {}
local Images = {}
local Hand = {}
local Card = {}
local Ball = {}
--- STD ---
do
    STD.__index = STD

    --- Gets a list of item data from any slot that matches "id" in the provided inventory.
    --- Also adds the slot index to that item data.
    --- Retuns nil if no match was found.
    --- @param inventory table Represents the inventory to search.
    --- @param id string Represents the item ID to find.
    --- @return table|nil allItemData The item data, plus index, of all matching items, or nil if nothing was found.
    function STD.getAllItemData(inventory, id)
        local allItemData = {}
        if (inventory == nil or id == nil) then
            print("Could not get item data because passed inventory or id is nil.")
            return nil
        end
        for slot, itemData in pairs(inventory.list()) do
            if itemData and itemData.name == id then
                itemData.index = slot
                allItemData[#allItemData+1] = itemData
            end
        end
        if #allItemData == 0 then
            print("Item '" .. id .. "' not found.")
            return nil
        end
        return allItemData
    end

    --- Gets the item data from the first slot that matches "id" in the provided inventory.
    --- Also adds the slot index to that item data.
    --- Retuns nil if no match was found.
    --- @param inventory table Represents the inventory to search.
    --- @param id string Represents the item ID to find.
    --- @return table|nil itemData The item data, plus index, of the item, or nil if nothing was found.
    function STD.getItemData(inventory, id)
        local allItemData = STD.getAllItemData(inventory, id)
        if allItemData == nil then return nil end
        local itemData = allItemData[1]
        return itemData
    end

    --- Gets the slot index from the first slot that matches "id" in the provided inventory.
    --- Also returns the number of items in that slot.
    --- Returns 0 for both if no item was found.
    --- @param inventory table Represents the inventory to search.
    --- @param id string Represents the item ID to find.
    --- @return number index The first index of the item.
    --- @return number count The count of this item in that slot.
    function STD.getIndex(inventory, id)
        local itemData = STD.getItemData(inventory, id)
        if itemData == nil or itemData.index == nil then
            return 0, 0
        end
        return itemData.index, itemData.count
    end

    --- Gets the total count of all items matching "id" in the provided inventory.
    --- Returns 0 if no items are found.
    --- @param inventory table Represents the inventory to search.
    --- @param id string Represents the item ID to find.
    --- @return number totalCount Total number of this type of item in the inventory.
    function STD.getTotalCount(inventory, id)
        local allItemData = STD.getAllItemData(inventory, id)
        if allItemData == nil then return 0 end
        local totalCount = 0
        for _, itemData in pairs(allItemData) do
            totalCount = totalCount + itemData.count
        end
        return totalCount
    end

    --- Clears all items from the specified turtle into the provided inventory.
    --- @param inventory table Represents the inventory to search.
    --- @param turtleName string Represents the turtle to clear.
    function STD.clearTurtle(inventory, turtleName)
        for i = 1, 16, 1 do
            inventory.pullItems(turtleName, i)
        end
    end

    --- Pushes all items from the provided inventory to the specified turtle.
    --- @param inventory table Represents the inventory to search.
    --- @param turtleName string Represents the turtle to send items to.
    function STD.turtleDevour(inventory, turtleName)
        for i = 1, 16, 1 do
            inventory.pushItems(turtleName, i)
        end
    end

    --- Generates a random key.
    --- @return string ranSeq Random sequence key.
    local function getKey()
        local characters = "12345678901234567890!#%&/=?+@$!#%&/=?+@$!#%&/=?+@$abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        local ranSeq = ""
        for _ = 1, 16, 1 do
            local random = math.random(1, #characters)
            ranSeq = ranSeq .. characters:sub(random,random)
        end
        return ranSeq
    end

    --- Writes a receipt.
    --- @param key string A random sequence key.
    --- @param creditType string The credit type.
    --- @param score number The amount.
    local function writeReceipt(key, creditType, score)
        local file = fs.open("receipts", "a")
        file.write("[\"" .. key .. "\"]:\n")
        file.write("    \"type\": \"" .. creditType .. "\"\n")
        file.write("    \"score\": " .. score .. "\n")
        file.close()
    end

    --- Generates an IOU.
    --- @param printer table Represents the printer to print the IOU receipt with.
    --- @param key string A random sequence key.
    --- @param creditType string The credit type.
    --- @param score number The amount.
    local function generateIOU(printer, key, creditType, score)
        printer.newPage()
        printer.setPageTitle("I.O.U -Mass")
        printer.write("The machine ran out of")
        printer.setCursorPos(1,2)
        printer.write("some resource.")
        printer.setCursorPos(1,3)
        printer.write("This receipt will hold")
        printer.setCursorPos(1,4)
        printer.write("your earnings.")
        printer.setCursorPos(1,6)
        printer.write("Credit Type: " .. creditType)
        printer.setCursorPos(1,7)
        printer.write("Credit Score: " .. score)
        printer.setCursorPos(1,8)
        printer.write("Key: #" .. key .. "-")
        printer.setCursorPos(1,9)
        printer.write("Please do not show this")
        printer.setCursorPos(1,10)
        printer.write("key to another player.")
        printer.endPage()
    end

    --- Counts the current Score of the player and cashes out that amount in the selected credit type.
    --- @param storage table Represents where currency is stored.
    --- @param intermediaryStorage table Represents an intermediary inventory to be used when moving items to and from turtles.
    --- @param output table Represents a turtle that outputs the currency.
    --- @param printer table Represents a connected printer in case of IOUs.
    --- @param turtleName string Represents the turtle to send items to when crafting.
    function STD.countScore(storage, intermediaryStorage, output, printer, turtleName)
        if Credits.selectedCredit == nil then
            print("Tried to count score with nil selected credit.", 1)
            return
        end

        local maxSize = Credits.selectedCredit:getMax() or 0

        if maxSize == 0 then
            print("Could not get max size of selected credit.", 1)
            return
        end

        local score = Score:getScore()
        for size=maxSize,1,-1 do
            local multiplier = Credits.selectedCredit:getMultiplierBySize(size)
            local id = Credits.selectedCredit:getIdBySize(size)
            local hasScore = score >= multiplier
            while hasScore do
                local index, count = STD.getIndex(storage, id)
                local numToGet = math.floor(score / multiplier)
                if (index <= 0) then
                    local success = Credits.selectedCredit:attemptCraft(size, numToGet, storage, intermediaryStorage, turtleName) or false
                    if success then
                        goto continue
                    end
                    if size > 1 then
                        break
                    end

                    local key = getKey()
                    generateIOU(printer, key, Credits.selectedCredit.name, score)
                    writeReceipt(key, Credits.selectedCredit.name, score)
                    intermediaryStorage.pullItems(peripheral.getName(printer), 8)
                    intermediaryStorage.pushItems(peripheral.getName(output), 1)
                    goto outerbreak
                end
                local numToPush = math.min(count, numToGet)
                storage.pushItems(peripheral.getName(output), index, numToPush)
                Score:updateScore(score - (multiplier * numToPush))
                score = Score:getScore()
                hasScore = score >= multiplier
                ::continue::
            end
        end
        ::outerbreak::
        rednet.send(output.getID(), "dispense")
    end

    --- Counts and gathers the credits in the input inventory and adds them to the score.
    --- @param screen table Represents the screen to draw score and credit to.
    --- @param storage table Represents where currency is stored.
    --- @param input any Represents an inventory where players can input currency.
    --- @param output any Represents a turtle that outputs unwanted items.
    --- @param colours table Represents a collection of colours for the game to use.
    function STD.countCredits(screen, storage, input, output, colours)
        local shouldThrow = false
        for i = 1,input.size(),1 do
            local item = input.getItemDetail(i)
            if item ~= nil
                and Credits:validCurrency(item.name)
                and (Credits.selectedCredit == nil or Credits.selectedCredit.name == Credits:getCreditType(item.name))
            then
                if Credits.selectedCredit == nil then
                    Credits.selectedCredit = Credits.credits[Credits:getCreditType(item.name)]
                    Credits.selectedCredit:draw(screen, 1, 1, colours)
                end
                local count = item.count
                local value = Credits.selectedCredit:getMultiplierById(item.name)
                for _ = 1, count, 1 do
                    local newValue = Score:getScore() + value
                    if (newValue > Score.max) then
                        shouldThrow = true
                    else
                        Score:updateScore(newValue)
                        local width, _ = screen.getSize()
                        Score:draw(screen, width / 2, 3, true, colours)
                        input.pushItems(peripheral.getName(storage), i, 1)
                    end
                end
            elseif item ~= nil then
                shouldThrow = true
            end
        end
        if shouldThrow then
            for i = 1,input.size(),1 do
                local item = input.getItemDetail(i)
                if item ~= nil then
                    input.pushItems(peripheral.getName(output), i)
                end
            end
            rednet.send(output.getID(), "dispense")
        end
    end
end
--- BUTTON ---
do
    Button.__index = Button

    --- Constructor for buttons.
    --- @param label string The label on the button.
    --- @param clickEvent function The function to call when the button is pressed.
    --- @param x number The X coordinate to place the button at.
    --- @param y number The Y coordinate to place the button at.
    --- @param width number The width of the button.
    --- @param height number The height of the button.
    --- @param labelPad number Whether there should be some padding outside the label of the button.
    --- @param backgroundColourNormal number The background colour of the button.
    --- @param borderColour number The border colour of the button.
    --- @param textColourNormal number The text colour of the button.
    --- @return table The button that was created.
    function Button.new(label, clickEvent, x, y, width, height, labelPad, backgroundColourNormal, borderColour, textColourNormal)
        local button = setmetatable({}, Button)
        button.isActive = false
        button.clickEvent = clickEvent or function() print("Click!") end
        button.x = x or 1
        button.y = y or 1
        button.width = width or 3
        button.height = height or 3
        button.isPressed = false
        button.backgroundColourCurrent = backgroundColourNormal or colours.black
        button.backgroundColourNormal = backgroundColourNormal or colours.black
        button.borderColour = borderColour
        button.label = label or "Press"
        button.labelPad = labelPad or 0
        button.textColourCurrent = textColourNormal or colours.lightGray
        button.textColourNormal = textColourNormal or colours.lightGray

        button.width = button.width + (button.labelPad * 2)
        button.height = button.height + (button.labelPad * 2)
        if button.borderColour then
            button.width = button.width + 2
            button.height = button.height + 2
        end

        return button
    end

    --- Displays the button on the provided screen.
    --- @param screen table Represents the game screen, usually a monitor.
    function Button:displayOnScreen(screen)
        local oldTerm = term.redirect(screen)
        local x_offset, y_offset = self.labelPad, self.labelPad

        if self.borderColour then
            x_offset = x_offset + 1
            y_offset = y_offset + 1
        end

        paintutils.drawFilledBox(self.x, self.y, self.x + self.width - 1, self.y + self.height - 1, self.backgroundColourCurrent)
        paintutils.drawBox(self.x, self.y, self.x + self.width - 1, self.y + self.height - 1, self.borderColour)

        term.setTextColour(self.textColourCurrent)
        term.setBackgroundColour(self.backgroundColourCurrent)
        term.setCursorPos(self.x + x_offset, self.y + y_offset)
        term.write(self.label)

        self.isActive = true
        term.redirect(oldTerm)
    end

    --- Disables the button.
    function Button:disable()
        self.isActive = false
    end

    --- Checks if the provided x,y coordinates collides with the button.
    --- @param x number
    --- @param y number
    --- @return boolean
    function Button:collides(x, y)
        return ((x >= self.x) and (x < (self.x + self.width))) and ((y >= self.y) and (y < (self.y + self.height))) and self.isActive
    end
end
--- BUTTONS ---
do
    Buttons.__index = Buttons
    Buttons.allButtons = {}

    --- Adds a button to the game.
    --- @param label string The label on the button.
    --- @param clickEvent function The function to call when the button is pressed.
    --- @param x number The X coordinate to place the button at.
    --- @param y number The Y coordinate to place the button at.
    --- @param width number The width of the button.
    --- @param height number The height of the button.
    --- @param labelPad number Whether there should be some padding outside the label of the button.
    --- @param backgroundColourNormal number The background colour of the button.
    --- @param borderColour number The border colour of the button.
    --- @param textColourNormal number The text colour of the button.
    --- @return table The button that was created.
    function Buttons:addButton(label, clickEvent, x, y, width, height, labelPad, backgroundColourNormal, borderColour, textColourNormal)
        local button = Button.new(label, clickEvent, x, y, width, height, labelPad, backgroundColourNormal, borderColour, textColourNormal)
        self.allButtons[#self.allButtons + 1] = button
        return button
    end
end
--- CREDIT ---
do
    Credit.__index = Credit
    Credit.SMALL = 1
    Credit.MEDIUM = 2
    Credit.LARGE = 3

    --- Returns the max size of this credit type.
    --- @return number maxSize Max size of this credit type.
    function Credit:getMax()
        if self.values == nil then return 0 end
        local maxSize = 0
        for _ in pairs(self.values) do
            maxSize = maxSize + 1
        end
        return maxSize
    end

    --- Crafts from big to small, aka places just one item in the turtles inventory to craft with.
    --- @param size number The size to craft towards.
    --- @param num number How many to craft.
    --- @param storage table Represents where currency is stored.
    --- @param intermediaryStorage table Represents an intermediary inventory to be used when moving items to and from turtles.
    --- @param turtleName string Represents a turtle.
    --- @return boolean success Whether the craft was successful.
    function Credit:craftBig(size, num, storage, intermediaryStorage, turtleName)
        local itemData = self:getDataBySize(size+1)
        if itemData == nil then return false end

        local itemId = itemData.id
        local itemIndex, itemCount = STD.getIndex(storage, itemId)
        local numToCraft = math.floor(num / itemData.multiplier)
        numToCraft = math.min(math.max(numToCraft, 1), itemCount)
        if (itemIndex < 1) then
            return false
        end

        STD.clearTurtle(intermediaryStorage, turtleName)

        storage.pushItems(turtleName, itemIndex, numToCraft)

        local success = turtle.craft()

        STD.clearTurtle(storage, turtleName)
        STD.turtleDevour(intermediaryStorage, turtleName)

        return success
    end

    --- Crafts from small to big, aka a 2x2 or 3x3 recipe depending on the credit.
    --- @param size number The size to craft towards.
    --- @param num number How many to craft.
    --- @param storage table Represents where currency is stored.
    --- @param intermediaryStorage table Represents an intermediary inventory to be used when moving items to and from turtles.
    --- @param turtleName string Represents a turtle.
    --- @return boolean success Whether the craft was successful.
    function Credit:craftSmall(size, num, storage, intermediaryStorage, turtleName)
        local itemData = self:getDataBySize(size-1)
        if itemData == nil then return false end

        local itemId = itemData.id
        local multiplier = self.values[size].multiplier
        if type(multiplier) ~= "number" then
            return false
        end
        local subSize = math.sqrt(multiplier)
        local totalCount = STD.getTotalCount(storage, itemId)
        local maxCraft = math.floor(totalCount / multiplier)
        local totalNum = math.min(num, maxCraft)

        STD.clearTurtle(intermediaryStorage, turtleName)

        local leftoverCount = 0
        local index, count = STD.getIndex(storage, itemId)
        for row = 1, subSize do
            for col = 1, subSize do
                local countToPush = totalNum
                while countToPush > 0 do
                    local currentNum = totalNum
                    if leftoverCount > 0 then
                        currentNum = leftoverCount
                        leftoverCount = 0
                    elseif (count < totalNum) then
                        leftoverCount = math.abs(count - totalNum)
                        currentNum = count
                    end

                    if index < 1 then
                        STD.clearTurtle(storage, turtleName)
                        STD.turtleDevour(intermediaryStorage, turtleName)
                        return false
                    end

                    local coord = (row - 1) * 4 + col

                    storage.pushItems(turtleName, index, currentNum, coord)
                    countToPush = countToPush - currentNum

                    count = count - currentNum
                    if leftoverCount > 0 then
                        index, count = STD.getIndex(storage, itemId)
                    end
                end
            end
        end

        local success = turtle.craft()
        STD.clearTurtle(storage, turtleName)
        STD.turtleDevour(intermediaryStorage, turtleName)
        print("Small sucess: " .. tostring(success))
        return success
    end

    --- Attempts to craft the item matching the provided size.
    --- @param size number The size to craft towards.
    --- @param num number How many to craft.
    --- @param storage table Represents where currency is stored.
    --- @param intermediaryStorage table Represents an intermediary inventory to be used when moving items to and from turtles.
    --- @param turtleName string Represents a turtle.
    --- @return boolean success Whether the craft was successful.
    function Credit:attemptCraft(size, num, storage, intermediaryStorage, turtleName)
        local maxSize = self:getMax()
        if size < maxSize then
            local result = self:craftBig(size, num, storage, intermediaryStorage, turtleName)
            if result then return true end
        end
        local result = self:craftSmall(size, num, storage, intermediaryStorage, turtleName)
        return result
    end

    --- Gets the size and data matching the ID for this credit.
    --- Returns nil if the ID does not match anything.
    --- @param id string Represents the item ID to match.
    --- @return table|nil data The data matching this ID, or nil if none match.
    function Credit:getDataById(id)
        if self.values == nil then return nil end
        for _,data in pairs(self.values) do
            if (id == data["id"]) then return data end
        end
        return nil
    end

    --- Gets the data matching the size for this credit.
    --- Returns nil if the size is outside the min or max of this credit type.
    --- @param size number Represents the size to match.
    --- @return table|nil data The data matching this size, or nil if it's out of bounds.
    function Credit:getDataBySize(size)
        if self.values == nil then
            print("Credit has no values.")
            return nil
        end

        return self.values[size]
    end

    --- Gets the multiplier matching the ID for this credit.
    --- Returns nil if the ID does not match anything.
    --- @param id string Represents the item ID to match.
    --- @return number|nil multiplier The multiplier matching this ID, or nil if none match.
    function Credit:getMultiplierById(id)
        local size = self:getSizeById(id)
        if size == nil then return nil end
        return self:getMultiplierBySize(size)
    end

    --- Gets the multiplier matching the ID for this credit.
    --- Returns nil if the ID does not match anything.
    --- @param size number Represents the size to match.
    --- @return number|nil multiplier The multiplier matching this ID, or nil if none match.
    function Credit:getMultiplierBySize(size)
        if self.values == nil then return nil end
        if type(size) ~= "number" then return nil end
        local totalMultiplier = 1
        for _ = size - 1, 1, -1 do
            local multiplier = self.values[size].multiplier or 1
            totalMultiplier = totalMultiplier * multiplier
        end
        return totalMultiplier
    end

    --- Gets the size matching the ID for this credit.
    --- Returns nil if the ID does not match anything.
    --- @param id string Represents the item ID to match.
    --- @return number|nil size The size matching this ID, or nil if none match.
    function Credit:getSizeById(id)
        if self.values == nil then return nil end
        for size, data in pairs(self.values) do
            if (id == data["id"]) then return size end
        end
        return nil
    end

    --- Gets the IDs matching the size for this credit.
    --- Returns nil if the size does not match anything.
    --- @param size number Represents the item size to match.
    --- @return string|nil id The ID matching this size, or nil if none match.
    function Credit:getIdBySize(size)
        if self.values == nil then
            print("Credit has no values.")
            return nil
        end
        if type(size) ~= "number" then
            print("Size is not a number.")
            return nil
        end
        local data = self:getDataBySize(size)
        if data == nil then
            print("Could not fetch data from credit.")
            return nil
        end
        return data.id
    end

    --- Draws the name of this credit type to the screen.
    --- @param screen table Represents the screen to draw to.
    --- @param x number Represents the X coordinate to start drawing at.
    --- @param y number Represents the Y coordinate to start drawing at.
    --- @param colours table Represents a collection of colours for the game to use.
    function Credit:draw(screen, x, y, colours)
        local oldTerm = term.redirect(screen)
        local label = "Credit Type: " .. self.name

        term.setTextColour(colours.creditTextColour)
        term.setBackgroundColour(colours.creditBackgroundColour)
        term.setCursorPos(x, y)
        term.write(label)

        term.redirect(oldTerm)
    end

    --- Credit constructor.
    --- @param name string The name of this credit.
    --- @param values table The data of this credit.
    --- @return table credit The created credit.
    function Credit.new(name, values)
        local credit = setmetatable({}, Credit)

        credit.name = name
        credit.values = values or {
            [Credit.LARGE] = { ['id'] = 'minecraft:iron_block', ['multiplier'] = 9 },
            [Credit.MEDIUM] = { ['id'] = 'minecraft:iron_ingot', ['multiplier'] = 9 },
            [Credit.SMALL] = { ['id'] = 'minecraft:iron_nugget' },
        }

        return credit
    end
end
--- CREDITS ---
do
    Credits.credits = {
        --["emeralds"] = Credit.new("emeralds"),
        ["iron"] = Credit.new("iron", {
            [Credit.LARGE] = { ['id'] = 'minecraft:iron_block', ['multiplier'] = 9 },
            [Credit.MEDIUM] = { ['id'] = 'minecraft:iron_ingot', ['multiplier'] = 9 },
            [Credit.SMALL] = { ['id'] = 'minecraft:iron_nugget' },
        }),
    }
    Credits.selectedCredit = nil
    Credits.__index = Credits

    --- Checks if the provided id is a valid type of currency.
    --- @param id string Represents an item ID to check against.
    --- @return boolean valid Whether the currency is valid or not.
    function Credits:validCurrency(id)
        for _,credit in pairs(Credits.credits) do
            local size = credit:getDataById(id)
            if size ~= nil then return true end
        end
        return false
    end

    --- Gets the type of credit this ID is affiliated with.
    --- Returns nil if there are no matches.
    --- @param id string Represents an item ID to check against.
    --- @return string|nil creditName The name of the credit type.
    function Credits:getCreditType(id)
        for creditName,credit in pairs(Credits.credits) do
            local size = credit:getDataById(id)
            if size ~= nil then return creditName end
        end
    end
end
--- SCORE ---
do
    Score.__index = Score
    Score.value = 0
    Score.max = 10000
    Score.min = 0

    --- Updates the score to the provided value.
    --- @param value number The value to set the score to.
    function Score:updateScore(value)
        if type(value) ~= "number" then return end
        Score.value = value
    end

    --- Gets the current score.
    --- @return number value The current score.
    function Score:getScore()
        return Score.value
    end

    --- Draws the score to the screen.
    --- @param screen table Represents the screen to draw to.
    --- @param x number Represents the X coordinate to start drawing at.
    --- @param y number Represents the Y coordinate to start drawing at.
    --- @param offset boolean Whether to offset the score by the score text length.
    --- @param colours table Represents a collection of colours for the game to use.
    function Score:draw(screen, x, y, offset, colours)
        local oldTerm = term.redirect(screen)
        local scoreTitle = "Score:"
        local scoreText = tostring(self.value)
        local scoreTextLen = string.len(scoreText) + 2
        if scoreTextLen < 13 then scoreTextLen = 13 end
        if offset then x = x - math.floor(scoreTextLen / 2) end

        term.setTextColour(colours.scoreTitleTextColour)
        term.setBackgroundColour(colours.scoreTitleBackgroundColour)
        term.setCursorPos(x+1, y)
        term.write(scoreTitle)

        paintutils.drawFilledBox(x, y+1, x + scoreTextLen - 1, y + 2, colours.scoreValueBackgroundColour)

        term.setTextColour(colours.scoreValueTextColour)
        term.setBackgroundColour(colours.scoreValueBackgroundColour)
        term.setCursorPos(x+1, y+2)
        term.write(scoreText)

        term.redirect(oldTerm)
    end
end
--- IMAGES ---
do
    Images.__index = Images
Images.num1 = paintutils.parseImage([[
 32
  2
  2
  1
 211
]])
Images.num2 = paintutils.parseImage([[
 32
3  1
  2
 2
2111
]])
Images.num3 = paintutils.parseImage([[
 32
3  2
  1
2  1
 21
]])
Images.num4 = paintutils.parseImage([[
3  2
3  1
2211
   1
   1
]])
Images.num5 = paintutils.parseImage([[
3322
2
 211
   1
211
]])
Images.num6 = paintutils.parseImage([[
 322
3
221
2  1
 11
]])
Images.num7 = paintutils.parseImage([[
3322
   1
  1
 1
2
]])
Images.num8 = paintutils.parseImage([[
 32
3  1
 21
2  1
 11
]])
Images.num9 = paintutils.parseImage([[
 32
3  1
 211
   1
211
]])
Images.num0 = paintutils.parseImage([[
 32
3  1
2  1
2  1
 11
]])
Images.jack = paintutils.parseImage([[
332
   2
   1
2  1
 21
]])
Images.queen = paintutils.parseImage([[
 32
3  2
2  1
2 1
 1 1
]])
Images.king = paintutils.parseImage([[
3  1
3 2
22
2 1
2  1
]])
Images.ace = paintutils.parseImage([[
 32
3  1
2211
2  1
2  1
]])
Images.joker = paintutils.parseImage([[
  649
  5aa9
    a9 9
  a9aaaa95
 5aaaaaa456
654aaaa9 4
 4  9999
    2211
]])
Images.spade = paintutils.parseImage([[
  2
 231
23211
  1
 211
]])
Images.heart = paintutils.parseImage([[
 5 4
56544
55544
 544
  4
]])
Images.club = paintutils.parseImage([[
 222
23211
22111
  1
 211
]])
Images.diamond = paintutils.parseImage([[
  5
 564
56544
 544
  4
]])
Images.bust = paintutils.parseImage([[
 32222  3     2   3222   32221
3     2 3     2  3    1 3  2  1
2     2 2     2 2          2
2    2  2     2  2         2
22222   2     1   222      2
2    1  2     1      1     2
2     1  2   1        1    1
2     1  2   1  2    1     1
 21111    211    2211     211
]])
Images.win = paintutils.parseImage([[
 3   2   3221 3    2
3     2 3 2   32    2
2     2   2   2 2   2
2     1   2   2 2   1
 2   1    2   2  2  1
 2 2 1    1   2   2 1
 2 2 1    1   2   1 1
  2 1     1 1 2    11
  2 1   2111   2    1
]])
Images.draw = paintutils.parseImage([[
 3222   32222     322    3   2
3    2  3    2   3   2  3     2
2     2 2     2 2     1 2     2
2     1 2     1 2     1 2     1
2     1 2    1  2222211  2   1
2     1 22221   2     1  2 2 1
2     1 2    1  2     1  2 2 1
2    1  2     1 2     1   2 1
 2211   2     1 2     1   2 1
]])
Images.lose = paintutils.parseImage([[
 3       322     3222   32222
3       3   2   3    1 3     1
2      2     2 2       2
2      2     2  2      2
2      2     1   222   2222
2      2     1      1  2
2      2     1       1 2
2    1  2   1  2    1  2     1
 22111   211    2211    22111
]])
Images.forfeit = paintutils.parseImage([[
  3222    322   32222     3222   32222   3221  32221
 3    2  3   2  3    2   3    2 3     2 3 2   3  2  1
 2      2     2 2     2  2      2         2      2
 2      2     2 2     1  2      2         2      2
 2222   2     1 2    1   2222   2222      2      2
 2      2     1 22221    2      2         1      2
 2      2     1 2    1   2      2         1      1
 2       2   1  2     1  2      2     1   1 1    1
2         211   2     1 2        22111  2111    211
]])

    local cardLength = 13
    local cardHeight = 13

    --- Draws a joker card.
    --- @param screen table Represents the screen to draw to.
    --- @param x number Represents the X coordinate to start drawing at.
    --- @param y number Represents the Y coordinate to start drawing at.
    function Images:drawJoker(screen, x, y)
        local oldTerm = term.redirect(screen)
        local borderColour = 2
        local background = 1

        term.setCursorPos(x+1, y)
        term.setBackgroundColour(borderColour)
        term.write(string.rep(" ", cardLength))

        for i=1, cardHeight, 1 do
            term.setCursorPos(x, y+i)
            term.setBackgroundColour(borderColour)
            term.write(" ")

            term.setCursorPos(x+1, y+i)
            term.setBackgroundColour(background)
            term.write(string.rep(" ", cardLength))

            term.setCursorPos(x+1+cardLength, y+i)
            term.setBackgroundColour(borderColour)
            term.write(" ")
        end

        term.setCursorPos(x+1, y+1+cardHeight)
        term.setBackgroundColour(borderColour)
        term.write(string.rep(" ", cardLength))

        term.setBackgroundColour(borderColour)
        for i=1,cardHeight,(cardHeight-1) do
            term.setCursorPos(x+1, y+i)
            term.write(" ")
            term.setCursorPos(x+cardLength, y+i)
            term.write(" ")
        end

        paintutils.drawImage(Images.joker, x+2, y+3)
        term.redirect(oldTerm)
    end

    --- Draws a card.
    --- @param screen table Represents the screen to draw to.
    --- @param x number Represents the X coordinate to start drawing at.
    --- @param y number Represents the Y coordinate to start drawing at.
    --- @param num table Represents the number image to draw.
    --- @param suit string Represents the suit of the card.
    function Images:drawCard(screen, x, y, num, suit)
        local oldTerm = term.redirect(screen)
        local borderColour = 2
        local numBackground = 1
        local suitBackgroundPrimary
        local suitBackgroundSecondary
        local suitImg

        if suit == "spade" or suit == "club" then
            suitBackgroundPrimary = 32
            suitBackgroundSecondary = 16
        elseif suit == "heart" or suit == "diamond" then
            suitBackgroundPrimary = 8
            suitBackgroundSecondary = 4
        end

        if suit == "spade" then
            suitImg = Images.spade
        elseif suit == "heart" then
            suitImg = Images.heart
        elseif suit == "club" then
            suitImg = Images.club
        elseif suit == "diamond" then
            suitImg = Images.diamond
        end

        term.setCursorPos(x+1, y)
        term.setBackgroundColour(borderColour)
        term.write(string.rep(" ", cardLength))

        for i=1, cardHeight, 1 do
            term.setCursorPos(x, y+i)
            term.setBackgroundColour(borderColour)
            term.write(" ")

            for j=1, cardLength, 1 do
                term.setCursorPos(x+j, y+i)
                local diagonal_forward = j + i <= math.floor((cardLength + cardHeight) / 2)+1
                local diagonal_backward = j - i >= 1
                if (i == j) then
                    term.setBackgroundColour(borderColour)
                elseif (diagonal_backward) then
                    if (diagonal_forward) then
                        term.setBackgroundColour(suitBackgroundPrimary)
                    else
                        term.setBackgroundColour(suitBackgroundSecondary)
                    end
                else
                    term.setBackgroundColour(numBackground)
                end
                term.write(" ")
            end

            term.setCursorPos(x+1+cardLength, y+i)
            term.setBackgroundColour(borderColour)
            term.write(" ")
        end

        term.setCursorPos(x+1, y+1+cardHeight)
        term.setBackgroundColour(borderColour)
        term.write(string.rep(" ", cardLength))

        term.setBackgroundColour(borderColour)
        for i=1,cardHeight,(cardHeight-1) do
            term.setCursorPos(x+1, y+i)
            term.write(" ")
            term.setCursorPos(x+cardLength, y+i)
            term.write(" ")
        end

        paintutils.drawImage(suitImg, x+cardLength-5, y+2)
        paintutils.drawImage(num, x+2, y+cardHeight-5)
        term.redirect(oldTerm)
    end

    --- Draws a face down card.
    --- @param screen table Represents the screen to draw to.
    --- @param x number Represents the X coordinate to start drawing at.
    --- @param y number Represents the Y coordinate to start drawing at.
    function Images:drawFaceDown(screen, x, y)
        local oldTerm = term.redirect(screen)
        local borderColour = 1
        local primaryColour = 32
        local secondaryColour = 16

        term.setCursorPos(x+1, y)
        term.setBackgroundColour(borderColour)
        term.write(string.rep(" ", cardLength))

        for i=1, cardHeight, 1 do
            term.setCursorPos(x, y+i)
            term.setBackgroundColour(borderColour)
            term.write(" ")

            for j=1, cardLength, 1 do
                if (i + j) % 2 == 1 then
                    term.setBackgroundColour(primaryColour)
                else
                    term.setBackgroundColour(secondaryColour)
                end
                term.setCursorPos(x+j, y+i)
                term.write(" ")
            end

            term.setCursorPos(x+1+cardLength, y+i)
            term.setBackgroundColour(borderColour)
            term.write(" ")
        end

        term.setCursorPos(x+1, y+1+cardHeight)
        term.setBackgroundColour(borderColour)
        term.write(string.rep(" ", cardLength))

        term.setBackgroundColour(borderColour)
        for i=1,cardHeight,(cardHeight-1) do
            term.setCursorPos(x+1, y+i)
            term.write(" ")
            term.setCursorPos(x+cardLength, y+i)
            term.write(" ")
        end

        term.redirect(oldTerm)
    end

    --- Gets the width of an image.
    --- @param image table Represents the image to measure.
    --- @return number widest The width of the image.
    function Images:getWidth(image)
        local widest = 0
        for _, line in pairs(image) do
            if #line > widest then
                widest = #line
            end
        end
        return widest
    end

    --- Draws a box.
    --- @param screen table Represents the screen to draw to.
    --- @param x number Represents the X coordinate to start drawing at.
    --- @param y number Represents the Y coordinate to start drawing at.
    --- @param image table Represents the image to draw in the box.
    --- @param borderColour number Represents the border colour of the box.
    --- @param topBackgroundColour number Represents the top background colour of the box.
    --- @param bottomBackgroundColour number Represents the bottom background colour of the box.
    function Images:drawBox(screen, x, y, image, borderColour, topBackgroundColour, bottomBackgroundColour)
        local oldTerm = term.redirect(screen)
        local length = Images:getWidth(image) + 3
        local height = #image + 3
        x = x - math.floor(length/2)
        y = y - math.floor(height/2)
        for i=1,height,1 do
            if i == 1 or i == height then
                term.setBackgroundColour(borderColour)
            elseif (i > 6) then
                term.setBackgroundColour(topBackgroundColour)
            else
                term.setBackgroundColour(bottomBackgroundColour)
            end
            term.setCursorPos(x, y+i-1)
            term.write(string.rep(" ", length))

            term.setBackgroundColour(borderColour)
            term.setCursorPos(x, y+i-1)
            term.write(" ")
            term.setCursorPos(x + length, y+i-1)
            term.write(" ")
        end

        paintutils.drawImage(image, x+2, y+2)

        term.redirect(oldTerm)
    end

    --- Draws a bust box.
    --- @param screen table Represents the screen to draw to.
    --- @param x number Represents the X coordinate to start drawing at.
    --- @param y number Represents the Y coordinate to start drawing at.
    function Images:drawBust(screen, x, y)
        Images:drawBox(screen, x, y, Images.bust, 2, 512, 1024)
    end

    --- Draws a win box.
    --- @param screen table Represents the screen to draw to.
    --- @param x number Represents the X coordinate to start drawing at.
    --- @param y number Represents the Y coordinate to start drawing at.
    function Images:drawWin(screen, x, y)
        Images:drawBox(screen, x, y, Images.win, 2, 512, 1024)
    end

    --- Draws a draw box.
    --- @param screen table Represents the screen to draw to.
    --- @param x number Represents the X coordinate to start drawing at.
    --- @param y number Represents the Y coordinate to start drawing at.
    function Images:drawDraw(screen, x, y)
        Images:drawBox(screen, x, y, Images.draw, 2, 512, 1024)
    end

    --- Draws a lose box.
    --- @param screen table Represents the screen to draw to.
    --- @param x number Represents the X coordinate to start drawing at.
    --- @param y number Represents the Y coordinate to start drawing at.
    function Images:drawLose(screen, x, y)
        Images:drawBox(screen, x, y, Images.lose, 2, 512, 1024)
    end

    --- Draws a forfeit box.
    --- @param screen table Represents the screen to draw to.
    --- @param x number Represents the X coordinate to start drawing at.
    --- @param y number Represents the Y coordinate to start drawing at.
    function Images:drawForfeit(screen, x, y)
        Images:drawBox(screen, x, y, Images.forfeit, 2, 512, 1024)
    end
end
--- HAND ---
do
    Hand.__index = Hand

    --- Hand constructor
    --- @param includeJoker boolean Whether to include jokers when drawing initial cards.
    --- @param cards number How many initial cards to draw.
    --- @param faceDown boolean Whether cards should display face down.
    --- @return table hand The created hand.
    function Hand.new(includeJoker, cards, faceDown)
        local hand = setmetatable({}, Hand)
        hand.cards = {}
        hand.cardAmount = 0
        for _=1,cards,1 do
            hand:addCard(Card.newRandom(includeJoker, faceDown))
        end
        return hand
    end

    --- Adds a card to the hand.
    --- @param card table The card to add.
    function Hand:addCard(card)
        table.insert(self.cards, card)
        self.cardAmount = self.cardAmount + 1
    end

    --- Gets the value of the current hand.
    --- @return number total Sums the value of the cards in the hand.
    function Hand:getValue()
        local total = 0
        local aces = {}
        for _, card in pairs(self.cards) do
            if card.isAce then
                table.insert(aces, card)
            else
                total = total + card.value
            end
        end
        for i=1,#aces,1 do
            if total + #aces - i <= 10 then
                total = total + 11
            else
                total = total + 1
            end
        end
        return total
    end

    --- Evaluates the value of the hand based on BlackJack rules.
    --- @return number totalValue Minimum 0, maximum 22 with starting BlackJack, or 21 with normal BlackJack.
    function Hand:evaluateHand()
        local totalValue = self:getValue()
        if totalValue == 21 and self.cardAmount == 2 then
            -- BlackJack
            return 22
        end
        if totalValue > 21 then
            -- Bust
            return 0
        end
        return totalValue
    end

    --- Draws the hand to the screen.
    --- @param screen table Represents the screen to draw to.
    --- @param width number Represents the max width of the hand.
    --- @param y number Represents the Y coordinate to start drawing at.
    function Hand:draw(screen, width, y)
        local amount = self.cardAmount
        local startX = width / 2 - 7 - (9 * (amount-1))
        if amount > 3 then
            startX = startX + math.floor((9 * (amount-2)) / 2) + 2
        end
        local cards = self.cards
        for i, card in ipairs(cards) do
            local boost = (16 * (i-1))
            if i < amount-1 then
                boost = (7 * (i-1))
            elseif amount > 3 then
                boost = (7 * (amount - 3)) + (16 * (2 - (amount - i)))
            end
            local x = startX + boost
            card:draw(screen, x, y)
        end
    end
end
--- CARD ---
do
    Card.__index = Card
    Card.suits = {
        "spade",
        "heart",
        "club",
        "diamond"
    }
    Card.numbers = {
        Images.num1,
        Images.num2,
        Images.num3,
        Images.num4,
        Images.num5,
        Images.num6,
        Images.num7,
        Images.num8,
        Images.num9
    }
    Card.courts = {
        Images.jack,
        Images.queen,
        Images.king,
        Images.ace,
    }

    --- Card constructor.
    --- @param value number The value of the card being created.
    --- @param suit string The suit of the card being created.
    --- @param faceDown boolean Whether the card should be drawn face down.
    --- @return table card The created card.
    function Card.new(value, suit, faceDown)
        local card = setmetatable({}, Card)
        if value == 14 then
            card.isJoker = true
            return card
        elseif value < 10 and value > 0 then
            card.num = Card.numbers[value]
            card.isCourt = true
            card.value = value
        elseif value < 13 and value > 9 then
            card.num = Card.courts[value-9]
            card.isNumber = true
            card.value = 10
        else
            card.num = Images.ace
            card.isAce = true
            card.value = 11
        end
        card.suit = suit
        card.faceDown = faceDown or false
        return card
    end

    --- Random card constructor.
    --- @param includeJoker boolean Whether to include jokers when randomly selecting a card.
    --- @param faceDown boolean Whether the card should be drawn face down.
    --- @return table card The created card.
    function Card.newRandom(includeJoker, faceDown)
        local card = setmetatable({}, Card)
        local joker = false
        if includeJoker then
            joker = math.random(1,27) == 1
        end
        if joker then
            card.isJoker = true
            return card
        end
        card.suit = Card.suits[math.random(1,4)]
        local value = math.random(2,13)
        if value < 10 then
            card.num = Card.numbers[value]
            card.isNumber = true
            card.value = value
        elseif value < 13 then
            card.num = Card.courts[value-9]
            card.isCourt = true
            card.value = 10
        else
            card.num = Images.ace
            card.isAce = true
            card.value = 11
        end
        card.faceDown = faceDown or false
        return card
    end

    --- Draws the card.
    --- @param screen table Represents the screen to draw to.
    --- @param x number Represents the X coordinate to start drawing at.
    --- @param y number Represents the Y coordinate to start drawing at.
    function Card:draw(screen, x, y)
        if self.faceDown then
            Images:drawFaceDown(screen, x, y)
            return
        end
        if self.isJoker then
            Images:drawJoker(screen, x, y)
            return
        end
        Images:drawCard(screen, x, y, self.num, self.suit)
    end
end
--- BALL ---
do
    Ball.__index = Ball

    --- Ball constructor.
    --- @param x number The X coordinate to spawn the ball at.
    --- @param y number The Y coordinate to spawn the ball at.
    --- @param colour number The colour of the ball.
    --- @param foregroundColourMap table The colour map of the foreground.
    --- @param backgroundColourMap table The colour map of the background.
    --- @return table ball The created ball.
    function Ball.new(x, y, colour, foregroundColourMap, backgroundColourMap)
        local ball = setmetatable({}, Ball)

        ball.x = x or 0
        ball.y = y or 0
        ball.colour = colour or colours.black
        ball.foregroundColourMap = foregroundColourMap or {}
        ball.backgroundColourMap = backgroundColourMap or {}
        ball.prevPixels = {
            ["1:1"] = colours.black,
            ["1:2"] = colours.black,
            ["2:1"] = colours.black,
            ["2:2"] = colours.black,
        }

        return ball
    end

    --- Checks if the coordinates collide with a pin.
    --- @param pinAreas table The pins to check against.
    --- @param x number The x coordinate to check.
    --- @param y number The y coordinate to check.
    --- @return boolean collides Whether the coordinates collide with the pin.
    local function checkPinCollision(pinAreas, x, y)
        for _, area in pairs(pinAreas) do
            for _, pinCoord in pairs(area) do
                local result = x == pinCoord.x and y == pinCoord.y
                if result then return true end
            end
        end
        return false
    end

    --- Checks for collisions below the ball based on passed function.
    --- @param pinAreas table The pins to check against.
    --- @return table result
    function Ball:checkBelowBall(pinAreas)
        local result = {
            left_collided = checkPinCollision(pinAreas, self.x, self.y+2),
            right_collided = checkPinCollision(pinAreas, self.x+1, self.y+2)
        }
        return result
    end

    --- Clears the ball from the screen and replaces it with a fallbackColour.
    --- @param screen tablelib The screen to draw to.
    --- @param fallbackColour number The colour to replace the ball with.
    function Ball:clear(screen, fallbackColour)
        local oldTerm = term.redirect(screen)
        fallbackColour = fallbackColour or colours.black
        for x = 1, 2, 1 do
            local checkX = self.x + x - 1
            local backgroundColumns = self.backgroundColourMap[checkX]
            local foregroundColumns = self.foregroundColourMap[checkX]
            for y = 1, 2, 1 do
                local checkY  =self.y + y - 1
                term.setBackgroundColour(fallbackColour)
                if backgroundColumns ~= nil and backgroundColumns[checkY] ~= nil then
                    term.setBackgroundColour(backgroundColumns[checkY]) end
                if foregroundColumns ~= nil and foregroundColumns[checkY] ~= nil then
                    term.setBackgroundColour(foregroundColumns[checkY]) end

                term.setCursorPos(checkX, checkY)
                term.write(" ")
            end
        end
        self.isActive = false
        term.redirect(oldTerm)
    end

    --- Moves the ball.
    --- @param screen tablelib The screen to draw to.
    --- @param x number The X amount to move the ball by.
    --- @param y number The Y amount to move the ball by.
    --- @param fallbackColour number The colour to replace the ball with.
    function Ball:move(screen, x, y, fallbackColour)
        self:clear(screen, fallbackColour)
        self.x = self.x + x
        self.y = self.y + y
        self:displayOnScreen(screen)
    end

    function Ball:displayOnScreen(screen)
        local oldTerm = term.redirect(screen)
        term.setCursorPos(self.x,self.y)
        term.setBackgroundColour(self.colour)
        for x = 1, 2, 1 do
            local checkX = self.x + x - 1
            local columns = self.foregroundColourMap[checkX]
            for y = 1, 2, 1 do
                local checkY = self.y + y - 1
                if columns ~= nil and columns[checkY] ~= nil then goto continue end
                term.setCursorPos(checkX, checkY)
                term.write(" ")
                ::continue::
            end
        end
        self.isActive = true
        term.redirect(oldTerm)
    end
end
--- RETURN ---
return { STD = STD, Buttons = Buttons, Credits = Credits, Score = Score, Hand = Hand, Card = Card, Images = Images, Ball = Ball }
