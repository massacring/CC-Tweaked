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

--- Downloads and writes the script onto the computer, based on the provided file.
--- @param file table
local function downloadScript(file)
    if file.type == "file" then
        print("Downloading " .. file.name)

        local repo = http.get(file.download_url)
        local script = fs.open(file.name, "w")
        script.write(repo.readAll())
        script.close()
        repo.close()
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