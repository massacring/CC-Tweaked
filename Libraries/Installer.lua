-- Can be used in computer or turtle terminal to install the
-- latest version of the script, or update an existing installation
-- by fetching the latest files from the GitHub repository.
-- Updating requires the installer to be downloaded first.
-- Usage:
-- To install :
--   first run  : wget https://raw.githubusercontent.com/massacring/CC-Tweaked/main/Libraries/Installer.lua Installer.lua
--   then run   : Installer.lua run <filepath>
-- To update  : Installer update <subdirectory>
-- Optional install (cannot update) : wget run https://raw.githubusercontent.com/massacring/CC-Tweaked/main/Libraries/Installer.lua <filepath>

local GIT_API = "https://api.github.com/repos/massacring/CC-Tweaked/"

--- Returns a list of auto complete options based on the provided index, text and previous.
--- Index is which argument is being auto completed.
--- Text is the current text of the argument being auto completed.
--- Previous is a list of the previous arguments.
--- @param index number
--- @param text string
--- @param previous table
--- @return table
local function autoComplete(_, index, text, previous)
    --- Returns the remainder of words that start with the provided text, based on the provided list of words.
    --- @param words table
    --- @return table
    local function wordComplete(words)
        local result = {}
        for _, word in ipairs(words) do
            if word:sub(1, #text) == text then
                table.insert(result, word:sub(#text+1, #word))
            end
        end
        return result
    end

    if index == 1 then
        local options = {"run", "update"}
        if text == "" then
            return options
        end
        return wordComplete(options)
    end
    return {}
end

--- Uses the Git API to fetch the contents of the provided subdirectory.
--- @param subdirectory string
--- @return table
local function getContents(subdirectory)
    local url = GIT_API .. "contents/" .. subdirectory
    local response = http.get(url)
    local files = textutils.unserializeJSON(response.readAll())
    response.close()
    return files
end

--- Reads a file by name.
--- @param name string
--- @param mode string
--- @return string
local function readAll(name, mode)
    local file = fs.open(name, mode)
    if not file then return "" end
    local data = file.readAll()
    file.close()
    return data
end

--- Downloads and writes the script onto the computer, based on the provided data.
--- @param data table
local function updateScript(data)
    if data.type == "file" and fs.exists(data.name) then
        print("Updating " .. data.name)

        local oldScript = readAll(data.name, "rb")

        local repo = http.get(data.download_url)
        local script = repo.readAll()
        local file = fs.open(data.name, "w")
        file.write(script)
        file.close()
        repo.close()

        local newScript = readAll(data.name, "rb")

        local oldLen = #oldScript
        local newLen = #newScript
        local maxLen = math.max(oldLen, newLen)

        local diffCount = 0

        for i = 1, maxLen do
            local oldBytes = oldScript:byte(i) or 0
            local newBytes = newScript:byte(i) or 0

            if oldBytes ~= newBytes then
                diffCount = diffCount + 1
            end
        end

        if diffCount > 0 then
            print("Updated " .. data.name .. " with " .. diffCount .. " byte differences.")
        else
            print(data.name .. " is already up to date.")
        end
    end
end

--- Gets the auto complete function for the provided script.
--- Returns nil if the script is invalid or does not support auto complete.
--- @param script string
--- @return function|nil
local function getAutoComplete(script)
    local autoCompleteFunction = ""
    local inAutoComplete = false
    for line in script:gmatch("([^".."\n".."]+)") do
        if line:find("function autoComplete") then
            inAutoComplete = true
        end
        if inAutoComplete then
            autoCompleteFunction = autoCompleteFunction .. line .. "\n"
        end
        if line == "end" then
            break
        end
    end

    local fn, err = load(autoCompleteFunction)

    if not fn then
        print("Failed to load auto complete function: " .. (err or "N/A"))
        return
    end

    return fn
end

local function downloadScript(data)
    if data.type == "file" then
        print("Downloading " .. data.name)

        local repo = http.get(data.download_url)
        local script = repo.readAll()
        local file = fs.open(data.name, "w")
        file.write(script)
        file.close()
        repo.close()
        local autoCompleteFunction = getAutoComplete(script)
        if autoCompleteFunction then
            shell.setCompletionFunction(data.name, autoCompleteFunction)
        end
    end
end

--- Connects to my CC: Tweaked GitHub repo and updates all the files of the provided subdirectory.
--- @param subdirectory string
--- @param fn function
--- @return any
local function getGit(subdirectory, fn)
    local contentData = getContents(subdirectory)
    local errs = {}

    if contentData.name then
        contentData = {contentData}
    end
    for _, file in ipairs(contentData) do
        if file.type and file.name and file.download_url then
            local status, err = pcall(fn, file)
            if not status then
                errs[file.name] = err
            end
        end
    end
    return errs
end

local function install()
    local args = arg
    arg = {}
    local counter = 0
    for k,v in pairs(args) do
        counter = counter + 1
        if counter ~= 2 and k ~= 0 then
            table.insert(arg, v)
        end
    end
end

if arg[1] == "run" then
    if arg[0] == "wget" then
        install()
    end
    local errs = getGit(arg[2], downloadScript)
    if errs then
        for file, err in pairs(errs) do
            print("Failed to update " .. file .. ": " .. err)
        end
    end
elseif arg[1] == "update" then
    local errs = getGit(arg[2], updateScript)
    if errs then
        for file, err in pairs(errs) do
            print("Failed to update " .. file .. ": " .. err)
        end
    end
end
