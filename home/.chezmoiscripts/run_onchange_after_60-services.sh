#!/bin/bash
# UnMacOS: start the desktop. Retires AeroSpace if present.
set -euo pipefail
eval "$(/opt/homebrew/bin/brew shellenv)"

if pgrep -xq AeroSpace || [[ -d /Applications/AeroSpace.app ]]; then
  echo "==> Retiring AeroSpace"
  osascript -e 'tell application "AeroSpace" to quit' >/dev/null 2>&1 || pkill -x AeroSpace || true
  osascript -e 'tell application "System Events" to delete login item "AeroSpace"' >/dev/null 2>&1 || true
  echo "    Uninstall later with: brew uninstall --cask aerospace"
fi

echo "==> SketchyBar"
brew services restart sketchybar >/dev/null

echo "==> Rift (grant Accessibility when asked)"
rift service install >/dev/null 2>&1 || true
rift service restart >/dev/null 2>&1 || rift service start || true
# Rift's run_on_start launches borders; start it now too in case Rift is waiting for permission
pgrep -xq borders || ("$HOME/.config/borders/bordersrc" >/dev/null 2>&1 &)
