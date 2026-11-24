#!/usr/bin/env bash
# UnMacOS installer: run on a fresh Mac.
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/shrujancheruku/unmacos/main/install.sh)"
#
# 1. Homebrew (+ Xcode Command Line Tools)  2. one choice: "Install with defaults" (no
# questions) or "Customise" (unmacos-setup asks)  3. unmacos-setup applies it (chezmoi init
# --apply). chezmoi then runs the home/run_* scripts: brew bundle, SbarLua, macOS settings,
# theme, services. Re-runnable.
# Never asks anything without a terminal: it takes the defaults (or the saved answers).
# Reuse answers from another Mac: UNMACOS_SETUP=setup.toml (no questions either).
# After the sudo password, "Install with defaults" needs nothing but macOS's Manual steps.
set -euo pipefail

REPO="${UNMACOS_REPO:-shrujancheruku/unmacos}"
BRANCH="${UNMACOS_BRANCH:-main}"
BREW="${UNMACOS_BREW:-/opt/homebrew/bin/brew}"

say() { printf '\n\033[1;34m==> %s\033[0m\n' "$1"; }

[[ "$(uname -s)" == "Darwin" ]] || { echo "UnMacOS only runs on macOS."; exit 1; }
[[ "$(uname -m)" == "arm64" ]] || echo "Warning: only tested on Apple silicon."

say "Administrator password (asked once)"
sudo -v
# Keep sudo cached until this script exits: Homebrew and some casks need it.
while kill -0 "$$" 2>/dev/null; do sudo -n true; sleep 50; done >/dev/null 2>&1 &

say "Homebrew (also installs the Xcode Command Line Tools)"
if [[ ! -x "$BREW" ]]; then
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$("$BREW" shellenv)"

say "chezmoi and gum"
for f in chezmoi gum; do command -v "$f" >/dev/null || brew install "$f"; done

say "Get UnMacOS ($REPO@$BRANCH)"
SRC="$HOME/.local/share/chezmoi"
[[ -d "$SRC/.git" ]] || git clone --branch "$BRANCH" "https://github.com/$REPO.git" "$SRC"

# Your choices: optional apps, what to leave alone, theme... Saved to
# ~/.config/unmacos/setup.toml. UNMACOS_SETUP=<file> reuses one from another Mac.
# The only question install.sh asks is the choice below, and only with a terminal.
# UNMACOS_SETUP_UI=1 asks it without one (the tests script a fake gum).
SETUP_BIN="$SRC/home/dot_local/bin/executable_unmacos-setup"

say "Setup"
if [[ -n "${UNMACOS_SETUP:-}" ]]; then
  bash "$SETUP_BIN" --import "$UNMACOS_SETUP"
elif [[ -n "${UNMACOS_SETUP_UI:-}" || ( -t 0 && -t 1 ) ]]; then
  choice="$(gum choose --header "How do you want to install UnMacOS?" \
    "Install with defaults" "Customise")" || choice=""
  case "$choice" in
    Customise) bash "$SETUP_BIN" ;;
    "Install with defaults") bash "$SETUP_BIN" --yes ;;
    *) echo "Nothing changed."; exit 0 ;;
  esac
else
  echo "No terminal: installing with the defaults (or your saved answers)."
  bash "$SETUP_BIN" --yes
fi

say "Done"
"$HOME/.local/bin/unmacos-doctor" || true

# The desktop is up: offer the Tune phase (Look Settings shown live). Only with a terminal, and
# not for an imported Answers file.
if [[ -z "${UNMACOS_SETUP:-}" && -x "$HOME/.local/bin/unmacos-tune" ]] \
   && [[ -n "${UNMACOS_SETUP_UI:-}" || ( -t 0 && -t 1 ) ]]; then
  if gum confirm "Tune the look on your desktop now?"; then "$HOME/.local/bin/unmacos-tune" || true; fi
fi
