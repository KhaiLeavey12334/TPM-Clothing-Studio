Config = Config or {}

Config.Debug = true
Config.ResourceName = 'TPM Clothing Studio'
Config.Version = '0.0.2-alpha'

Config.Commands = {
    openStudio = 'tpmstudio',
    toggleCamera = 'tpmcamera'
}

Config.Nui = {
    defaultVisible = false
}

Config.Logging = {
    prefix = 'TPM Clothing Studio',
    showTimestamps = true
}

Config.Camera = {
    defaultPreset = 'fullBody',
    transitionMs = 650,
    rotationStep = 15.0,
    zoomStep = 0.15,
    minDistance = 0.75,
    maxDistance = 4.0,
    presets = {
        fullBody = {
            label = 'Full Body',
            bone = 0,
            offset = vector3(0.0, 2.4, 0.65),
            targetOffset = vector3(0.0, 0.0, 0.15),
            fov = 38.0,
            distance = 2.4,
            heading = 180.0
        },
        torso = {
            label = 'Torso',
            bone = 24818,
            offset = vector3(0.0, 1.45, 0.12),
            targetOffset = vector3(0.0, 0.0, 0.08),
            fov = 32.0,
            distance = 1.45,
            heading = 180.0
        },
        head = {
            label = 'Head',
            bone = 31086,
            offset = vector3(0.0, 0.95, 0.02),
            targetOffset = vector3(0.0, 0.0, 0.02),
            fov = 28.0,
            distance = 0.95,
            heading = 180.0
        },
        shoes = {
            label = 'Shoes',
            bone = 0,
            offset = vector3(0.0, 1.25, -0.82),
            targetOffset = vector3(0.0, 0.0, -0.85),
            fov = 30.0,
            distance = 1.25,
            heading = 180.0
        }
    }
}
