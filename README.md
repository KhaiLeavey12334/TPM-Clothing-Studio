# TPM Clothing Studio

TPM Clothing Studio is a FiveM developer toolkit for previewing custom clothing, pairing items with body setups, and capturing catalogue-ready screenshots.

## Current Version

`0.0.5-alpha`

Alpha 0.0.5 includes the production framework, camera system, clothing engine, full NUI, and manual screenshots:

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
- Browser, Studio, Screenshot, and Settings pages
- Modern dark NUI
- NUI controls for browsing clothing variations
- F13 screenshot capture
- Automatic filename formatting
- UI hiding and capture delay

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
7. Use F13 or `/tpmscreenshot` to capture the current clothing item.

## Roadmap

The next milestones add the camera system, clothing browser, modern NUI, screenshot tools, and automated preview capture.
