Studio.Screenshot = Studio.Screenshot or {}

local captureInProgress = false

local function pad(value)
    return ('%03d'):format(value or 0)
end

local function sanitize(value)
    return tostring(value or 'unknown'):gsub('[^%w%-_]', '_'):lower()
end

local function buildFilename()
    local clothing = Studio.GetState('clothing') or {}
    local slot = clothing.mode == 'prop' and clothing.propId or clothing.componentId
    local filename = Config.Screenshot.format
        :gsub('{mode}', sanitize(clothing.mode))
        :gsub('{slot}', pad(slot))
        :gsub('{drawable}', pad(clothing.drawable))
        :gsub('{texture}', pad(clothing.texture))
        :gsub('{collection}', sanitize(clothing.collection))

    return ('%s/%s.%s'):format(Config.Screenshot.folder, filename, Config.Screenshot.encoding)
end

local function setUiVisible(visible)
    if not Config.Screenshot.hideUi or not Studio.Menu then
        return
    end

    Studio.Menu.SetVisible(visible)
end

local function requestScreenshot(filename)
    if Config.Screenshot.uploadUrl ~= '' then
        exports['screenshot-basic']:requestScreenshotUpload(Config.Screenshot.uploadUrl, 'files[]', {
            encoding = Config.Screenshot.encoding,
            quality = Config.Screenshot.quality
        }, function()
            Studio.Logger.Info(('Screenshot uploaded as "%s".'):format(filename))
        end)

        return
    end

    TriggerServerEvent('tpm_clothing_studio:screenshot:capture', filename)
end

function Studio.Screenshot.BuildFilename()
    return buildFilename()
end

function Studio.Screenshot.IsBusy()
    return captureInProgress
end

function Studio.Screenshot.Capture()
    if captureInProgress then
        Studio.Logger.Warn('Screenshot capture already in progress.')
        return false
    end

    captureInProgress = true

    CreateThread(function()
        local wasVisible = Studio.GetState('nuiVisible')
        local filename = buildFilename()

        setUiVisible(false)
        Wait(Config.Screenshot.delayMs)
        requestScreenshot(filename)
        Wait(250)
        setUiVisible(wasVisible)

        captureInProgress = false
    end)

    return true
end

function Studio.Screenshot.Start()
    RegisterCommand(Config.Commands.screenshot, function()
        Studio.Screenshot.Capture()
    end, false)

    RegisterKeyMapping(Config.Commands.screenshot, 'TPM Clothing Studio screenshot', 'keyboard', Config.Screenshot.key)
    Studio.Logger.Debug('Screenshot module ready.')
end

Studio.ModuleLoader.Register('screenshot', Studio.Screenshot)
