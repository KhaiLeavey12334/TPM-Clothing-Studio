Studio.Controls = Studio.Controls or {}

function Studio.Controls.Start()
    Studio.Logger.Debug('Controls module ready.')
end

Studio.ModuleLoader.Register('controls', Studio.Controls)
