Studio.ModuleLoader = Studio.ModuleLoader or {}

local function hasLifecycle(module, lifecycleName)
    return type(module) == 'table' and type(module[lifecycleName]) == 'function'
end

function Studio.ModuleLoader.Register(name, module)
    if not name or name == '' then
        Studio.Logger.Error('Attempted to register a module without a name.')
        return false
    end

    if type(module) ~= 'table' then
        Studio.Logger.Error(('Module "%s" must be a table.'):format(name))
        return false
    end

    Studio.modules[name] = module
    Studio.Logger.Debug(('Registered module "%s".'):format(name))
    return true
end

function Studio.ModuleLoader.Start(name)
    local module = Studio.modules[name]

    if not module then
        Studio.Logger.Warn(('Module "%s" is not registered.'):format(name))
        return false
    end

    if hasLifecycle(module, 'Start') then
        module.Start()
    end

    Studio.SetState('activeModule', name)
    Studio.Logger.Info(('Started module "%s".'):format(name))
    return true
end

function Studio.ModuleLoader.StartAll()
    for name in pairs(Studio.modules) do
        Studio.ModuleLoader.Start(name)
    end
end
