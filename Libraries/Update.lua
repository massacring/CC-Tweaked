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

--- Counts the number of bytes in a file by name.
--- @param name string
--- @return number
local function countBytes(name)
    local file = fs.open(name, "rb")
    local bytes = (file and file.readAll) and #file.readAll() or 0
    file.close()
    return bytes
end

--- Reads a file by name.
--- @param name string
--- @return string
local function readAll(name)
    local file = fs.open(name, "r")
    if not file then return "" end
    local data = file.readAll()
    file.close()
    return data
end

--- Seperates a string line into words based on newline character.
--- @param line string
--- @return table
local function getWordsByLine(line)
    local words = {}
    for word in line:gmatch("%S+") do
        table.insert(words, word)
    end
    return words
end

--- Seperates a string of data into lines based on newline character.
--- @param data string
--- @return table
local function getLinesByData(data)
    local lines = {}
    for line in (data .. "\n"):gmatch("(.-)\n") do
        table.insert(lines, line)
    end
    return lines
end

-- Calculates the Longest Common Subsequence of two tables.
--- @param dataA table
--- @param dataB table
--- @return table
local function LCS(dataA, dataB)
    local lengthA, lengthB = #dataA, #dataB

    local lcs = {}

    for i = 0, lengthA do
        lcs[i] = {}
        for j = 0, lengthB do
            lcs[i][j] = 0
        end
    end

    for i = 1, lengthA do
        for j = 1, lengthB do
            if dataA[i] == dataB[j] then
                lcs[i][j] = lcs[i-1][j-1] + 1
            else
                lcs[i][j] = math.max(lcs[i-1][j], lcs[i][j-1])
            end
        end
    end

    return lcs
end

local function backtrack(lcs, dataA, dataB, i, j, result)
    if i > 0 and j > 0 and dataA[i] == dataB[j] then
        backtrack(lcs, dataA, dataB, i-1, j-1, result)
        --table.insert(result, {type="context", text=dataA[i]})
    elseif j > 0 and (i == 0 or lcs[i][j-1] >= lcs[i-1][j]) then
        backtrack(lcs, dataA, dataB, i, j-1, result)
        table.insert(result, {type="add", text=dataB[j]})
    elseif i > 0 then
        backtrack(lcs, dataA, dataB, i-1, j, result)
        table.insert(result, {type="remove", text=dataA[i]})
    end
end

--- Compares the data of two files using Myers algorithm (imitating git).
--- @param dataA string
--- @param dataB string
local function compareData(dataA, dataB)
    local linesA, linesB = getLinesByData(dataA), getLinesByData(dataB)

    local lcs = LCS(linesA, linesB)

    local difference = {}
    backtrack(lcs, linesA, linesB, #linesA, #linesB, difference)

    if #difference == 0 or not next(difference) then return end

    print("--- a")
    print("+++ b")

    print(("@@ -1,%d +1,%d @@"):format(#linesA, #linesB))

    for _, diff in ipairs(difference) do
        if diff.type == "context" then
            print(" " .. diff.text)
        elseif diff.type == "remove" then
            print("-" .. diff.text)
        elseif diff.type == "add" then
            print("+" .. diff.text)
        end
    end
end

--- Downloads and writes the script onto the computer, based on the provided data.
--- @param data table
local function downloadScript(data)
    if data.type == "file" then
        print("Downloading " .. data.name)

        local oldScript = readAll(data.name)

        local repo = http.get(data.download_url)
        local script = repo.readAll()
        compareData(oldScript, script)
        local file = fs.open(data.name, "w")
        file.write(script)
        file.close()
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