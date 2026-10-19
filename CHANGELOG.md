# Changelog

## 1.0.0

First public release.

- Plumbob above player heads in three colours (green, orange, red), synced through state bags.
- Menu for players (`/plumbob`), admin command for others (`/plumbob <id> [colour|hide]`).
- Client and server exports.
- Server validates every request from clients (colour whitelist, cooldown).
- Colours are defined in `config.lua`; add your own by streaming another model.
- Blender source and build script included in `_source/`.
