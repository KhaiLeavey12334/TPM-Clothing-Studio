Studio.Screenshot = Studio.Screenshot or {}

local captureInProgress = false
local lastCaptureContext = 'manual'
local shouldReopenMenu = false
local restoreUiAfterCapture = false
local restoreUiVisible = false
local cameraPreset = Config.AutoPreview.cameraPreset
local cameraAngle = 'front'

local function pad(value)
    return ('%03d'):format(value or 0)
end

local function sanitize(value)
    return tostring(value or 'unknown'):gsub('[^%w%-_]', '_'):lower()
end

local function getPackPrefix()
    local packName = GetResourceKvpString('tpm_clothing_studio:pack_name')

    if not packName or packName == '' then
        return ''
    end

    return sanitize(packName) .. '_'
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

    return ('%s/%s%s.%s'):format(Config.Screenshot.folder, getPackPrefix(), filename, Config.Screenshot.encoding)
end

local function setUiVisible(visible)
    if not Config.Screenshot.hideUi or not Studio.Menu then
        return
    end

    if Studio.Menu.SetCaptureVisible then
        Studio.Menu.SetCaptureVisible(visible)
        return
    end

    Studio.Menu.SetVisible(visible, {
        keepCamera = true
    })
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

local function publishScreenshotStatus(success, message, path)
    if restoreUiAfterCapture and Studio.Menu then
        Studio.Menu.SetVisible(restoreUiVisible, {
            keepCamera = true
        })
        restoreUiAfterCapture = false
        restoreUiVisible = false
    end

    if lastCaptureContext == 'manual' and shouldReopenMenu and Studio.Menu then
        Studio.Menu.SetVisible(true, {
            keepCamera = true
        })
        shouldReopenMenu = false
    end

    SendNUIMessage({
        type = 'screenshot:result',
        payload = {
            success = success,
            message = message,
            path = path,
            context = lastCaptureContext
        }
    })

    if lastCaptureContext == 'manual' and Studio.Camera then
        Studio.Camera.Destroy()
    end
end

function Studio.Screenshot.BuildFilename()
    return buildFilename()
end

function Studio.Screenshot.IsBusy()
    return captureInProgress
end

function Studio.Screenshot.GetCameraSettings()
    return {
        preset = cameraPreset,
        angle = cameraAngle
    }
end

function Studio.Screenshot.SetCameraSettings(preset, angle)
    if Config.Camera.presets[preset] then
        cameraPreset = preset
    end

    if angle == 'back' or angle == 'front' then
        cameraAngle = angle
    end

    if Studio.Camera then
        Studio.Camera.SetShot(cameraPreset, cameraAngle, 0)
    end
end

function Studio.Screenshot.Capture(context)
    if captureInProgress then
        Studio.Logger.Warn('Screenshot capture already in progress.')
        publishScreenshotStatus(false, 'Screenshot capture already in progress. Wait for the current capture to finish.', nil)
        return false, 'Screenshot capture already in progress.'
    end

    if Config.Screenshot.uploadUrl == '' and GetResourceState('screenshot-basic') ~= 'started' then
        local message = 'screenshot-basic is not started. Start screenshot-basic before taking screenshots.'

        Studio.Logger.Error(message)
        publishScreenshotStatus(false, message, nil)
        return false, message
    end

    captureInProgress = true
    lastCaptureContext = context or 'manual'

    CreateThread(function()
        local wasVisible = Studio.GetState('nuiVisible')
        local filename = buildFilename()

        if Studio.Camera then
            Studio.Camera.SetShot(cameraPreset, cameraAngle, 0)
            Wait(150)
        end

        restoreUiAfterCapture = wasVisible
        restoreUiVisible = wasVisible
        shouldReopenMenu = lastCaptureContext == 'manual' and wasVisible
        setUiVisible(false)
        Wait(Config.Screenshot.delayMs)
        requestScreenshot(filename)

        local timeoutAt = GetGameTimer() + 10000
        while captureInProgress and GetGameTimer() < timeoutAt do
            Wait(100)
        end

        if captureInProgress then
            captureInProgress = false
            publishScreenshotStatus(false, 'Screenshot timed out before screenshot-basic returned a result.', nil)
        end
    end)

    return true, nil
end

RegisterNetEvent('tpm_clothing_studio:screenshot:result', function(success, errorMessage, outputPath)
    local message = success and 'Screenshot taken' or ('Screenshot failed: ' .. tostring(errorMessage or 'unknown error'))
    publishScreenshotStatus(success, message, outputPath)
    captureInProgress = false
end)

function Studio.Screenshot.Start()
    local savedKey = GetResourceKvpString('tpm_clothing_studio:screenshot_key')
    local key = savedKey ~= nil and savedKey ~= '' and savedKey or Config.Screenshot.key

    RegisterCommand(Config.Commands.screenshot, function()
        local ok, errorMessage = Studio.Screenshot.Capture('manual')

        if not ok then
            Studio.Logger.Warn(errorMessage or 'Screenshot command failed.')
        end
    end, false)

    RegisterKeyMapping(Config.Commands.screenshot, 'TPM Clothing Studio screenshot', 'keyboard', key)
    Studio.Logger.Debug('Screenshot module ready.')
end

Studio.ModuleLoader.Register('screenshot', Studio.Screenshot)
