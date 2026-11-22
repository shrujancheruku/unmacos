<div align="center">

# UnMacOS

**An Omarchy-style, keyboard-first macOS desktop: tiling, TUIs and one theme for everything.**

[![macOS](https://img.shields.io/badge/macOS-15%20→%2027-000000?style=for-the-badge&logo=apple)](https://www.apple.com/macos/)
[![Rift](https://img.shields.io/badge/WM-Rift-7aa2f7?style=for-the-badge)](https://github.com/acsandmann/rift)
[![SketchyBar](https://img.shields.io/badge/Bar-SketchyBar-bb9af7?style=for-the-badge)](https://github.com/FelixKratz/SketchyBar)
[![chezmoi](https://img.shields.io/badge/dotfiles-chezmoi-9ece6a?style=for-the-badge)](https://www.chezmoi.io/)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-e0af68?style=for-the-badge)](LICENSE)

</div>

UnMacOS makes a Mac feel like [Omarchy](https://omarchy.org): windows tile themselves, every app is one
keystroke away, menus are fuzzy finders, and the whole desktop shares one swappable Tokyo Night theme.
One command sets up a fresh Mac, and the same command rebuilds it after a wipe.

- **Tiling**: [Rift](https://github.com/acsandmann/rift), with BSP, stacks, master/stack and scrolling layouts, and 5 workspaces per display
- **Bar**: [SketchyBar](https://github.com/FelixKratz/SketchyBar) (SbarLua), with Rift workspaces, media, volume, Wi-Fi, CPU, battery and weather
- **Borders**: [JankyBorders](https://github.com/FelixKratz/JankyBorders) around the focused window
- **TUIs over apps**: spotify_player, nnn, btop, lazygit, lazydocker, Neovim (LazyVim), tmux in [Ghostty](https://ghostty.org)
- **Menus**: [television](https://github.com/alexpasmantier/television) for apps, windows, clipboard, emoji, audio, Bluetooth, theme, keybindings and system
- **Theme system**: one `colors.toml` per theme, rendered into every app with live reload. Ships Tokyo Night plus the 22 other Omarchy themes, with a palette preview in the picker
- **Quieter macOS**: on macOS 26+ the installer turns off Apple Intelligence and Liquid Glass, to get as close to a Sequoia desktop as possible

## Install

On a fresh Mac (Apple silicon):

```sh
bash -c "$(curl -fsSL https://raw.githubusercontent.com/shrujancheruku/unmacos/main/install.sh)"
```

This installs the Xcode Command Line Tools and Homebrew, then runs `chezmoi init --apply`. chezmoi asks for:

| Prompt | Used for |
|---|---|
| Git name / email | `~/.gitconfig` (kept on your machine, never committed) |
| Use 1Password | Reads secrets (the spotify_player `client_id`) with `op` on apply |
| Personal apps | Also installs `Brewfile.personal` (my extra apps). Say no unless you're me |

Then finish the steps macOS doesn't let scripts do:

1. **System Settings → Privacy & Security → Accessibility**: allow `rift` and `clipse` (clipse asks when it starts). Then run `rift service restart`. (Paste-back from the clipboard and emoji pickers uses Rift's permission, so Ghostty doesn't need it.) The first time a menu opens, Ghostty asks whether to allow running a command: allow it.
2. **Log out and back in.** This applies the Spaces, hidden menu bar and Liquid Glass changes.
3. macOS 26+: approve **UnMacOS: no Apple Intelligence** in *System Settings → General → Device Management*.
4. Run `unmacos-doctor` to check everything.

Update later with `chezmoi update`, or from the menu (`Alt + Ctrl + Space` → Update).

## Keybindings

`Alt` is Omarchy's `SUPER`. Omarchy's `ALT` becomes `Ctrl`, and its `CTRL` becomes `Cmd`. Press `Alt + Ctrl + K` to search them all.

| Keys | Action |
|---|---|
| `Alt + Enter` | Terminal (Ghostty) |
| `Alt + Ctrl + Enter` | tmux session "Work" |
| `Alt + Shift + B` / `Alt + Shift + Enter` | Browser (Firefox); add `Ctrl` for a private window |
| `Alt + Shift + M` / `F` / `N` / `G` / `D` / `A` | Music, files, Neovim, lazygit, lazydocker, Claude: focuses the window if it's already open |
| `Alt + Cmd + T` | btop |
| `Alt + Shift + /` | 1Password |
| `Alt + Space` | App launcher |
| `Alt + Ctrl + Space` | UnMacOS menu |
| `Alt + Escape` | Lock, sleep, restart, shut down |
| `Alt + Ctrl + V` / `Alt + Ctrl + .` | Clipboard history / emoji |
| `Alt + Ctrl + W` | Find a window |
| `Alt + Cmd + A` / `B` / `W` | Audio output / Bluetooth / Wi-Fi |
| `Alt + Cmd + N` / `L` | Night light / lock |
| `Alt + Shift + S` | Screenshot to clipboard |
| `Alt + Shift + Space` | Show or hide the bar |
| `Alt + Ctrl + Shift + Space` | Switch theme |
| `Alt + H J K L` | Focus window |
| `Alt + Shift + H J K L` | Move window |
| `Alt + 1–5` | Go to workspace |
| `Alt + Shift + 1–5` | Move window there and follow (`Alt + Ctrl + 1–5` moves it and stays) |
| `Alt + Tab` / `Alt + Shift + Tab` / `Alt + Ctrl + Tab` | Next / previous / last workspace |
| `Alt + W` | Close window |
| `Alt + T` | Float / tile |
| `Alt + F` / `Alt + Cmd + F` | Fullscreen / fullscreen inside gaps |
| `Alt + G` / `Alt + Ctrl + G` | Stack windows / unstack |
| `Alt + /` | Flip split direction |
| `Alt + − / =` | Resize width; add `Shift` for height. `Alt + R` enters resize mode |
| `Alt + Ctrl + B / T / M / S` | Layout: BSP, traditional, master/stack, scrolling |
| `Alt + Z` | Turn tiling off or on for this Space |
| `Alt + Shift + R` | Reload Rift |

## Themes

Everything reads its colours from `~/.local/state/unmacos/theme/`. That directory is rendered by
`unmacos-theme-render` from `~/.local/share/unmacos/`:

```
themes/<name>/colors.toml    palette (Omarchy keys: accent, background, foreground, red, …)
themes/<name>/<file>         optional hand-made file that replaces a rendered one (e.g. ghostty.conf)
templates/<file>.tpl         {{ key }} → #rrggbb, {{ key_strip }} → rrggbb, {{ key_rgb }} → r,g,b
```

```sh
unmacos-theme-render --list
unmacos-theme-render tokyo-night     # or Alt + Ctrl + Shift + Space
```

Switching a theme updates these live: SketchyBar, borders, Ghostty, tmux, btop and Neovim (open editors
switch too). television and fzf pick it up the next time they open. To add a theme, copy any
`themes/<name>/colors.toml` (an Omarchy `colors.toml` works as is) and change the colours.

Tokyo Night is UnMacOS's own, hand-tuned theme. The other 22 are Omarchy's palettes, converted by
adding `border_inactive` and `bar_border` (and `orange`/`brown` where missing) from their own colours.

## What's in the repo

```
install.sh                 bootstrap: CLT, Homebrew, chezmoi
Brewfile                   the desktop and terminal tools
Brewfile.personal          optional extra apps
home/                      chezmoi source → $HOME
  .chezmoiscripts/         brew bundle, SbarLua, macOS settings, no-AI/no-glass, theme, services, clipse
  dot_config/rift/         tiling + keybindings
  dot_config/sketchybar/   bar (Lua)
  dot_config/television/   pickers (cable channels)
  dot_config/{ghostty,tmux,nvim,btop,borders,spotify-player,…}
  dot_local/bin/           unmacos-* helpers (menu, tui, popup, paste, theme-render, theme-preview, doctor)
  dot_local/share/unmacos/ themes, templates, configuration profile
```

## Things to change for your Mac

- **Gaps** are 4px you can see. JankyBorders draws its 6px border outside each window, so Rift's gaps
  include it: inner 16, sides 10, top 44. Change `UNMACOS_GAP`/`UNMACOS_BORDER` in `unmacos-toggle-bar`
  and the gaps section of `dot_config/rift/config.toml` together.
- **Animations**: `rift-cli execute config set-animate false` turns them off. Rift moves real windows, so
  a new window slides in from wherever macOS first put it; Hyprland-style compositor effects aren't possible.
- **Wi-Fi widget** uses interface `en0` (`dot_config/sketchybar/items/widgets/wifi.lua`).
- **Browser** is Firefox. Change the `Alt + Shift + B` lines in `dot_config/rift/config.toml`.
- **Personal apps**: edit `Brewfile.personal`, or answer no.
- **Secrets**: only the spotify_player `client_id`, read from `op://Private/spotify-player/client_id`. Change
  `spotify_client_id_ref` in `~/.config/chezmoi/chezmoi.toml`.
- **Machine-only shell config** goes in `~/.zshrc.local`. It's sourced, never committed.

## macOS 26+ (Tahoe, Golden Gate)

`home/.chezmoiscripts/run_onchange_after_40-no-ai-no-glass.sh.tmpl` turns off:

- **Apple Intelligence**: a configuration profile turns off Siri, Writing Tools, Genmoji, Image Playground, ChatGPT and the Mail, Safari, Notes and notification summaries. A feature flag removes the Writing Tools popup.
- **Liquid Glass**: Reduce Transparency, plus the SwiftUI `DisableSolarium` switch. Control Center keeps the new UI so menu bar items keep working. On 27 you also set *Appearance → Liquid Glass* to the minimum; the script opens that page for you.

Opt out with `UNMACOS_KEEP_AI=1` / `UNMACOS_KEEP_GLASS=1 chezmoi apply`. The script header explains how to undo each change.

## Credits

- [FelixKratz](https://github.com/FelixKratz): SketchyBar, SbarLua, JankyBorders and the dotfiles this bar started from
- [acsandmann/rift](https://github.com/acsandmann/rift): the window manager
- [Omarchy](https://github.com/basecamp/omarchy): the keybindings, menus, theme format and 22 theme palettes (MIT, see `home/dot_local/share/unmacos/licenses/omarchy.txt`)
- [Unicode emoji data](https://www.unicode.org/license.txt): the emoji picker's list
- [television](https://github.com/alexpasmantier/television), [clipse](https://github.com/savedra1/clipse), [spotify_player](https://github.com/aome510/spotify-player), [nnn](https://github.com/jarun/nnn)
- [kvndrsslr/sketchybar-app-font](https://github.com/kvndrsslr/sketchybar-app-font), [Tokyo Night](https://github.com/folke/tokyonight.nvim)

## License

[GPL-3.0](LICENSE)
