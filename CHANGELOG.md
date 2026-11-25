# Changelog

All notable changes to UnMacOS. Versions follow [Semantic Versioning](https://semver.org/);
full notes for each are on [GitHub Releases](https://github.com/shrujancheruku/unmacos/releases).

## [Unreleased]

### Added
- The Tune phase, `unmacos-tune` (menu → Tune the Look): pick Look Settings on your own desktop
  and see each one straight away as a Draft Look, then Save or Discard. Settings that can't be
  shown live are badged (after restart, after logout, on save) and applied when you save. The
  installer offers it once the desktop is up, or says how to run it later.
- `unmacos-look`: renders the Look (every app's themed config) from chezmoi templates into any
  folder, keeps a Draft Look (`draft set`, `save`, `discard`) and live-reloads apps (`reload`).
- New Look Settings, all shown live in Tune: window gap, border width, bar height, bar position
  (top or bottom), terminal font and size, bar font, window animation on/off and animation duration.
- `corner_radius` sets one corner radius for windows, bar chips, popups and Spotify. The bar and
  Spotify change at once; window corners change as each app relaunches.
- The bar can sit at the bottom of the screen, with Rift's tiling area following it.

### Changed
- Rift's config is now rendered by the Look from `templates/rift.toml.tpl`, with its gaps worked out
  from the window gap, border width and bar height. `~/.config/rift/config.toml` is a symlink to the
  rendered file, so local edits to it are lost: move them into the template (or a Setting).
- Window animation on/off moves from `[desktop] animate` to `[look] animate`, set in Tune, and the
  setup wizard no longer asks it. Older Answers keep working, and the key moves across (with a `.bak`) the next time they are read.
- The bar's chips, popups and the clock's inner pill and the windows share 8px corners (bar chips were 9–10px, windows 4px).
- `unmacos-toggle-bar` fits Rift's gaps to the rendered config, so a bar that is still reloading can't
  leave the wrong gap.

## [1.5.0] - 2026-11-23

### Added
- Setup wizard, `unmacos-setup`: git identity, 1Password, theme, optional app groups, what UnMacOS
  may change, Rift desktop options and weather, saved to `~/.config/unmacos/setup.toml`.
  `--export` / `--import` (or `UNMACOS_SETUP=… install.sh`) rebuild the same setup on another Mac;
  `--checklist` shows the manual steps left. Optional apps live in `brew/*.Brewfile` groups.

### Fixed
- Firefox's new tab wallpaper follows theme switches live.

## [1.4.0] - 2026-11-23

### Changed
- A larger, clearer bar: bigger text, one chip style, one typeface, the clock's date on its own pill.
- Bar outlines and dimmed text are blended from each theme's colours, so they stay visible everywhere.

### Added
- Workspace icons for every app sketchybar-app-font knows (about 950).

### Fixed
- Keyboard window switching moves the pointer to the new window and hides it.
- Even gaps at the bottom of the screen; labels no longer fall back to the system font.

## [1.3.0] - 2026-11-23

### Added
- Firefox (Pywalfox, Dark Reader), Firefox's new tab wallpaper, Spotify (Spicetify) and Orca follow the theme live.
- macOS accent and highlight colours follow the theme.
- Weather finds your location by IP; pin a city with `unmacos-weather set <city>`.
- A compact fastfetch config for a quarter-screen tile.

### Fixed
- Ghostty, btop, Neovim and spotify_player switch live; the picker sets the wallpaper.
- The Apple Intelligence and Liquid Glass settings are reapplied after macOS upgrades.
- No notification on every theme switch.

## [1.2.0] - 2026-11-22

### Added
- Theme wallpapers for all 23 themes, downloaded on first use and checked against their hashes.
  `Alt + Cmd + Space` cycles them (this replaces macOS's Finder search shortcut).

## [1.1.0] - 2026-11-22

### Added
- Keyboard shortcut cheatsheet on `Alt + Ctrl + K`, built from the Rift config each time it opens.

## [1.0.0] - 2026-11-22

First release: a keyboard-first desktop for macOS, inspired by Omarchy, installed with one command.
Rift tiling, Omarchy-style keybindings, fuzzy menus, terminal apps on one key each, SketchyBar,
23 themes switched live, Apple Intelligence and Liquid Glass off on macOS 26+, and `unmacos-doctor`.

### Breaking
- The repo became a chezmoi monorepo for the whole desktop, and AeroSpace was replaced by Rift.

[1.5.0]: https://github.com/shrujancheruku/unmacos/releases/tag/v1.5.0
[1.4.0]: https://github.com/shrujancheruku/unmacos/releases/tag/v1.4.0
[1.3.0]: https://github.com/shrujancheruku/unmacos/releases/tag/v1.3.0
[1.2.0]: https://github.com/shrujancheruku/unmacos/releases/tag/v1.2.0
[1.1.0]: https://github.com/shrujancheruku/unmacos/releases/tag/v1.1.0
[1.0.0]: https://github.com/shrujancheruku/unmacos/releases/tag/v1.0.0
