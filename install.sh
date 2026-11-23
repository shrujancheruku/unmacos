#!/usr/bin/env bash
# UnMacOS installer: run on a fresh Mac.
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/shrujancheruku/unmacos/main/install.sh)"
#
# 1. Homebrew (+ Xcode Command Line Tools)  2. unmacos-setup asks what you want
# 3. chezmoi init --apply. Reuse answers from another Mac: UNMACOS_SETUP=setup.toml
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

say "chezmoi and gum"
for f in chezmoi gum; do command -v "$f" >/dev/null || brew install "$f"; done

say "Get UnMacOS ($REPO@$BRANCH)"
SRC="$HOME/.local/share/chezmoi"
[[ -d "$SRC/.git" ]] || git clone --branch "$BRANCH" "https://github.com/$REPO.git" "$SRC"

# Your choices: optional apps, what to leave alone, theme... Saved to
# ~/.config/unmacos/setup.toml. UNMACOS_SETUP=<file> reuses one from another Mac.
say "Setup"
if [[ -n "${UNMACOS_SETUP:-}" ]]; then
  bash "$SRC/home/dot_local/bin/executable_unmacos-setup" --import "$UNMACOS_SETUP" --no-apply
else
  bash "$SRC/home/dot_local/bin/executable_unmacos-setup" --no-apply
fi

say "Apply UnMacOS"
chezmoi init --apply

say "Done"
"$HOME/.local/bin/unmacos-doctor" || true
echo
"$HOME/.local/bin/unmacos-setup" --checklist || true
