# Architecture

TPM Clothing Studio is a modular FiveM resource. The shared `Studio` namespace owns state, logging, and module registration. Feature modules register themselves with the loader and expose small lifecycle functions.

## Modules

- `core`: shared namespace, logger, and module loader.
- `camera`: scripted camera tools planned for Alpha 0.0.2.
- `clothing`: clothing and prop browsing planned for Alpha 0.0.3.
- `menu`: NUI visibility and interaction bridge.
- `controls`: keyboard and input handling.
- `screenshot`: screenshot capture workflow planned for Alpha 0.0.5.
- `studio`: application bootstrap.

## Principles

- Keep FiveM natives behind focused modules.
- Store shared state in `Studio.state`.
- Use config values instead of hard-coded commands or labels.
- Prefer small lifecycle functions so each alpha can be tested independently.
