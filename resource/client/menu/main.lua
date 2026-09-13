Studio.Menu = Studio.Menu or {}

function Studio.Menu.SetVisible(visible, options)
    options = options or {}

    Studio.SetState('nuiVisible', visible)
    SetNuiFocus(visible, visible)
    SendNUIMessage({
        type = 'studio:visibility',
        visible = visible
    })

    if visible and Studio.Clothing then
        TriggerServerEvent('tpm_clothing_studio:packs:request')
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
    Studio.Menu.SetVisible(false)
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

RegisterNUICallback('autoPreview:start', function(data, callback)
    local ok = Studio.AutoPreview.Start(tonumber(data.limit))
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
