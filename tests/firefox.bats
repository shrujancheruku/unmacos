#!/usr/bin/env bats
# The Firefox script (Pywalfox) on a Mac where Firefox has never been opened: no profile yet.

load test_helper

setup() {
  unmacos_temp_home
  unmacos_stub_op
  unmacos_write_answers
  unmacos_chezmoi_init
}

# stub DIR NAME: a fake command NAME in DIR that logs how it was called
stub() {
  local dir="$1" name="$2"
  mkdir -p "$dir"
  printf '#!/bin/sh\necho "%s $*" >> "%s"\n' "$name" "$BATS_TEST_TMPDIR/calls" > "$dir/$name"
  chmod +x "$dir/$name"
}

# firefox_script: the rendered script, with Homebrew's PATH left out so the stubs are the
# tools it runs (uv, defaults, pywalfox and the unmacos helpers)
firefox_script() {
  local out="$BATS_TEST_TMPDIR/80-firefox.sh"
  # shellcheck disable=SC2016 # the brew line is matched as text, not expanded
  unmacos_chezmoi execute-template \
    < "$REPO_ROOT/home/.chezmoiscripts/run_onchange_after_80-firefox.sh.tmpl" \
    | sed 's|^eval "$(/opt/homebrew/bin/brew shellenv)"$|: # brew shellenv: stubbed|' > "$out"
  grep -q '^: # brew shellenv: stubbed$' "$out"
  printf '%s' "$out"
}

@test "with no Firefox profile the script installs Pywalfox without a profile path and succeeds" {
  local script
  script="$(firefox_script)"
  stub "$BATS_TEST_TMPDIR/bin" uv
  stub "$BATS_TEST_TMPDIR/bin" defaults
  stub "$HOME/.local/bin" pywalfox
  stub "$HOME/.local/bin" unmacos-theme-render
  stub "$HOME/.local/bin" unmacos-firefox-wallpaper
  [ ! -e "$HOME/Library/Application Support/Firefox/profiles.ini" ]
  # /bin/bash: the script runs on macOS's own bash 3.2
  PATH="$BATS_TEST_TMPDIR/bin:$PATH" run /bin/bash "$script"
  echo "$output"
  [ "$status" -eq 0 ]
  [[ "$output" == *"No Firefox profile yet"* ]]
  run cat "$BATS_TEST_TMPDIR/calls"
  echo "$output"
  [[ "$output" == *"pywalfox install --executable $HOME/.local/share/unmacos/pywalfox-host"* ]]
  [[ "$output" != *"--profile-path"* ]]
  [[ "$output" == *"unmacos-theme-render"* ]]
}
