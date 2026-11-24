#!/usr/bin/env bats
# The Look renderer: unmacos-look render <out_dir> renders every Look template with chezmoi,
# from the Theme's colours and the Look Settings in the Answers.

load test_helper

LOOK="$REPO_ROOT/home/dot_local/bin/executable_unmacos-look"
SHARE="$REPO_ROOT/home/dot_local/share/unmacos"

setup() {
  unmacos_temp_home
  unmacos_stub_op
  unmacos_write_answers
  # chezmoi on a Mac finds its source in ~/.local/share/chezmoi; point that at this checkout
  mkdir -p "$HOME/.local/share"
  ln -s "$REPO_ROOT" "$HOME/.local/share/chezmoi"
  unmacos_chezmoi_init
  export UNMACOS_SHARE="$SHARE"
  export UNMACOS_STATE="$HOME/.local/state/unmacos"
  export UNMACOS_NO_RELOAD=1
  mkdir -p "$UNMACOS_STATE"
}

# use_theme <name>: make <name> the current Theme, as a menu pick does
use_theme() {
  echo "$1" > "$UNMACOS_STATE/theme.name"
}

# Golden output under tests/golden/look/<theme>/. To change it on purpose, regenerate with
#   UNMACOS_UPDATE_GOLDEN=1 bats tests/look.bats
# and say why in the commit message.
golden() {
  local theme="$1" out="$BATS_TEST_TMPDIR/out"
  use_theme "$theme"
  run "$LOOK" render "$out"
  echo "$output"
  [ "$status" -eq 0 ]
  if [[ -n "${UNMACOS_UPDATE_GOLDEN:-}" ]]; then
    rm -rf "${REPO_ROOT:?}/tests/golden/look/$theme"
    cp -R "$out" "$REPO_ROOT/tests/golden/look/$theme"
  fi
  run diff -ru "$REPO_ROOT/tests/golden/look/$theme" "$out"
  echo "$output"
  [ "$status" -eq 0 ]
}

@test "a dark Theme renders byte for byte to the golden output" {
  golden nord
}

@test "a light Theme renders byte for byte to the golden output" {
  golden catppuccin-latte
}

@test "every shipped Theme renders all 14 templates with nothing left unrendered" {
  local theme out n
  for theme in $(cd "$SHARE/themes" && ls); do
    out="$BATS_TEST_TMPDIR/out-$theme"
    use_theme "$theme"
    "$LOOK" render "$out"
    n=0
    for tpl in "$SHARE"/templates/*.tpl; do
      [ -s "$out/$(basename "$tpl" .tpl)" ] || { echo "$theme: $(basename "$tpl" .tpl) missing"; return 1; }
      n=$((n + 1))
    done
    [ "$n" -eq 14 ]
    if grep -l -e '{{' -e '<no value>' "$out"/* | grep -v '/colors.toml$'; then
      echo "$theme: unrendered placeholders"; return 1
    fi
  done
}

@test "a Theme's own file replaces the rendered template" {
  # tokyo-night ships its own ghostty.conf
  use_theme tokyo-night
  "$LOOK" render "$BATS_TEST_TMPDIR/out"
  cmp "$SHARE/themes/tokyo-night/ghostty.conf" "$BATS_TEST_TMPDIR/out/ghostty.conf"
  # and a template it doesn't override is still rendered
  grep -q '0xff7aa2f7' "$BATS_TEST_TMPDIR/out/borders.sh"
}

@test "a template reads the Look Settings from the Answers" {
  mkdir -p "$BATS_TEST_TMPDIR/share"
  cp -R "$SHARE/themes" "$BATS_TEST_TMPDIR/share/themes"
  mkdir "$BATS_TEST_TMPDIR/share/templates"
  echo 'radius={{ .look.corner_radius }} accent={{ .rgb.accent }} dark={{ .theme.dark }}' \
    > "$BATS_TEST_TMPDIR/share/templates/probe.tpl"
  printf '[look]\ncorner_radius = 13\n' >> "$HOME/.config/unmacos/setup.toml"
  unmacos_chezmoi_init
  use_theme nord
  UNMACOS_SHARE="$BATS_TEST_TMPDIR/share" "$LOOK" render "$BATS_TEST_TMPDIR/out"
  # nord accent = #81a1c1
  [ "$(cat "$BATS_TEST_TMPDIR/out/probe")" = "radius=13 accent=129,161,193 dark=true" ]
}

@test "with no Theme picked yet, the Answers' Theme is used" {
  sed -i '' 's/^theme = .*/theme = "catppuccin-latte"/' "$HOME/.config/unmacos/setup.toml"
  grep -q 'theme = "catppuccin-latte"' "$HOME/.config/unmacos/setup.toml"
  unmacos_chezmoi_init
  "$LOOK" render "$BATS_TEST_TMPDIR/out"
  diff -r "$REPO_ROOT/tests/golden/look/catppuccin-latte" "$BATS_TEST_TMPDIR/out"
}

@test "an unknown Theme fails and leaves the old render in place" {
  use_theme nord
  "$LOOK" render "$BATS_TEST_TMPDIR/out"
  use_theme no-such-theme
  run "$LOOK" render "$BATS_TEST_TMPDIR/out"
  [ "$status" -ne 0 ]
  [[ "$output" == *"no theme 'no-such-theme'"* ]]
  diff -r "$REPO_ROOT/tests/golden/look/nord" "$BATS_TEST_TMPDIR/out"
}

# The commands as installed side by side in ~/.local/bin
install_bin() {
  mkdir -p "$HOME/.local/bin"
  ln -sf "$LOOK" "$HOME/.local/bin/unmacos-look"
  ln -sf "$REPO_ROOT/home/dot_local/bin/executable_unmacos-theme-render" "$HOME/.local/bin/unmacos-theme-render"
  THEME_RENDER="$HOME/.local/bin/unmacos-theme-render"
}

@test "unmacos-theme-render <theme> sets the Theme and renders it to the state dir" {
  install_bin
  run "$THEME_RENDER" catppuccin-latte
  echo "$output"
  [ "$status" -eq 0 ]
  [ "$(cat "$UNMACOS_STATE/theme.name")" = "catppuccin-latte" ]
  diff -r "$REPO_ROOT/tests/golden/look/catppuccin-latte" "$UNMACOS_STATE/theme"
  # Firefox's Pywalfox reads the light layout through pywal's colors file
  [ "$(readlink "$XDG_CACHE_HOME/wal/colors.json")" = "$UNMACOS_STATE/theme/pywal-colors-light.json" ]
}

@test "unmacos-theme-render with an unknown Theme changes nothing" {
  install_bin
  "$THEME_RENDER" nord
  run "$THEME_RENDER" no-such-theme
  [ "$status" -ne 0 ]
  [ "$(cat "$UNMACOS_STATE/theme.name")" = "nord" ]
  diff -r "$REPO_ROOT/tests/golden/look/nord" "$UNMACOS_STATE/theme"
}

@test "unmacos-theme-render --list lists the shipped Themes" {
  install_bin
  run "$THEME_RENDER" --list
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq "$(cd "$SHARE/themes" && ls | wc -l)" ]
  [[ "$output" == *nord* ]]
}

@test "unmacos-theme-render reloads running apps after a switch" {
  install_bin
  # Stub the apps: only the bar is "running", and it logs what it's told
  local stubs="$BATS_TEST_TMPDIR/stubs" log="$BATS_TEST_TMPDIR/reload.log"
  printf '#!/bin/sh\n[ "$2" = sketchybar ]\n' > "$stubs/pgrep"
  printf '#!/bin/sh\necho "sketchybar $*" >> %s\n' "$log" > "$stubs/sketchybar"
  printf '#!/bin/sh\necho "osascript $*" >> %s\n' "$log" > "$stubs/osascript"
  for c in ps pkill spicetify; do printf '#!/bin/sh\nexit 0\n' > "$stubs/$c"; done
  chmod +x "$stubs"/*
  unset UNMACOS_NO_RELOAD
  run "$THEME_RENDER" catppuccin-latte
  [ "$status" -eq 0 ]
  cat "$log"
  grep -qx 'sketchybar --reload' "$log"
  grep -q 'set dark mode to false' "$log"
}
