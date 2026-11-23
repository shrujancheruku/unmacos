#!/bin/bash
# UnMacOS: Firefox follows the UnMacOS theme through Pywalfox.
#   - pywalfox (uv tool) + its native messaging host, so the extension can read
#     the colors unmacos-theme-render writes to ~/.cache/wal/colors.json
#   - a Firefox policy that installs the Pywalfox and Dark Reader extensions
#     (no "Add" click); Dark Reader recolors pages from the rendered darkreader.json
# Opt out: UNMACOS_KEEP_FIREFOX=1 chezmoi apply
# Undo:    uv tool uninstall pywalfox,
#          rm ~/Library/Application\ Support/Mozilla/NativeMessagingHosts/pywalfox.json,
#          defaults delete org.mozilla.firefox ExtensionSettings,
#          then remove Pywalfox and Dark Reader in Firefox > Add-ons
set -euo pipefail
[[ "${UNMACOS_KEEP_FIREFOX:-}" == 1 ]] && exit 0
eval "$(/opt/homebrew/bin/brew shellenv)"

echo "==> Firefox theme (Pywalfox)"
uv tool install --quiet pywalfox
# macOS 27 blocks the Firefox-launched daemon from reading Firefox's
# profiles.ini, so hand it a copy outside the Firefox folder that points at the
# profile Firefox actually uses.
ff="$HOME/Library/Application Support/Firefox"
pf="$HOME/.local/state/unmacos/firefox"
profile="$(awk -F= '/^\[Install/ {i=1} i && $1 == "Default" {print $2; exit}' "$ff/profiles.ini" 2>/dev/null || true)"
args=()
if [[ -n "$profile" ]]; then
  mkdir -p "$pf"
  printf '[Profile0]\nName=unmacos\nIsRelative=0\nPath=%s\n' "$ff/$profile" > "$pf/profiles.ini"
  args=(--profile-path "$pf")
else
  echo "    No Firefox profile yet: open Firefox once, then run chezmoi apply again"
fi
"$HOME/.local/bin/pywalfox" install --executable "$HOME/.local/share/unmacos/pywalfox-host" "${args[@]}" >/dev/null

defaults write org.mozilla.firefox EnterprisePoliciesEnabled -bool true
defaults write org.mozilla.firefox ExtensionSettings -dict-add pywalfox@frewacom.org \
  '<dict><key>installation_mode</key><string>normal_installed</string><key>install_url</key><string>https://addons.mozilla.org/firefox/downloads/latest/pywalfox/latest.xpi</string></dict>'
# Dark Reader recolors web pages; unmacos-theme-render writes darkreader.json to import
defaults write org.mozilla.firefox ExtensionSettings -dict-add addon@darkreader.org \
  '<dict><key>installation_mode</key><string>normal_installed</string><key>install_url</key><string>https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest.xpi</string></dict>'

# Colors for the current theme (the renderer links them on every theme switch)
"$HOME/.local/bin/unmacos-theme-render" >/dev/null
# New tab wallpaper = desktop wallpaper (unmacos-wallpaper keeps it in step)
"$HOME/.local/bin/unmacos-firefox-wallpaper" >/dev/null 2>&1 || true
echo "    Restart Firefox, then Pywalfox icon > Fetch Pywal colors (once); theme switches then apply live."
