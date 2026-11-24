# Changelog

All notable changes to UnMacOS. Versions follow [Semantic Versioning](https://semver.org/);
full notes for each are on [GitHub Releases](https://github.com/shrujancheruku/unmacos/releases).

## [Unreleased]

### Changed
- The bar's chips, popups and the clock's inner pill and the windows share 8px corners (bar chips were 9–10px, windows 4px).

### Added
- `corner_radius` in `setup.toml` sets one corner radius for windows, bar chips, popups and Spotify.

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
