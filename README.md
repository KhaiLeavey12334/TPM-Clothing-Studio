# TPM Clothing Studio

For support contact `@el_legion` on Discord.

TPM Clothing Studio Beta 0.1.2 is a FiveM developer tool for previewing clothing packs, browsing drawables and textures, switching peds, and capturing catalogue-ready screenshots with clean filenames.

## Features

- Browse GTA/FiveM clothing components and props.
- Preview drawable and texture variations in-game.
- Capture manual screenshots with a configurable keybind.
- Run automatic screenshot jobs across a drawable range.
- Capture every texture for every selected drawable.
- Add a pack name prefix to screenshot filenames.
- Switch between male, female, and detected ped resources.
- Use a polished in-game NUI built for clothing catalogue work.

## Installation

1. Place `tpm_clothing_studio` inside your server resources folder.
2. Place `screenshot-basic` inside your server resources folder as a separate resource. A copy is included in this repository under `included-resources/screenshot-basic`.
3. Ensure `screenshot-basic` before this resource.
4. Add this to `server.cfg`:

```cfg
ensure screenshot-basic
ensure tpm_clothing_studio
```

Do not put `screenshot-basic` inside the `tpm_clothing_studio` folder. They must be unpacked as two separate resources.

5. Restart the server or run:

```txt
refresh
restart tpm_clothing_studio
```

## How To Use

Open the studio with `F1` or `/tpmstudio`.

Use **Browser** to choose a clothing component or prop. Pick a slot, then move through drawables and textures using the buttons or number fields.

Use **Screenshot** to capture the current item. Screenshots save into `resources/tpm_clothing_studio/screenshots` with structured filenames.

Use **Studio** for automatic screenshots. Enter the first drawable, then the last drawable. TPM Clothing Studio captures every texture for every drawable in that range.

Use **Ped Chooser** to switch between Male, Female, or detected ped resources.

Press `Esc` to close the UI and cancel active work.

## Screenshot Filenames

Screenshot output folder:

```txt
resources/tpm_clothing_studio/screenshots
```

By default, screenshots use:

```txt
component_011_000_000.jpg
```

If you set a pack name in Settings, it is added to the front:

```txt
tpm67_component_011_000_000.jpg
```

## Ped Resources

By default, TPM Clothing Studio scans:

```txt
resources/[peds]
```

Change this in `config.lua` under `Config.Peds.scanFolder` if your server uses a different folder.

## Configuration

Most server owners should only edit the clearly marked sections in `config.lua`, especially:

- `Config.Studio.autoStartCoords`
- `Config.Screenshot`
- `Config.AutoPreview`
- `Config.Peds`

Avoid changing internal commands or clothing component IDs unless you know exactly what your server needs.
