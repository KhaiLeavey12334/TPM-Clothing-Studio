local resourceName = GetCurrentResourceName()
local screenshotDirectory = GetResourcePath(resourceName) .. '/screenshots'
local resourceRoot = GetResourcePath(resourceName):gsub('\\', '/'):gsub('/[^/]+$', '')

local function ensureScreenshotDirectory()
    os.execute(('mkdir "%s" 2>nul'):format(screenshotDirectory:gsub('/', '\\')))
end

local function basename(path)
    local normalized = path:gsub('\\', '/')

    return normalized:match('([^/]+)$') or 'screenshot.jpg'
end

CreateThread(function()
    ensureScreenshotDirectory()
end)

local function normalizePackId(name)
    return tostring(name or ''):gsub('[^%w%-_]', '_'):lower()
end

local function commandLines(command)
    local handle = io.popen(command)
    local lines = {}

    if not handle then
        return lines
    end

    for line in handle:lines() do
        lines[#lines + 1] = line
    end

    handle:close()
    return lines
end

local function packExists(packs, id)
    for _, pack in ipairs(packs) do
        if pack.id == id then
            return true
        end
    end

    return false
end

local function addPack(packs, folderName, path)
    local id = normalizePackId(folderName)

    if id == '' or packExists(packs, id) then
        return
    end

    packs[#packs + 1] = {
        id = id,
        label = folderName,
        resource = folderName,
        collection = folderName,
        gender = 'any',
        detected = true,
        started = GetResourceState(folderName) == 'started',
        hasStream = path and path ~= ''
    }
end

local function discoverRegisteredClothingResources(packs)
    local totalResources = GetNumResources()

    for index = 0, totalResources - 1 do
        local folderName = GetResourceByFindIndex(index)
        local path = folderName and GetResourcePath(folderName)

        if path then
            local normalizedPath = path:gsub('\\', '/'):lower()

            if normalizedPath:find('/[clothingpacks]/', 1, true) then
                addPack(packs, folderName, path)
            end
        end
    end
end

local function discoverClothingFolders(packs)
    local clothingRoot = resourceRoot .. '/[clothingpacks]'
    local command = ('dir /b /ad "%s" 2>nul'):format(clothingRoot:gsub('/', '\\'))

    for _, folderName in ipairs(commandLines(command)) do
        addPack(packs, folderName, clothingRoot .. '/' .. folderName)
    end
end

local function discoverClothingPacks()
    local packs = {
        {
            id = 'base',
            label = 'Default / Base GTA',
            resource = '',
            collection = '',
            gender = 'any',
            detected = true,
            started = true
        }
    }

    discoverRegisteredClothingResources(packs)
    discoverClothingFolders(packs)

    return packs
end

local function discoverPeds()
    local peds = {
        {
            id = 'male',
            label = 'Male Freemode',
            model = Config.Peds.defaultMaleModel,
            type = 'preset'
        },
        {
            id = 'female',
            label = 'Female Freemode',
            model = Config.Peds.defaultFemaleModel,
            type = 'preset'
        }
    }

    if not Config.Peds.enabled then
        return peds
    end

    local totalResources = GetNumResources()
    local scanSegment = '/' .. tostring(Config.Peds.scanFolder or '[peds]'):lower() .. '/'

    for index = 0, totalResources - 1 do
        local folderName = GetResourceByFindIndex(index)
        local path = folderName and GetResourcePath(folderName)

        if path and path:gsub('\\', '/'):lower():find(scanSegment, 1, true) then
            peds[#peds + 1] = {
                id = normalizePackId(folderName),
                label = folderName,
                model = folderName,
                resource = folderName,
                type = 'resource',
                started = GetResourceState(folderName) == 'started'
            }
        end
    end

    return peds
end

RegisterNetEvent('tpm_clothing_studio:packs:request', function()
    local packs = discoverClothingPacks()

    if Config.Debug then
        print(('[TPM Clothing Studio] Detected %s clothing pack option(s).'):format(#packs))
    end

    TriggerClientEvent('tpm_clothing_studio:packs:update', source, packs)
end)

RegisterNetEvent('tpm_clothing_studio:peds:request', function()
    TriggerClientEvent('tpm_clothing_studio:peds:update', source, discoverPeds())
end)

RegisterNetEvent('tpm_clothing_studio:screenshot:capture', function(filename)
    local playerId = source

    if type(filename) ~= 'string' or filename == '' then
        print(('[TPM Clothing Studio] Refused screenshot request from %s because the filename was invalid.'):format(playerId))
        return
    end

    ensureScreenshotDirectory()

    local outputPath = screenshotDirectory .. '/' .. basename(filename)

    exports['screenshot-basic']:requestClientScreenshot(playerId, {
        fileName = outputPath,
        encoding = Config.Screenshot.encoding,
        quality = Config.Screenshot.quality
    }, function(error)
        if error then
            print(('[TPM Clothing Studio] Screenshot failed for %s: %s'):format(playerId, error))
            TriggerClientEvent('tpm_clothing_studio:screenshot:result', playerId, false, tostring(error), outputPath)
            return
        end

        if Config.Debug then
            print(('[TPM Clothing Studio] Screenshot saved for %s as "%s".'):format(playerId, outputPath))
        end

        TriggerClientEvent('tpm_clothing_studio:screenshot:result', playerId, true, nil, outputPath)
    end)
end)
