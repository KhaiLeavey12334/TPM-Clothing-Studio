Studio.Menu = Studio.Menu or {}

local environmentLocked = false

local function lockStudioEnvironment()
    if environmentLocked or not Config.Studio.lockDayWeatherOnFirstOpen then
        return
    end

    environmentLocked = true
    NetworkOverrideClockTime(Config.Studio.dayHour, 0, 0)
    ClearOverrideWeather()
    ClearWeatherTypePersist()
    SetWeatherTypePersist(Config.Studio.weather)
    SetWeatherTypeNow(Config.Studio.weather)
    SetWeatherTypeNowPersist(Config.Studio.weather)
end

function Studio.Menu.SetVisible(visible, options)
    options = options or {}

    Studio.SetState('nuiVisible', visible)
    if not visible then
        Studio.SetState('nuiMinimized', false)
    end
    SetNuiFocus(visible, visible)
    SendNUIMessage({
        type = 'studio:visibility',
        visible = visible
    })

    if visible and Studio.Clothing then
        lockStudioEnvironment()
        TriggerServerEvent('tpm_clothing_studio:packs:request')
        TriggerServerEvent('tpm_clothing_studio:peds:request')
        Studio.Clothing.PublishState()
    end

    if not visible and not options.keepCamera and Studio.Camera then
        Studio.Camera.Destroy()
    end
end

function Studio.Menu.SetCaptureVisible(visible)
    Studio.Menu.SetVisible(visible, {
        keepCamera = true
    })
end

function Studio.Menu.Toggle()
    Studio.Menu.SetVisible(not Studio.GetState('nuiVisible'))
end

function Studio.Menu.CancelAndClose()
    if Studio.AutoPreview then
        Studio.AutoPreview.Stop()
    end

    Studio.Menu.SetVisible(false)
end

function Studio.Menu.SetMinimized(minimized)
    Studio.SetState('nuiMinimized', minimized)
    SetNuiFocus(not minimized, not minimized)
    SendNUIMessage({
        type = 'studio:minimized',
        minimized = minimized
    })
end

function Studio.Menu.Start()
    Studio.Logger.Debug('Menu module ready.')
end

RegisterCommand(Config.Commands.openStudio, function()
    Studio.Menu.Toggle()
end, false)

RegisterKeyMapping(Config.Commands.openStudio, 'Open TPM Clothing Studio', 'keyboard', 'F1')

RegisterCommand('tpmtest', function()
    Studio.Menu.Toggle()
end, false)

RegisterNUICallback('studio:close', function(_, callback)
    Studio.Menu.CancelAndClose()
    callback({ ok = true })
end)

RegisterNUICallback('studio:minimize', function(_, callback)
    Studio.Menu.SetMinimized(true)
    callback({ ok = true })
end)

RegisterNUICallback('studio:restore', function(_, callback)
    Studio.Menu.SetMinimized(false)
    callback({ ok = true })
end)

RegisterNUICallback('clothing:setComponent', function(data, callback)
    local componentId = tonumber(data.componentId)

    if componentId then
        Studio.Clothing.SetComponent(componentId)
    end

    callback({ ok = true })
end)

RegisterNUICallback('clothing:setProp', function(data, callback)
    local propId = tonumber(data.propId)

    if propId then
        Studio.Clothing.SetProp(propId)
    end

    callback({ ok = true })
end)

RegisterNUICallback('clothing:setDrawable', function(data, callback)
    local drawable = tonumber(data.drawable)

    if drawable then
        Studio.Clothing.SetDrawable(drawable)
    end

    callback({ ok = true })
end)

RegisterNUICallback('clothing:setTexture', function(data, callback)
    local texture = tonumber(data.texture)

    if texture then
        Studio.Clothing.SetTexture(texture)
    end

    callback({ ok = true })
end)

RegisterNUICallback('pack:setActive', function(data, callback)
    local packId = tostring(data.packId or 'base')
    local ok = Studio.Clothing.SetPack(packId)

    callback({ ok = ok })
end)

RegisterNUICallback('ped:setModel', function(data, callback)
    local modelName = tostring(data.model or '')
    local model = joaat(modelName)

    if modelName == '' or not IsModelInCdimage(model) or not IsModelValid(model) then
        callback({ ok = false, error = 'Ped model is not valid or not streamed.' })
        return
    end

    RequestModel(model)
    local timeoutAt = GetGameTimer() + 5000

    while not HasModelLoaded(model) and GetGameTimer() < timeoutAt do
        Wait(0)
    end

    if not HasModelLoaded(model) then
        callback({ ok = false, error = 'Ped model timed out while loading.' })
        return
    end

    SetPlayerModel(PlayerId(), model)
    SetModelAsNoLongerNeeded(model)
    Wait(150)

    if Studio.Clothing then
        Studio.Clothing.PublishState()
    end

    callback({ ok = true })
end)

RegisterNUICallback('autoPreview:start', function(data, callback)
    local ok = Studio.AutoPreview.Start(tonumber(data.startDrawable), tonumber(data.endDrawable))
    local state = Studio.AutoPreview.GetState()

    callback({ ok = ok, error = state.error })
end)

RegisterNUICallback('autoPreview:pause', function(_, callback)
    callback({ ok = Studio.AutoPreview.Pause() })
end)

RegisterNUICallback('autoPreview:resume', function(_, callback)
    callback({ ok = Studio.AutoPreview.Resume() })
end)

RegisterNUICallback('autoPreview:stop', function(_, callback)
    callback({ ok = Studio.AutoPreview.Stop() })
end)

RegisterNUICallback('screenshot:capture', function(_, callback)
    local ok, errorMessage = Studio.Screenshot.Capture('manual')

    callback({ ok = ok, error = errorMessage })
end)

RegisterNUICallback('settings:screenshotKey', function(data, callback)
    local key = tostring(data.key or Config.Screenshot.key):upper()

    SetResourceKvp('tpm_clothing_studio:screenshot_key', key)

    SendNUIMessage({
        type = 'settings:keySaved',
        payload = {
            key = key
        }
    })

    callback({ ok = true, key = key })
end)

RegisterNUICallback('settings:packName', function(data, callback)
    local packName = tostring(data.packName or ''):gsub('[^%w%-_]', '_'):lower()

    SetResourceKvp('tpm_clothing_studio:pack_name', packName)

    SendNUIMessage({
        type = 'settings:packSaved',
        payload = {
            packName = packName
        }
    })

    callback({ ok = true, packName = packName })
end)

Studio.ModuleLoader.Register('menu', Studio.Menu)

RegisterNetEvent('tpm_clothing_studio:packs:update', function(packs)
    if Studio.Clothing then
        Studio.Clothing.SetAvailablePacks(packs)
    end
end)

RegisterNetEvent('tpm_clothing_studio:peds:update', function(peds)
    SendNUIMessage({
        type = 'peds:update',
        payload = peds or {}
    })
end)

CreateThread(function()
    while true do
        Wait(0)

        if Studio.GetState('nuiVisible') then
            if IsControlJustReleased(0, 177) or IsControlJustReleased(0, 200) then
                Studio.Menu.CancelAndClose()
            end
        end
    end
end)
