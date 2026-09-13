Studio.App = Studio.App or {}
Studio.AutoPreview = Studio.AutoPreview or {}

local autoState = {
    active = false,
    paused = false,
    total = 0,
    completed = 0,
    startedAt = 0,
    etaSeconds = 0
}

local function publishAutoState()
    Studio.SetState('autoPreview', autoState)
    SendNUIMessage({
        type = 'autoPreview:state',
        payload = autoState
    })
end

local function countQueueItems()
    local total = 0
    local current = Studio.Clothing.GetState()
    local original = {
        mode = current.mode,
        componentId = current.componentId,
        propId = current.propId,
        drawable = current.drawable,
        texture = current.texture
    }
    local drawableCount = Studio.Clothing.GetDrawableCount()

    for drawable = 0, drawableCount - 1 do
        Studio.Clothing.SetDrawable(drawable)

        local textureCount = Config.AutoPreview.includeTextures and Studio.Clothing.GetTextureCount() or 1
        total = total + math.max(1, textureCount)
    end

    if original.mode == 'prop' then
        Studio.Clothing.SetProp(original.propId)
    else
        Studio.Clothing.SetComponent(original.componentId)
    end

    Studio.Clothing.SetDrawable(original.drawable)
    Studio.Clothing.SetTexture(original.texture)

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

    return Config.AutoPreview.maxItemsPerRun > 0 and autoState.completed >= Config.AutoPreview.maxItemsPerRun
end

local function captureCurrentItem()
    Wait(Config.AutoPreview.captureDelayMs)
    Studio.Screenshot.Capture()
    while Studio.Screenshot.IsBusy() do
        Wait(100)
    end

    autoState.completed = autoState.completed + 1
    updateProgress()
    Wait(Config.AutoPreview.betweenItemsMs)
end

function Studio.AutoPreview.Start()
    if autoState.active then
        Studio.Logger.Warn('Auto Preview is already running.')
        return false
    end

    autoState.active = true
    autoState.paused = false
    autoState.completed = 0
    autoState.startedAt = GetGameTimer()
    autoState.total = countQueueItems()
    autoState.etaSeconds = 0

    if Studio.Camera then
        Studio.Camera.ApplyPreset(Config.AutoPreview.cameraPreset)
    end

    publishAutoState()

    CreateThread(function()
        local drawableCount = Studio.Clothing.GetDrawableCount()

        for drawable = 0, drawableCount - 1 do
            if shouldStop() then break end

            Studio.Clothing.SetDrawable(drawable)

            local textureCount = Config.AutoPreview.includeTextures and Studio.Clothing.GetTextureCount() or 1

            for texture = 0, math.max(1, textureCount) - 1 do
                if shouldStop() then break end

                waitWhilePaused()
                if shouldStop() then break end

                Studio.Clothing.SetTexture(texture)
                captureCurrentItem()
            end
        end

        autoState.active = false
        autoState.paused = false
        publishAutoState()
        Studio.Logger.Info('Auto Preview completed.')
    end)

    return true
end

function Studio.AutoPreview.Pause()
    if autoState.active then
        autoState.paused = true
        publishAutoState()
    end
end

function Studio.AutoPreview.Resume()
    if autoState.active then
        autoState.paused = false
        publishAutoState()
    end
end

function Studio.AutoPreview.Stop()
    autoState.active = false
    autoState.paused = false
    publishAutoState()
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

    Studio.Logger.Info(('Booting %s %s.'):format(Studio.name, Studio.version))
end

CreateThread(function()
    Studio.ModuleLoader.Register('studio', Studio.App)
    Wait(0)
    Studio.ModuleLoader.StartAll()
end)
