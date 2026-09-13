Studio.Camera = Studio.Camera or {}

local activeCamera = nil
local currentPresetName = Config.Camera.defaultPreset
local currentHeading = Config.Camera.presets[Config.Camera.defaultPreset].heading
local currentDistance = Config.Camera.presets[Config.Camera.defaultPreset].distance

local function getTargetPosition(ped, preset)
    local target = GetEntityCoords(ped)

    if preset.bone and preset.bone ~= 0 then
        local boneIndex = GetPedBoneIndex(ped, preset.bone)
        target = GetWorldPositionOfEntityBone(ped, boneIndex)
    end

    return target + preset.targetOffset
end

local function getCameraPosition(ped, target, preset, distance)
    local heading = GetEntityHeading(ped)
    local directionRadians = math.rad(heading + currentHeading)
    local forward = vector3(math.sin(directionRadians), math.cos(directionRadians), 0.0)
    local rightRadians = math.rad(heading + 90.0)
    local right = vector3(math.sin(rightRadians), math.cos(rightRadians), 0.0)
    local offset = preset.offset

    return vector3(
        target.x + (forward.x * distance) + (right.x * offset.x),
        target.y + (forward.y * distance) + (right.y * offset.x),
        target.z + offset.z
    )
end

local function createCamera()
    local camera = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)

    SetCamActive(camera, true)
    RenderScriptCams(true, true, Config.Camera.transitionMs, true, true)

    return camera
end

local function setCameraView(camera, position, target, fov)
    SetCamCoord(camera, position.x, position.y, position.z)
    PointCamAtCoord(camera, target.x, target.y, target.z)
    SetCamFov(camera, fov)
end

local function moveCamera(position, target, fov, transitionMs)
    if not activeCamera then
        activeCamera = createCamera()
        setCameraView(activeCamera, position, target, fov)
        return
    end

    if transitionMs and transitionMs > 0 then
        local previousCamera = activeCamera
        local nextCamera = createCamera()

        setCameraView(nextCamera, position, target, fov)
        SetCamActiveWithInterp(nextCamera, previousCamera, transitionMs, true, true)
        activeCamera = nextCamera

        CreateThread(function()
            Wait(transitionMs + 50)
            DestroyCam(previousCamera, false)
        end)

        return
    end

    setCameraView(activeCamera, position, target, fov)
end

function Studio.Camera.IsActive()
    return activeCamera ~= nil
end

function Studio.Camera.ApplyPreset(presetName, transitionMs)
    local preset = Config.Camera.presets[presetName]

    if not preset then
        Studio.Logger.Warn(('Camera preset "%s" does not exist.'):format(presetName))
        return false
    end

    if currentPresetName ~= presetName then
        currentHeading = preset.heading
        currentDistance = preset.distance
    end

    local ped = PlayerPedId()
    local target = getTargetPosition(ped, preset)
    local position = getCameraPosition(ped, target, preset, currentDistance)

    currentPresetName = presetName

    moveCamera(position, target, preset.fov, transitionMs or Config.Camera.transitionMs)
    Studio.Logger.Debug(('Applied camera preset "%s".'):format(presetName))

    return true
end

function Studio.Camera.SetShot(presetName, angle, transitionMs)
    local preset = Config.Camera.presets[presetName]

    if not preset then
        return false
    end

    currentPresetName = presetName
    currentDistance = preset.distance
    currentHeading = angle == 'back' and 0.0 or 180.0

    return Studio.Camera.ApplyPreset(presetName, transitionMs or 0)
end

function Studio.Camera.Rotate(delta)
    currentHeading = (currentHeading + delta) % 360.0
    Studio.Camera.ApplyPreset(currentPresetName, 0)
end

function Studio.Camera.Zoom(delta)
    currentDistance = math.min(Config.Camera.maxDistance, math.max(Config.Camera.minDistance, currentDistance + delta))
    Studio.Camera.ApplyPreset(currentPresetName, 0)
end

function Studio.Camera.Reset()
    local preset = Config.Camera.presets[Config.Camera.defaultPreset]

    currentPresetName = Config.Camera.defaultPreset
    currentHeading = preset.heading
    currentDistance = preset.distance
    Studio.Camera.ApplyPreset(currentPresetName, Config.Camera.transitionMs)
end

function Studio.Camera.Destroy()
    if not activeCamera then
        return
    end

    RenderScriptCams(false, true, Config.Camera.transitionMs, true, true)
    DestroyCam(activeCamera, false)
    activeCamera = nil
    Studio.Logger.Debug('Camera destroyed.')
end

function Studio.Camera.Toggle()
    if Studio.Camera.IsActive() then
        Studio.Camera.Destroy()
        return
    end

    Studio.Camera.Reset()
end

function Studio.Camera.Start()
    RegisterCommand(Config.Commands.toggleCamera, function()
        Studio.Camera.Toggle()
    end, false)

    Studio.Logger.Debug('Camera module ready.')
end

Studio.ModuleLoader.Register('camera', Studio.Camera)
