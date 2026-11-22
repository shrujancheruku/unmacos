#!/usr/bin/env bash
# Migrate from AeroSpace to Rift.
# Run after the macOS upgrade: ~/.config/sketchybar/scripts/migrate-to-rift.sh
# Re-runnable; each step checks before acting.
set -euo pipefail

REPO="$HOME/.config/sketchybar"
RIFT_SRC="$REPO/rift/config.toml"
RIFT_DST="$HOME/.config/rift/config.toml"
BREW=/opt/homebrew/bin/brew

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$1"; }
warn() { printf '\033[1;33m!! %s\033[0m\n' "$1"; }
pause() { read -r -p "$1 [Enter to continue] " _; }

step "1/7 Pre-flight"
sw_vers
[[ -f "$RIFT_SRC" ]] || { echo "Missing $RIFT_SRC"; exit 1; }
if [[ "$(defaults read com.apple.spaces spans-displays 2>/dev/null || echo 0)" == "1" ]]; then
  warn "Turn ON: System Settings > Desktop & Dock > Mission Control > 'Displays have separate Spaces' (needs logout)."
  pause "Done (or handling it later)?"
fi

step "2/7 Stop AeroSpace"
if pgrep -xq AeroSpace; then
  osascript -e 'quit app "AeroSpace"' || pkill -x AeroSpace || true
fi
# Stop it from launching at login (start-at-login = true in aerospace.toml)
AERO_CFG="$HOME/.config/aerospace/aerospace.toml"
if [[ -f "$AERO_CFG" ]] && grep -q '^start-at-login = true' "$AERO_CFG"; then
  sed -i '' 's/^start-at-login = true/start-at-login = false/' "$AERO_CFG"
  echo "Set start-at-login = false in $AERO_CFG"
fi
osascript -e 'tell application "System Events" to delete (every login item whose name is "AeroSpace")' 2>/dev/null || true

step "3/7 Install Rift"
if ! command -v rift >/dev/null && [[ ! -x /opt/homebrew/bin/rift ]]; then
  "$BREW" install acsandmann/tap/rift
fi
rift --version 2>/dev/null || true

step "4/7 Link Rift config"
mkdir -p "$(dirname "$RIFT_DST")"
if [[ -e "$RIFT_DST" && ! -L "$RIFT_DST" ]]; then
  mv "$RIFT_DST" "$RIFT_DST.bak.$(date +%Y%m%d%H%M%S)"
fi
ln -sfn "$RIFT_SRC" "$RIFT_DST"
ls -l "$RIFT_DST"

step "5/7 Start Rift service"
rift service install || true
rift service start || true
echo
warn "Grant Accessibility to rift: System Settings > Privacy & Security > Accessibility."
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility" || true
pause "Granted?"
rift service restart

step "6/7 Restart SketchyBar (auto-switches to items/rift_workspaces.lua)"
"$BREW" services restart sketchybar
sleep 2

step "7/7 Verify"
ok=1
if RIFT_CLI_PRETTY=1 rift-cli query workspaces >/tmp/rift-workspaces.json 2>&1; then
  head -c 1500 /tmp/rift-workspaces.json; echo
  grep -q '"name": "1"' /tmp/rift-workspaces.json || { warn "Workspace names aren't 1..5 — config not loaded?"; ok=0; }
else
  warn "rift-cli query failed:"; cat /tmp/rift-workspaces.json; ok=0
fi
echo "Subscriptions:"; rift-cli subscribe list-cli || { warn "No CLI subscriptions"; ok=0; }
sketchybar --query rws.1 >/dev/null 2>&1 && echo "SketchyBar: rift workspace items present" \
  || { warn "SketchyBar still on AeroSpace items (rws.1 missing)"; ok=0; }

echo
if [[ $ok == 1 ]]; then
  echo "Migration done. Try Alt+Enter, Alt+1..5, Alt+Slash."
  echo "Once happy: $BREW uninstall --cask aerospace   (then delete items/aerospace_workspaces.lua)"
else
  warn "Some checks failed — see above. Logs: rift service logs / ~/Library/Logs."
fi
