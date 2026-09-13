# TPM Clothing Studio

For support contact `@el_legion` on Discord.

TPM Clothing Studio Beta 0.1.5 is a FiveM clothing preview and screenshot toolkit built for creators, server owners, and catalogue teams.

Stop wasting hours loading outfits into Blender just to check textures, frame screenshots, and build product previews. TPM Clothing Studio lets you preview clothing directly in FiveM, cycle drawables and textures in-game, and automatically capture clean catalogue screenshots with structured filenames.

It is designed to turn a slow manual clothing-preview workflow into a faster in-server studio process.

## Why Use It?

- Save hours on clothing pack previews and catalogue work.
- Preview items in the same game environment your players will use.
- Capture every texture variation without manually clicking through each one.
- Keep screenshots consistently framed with preset camera positions.
- Build cleaner clothing showcases for Discord, Tebex, websites, or internal review.

## Features

- Browse GTA/FiveM clothing components and props.
- Preview drawable and texture variations in-game.
- Capture manual screenshots with a configurable keybind.
- Run automatic screenshot jobs across a drawable range.
- Capture every texture for every selected drawable.
- Add a pack name prefix to screenshot filenames.
- Choose screenshot camera framing: Full Body, Torso, Head, or Shoes.
- Choose front or back screenshot angle.
- Switch between male, female, and detected ped resources.
- Use a polished in-game NUI built for clothing catalogue work.

## Included Resources

This repository includes:

- `resource` - TPM Clothing Studio
- `included-resources/screenshot-basic` - bundled screenshot-basic dependency

Install them as two separate resources. Do not place `screenshot-basic` inside the `tpm_clothing_studio` folder.

## Installation

1. Copy `resource` into your server resources folder and rename it to `tpm_clothing_studio`.
2. Copy `included-resources/screenshot-basic` into your server resources folder as `screenshot-basic`.
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

Use **Screenshot** to choose the camera position and angle, then capture the current item. Screenshots save into `resources/tpm_clothing_studio/screenshots` with structured filenames. The same camera settings are used for manual and automatic screenshots.

Use **Studio** for automatic screenshots. Enter the first drawable, then the last drawable. TPM Clothing Studio captures every texture for every drawable in that range.

Use **Ped Chooser** to switch between Male, Female, or detected ped resources.

Press `Esc` to close the UI and cancel active work.

## Recommended Workflow

1. Load into your FiveM server.
2. Open TPM Clothing Studio with `F1`.
3. Choose Male, Female, or a detected ped.
4. Select the clothing component or prop you want to preview.
5. Choose the screenshot camera position and angle.
6. Run Auto Screenshot across the drawable range you need.
7. Use the saved screenshots for your catalogue, Discord posts, or clothing previews.

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

Change this in `config.lua` under `Config.Peds.scanFolder` if your server uses a different folder. The default is `[peds]`.

## Configuration

Most server owners should only edit the clearly marked sections in `config.lua`, especially:

- `Config.Studio.autoStartCoords`
- `Config.Screenshot`
- `Config.AutoPreview`
- `Config.Peds`

Avoid changing internal commands or clothing component IDs unless you know exactly what your server needs.
