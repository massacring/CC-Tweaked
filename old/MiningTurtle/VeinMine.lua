local MiningLib = require('MassaMiningTurtleLib')

local tags = {}
local ids = {}
local inclusive

local function tutorial()
    print("How to use the VeinMine script.")
    print("")
    print("[] means required.")
    print("<> means optional.")
    print("bool means either true or false.")
    print("")
    print("VerticalMining [inclusive: bool] <id: text> <tag: #text>")
    print("")
    print("You can enter as many tags and ids as you wish.")
    print("Tags must always be affixed with '#'.")
    print("'inclusive' is whether the ids and tags should be a whitelist (true) or blacklist (false).")
    print("")
    print("Example command:")
    print("'VeinMine true #minecraft:logs #minecraft:leaves'")
    print("This will mine all logs and leaves connected in front of the turtle.")
end

local function init()
    if arg[1] == "help" then return true end
    if (arg[1] and string.lower(arg[1])) == "true" and true or false then
        inclusive = true
    elseif (arg[1] and string.lower(arg[1])) ~= "false" then error("Requires a boolean argument.", 0)
    else inclusive = false end
    for i,argument in ipairs(arg) do
        if i <= 1 then goto continue end

        if string.sub(argument, 1, 1) == "#" then
            tags[i-1] = argument:sub(2)
        else
            ids[i-1] = argument
        end

        ::continue::
    end

    MiningLib.veinMine(inclusive, ids, tags)
end

local guide = init()
if guide then tutorial() end