Studio.Clothing = Studio.Clothing or {}

local state = {
    mode = 'component',
    componentId = Config.Clothing.defaultComponent,
    propId = Config.Clothing.defaultProp,
    drawable = 0,
    texture = 0,
    collection = Config.Clothing.collections.fallback
}

local function clampIndex(value, count)
    if count <= 0 then
        return 0
    end

    return value % count
end

local function getPed()
    return PlayerPedId()
end

local function getDrawableCount()
    local ped = getPed()

    if state.mode == 'prop' then
        return GetNumberOfPedPropDrawableVariations(ped, state.propId) + 1
    end

    return GetNumberOfPedDrawableVariations(ped, state.componentId)
end

local function getTextureCount()
    local ped = getPed()

    if state.mode == 'prop' then
        local propDrawable = math.max(0, state.drawable - 1)

        return GetNumberOfPedPropTextureVariations(ped, state.propId, propDrawable)
    end

    return GetNumberOfPedTextureVariations(ped, state.componentId, state.drawable)
end

local function applyComponent()
    local ped = getPed()
    local textureCount = getTextureCount()

    state.texture = clampIndex(state.texture, textureCount)
    SetPedComponentVariation(ped, state.componentId, state.drawable, state.texture, 0)
end

local function applyProp()
    local ped = getPed()
    local textureCount = getTextureCount()

    state.texture = clampIndex(state.texture, textureCount)

    if state.drawable <= 0 then
        ClearPedProp(ped, state.propId)
        return
    end

    SetPedPropIndex(ped, state.propId, state.drawable - 1, state.texture, true)
end

local function publishState()
    local drawableCount = getDrawableCount()
    local textureCount = getTextureCount()

    Studio.SetState('clothing', {
        mode = state.mode,
        componentId = state.componentId,
        propId = state.propId,
        drawable = state.drawable,
        texture = state.texture,
        drawableCount = drawableCount,
        textureCount = textureCount,
        collection = state.collection
    })

    SendNUIMessage({
        type = 'clothing:state',
        payload = Studio.GetState('clothing')
    })
end

local function applyCurrent()
    if state.mode == 'prop' then
        applyProp()
    else
        applyComponent()
    end

    publishState()
end

function Studio.Clothing.GetState()
    return state
end

function Studio.Clothing.SetComponent(componentId)
    state.mode = 'component'
    state.componentId = componentId
    state.drawable = 0
    state.texture = 0
    applyCurrent()
end

function Studio.Clothing.SetProp(propId)
    state.mode = 'prop'
    state.propId = propId
    state.drawable = 0
    state.texture = 0
    applyCurrent()
end

function Studio.Clothing.SetDrawable(drawable)
    state.drawable = clampIndex(drawable, getDrawableCount())
    state.texture = 0
    applyCurrent()
end

function Studio.Clothing.SetTexture(texture)
    state.texture = clampIndex(texture, getTextureCount())
    applyCurrent()
end

function Studio.Clothing.StepDrawable(delta)
    Studio.Clothing.SetDrawable(state.drawable + delta)
end

function Studio.Clothing.StepTexture(delta)
    Studio.Clothing.SetTexture(state.texture + delta)
end

function Studio.Clothing.SetCollection(collectionName)
    state.collection = collectionName or Config.Clothing.collections.fallback
    publishState()
end

function Studio.Clothing.GetComponents()
    return Config.Clothing.components
end

function Studio.Clothing.GetProps()
    return Config.Clothing.props
end

function Studio.Clothing.Start()
    RegisterCommand(Config.Commands.nextDrawable, function()
        Studio.Clothing.StepDrawable(1)
    end, false)

    RegisterCommand(Config.Commands.previousDrawable, function()
        Studio.Clothing.StepDrawable(-1)
    end, false)

    RegisterCommand(Config.Commands.nextTexture, function()
        Studio.Clothing.StepTexture(1)
    end, false)

    RegisterCommand(Config.Commands.previousTexture, function()
        Studio.Clothing.StepTexture(-1)
    end, false)

    applyCurrent()
    Studio.Logger.Debug('Clothing module ready.')
end

Studio.ModuleLoader.Register('clothing', Studio.Clothing)
