#!/bin/bash
# UnMacOS: SbarLua (SketchyBar's Lua API) into ~/.local/share/sketchybar_lua
set -euo pipefail
eval "$(/opt/homebrew/bin/brew shellenv)"
[[ -f "$HOME/.local/share/sketchybar_lua/sketchybar.so" ]] && exit 0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
git clone --depth 1 https://github.com/FelixKratz/SbarLua.git "$tmp/SbarLua"
(cd "$tmp/SbarLua" && make install)
