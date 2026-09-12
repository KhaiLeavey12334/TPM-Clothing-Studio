Studio.Menu = Studio.Menu or {}

function Studio.Menu.SetVisible(visible)
    Studio.SetState('nuiVisible', visible)
    SetNuiFocus(visible, visible)
    SendNUIMessage({
        type = 'studio:visibility',
        visible = visible
    })
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

Studio.ModuleLoader.Register('menu', Studio.Menu)
