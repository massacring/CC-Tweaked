--- Modify "Navigator" to any file that returns a setup function and errData string.
local setup = require("Navigator").setup

if type(setup) ~= "function" then
    error("Required file does not return correct data.")
end

local modem
for _, name in ipairs(peripheral.getNames()) do
    modem = peripheral.wrap(name)
    if modem.isWireless and modem.isWireless() then break
    else modem = nil end
end
local channel = 4200 -- Info Log channel, never replies
if modem then modem.open(channel) end

local function errorHandler(err)
    print("Fatal Error occurred:")
    print(err)
    local utc = os.time("utc")

    local hour = math.floor(utc)
    local minute = math.floor((utc - hour) * 60)
    local second = math.floor((((utc - hour) * 60) - minute) * 60)

    local time = string.format("%02d:%02d:%02d UTC", hour, minute, second)

    local sosMessage = string.format("[%s] Halting process due to fatal error.", time)

    while true do
        rednet.broadcast(sosMessage)
        sleep(5)
    end
end

--- Returns a key and value based on the passed argument.
--- The key is a string.
--- The value is either a string or boolean.
--- Returns nil if the argument is invalid.
--- @param argument string
--- @return string|nil
--- @return string|boolean|nil
local function handleArgument(argument)
    if #argument < 2 then return end
    if argument:sub(1, 2) == "--" then
        if #argument < 3 then return end
        local equals = argument:find("=")
        local key = argument:sub(3, (equals ~= nil and equals-1 or nil))
        local value = equals ~= nil and argument:sub(equals+1, #argument) or true
        return key, value
    elseif argument:sub(1, 1) == "-" then
        local key = argument:sub(2, 2)
        local value = #argument >= 3 and argument:sub(3, #argument) or true
        return key, value
    else
        return
    end
end

--- Loops through and gathers the key value pairs of all arguments in the passed args.
--- Returns a table of key value pairs.
--- If it fails, returns nil and a string reason why.
--- @param arg table
--- @return table|nil
--- @return string|nil
local function handleArguments(arg)
    local arguments = {}
    for _, argument in ipairs(arg) do
        local key, value = handleArgument(argument)
        if key == nil then
            return nil, "Contains invalid argument."
        end
        arguments[key] = value
    end
    return arguments
end

local function run()
    local arguments, reason = handleArguments(arg)
    if arguments == nil then
        error("Could not process arguments: " .. reason)
    end
    if next(arguments) == nil then
        arguments["h"] = true
    end

    local success, result = pcall(setup, arguments)
    if not success then
        errorHandler(result)
    end
    return result
end

if arg[1] ~= nil then
    run()
end

return run
