# TPM Clothing Studio

TPM Clothing Studio is a FiveM developer toolkit for previewing custom clothing, pairing items with body setups, and capturing catalogue-ready screenshots.

## Current Version

`0.0.1-alpha`

Alpha 0.0.1 establishes the production framework:

- FiveM `fxmanifest.lua`
- Lua 5.4 resource configuration
- Shared `Studio` namespace
- Logger
- Module loader
- Modular client folders
- Server bootstrap
- NUI shell

## Install

1. Copy the `resource` folder into your FiveM server resources directory.
2. Rename it to `tpm_clothing_studio` if desired.
3. Add this to `server.cfg`:

```cfg
ensure tpm_clothing_studio
```

4. Start the server and use `/tpmstudio` in-game.

## Roadmap

The next milestones add the camera system, clothing browser, modern NUI, screenshot tools, and automated preview capture.
