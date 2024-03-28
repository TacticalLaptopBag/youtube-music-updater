#!/bin/lua5.3
local http = require("socket.http")
local json = require("json")
local lyaml = require("lyaml")
local dir = require("pl.dir")
local path = require("pl.path")
local utils = require("pl.utils")
require("pl.stringx").import()

local YOUTUBE_MUSIC_PATTERN = "YouTube-Music-*.*.*.AppImage" -- Might need to remove the last e
local VERSION_PATTERN = "%d+.%d+.%d+"
local LATEST_METADATA_URL = "https://api.github.com/repos/th-ch/youtube-music/releases/latest"
local DOWNLOAD_URL_FORMAT = "https://github.com/th-ch/youtube-music/releases/download/v%s/%s"

local function exit(code)
    dir.rmtree(TempDir)
    os.exit(code)
end

local function getVersion(versionString)
    local versionSplit = versionString:split(".")
    return {
        major = versionSplit[1],
        minor = versionSplit[2],
        patch = versionSplit[3],
        number = versionSplit[1] * 100 + versionSplit[2] * 10 + versionSplit[3],
        string = versionString
    }
end

local function getYoutubeApps(applicationsPath)
    local youtubeApps = dir.getfiles(applicationsPath, YOUTUBE_MUSIC_PATTERN)

    if #youtubeApps > 1 then
        print("NOTICE: You have more than one YouTube Music AppImage!")
    elseif #youtubeApps == 0 then
        print("FATAL: You have no YouTube Music AppImages installed!")
        print("Are you sure YouTube Music is installed via AppImage?")
        print("If your AppImages are not stored in `~/Applications`, set the YTMU_APPLICATIONS_PATH environment "..
              "variable to your AppImages directory.")

        exit(1)
    end

    return youtubeApps
end

local function getCurrentVersion(youtubeApps)
    local currentVersion = nil
    for _, youtubeApp in ipairs(youtubeApps) do
        local versionStr = youtubeApp:gmatch(VERSION_PATTERN)()
        if versionStr == nil then
            goto continue
        end

        local thisVersion = getVersion(versionStr)
        if currentVersion == nil or currentVersion.number < thisVersion.number then
            currentVersion = thisVersion
        end

        ::continue::
    end

    if currentVersion == nil then
        print("FATAL: Unable to determine current YouTube Music version!")
        exit(1)
    end

    return currentVersion
end

-- https://stackoverflow.com/a/29654933
local function downloadFile(url, destination_file)
    -- retrieve the content of a URL
    local body, code = http.request(url)
    if not body then return code end

    -- save the content to a file
    local f = assert(io.open(destination_file, 'wb')) -- open in "binary" mode
    f:write(body)
    f:close()

    return code
end

local function getLatestMetadata(tempDir)
    local metadataPath = path.join(tempDir, "latest.json")

    print("Getting latest version...")
    local resultCode = downloadFile(LATEST_METADATA_URL, metadataPath)
    if resultCode ~= 200 then
        print("FATAL: Failed to retrieve metadata! Code "..resultCode)
        exit(1)
    end

    local metadataContent, metadataError = utils.readfile(metadataPath)
    if metadataContent == nil then
        print("FATAL: Failed to open metadata file: "..metadataError)
        exit(1)
    end

    local metadata = json.decode(metadataContent)

    local latestUrl = ""
    for _, asset in pairs(metadata.assets) do
        if asset.name == "latest-linux.yml" then
            latestUrl = asset.browser_download_url
        end
    end

    local latestPath = path.join(tempDir, "latest.yml")
    resultCode = downloadFile(latestUrl, latestPath)
    if resultCode ~= 200 then
        print("FATAL: Failed to retrieve latest-linux.yml!")
        exit(1)
    end

    -- Load yaml and return
    local latestContent, latestError = utils.readfile(latestPath)
    if latestContent == nil then
        print("FATAL: Failed to open latest-linux.yml: "..latestError)
        exit(1)
    end

    local latest = lyaml.load(latestContent)
    return latest
end

local function promptUpdate(currentVersion, latestVersion)
    print("Update available!")
    print("Latest version is "..latestVersion.string)
    print("Current version is "..currentVersion.string)

    io.write("Proceed with update? (Y/n): ")
    local proceedPrompt = io.read():strip():lower()
    if #proceedPrompt > 0 and proceedPrompt:at(1) == "n" then
        print("Canceled.")
        return false
    end

    return true
end

local function downloadUpdate(latest, applicationsPath)
    for _, file in pairs(latest.files) do
        if file.url:endswith(".AppImage") then
            local url = DOWNLOAD_URL_FORMAT:format(latest.version, file.url)
            local destination = path.expanduser(path.join(applicationsPath, file.url))
            print("Downloading latest version from \""..url.."\"")

            local resultCode = downloadFile(url, destination)

            print("Downloaded to "..destination)
            break
        end
    end
end

local function cleanupOldVersions(youtubeApps, applicationsPath)
    if #youtubeApps > 1 then
        print("Found "..#youtubeApps.." old versions")
    end

    local removeAll = false
    for _, oldFile in pairs(youtubeApps) do
        local prompt = ""
        if removeAll then
            prompt = "a"
        else
            local showAllText = #youtubeApps > 1
            local allText = showAllText and "/all" or ""
            io.write("Remove old version, "..oldFile.."? (Y/n"..allText.."): ")
            local prompt = io.read():strip():lower()
            if showAllText and #prompt > 0 and prompt[1] == "a" then
                removeAll = true
            end
        end

        if #prompt == 0 or prompt[1] ~= "n" then
            os.remove(path.join(applicationsPath, oldFile))
            print("Removed old version: "..oldFile)
        end
    end
end


print("YouTube Music AppImage Updater")

TempDir = path.tmpname()
os.remove(TempDir)
if not dir.makepath(TempDir) then
    print("FATAL: Failed to create temp directory: "..TempDir)
    os.exit(1)
end

local applicationsPath = os.getenv("YTMU_APPLICATIONS_PATH") or path.expanduser("~/Applications")
local youtubeApps = getYoutubeApps(applicationsPath)

local currentVersion = getCurrentVersion(youtubeApps)
local latest = getLatestMetadata(TempDir)
local latestVersion = getVersion(latest.version)

-- currentVersion is never nil. If it is, we should have exited by now.
---@diagnostic disable-next-line: need-check-nil
if currentVersion.number >= latestVersion.number then
    print("Already up-to-date!")
    exit(0)
end

if not promptUpdate(currentVersion, latestVersion) then
    exit(0)
end

downloadUpdate(latest, applicationsPath)
cleanupOldVersions(youtubeApps, applicationsPath)

print("All done!")

exit(0)
