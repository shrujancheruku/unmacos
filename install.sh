#!/usr/bin/env bash
# UnMacOS installer: run on a fresh Mac.
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/shrujancheruku/unmacos/main/install.sh)"
#
# 1. Homebrew (+ Xcode Command Line Tools)  2. chezmoi init --apply
# chezmoi then runs the home/run_* scripts: brew bundle, SbarLua, macOS settings,
# theme, services. Re-runnable.
set -euo pipefail

REPO="${UNMACOS_REPO:-shrujancheruku/unmacos}"
BRANCH="${UNMACOS_BRANCH:-main}"

say() { printf '\n\033[1;34m==> %s\033[0m\n' "$1"; }

[[ "$(uname -s)" == "Darwin" ]] || { echo "UnMacOS only runs on macOS."; exit 1; }
[[ "$(uname -m)" == "arm64" ]] || echo "Warning: only tested on Apple silicon."

say "Administrator password (asked once)"
sudo -v
# Keep sudo cached until this script exits: Homebrew and some casks need it.
while kill -0 "$$" 2>/dev/null; do sudo -n true; sleep 50; done 2>/dev/null &

say "Homebrew (also installs the Xcode Command Line Tools)"
if [[ ! -x /opt/homebrew/bin/brew ]]; then
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"

say "chezmoi"
command -v chezmoi >/dev/null || brew install chezmoi

say "Apply UnMacOS ($REPO@$BRANCH)"
chezmoi init --apply --branch "$BRANCH" "https://github.com/$REPO.git"

say "Done"
"$HOME/.local/bin/unmacos-doctor" || true
cat <<'EOF'

Manual steps macOS doesn't allow scripts to do:
  1. System Settings > Privacy & Security > Accessibility: turn on rift and clipse
     (it asks when it starts), and Ghostty for paste-back. Then: rift service restart
  2. Log out and back in (Spaces and menu bar settings take effect)
  3. spotify_player: run it once to log in to Spotify
  4. 1Password: sign in, then Settings > Developer > "Integrate with 1Password CLI"
  5. On macOS 26+: approve the "UnMacOS: no Apple Intelligence" profile in
     System Settings > General > Device Management (opened for you)
  6. Run unmacos-doctor
EOF
