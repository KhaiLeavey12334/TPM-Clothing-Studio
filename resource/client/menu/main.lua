Studio.Menu = Studio.Menu or {}

function Studio.Menu.SetVisible(visible)
    Studio.SetState('nuiVisible', visible)
    SetNuiFocus(visible, visible)
    SendNUIMessage({
        type = 'studio:visibility',
        visible = visible
    })

    if visible and Studio.Clothing then
        Studio.Clothing.PublishState()
    end
end

function Studio.Menu.Toggle()
    Studio.Menu.SetVisible(not Studio.GetState('nuiVisible'))
end

function Studio.Menu.Start()
    RegisterCommand(Config.Commands.openStudio, function()
        Studio.Menu.Toggle()
    end, false)

    Studio.Logger.Debug('Menu module ready.')
end

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

RegisterNUICallback('autoPreview:start', function(_, callback)
    Studio.AutoPreview.Start()
    callback({ ok = true })
end)

RegisterNUICallback('autoPreview:pause', function(_, callback)
    Studio.AutoPreview.Pause()
    callback({ ok = true })
end)

RegisterNUICallback('autoPreview:resume', function(_, callback)
    Studio.AutoPreview.Resume()
    callback({ ok = true })
end)

Studio.ModuleLoader.Register('menu', Studio.Menu)
