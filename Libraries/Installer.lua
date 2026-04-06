local GIT_API = "https://api.github.com/repos/massacring/CC-Tweaked/"

--- Uses the Git API to fetch the contents of the provided subdirectory.
--- @param subdirectory string
--- @return table
local function getDirectoryContents(subdirectory)
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

--- Connects to my CC: Tweaked GitHub repo and updates all the files of the provided subdirectory.
--- @param subdirectory string
local function getGit(subdirectory)
    local files = getDirectoryContents(subdirectory)

    for _, file in ipairs(files) do
        local status, err = pcall(updateScript, file)
        if not status then
            print("Failed to update file: " .. (file.name or "N/A"))
            print("Reason: " .. err)
        end
    end
    print("Done!")
end

local function install()
    local args = arg
    arg = {}
    local counter = 0
    for k,v in pairs(args) do
        counter = counter + 1
        if counter > 2 and k ~= 0 then
            table.insert(arg, v)
        end
    end

    print("installing " .. arg[1])

end

if arg[1] == "run" then
    install()
elseif arg[1] == "update" then
    getGit(arg[2])
end
