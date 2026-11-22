#!/bin/bash
# UnMacOS: clipse clipboard history (not in Homebrew) + a launchd listener
set -euo pipefail
eval "$(/opt/homebrew/bin/brew shellenv)"
export GOBIN="$HOME/.local/bin"
[[ -x "$GOBIN/clipse" ]] || go install github.com/savedra1/clipse@v1.2.1
launchctl bootout "gui/$(id -u)" "$HOME/Library/LaunchAgents/io.github.unmacos.clipse.plist" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$HOME/Library/LaunchAgents/io.github.unmacos.clipse.plist"
