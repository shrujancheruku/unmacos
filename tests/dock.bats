#!/usr/bin/env bats
# Dock autohide and Dock size are Settings; the macOS defaults script renders them.

load test_helper

setup() {
  unmacos_temp_home
  unmacos_stub_op
}

answers() {
  mkdir -p "$HOME/.config/unmacos"
  cat > "$HOME/.config/unmacos/setup.toml"
}

defaults_lines() {
  unmacos_chezmoi execute-template < "$REPO_ROOT/home/.chezmoiscripts/run_onchange_after_30-macos-defaults.sh.tmpl" \
    | grep '^defaults write'
}

@test "defaults reproduce today's script byte for byte (every defaults write line)" {
  unmacos_write_answers
  unmacos_chezmoi_init
  run defaults_lines
  [ "$status" -eq 0 ]
  diff -u "$REPO_ROOT/tests/golden/macos-defaults-today.txt" <(printf '%s\n' "$output")
}

@test "dry-run shows the Dock values from the Answers" {
  answers <<'TOML'
name = "Test User"
email = "test@example.invalid"
use_1password = false
[desktop]
dock_autohide = false
dock_size = 32
TOML
  unmacos_chezmoi_init
  run defaults_lines
  [[ "$output" == *"defaults write com.apple.dock autohide -bool false"* ]]
  [[ "$output" == *"defaults write com.apple.dock tilesize -int 32"* ]]
  # the rest is untouched
  [[ "$output" == *"defaults write com.apple.dock show-recents -bool false"* ]]
}

@test "the rendered script differs (so chezmoi re-runs it) when a Dock value changes" {
  answers <<'TOML'
name = "Test User"
email = "test@example.invalid"
use_1password = false
TOML
  unmacos_chezmoi_init
  run unmacos_chezmoi cat "$(unmacos_chezmoi target-path "$REPO_ROOT/home/.chezmoiscripts/run_onchange_after_30-macos-defaults.sh.tmpl")"
  [ "$status" -eq 0 ]
  before="$output"
  answers <<'TOML'
name = "Test User"
email = "test@example.invalid"
use_1password = false
[desktop]
dock_size = 80
TOML
  unmacos_chezmoi_init
  run unmacos_chezmoi cat "$(unmacos_chezmoi target-path "$REPO_ROOT/home/.chezmoiscripts/run_onchange_after_30-macos-defaults.sh.tmpl")"
  [ "$status" -eq 0 ]
  [ "$output" != "$before" ]
}

@test "Dock Settings are in the schema with label, help and range" {
  run grep -A9 'key = "dock_size"' "$REPO_ROOT/home/.chezmoidata/settings.toml"
  [[ "$output" == *"min = 16"* && "$output" == *"max = 128"* && "$output" == *"default = 64"* ]]
  [[ "$output" == *"label ="* && "$output" == *"help ="* ]]
  run grep -A6 'key = "dock_autohide"' "$REPO_ROOT/home/.chezmoidata/settings.toml"
  [[ "$output" == *"default = true"* && "$output" == *"label ="* && "$output" == *"help ="* ]]
}
