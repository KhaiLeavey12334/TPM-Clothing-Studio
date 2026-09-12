Studio.Clothing = Studio.Clothing or {}

function Studio.Clothing.Start()
    Studio.Logger.Debug('Clothing module ready.')
end

Studio.ModuleLoader.Register('clothing', Studio.Clothing)
