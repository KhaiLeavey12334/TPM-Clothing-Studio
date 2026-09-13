Studio.Clothing = Studio.Clothing or {}

local state = {
    mode = 'component',
    componentId = Config.Clothing.defaultComponent,
    propId = Config.Clothing.defaultProp,
    drawable = 0,
    texture = 0,
    collection = Config.Clothing.collections.fallback,
    packId = 'base'
}

local activePack = Config.Packs[1]
local availablePacks = Config.Packs

local function clampIndex(value, count)
    if count <= 0 then
        return 0
    end

    return value % count
end

local function getPed()
    return PlayerPedId()
end

local function isCollectionPack()
    return activePack and activePack.collection and activePack.collection ~= ''
end

local function callNative(nativeName, fallback, ...)
    local native = _G[nativeName]

    if type(native) ~= 'function' then
        return fallback
    end

    local ok, result = pcall(native, ...)

    if not ok or result == nil then
        return fallback
    end

    return result
end

local function getDrawableCount()
    local ped = getPed()

    if state.mode == 'prop' then
        if isCollectionPack() then
            return callNative('GetNumberOfPedCollectionPropDrawableVariations', 0, ped, state.propId, activePack.collection)
        end

        return GetNumberOfPedPropDrawableVariations(ped, state.propId) + 1
    end

    if isCollectionPack() then
        return callNative('GetNumberOfPedCollectionDrawableVariations', 0, ped, state.componentId, activePack.collection)
    end

    return GetNumberOfPedDrawableVariations(ped, state.componentId)
end

local function getTextureCount()
    local ped = getPed()

    if state.mode == 'prop' then
        local propDrawable = math.max(0, state.drawable - 1)

        if isCollectionPack() then
            return callNative('GetNumberOfPedCollectionPropTextureVariations', 0, ped, state.propId, activePack.collection, propDrawable)
        end

        return GetNumberOfPedPropTextureVariations(ped, state.propId, propDrawable)
    end

    if isCollectionPack() then
        return callNative('GetNumberOfPedCollectionTextureVariations', 0, ped, state.componentId, activePack.collection, state.drawable)
    end

    return GetNumberOfPedTextureVariations(ped, state.componentId, state.drawable)
end

local function getTextureCountForDrawable(drawable)
    local ped = getPed()

    if state.mode == 'prop' then
        local propDrawable = math.max(0, drawable - 1)

        if isCollectionPack() then
            return callNative('GetNumberOfPedCollectionPropTextureVariations', 0, ped, state.propId, activePack.collection, propDrawable)
        end

        return GetNumberOfPedPropTextureVariations(ped, state.propId, propDrawable)
    end

    if isCollectionPack() then
        return callNative('GetNumberOfPedCollectionTextureVariations', 0, ped, state.componentId, activePack.collection, drawable)
    end

    return GetNumberOfPedTextureVariations(ped, state.componentId, drawable)
end

local function applyComponent()
    local ped = getPed()
    local textureCount = getTextureCount()

    state.texture = clampIndex(state.texture, textureCount)

    if isCollectionPack() then
        callNative('SetPedCollectionComponentVariation', nil, ped, state.componentId, activePack.collection, state.drawable, state.texture, 0)
        return
    end

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

    if isCollectionPack() then
        callNative('SetPedCollectionPropIndex', nil, ped, state.propId, activePack.collection, state.drawable - 1, state.texture, true)
        return
    end

    SetPedPropIndex(ped, state.propId, state.drawable - 1, state.texture, true)
end

function Studio.Clothing.PublishState()
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
        collection = state.collection,
        packId = state.packId,
        packLabel = activePack.label or 'Default / Base GTA',
        packs = availablePacks
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

    Studio.Clothing.PublishState()
end

function Studio.Clothing.GetState()
    return state
end

function Studio.Clothing.GetDrawableCount()
    return getDrawableCount()
end

function Studio.Clothing.GetTextureCount()
    return getTextureCount()
end

function Studio.Clothing.GetTextureCountForDrawable(drawable)
    return getTextureCountForDrawable(drawable)
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
    Studio.Clothing.PublishState()
end

function Studio.Clothing.SetPack(packId)
    for _, pack in ipairs(availablePacks) do
        if pack.id == packId then
            activePack = pack
            state.packId = pack.id
            state.collection = pack.collection ~= '' and pack.collection or Config.Clothing.collections.fallback
            state.drawable = 0
            state.texture = 0
            applyCurrent()
            return true
        end
    end

    return false
end

function Studio.Clothing.SetAvailablePacks(packs)
    if type(packs) ~= 'table' or #packs == 0 then
        return
    end

    availablePacks = packs

    local activeExists = false
    for _, pack in ipairs(availablePacks) do
        if pack.id == state.packId then
            activePack = pack
            activeExists = true
            break
        end
    end

    if not activeExists then
        activePack = availablePacks[1]
        state.packId = activePack.id
        state.collection = Config.Clothing.collections.fallback
    end

    Studio.Clothing.PublishState()
end

function Studio.Clothing.GetPack()
    return activePack
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
