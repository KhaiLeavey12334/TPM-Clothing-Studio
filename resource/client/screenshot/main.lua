Studio.Screenshot = Studio.Screenshot or {}

function Studio.Screenshot.Start()
    Studio.Logger.Debug('Screenshot module ready.')
end

Studio.ModuleLoader.Register('screenshot', Studio.Screenshot)
