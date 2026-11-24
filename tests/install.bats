#!/usr/bin/env bats
# install.sh on a fresh Mac, with nothing real behind it: sudo, uname, brew, gum and
# `chezmoi init --apply` are stubs (no network, no sudo, no Homebrew). The wizard, unmacos-settings
# and chezmoi's templates are the real ones, on a copy of this checkout.

load test_helper

setup() {
  unmacos_temp_home
  export GIT_CONFIG_GLOBAL="$BATS_TEST_TMPDIR/no-gitconfig"
  STUBS="$BATS_TEST_TMPDIR/stubs"; mkdir -p "$STUBS"
  export GUM_LOG="$BATS_TEST_TMPDIR/gum.log" CHEZMOI_LOG="$BATS_TEST_TMPDIR/chezmoi.log"
  : > "$GUM_LOG"; : > "$CHEZMOI_LOG"

  # the source install.sh finds: a copy of this checkout that already looks cloned
  SRC="$HOME/.local/share/chezmoi"
  mkdir -p "$SRC"
  (cd "$REPO_ROOT" && git ls-files -co --exclude-standard | tar -cf - -T -) | tar -xf - -C "$SRC"
  mkdir -p "$SRC/.git"

  printf '#!/bin/sh\n[ "$1" = "-m" ] && echo arm64 || echo Darwin\n' > "$STUBS/uname"
  printf '#!/bin/sh\nexit 0\n' > "$STUBS/sudo"
  printf '#!/bin/sh\nexit 0\n' > "$STUBS/brew"
  printf '#!/bin/sh\necho "brew/curl/git must not run: $0 $*" >&2; exit 97\n' > "$STUBS/git"
  # gum: logs, prints $GUM_REPLY
  printf '#!/bin/sh\necho "gum $*" >> "$GUM_LOG"\necho "${GUM_REPLY:-}"\n' > "$STUBS/gum"
  # chezmoi: init is logged and not run; everything else is the real one
  real="$(command -v chezmoi)"
  printf '#!/bin/sh\nif [ "$1" = init ]; then echo "$*" >> "$CHEZMOI_LOG"; exit 0; fi\nexec %s "$@"\n' "$real" > "$STUBS/chezmoi"
  chmod +x "$STUBS"/*
  export PATH="$STUBS:$PATH" UNMACOS_BREW="$STUBS/brew" UNMACOS_CHEZMOI="$STUBS/chezmoi"
}

install() { bash "$REPO_ROOT/install.sh" "$@"; }

@test "with no terminal it installs with the defaults and never asks" {
  run install < /dev/null
  echo "$output"
  [ "$status" -eq 0 ]
  [ ! -s "$GUM_LOG" ]
  [ -f "$HOME/.config/unmacos/setup.toml" ]
  grep -q 'init --apply' "$CHEZMOI_LOG"
}

@test "with no terminal it still takes name and email from git config --global" {
  printf '[user]\n\tname = Existing Name\n\temail = existing@example.invalid\n' > "$GIT_CONFIG_GLOBAL"
  run install < /dev/null
  echo "$output"
  [ "$status" -eq 0 ]
  grep -q 'name = "Existing Name"' "$HOME/.config/unmacos/setup.toml"
  grep -q 'email = "existing@example.invalid"' "$HOME/.config/unmacos/setup.toml"
}

@test "with no terminal and no git config the saved Answers have no name or email, and nothing is asked" {
  run install < /dev/null
  [ "$status" -eq 0 ]
  run grep -q '^name = ' "$HOME/.config/unmacos/setup.toml"
  [ "$status" -ne 0 ]
  # chezmoi takes every prompt's default, so it cannot stop to ask for the git name
  grep -qw -- '--promptDefaults' "$CHEZMOI_LOG"
}

@test "UNMACOS_SETUP=<file> uses that file and never asks, even with a UI" {
  printf '[look]\ntheme = "nord"\n' > "$BATS_TEST_TMPDIR/in.toml"
  UNMACOS_SETUP="$BATS_TEST_TMPDIR/in.toml" UNMACOS_SETUP_UI=1 run install
  echo "$output"
  [ "$status" -eq 0 ]
  [ ! -s "$GUM_LOG" ]
  grep -q 'theme = "nord"' "$HOME/.config/unmacos/setup.toml"
}

@test "with a terminal the one choice is Install with defaults or Customise" {
  GUM_REPLY="Install with defaults" UNMACOS_SETUP_UI=1 run install
  echo "$output"
  [ "$status" -eq 0 ]
  # exactly one gum call: the choice
  [ "$(wc -l < "$GUM_LOG" | tr -d ' ')" -eq 1 ]
  grep -q 'gum choose .*Install with defaults.*Customise' "$GUM_LOG"
  [ -f "$HOME/.config/unmacos/setup.toml" ]
}

@test "choosing Customise starts the wizard's questions" {
  # a wizard that only records how it was called
  printf '#!/bin/sh\necho "wizard $*" >> "$CHEZMOI_LOG"\n' > "$SRC/home/dot_local/bin/executable_unmacos-setup"
  GUM_REPLY="Customise" UNMACOS_SETUP_UI=1 run install
  [ "$status" -eq 0 ]
  [ "$(grep '^wizard' "$CHEZMOI_LOG")" = "wizard " ]
}

@test "choosing Install with defaults runs the wizard with --yes" {
  printf '#!/bin/sh\necho "wizard $*" >> "$CHEZMOI_LOG"\n' > "$SRC/home/dot_local/bin/executable_unmacos-setup"
  GUM_REPLY="Install with defaults" UNMACOS_SETUP_UI=1 run install
  [ "$status" -eq 0 ]
  [ "$(grep '^wizard' "$CHEZMOI_LOG")" = "wizard --yes" ]
}

# the applied Tune phase, as a recorder
tune_recorder() {
  mkdir -p "$HOME/.local/bin"
  printf '#!/bin/sh\necho "tune" >> "$CHEZMOI_LOG"\n' > "$HOME/.local/bin/unmacos-tune"
  chmod +x "$HOME/.local/bin/unmacos-tune"
}

@test "with a terminal the installer offers the Tune phase once the desktop is up, and runs it on yes" {
  tune_recorder
  GUM_REPLY="Install with defaults" UNMACOS_SETUP_UI=1 run install
  echo "$output"
  [ "$status" -eq 0 ]
  grep -q 'gum confirm Tune the look' "$GUM_LOG"
  grep -qx 'tune' "$CHEZMOI_LOG"
}

@test "the Tune offer is never made without a terminal, or for an imported Answers file" {
  tune_recorder
  run install < /dev/null
  [ "$status" -eq 0 ]
  printf '[look]\ntheme = "nord"\n' > "$BATS_TEST_TMPDIR/in.toml"
  UNMACOS_SETUP="$BATS_TEST_TMPDIR/in.toml" UNMACOS_SETUP_UI=1 run install
  [ "$status" -eq 0 ]
  ! grep -q 'Tune the look' "$GUM_LOG"
  ! grep -qx 'tune' "$CHEZMOI_LOG"
}

@test "install.sh is bash 3.2 clean: it runs under /bin/bash" {
  run /bin/bash -n "$REPO_ROOT/install.sh"
  [ "$status" -eq 0 ]
}
