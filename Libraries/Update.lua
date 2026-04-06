local GIT_API = "https://api.github.com/repos/massacring/CC-Tweaked/"
local GIT_RAW = "https://raw.githubusercontent.com/massacring/CC-Tweaked/main/"

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
--- @return string
local function readAll(name, mode)
    mode = mode or "r"
    local file = fs.open(name, mode)
    if not file then return "" end
    local data = file.readAll()
    file.close()
    return data
end

--- Downloads and writes the script onto the computer, based on the provided data.
--- @param data table
local function downloadScript(data)
    if data.type == "file" then
        print("Downloading " .. data.name)

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

--- Connects to my CC: Tweaked GitHub repo and downloads all the files of the provided subdirectory.
--- @param subdirectory string
local function getGit(subdirectory)
    local files = getDirectoryContents(subdirectory)

    for _, file in ipairs(files) do
        local status, err = pcall(downloadScript, file)
        if not status then
            print("Failed to download file: " .. (file.name or "N/A"))
            print("Reason: " .. err)
        end
    end
    print("Done!")
end

getGit(arg[1])