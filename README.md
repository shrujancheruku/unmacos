<div align="center">

# UnMacOS

### Your Mac, without the mouse.

**Tiling windows, instant fuzzy menus, terminal apps and a desktop-wide theme you can switch live. The Omarchy workflow on macOS, installed with one command.**

[![macOS](https://img.shields.io/badge/macOS-15%20→%2027-000000?style=for-the-badge&logo=apple)](https://www.apple.com/macos/)
[![Rift](https://img.shields.io/badge/WM-Rift-7aa2f7?style=for-the-badge)](https://github.com/acsandmann/rift)
[![SketchyBar](https://img.shields.io/badge/Bar-SketchyBar-bb9af7?style=for-the-badge)](https://github.com/FelixKratz/SketchyBar)
[![chezmoi](https://img.shields.io/badge/dotfiles-chezmoi-9ece6a?style=for-the-badge)](https://www.chezmoi.io/)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-e0af68?style=for-the-badge)](LICENSE)

</div>

```sh
bash -c "$(curl -fsSL https://raw.githubusercontent.com/shrujancheruku/unmacos/main/install.sh)"
```

macOS is a great operating system wrapped in a desktop built for the trackpad. UnMacOS keeps the
OS and replaces the desktop. Windows arrange themselves, every app and setting is a keystroke away,
and the whole screen shares one look. It's [Omarchy](https://omarchy.org)'s keyboard-first desktop,
rebuilt for the Mac.

## Why you'll like it

**Windows that tile themselves.** Open a window and it takes its place next to the others, with even
4px gaps and a highlighted border on the one you're using. No dragging, no resizing, no overlapping.
Five workspaces per display, and four layouts to pick from: split, stacked, main-and-side, or
scrolling. Powered by [Rift](https://github.com/acsandmann/rift).

**Everything is one keystroke away.** `Alt + Space` launches apps. `Alt + Ctrl + V` brings back
anything you've copied. `Alt + Ctrl + .` finds an emoji. `Alt + Escape` locks, sleeps or restarts.
Every menu is a fuzzy finder ([television](https://github.com/alexpasmantier/television)): type a
few letters, press Enter, and the result is pasted straight into the app you came from.

**Terminal apps that feel like apps.** Music, files, Git, Docker, system monitor, editor and
Claude, each on its own key. Press the key and the app opens; press it again and it jumps to the
window that's already open. They all run in [Ghostty](https://ghostty.org) and look like they
belong together.

**One theme, everywhere, instantly.** Pick a theme and the bar, window borders, terminal, tmux, btop
and Neovim all change at once, even editors that are already open. Comes with 23 themes, including
hand-tuned Tokyo Night and every Omarchy palette from Catppuccin to Gruvbox, Nord, Rosé Pine and
Kanagawa. The picker shows each palette in colour before you commit.

**A status bar worth looking at.** [SketchyBar](https://github.com/FelixKratz/SketchyBar) replaces
the menu bar with your workspaces, now playing, volume, Wi-Fi, CPU, battery and weather. Need the
whole screen? `Alt + Shift + Space` hides it and your windows grow to fill the space.

**A calmer macOS.** On macOS 26 and later, UnMacOS switches off Apple Intelligence and turns Liquid
Glass down as far as it goes, for a desktop as close to Sequoia as possible.

**Rebuild any Mac in minutes.** The same command sets up a new Mac or restores one you've wiped.
`unmacos-doctor` checks every piece and tells you what to fix, and `chezmoi update` keeps you current.

## Get started

On a Mac with Apple silicon, run:

```sh
bash -c "$(curl -fsSL https://raw.githubusercontent.com/shrujancheruku/unmacos/main/install.sh)"
```

It asks for your password once, installs Homebrew and everything else, then asks three questions:

| Question | What it's for |
|---|---|
| Git name and email | Your `~/.gitconfig`. Stays on your Mac |
| Use 1Password? | Reads secrets (the Spotify player's `client_id`) from 1Password |
| Personal apps? | My own extra apps from `Brewfile.personal`. Say no unless you're me |

Then a few clicks macOS won't let a script make for you:

1. **System Settings → Privacy & Security → Accessibility**: turn on `rift` and `clipse`, then run
   `rift service restart`.
2. **Log out and back in.**
3. The first menu you open makes Ghostty ask to run a command: allow it.
4. On macOS 26 and later, approve **UnMacOS: no Apple Intelligence** in
   *System Settings → General → Device Management*.
5. Run `unmacos-doctor`. When it says *All good*, you're done.

## Learn the keys

`Alt` does what `SUPER` does in Omarchy, so Omarchy muscle memory works here: Omarchy's `ALT` is
`Ctrl`, and its `CTRL` is `Cmd`. Forgot one? `Alt + Ctrl + K` searches them all.

**Launch**

| Keys | Opens |
|---|---|
| `Alt + Enter` | Terminal |
| `Alt + Ctrl + Enter` | Terminal in the tmux session "Work" |
| `Alt + Shift + B` | Browser (Firefox). Add `Ctrl` for a private window |
| `Alt + Shift + M` / `F` / `N` | Music / files / Neovim |
| `Alt + Shift + G` / `D` / `A` | lazygit / lazydocker / Claude |
| `Alt + Cmd + T` | btop |
| `Alt + Shift + /` | 1Password |

**Menus**

| Keys | Menu |
|---|---|
| `Alt + Space` | Apps |
| `Alt + Ctrl + Space` | Everything UnMacOS can do |
| `Alt + Ctrl + V` / `Alt + Ctrl + .` | Clipboard history / emoji |
| `Alt + Ctrl + W` | Jump to any window |
| `Alt + Cmd + A` / `B` / `W` | Sound output / Bluetooth / Wi-Fi |
| `Alt + Ctrl + Shift + Space` | Themes |
| `Alt + Escape` | Lock, sleep, restart, shut down |

**Windows and workspaces**

| Keys | Does |
|---|---|
| `Alt + H J K L` | Focus left, down, up, right |
| `Alt + Shift + H J K L` | Move the window |
| `Alt + 1–5` | Go to a workspace |
| `Alt + Shift + 1–5` | Take the window there (`Ctrl` instead of `Shift` sends it and stays) |
| `Alt + Tab` / `Alt + Shift + Tab` / `Alt + Ctrl + Tab` | Next / previous / last workspace |
| `Alt + W` | Close |
| `Alt + T` | Float or tile |
| `Alt + F` / `Alt + Cmd + F` | Fullscreen / fullscreen inside the gaps |
| `Alt + G` / `Alt + Ctrl + G` | Stack / unstack |
| `Alt + /` | Flip the split |
| `Alt + −` / `Alt + =` | Narrower / wider (`Shift` for height, `Alt + R` for resize mode) |
| `Alt + Ctrl + B` / `T` / `M` / `S` | Layout: split, traditional, main-and-side, scrolling |
| `Alt + Z` | Tiling on or off for this Space |

**Everything else**

| Keys | Does |
|---|---|
| `Alt + Shift + Space` | Hide or show the bar |
| `Alt + Shift + S` | Screenshot to the clipboard |
| `Alt + Cmd + N` / `L` | Night light / lock |
| `Alt + Shift + R` | Reload Rift |

## Make it yours

**Themes.** Each theme is a single `colors.toml` in `~/.local/share/unmacos/themes/<name>/`, in
Omarchy's format, so any Omarchy theme drops straight in. Copy one, change the colours, and pick it
from the menu or run `unmacos-theme-render <name>`. A theme can also ship its own app config (say, a
`ghostty.conf`) to replace the generated one.

**Animations.** Windows glide into place. Prefer them to snap? Run
`rift-cli execute config set-animate false`.

**Gaps.** 4px everywhere you can see, adjusted for the window borders and for the notch on
MacBooks. Change `UNMACOS_GAP` in `unmacos-toggle-bar` and the gaps in `dot_config/rift/config.toml`.

**Your own bits.** Put machine-only shell config in `~/.zshrc.local`. Swap the browser in
`dot_config/rift/config.toml`, the Wi-Fi interface in `dot_config/sketchybar/items/widgets/wifi.lua`,
and your extra apps in `Brewfile.personal`.

**Keep Apple Intelligence or Liquid Glass.** Run `UNMACOS_KEEP_AI=1 chezmoi apply` or
`UNMACOS_KEEP_GLASS=1 chezmoi apply`. The header of
`home/.chezmoiscripts/run_onchange_after_40-no-ai-no-glass.sh.tmpl` lists exactly what changes and
how to undo it.

## Under the hood

UnMacOS is a [chezmoi](https://www.chezmoi.io/) repo. `install.sh` installs Homebrew and chezmoi;
chezmoi writes the configs and runs the setup scripts.

```
install.sh                 bootstrap: Homebrew, chezmoi
Brewfile                   the desktop and terminal tools
Brewfile.personal          optional extra apps
home/                      everything chezmoi puts in your home folder
  .chezmoiscripts/         packages, SbarLua, macOS settings, no-AI/no-glass, theme, services, clipse
  dot_config/rift/         tiling and keybindings
  dot_config/sketchybar/   the bar (Lua)
  dot_config/television/   the menus
  dot_local/bin/           unmacos-* commands: menu, popup, paste, tui, theme-render, theme-preview, doctor
  dot_local/share/unmacos/ themes, theme templates, emoji list, configuration profile
```

Themes render from `templates/*.tpl` into `~/.local/state/unmacos/theme/`, and every app reads its
colours from there. That's why one switch reaches them all.

## Credits

UnMacOS stands on the shoulders of:

- [Omarchy](https://github.com/basecamp/omarchy): the workflow, keybindings, menus, theme format and 22 of the themes (MIT, see `home/dot_local/share/unmacos/licenses/omarchy.txt`)
- [Rift](https://github.com/acsandmann/rift): the window manager
- [FelixKratz](https://github.com/FelixKratz): SketchyBar, SbarLua, JankyBorders and the dotfiles this bar started from
- [television](https://github.com/alexpasmantier/television), [clipse](https://github.com/savedra1/clipse), [spotify_player](https://github.com/aome510/spotify-player), [nnn](https://github.com/jarun/nnn), [Ghostty](https://ghostty.org)
- [sketchybar-app-font](https://github.com/kvndrsslr/sketchybar-app-font), [Tokyo Night](https://github.com/folke/tokyonight.nvim), and [Unicode's emoji data](https://www.unicode.org/license.txt)

## License

[GPL-3.0](LICENSE)
