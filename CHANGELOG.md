# Changelog

## 1.0.2

- Fixed: game crash after stopping the resource while a stray plumbob prop was still in the world. Untracked props are now removed every 1.5 s and all of them on stop.

## 1.0.1

- Fixed: changing the colour could leave an extra plumbob frozen in the air (two spawns raced while the model loaded).
- Fixed: the prop no longer flashes at the spawn point; it stays hidden until it is placed above the head.
- The plumbob now hides together with its owner (invisible ped, noclip, character select) instead of hanging in place.
- Restarting the resource resets every plumbob, so none show up right after the start.

## 1.0.0

First public release.

- Plumbob above player heads in three colours (green, orange, red), synced through state bags.
- Menu for players (`/plumbob`), admin command for others (`/plumbob <id> [colour|hide]`).
- Client and server exports.
- Server validates every request from clients (colour whitelist, cooldown).
- Colours are defined in `config.lua`; add your own by streaming another model.
- Blender source and build script included in `_source/`.
