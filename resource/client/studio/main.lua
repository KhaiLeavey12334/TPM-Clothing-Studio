Studio.App = Studio.App or {}
Studio.AutoPreview = Studio.AutoPreview or {}

local autoState = {
    active = false,
    paused = false,
    total = 0,
    completed = 0,
    startedAt = 0,
    etaSeconds = 0,
    saveLocation = '',
    error = '',
    limit = 0
}

local autoStopRequested = false

local function publishAutoState()
    Studio.SetState('autoPreview', autoState)
    SendNUIMessage({
        type = 'autoPreview:state',
        payload = autoState
    })
end

local function countQueueItems()
    local total = 0
    local drawableCount = Studio.Clothing.GetDrawableCount()

    for drawable = 0, drawableCount - 1 do
        local textureCount = Config.AutoPreview.includeTextures and Studio.Clothing.GetTextureCountForDrawable(drawable) or 1
        total = total + math.max(1, textureCount)
    end

    return total
end

local function updateProgress()
    local elapsed = math.max(1, math.floor((GetGameTimer() - autoState.startedAt) / 1000))
    local remaining = math.max(0, autoState.total - autoState.completed)
    local average = elapsed / math.max(1, autoState.completed)

    autoState.etaSeconds = math.floor(remaining * average)
    publishAutoState()
end

local function waitWhilePaused()
    while autoState.active and autoState.paused do
        publishAutoState()
        Wait(250)
    end
end

local function shouldStop()
    if not autoState.active then
        return true
    end

    local configuredLimit = Config.AutoPreview.maxItemsPerRun > 0 and Config.AutoPreview.maxItemsPerRun or 0
    local runLimit = autoState.limit > 0 and autoState.limit or configuredLimit

    return runLimit > 0 and autoState.completed >= runLimit
end

local function captureCurrentItem()
    Wait(Config.AutoPreview.captureDelayMs)
    local ok, errorMessage = Studio.Screenshot.Capture('auto')

    if not ok then
        autoState.error = errorMessage or 'Screenshot capture failed.'
        Studio.Logger.Warn(autoState.error)
    end

    while Studio.Screenshot.IsBusy() do
        Wait(100)
    end

    autoState.completed = autoState.completed + 1
    updateProgress()
    Wait(Config.AutoPreview.betweenItemsMs)
end

function Studio.AutoPreview.Start(limit)
    if autoState.active then
        Studio.Logger.Warn('Auto Preview is already running.')
        return false
    end

    local ok, totalOrError = pcall(countQueueItems)

    if not ok then
        autoState.error = tostring(totalOrError)
        publishAutoState()
        Studio.Logger.Error(('Auto Preview failed to count queue: %s'):format(autoState.error))
        return false
    end

    autoStopRequested = false
    autoState.active = true
    autoState.paused = false
    autoState.completed = 0
    autoState.startedAt = GetGameTimer()
    autoState.total = totalOrError
    if limit and limit > 0 then
        autoState.total = math.min(autoState.total, math.floor(limit))
        autoState.limit = math.floor(limit)
    else
        autoState.limit = 0
    end
    autoState.etaSeconds = 0
    autoState.saveLocation = ''
    autoState.error = ''

    if Studio.Camera then
        Studio.Camera.ApplyPreset(Config.AutoPreview.cameraPreset)
    end

    publishAutoState()

    CreateThread(function()
        local ok, errorMessage = pcall(function()
            local drawableCount = Studio.Clothing.GetDrawableCount()

            for drawable = 0, drawableCount - 1 do
                if shouldStop() then break end

                Studio.Clothing.SetDrawable(drawable)
                Wait(75)

                local textureCount = Config.AutoPreview.includeTextures and Studio.Clothing.GetTextureCount() or 1

                for texture = 0, math.max(1, textureCount) - 1 do
                    if shouldStop() then break end

                    waitWhilePaused()
                    if shouldStop() then break end

                    Studio.Clothing.SetTexture(texture)
                    Wait(75)
                    captureCurrentItem()
                end
            end
        end)

        if not ok then
            autoState.error = tostring(errorMessage)
            Studio.Logger.Error(('Auto Preview failed: %s'):format(autoState.error))
        end

        local wasStopped = autoStopRequested
        autoState.active = false
        autoState.paused = false
        if Studio.Camera then
            Studio.Camera.Destroy()
        end
        publishAutoState()
        SendNUIMessage({
            type = wasStopped and 'autoPreview:stopped' or 'autoPreview:complete',
            payload = autoState
        })
        Studio.Logger.Info(wasStopped and 'Auto Preview stopped.' or 'Auto Preview completed.')
    end)

    return true
end

function Studio.AutoPreview.GetState()
    return autoState
end

function Studio.AutoPreview.Pause()
    if autoState.active and not autoState.paused then
        autoState.paused = true
        publishAutoState()
        return true
    end

    return false
end

function Studio.AutoPreview.Resume()
    if autoState.active and autoState.paused then
        autoState.paused = false
        publishAutoState()
        return true
    end

    return false
end

function Studio.AutoPreview.Stop()
    if not autoState.active then
        publishAutoState()
        return false
    end

    autoStopRequested = true
    autoState.active = false
    autoState.paused = false
    if Studio.Camera then
        Studio.Camera.Destroy()
    end
    publishAutoState()
    return true
end

function Studio.App.Start()
    RegisterCommand(Config.Commands.autoPreview, function()
        Studio.AutoPreview.Start()
    end, false)

    RegisterCommand(Config.Commands.pauseAutoPreview, function()
        Studio.AutoPreview.Pause()
    end, false)

    RegisterCommand(Config.Commands.resumeAutoPreview, function()
        Studio.AutoPreview.Resume()
    end, false)

    RegisterCommand(Config.Commands.stopAutoPreview, function()
        Studio.AutoPreview.Stop()
    end, false)

    RegisterKeyMapping(Config.Commands.stopAutoPreview, 'TPM Clothing Studio stop auto preview', 'keyboard', 'SPACE')

    Studio.Logger.Info(('Booting %s %s.'):format(Studio.name, Studio.version))
end

CreateThread(function()
    Studio.ModuleLoader.Register('studio', Studio.App)
    Wait(0)
    Studio.ModuleLoader.StartAll()
end)
