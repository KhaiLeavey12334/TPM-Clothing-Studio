Studio.Camera = Studio.Camera or {}

function Studio.Camera.Start()
    Studio.Logger.Debug('Camera module ready.')
end

Studio.ModuleLoader.Register('camera', Studio.Camera)
