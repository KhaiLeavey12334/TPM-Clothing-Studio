Studio.App = Studio.App or {}

function Studio.App.Start()
    Studio.Logger.Info(('Booting %s %s.'):format(Studio.name, Studio.version))
end

CreateThread(function()
    Studio.ModuleLoader.Register('studio', Studio.App)
    Studio.ModuleLoader.Start('studio')
end)
