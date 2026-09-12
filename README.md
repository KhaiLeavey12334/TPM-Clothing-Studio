# TPM Clothing Studio

TPM Clothing Studio is a FiveM developer toolkit for previewing custom clothing, pairing items with body setups, and capturing catalogue-ready screenshots.

## Current Version

`0.0.3-alpha`

Alpha 0.0.3 includes the production framework, the first camera system, and the clothing engine:

- FiveM `fxmanifest.lua`
- Lua 5.4 resource configuration
- Shared `Studio` namespace
- Logger
- Module loader
- Modular client folders
- Server bootstrap
- NUI shell
- Scripted camera
- Camera presets
- Zoom and rotation helpers
- Smooth camera transitions
- Component and prop browser state
- Drawable and texture browser helpers
- Collection-aware shared clothing state

## Install

1. Copy the `resource` folder into your FiveM server resources directory.
2. Rename it to `tpm_clothing_studio` if desired.
3. Add this to `server.cfg`:

```cfg
ensure tpm_clothing_studio
```

4. Start the server and use `/tpmstudio` in-game.
5. Use `/tpmcamera` to toggle the current scripted preview camera.
6. Use `/tpmnextdrawable`, `/tpmprevdrawable`, `/tpmnexttexture`, and `/tpmprevtexture` to test clothing browsing.

## Roadmap

The next milestones add the camera system, clothing browser, modern NUI, screenshot tools, and automated preview capture.
