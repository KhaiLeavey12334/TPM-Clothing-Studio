Studio = Studio or {}

Studio.name = Config.ResourceName
Studio.version = Config.Version
Studio.modules = Studio.modules or {}
Studio.state = Studio.state or {
    nuiVisible = Config.Nui.defaultVisible,
    activeModule = nil
}

function Studio.SetState(key, value)
    Studio.state[key] = value
end

function Studio.GetState(key)
    return Studio.state[key]
end
