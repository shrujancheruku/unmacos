#!/usr/bin/env bats
# unmacos-look: the Look renderer. Tested at its command line (render) and through
# unmacos-theme-render, the alias menus call. Reloads are off (UNMACOS_NO_RELOAD=1).
#
# Goldens: tests/golden/look/<theme> is the rendered output of a fixture Theme in
# tests/fixtures/look-themes. Regenerate with UNMACOS_UPDATE_GOLDEN=1 bats tests/look.bats

load test_helper

LOOK="$REPO_ROOT/home/dot_local/bin/executable_unmacos-look"
THEME_RENDER="$REPO_ROOT/home/dot_local/bin/executable_unmacos-theme-render"
SHIPPED_SHARE="$REPO_ROOT/home/dot_local/share/unmacos"

setup() {
  unmacos_temp_home
  unmacos_write_answers
  # unmacos-settings finds the Settings schema through chezmoi's source directory
  mkdir -p "$HOME/.local/share"
  ln -sfn "$REPO_ROOT" "$HOME/.local/share/chezmoi"
  export GIT_CONFIG_GLOBAL="$BATS_TEST_TMPDIR/no-gitconfig"
  export UNMACOS_SETTINGS="$REPO_ROOT/home/dot_local/bin/executable_unmacos-settings"
  export UNMACOS_STATE="$BATS_TEST_TMPDIR/state"
  export UNMACOS_NO_RELOAD=1
  export UNMACOS_SHARE="$SHIPPED_SHARE"
}

look() { bash "$LOOK" "$@"; }

# fixture_share: a share folder with the shipped templates and the fixture Themes
fixture_share() {
  export UNMACOS_SHARE="$BATS_TEST_TMPDIR/share"
  mkdir -p "$UNMACOS_SHARE"
  ln -sfn "$SHIPPED_SHARE/templates" "$UNMACOS_SHARE/templates"
  ln -sfn "$REPO_ROOT/tests/fixtures/look-themes" "$UNMACOS_SHARE/themes"
}

# golden THEME DIR: DIR matches tests/golden/look/THEME byte for byte
golden() {
  local want="$REPO_ROOT/tests/golden/look/$1"
  if [[ "${UNMACOS_UPDATE_GOLDEN:-}" == 1 ]]; then
    rm -rf "$want" && cp -R "$2" "$want"
  fi
  diff -r "$want" "$2"
}

@test "render: a fixed dark Theme renders byte for byte to its golden" {
  fixture_share
  mkdir -p "$UNMACOS_STATE" && echo fixed-dark > "$UNMACOS_STATE/theme.name"
  run look render "$BATS_TEST_TMPDIR/out"
  [ "$status" -eq 0 ]
  golden fixed-dark "$BATS_TEST_TMPDIR/out"
}

@test "render: a fixed light Theme renders byte for byte to its golden" {
  fixture_share
  UNMACOS_THEME=fixed-light run look render "$BATS_TEST_TMPDIR/out"
  [ "$status" -eq 0 ]
  golden fixed-light "$BATS_TEST_TMPDIR/out"
}

@test "render: every shipped Theme renders all 16 templates with no placeholder left" {
  local theme name
  for theme in "$SHIPPED_SHARE"/themes/*/; do
    name="$(basename "$theme")"
    UNMACOS_THEME="$name" run look render "$BATS_TEST_TMPDIR/$name"
    [ "$status" -eq 0 ] || { echo "$name: $output"; false; }
    [ "$(ls "$BATS_TEST_TMPDIR/$name"/*.* | grep -vc -e '/colors.toml$' -e '/theme.name$')" -eq 16 ]
    # colors.toml is the Theme's own file, copied, not rendered
    run grep -rl --exclude=colors.toml '{{' "$BATS_TEST_TMPDIR/$name"
    [ "$status" -eq 1 ] || { echo "$name: placeholders in $output"; false; }
  done
}

@test "render: corner_radius reaches the bar and Spotify's CSS, and follows the Setting" {
  run look render "$BATS_TEST_TMPDIR/default"
  [ "$status" -eq 0 ]
  grep -qx $'\tcorner_radius = 8,' "$BATS_TEST_TMPDIR/default/sketchybar.lua"
  grep -q -- '--border-radius-base: 8px;' "$BATS_TEST_TMPDIR/default/spicetify-user.css"
  grep -q '^  border-radius: 8px;' "$BATS_TEST_TMPDIR/default/spicetify-user.css"
  # changing the Setting and rendering again is all it takes: no chezmoi apply
  printf '[look]\ntheme = "tokyo-night"\ncorner_radius = 3\n' > "$HOME/.config/unmacos/setup.toml"
  run look render "$BATS_TEST_TMPDIR/changed"
  [ "$status" -eq 0 ]
  grep -qx $'\tcorner_radius = 3,' "$BATS_TEST_TMPDIR/changed/sketchybar.lua"
  grep -q -- '--border-radius-base: 3px;' "$BATS_TEST_TMPDIR/changed/spicetify-user.css"
  grep -q '^  border-radius: 3px;' "$BATS_TEST_TMPDIR/changed/spicetify-user.css"
}

@test "render --draft: the Draft Look's corner_radius wins over the saved one" {
  mkdir -p "$UNMACOS_STATE"
  printf '[look]\ncorner_radius = 5\n' > "$UNMACOS_STATE/draft.toml"
  run look render --draft "$BATS_TEST_TMPDIR/draft"
  [ "$status" -eq 0 ]
  grep -qx $'\tcorner_radius = 5,' "$BATS_TEST_TMPDIR/draft/sketchybar.lua"
  grep -q -- '--border-radius-base: 5px;' "$BATS_TEST_TMPDIR/draft/spicetify-user.css"
}

@test "render: a file the Theme ships replaces the rendered template" {
  UNMACOS_THEME=tokyo-night run look render "$BATS_TEST_TMPDIR/out"
  [ "$status" -eq 0 ]
  cmp "$SHIPPED_SHARE/themes/tokyo-night/ghostty.conf" "$BATS_TEST_TMPDIR/out/ghostty.conf"
  # and a template the Theme doesn't ship is still rendered
  grep -q '7aa2f7' "$BATS_TEST_TMPDIR/out/borders.sh"
}

@test "render: the Theme is the live one, else the Answers' look.theme" {
  run look render "$BATS_TEST_TMPDIR/a"
  [ "$status" -eq 0 ]
  [ "$(cat "$BATS_TEST_TMPDIR/a/theme.name")" = tokyo-night ]
  mkdir -p "$UNMACOS_STATE" && echo nord > "$UNMACOS_STATE/theme.name"
  run look render "$BATS_TEST_TMPDIR/b"
  [ "$(cat "$BATS_TEST_TMPDIR/b/theme.name")" = nord ]
}

@test "render: an unknown Theme fails and leaves OUT_DIR alone" {
  mkdir -p "$BATS_TEST_TMPDIR/out" && echo keep > "$BATS_TEST_TMPDIR/out/sentinel"
  UNMACOS_THEME=no-such-theme run look render "$BATS_TEST_TMPDIR/out"
  [ "$status" -ne 0 ]
  [[ "$output" == *"no theme 'no-such-theme'"* ]]
  [ -f "$BATS_TEST_TMPDIR/out/sentinel" ]
}

@test "render --draft: the Draft Look's Theme wins over the saved one" {
  mkdir -p "$UNMACOS_STATE"
  printf '[look]\ntheme = "nord"\n' > "$UNMACOS_STATE/draft.toml"
  run look render --draft "$BATS_TEST_TMPDIR/draft"
  [ "$status" -eq 0 ]
  [ "$(cat "$BATS_TEST_TMPDIR/draft/theme.name")" = nord ]
  # without --draft the Draft Look is ignored
  run look render "$BATS_TEST_TMPDIR/saved"
  [ "$(cat "$BATS_TEST_TMPDIR/saved/theme.name")" = tokyo-night ]
}

@test "unmacos-theme-render THEME still switches the Theme" {
  export UNMACOS_LOOK="$LOOK"
  run bash "$THEME_RENDER" nord
  [ "$status" -eq 0 ]
  [ "$(cat "$UNMACOS_STATE/theme.name")" = nord ]
  [ "$(cat "$UNMACOS_STATE/theme/theme.name")" = nord ]
  local accent
  accent="$(awk -F'"' '/^accent/ {print $2}' "$SHIPPED_SHARE/themes/nord/colors.toml")"
  grep -q "${accent#\#}" "$UNMACOS_STATE/theme/borders.sh"
  # pywal's colors point at the rendered Theme
  [ "$(readlink "$XDG_CACHE_HOME/wal/colors.json")" = "$UNMACOS_STATE/theme/pywal-colors.json" ]
  # and with no Theme given it re-renders the live one
  run bash "$THEME_RENDER"
  [ "$status" -eq 0 ]
  [ "$(cat "$UNMACOS_STATE/theme/theme.name")" = nord ]
}

@test "unmacos-theme-render: an unknown Theme fails and keeps the live one" {
  export UNMACOS_LOOK="$LOOK"
  mkdir -p "$UNMACOS_STATE" && echo nord > "$UNMACOS_STATE/theme.name"
  run bash "$THEME_RENDER" no-such-theme
  [ "$status" -ne 0 ]
  [ "$(cat "$UNMACOS_STATE/theme.name")" = nord ]
}

# --- Draft Look: draft set, save, discard ---

snapshot() { (cd "$1" && find . -type f | sort | xargs shasum) ; }

@test "draft set renders the Draft Look live; discard restores the previous render byte for byte" {
  run look render "$UNMACOS_STATE/theme"
  [ "$status" -eq 0 ]
  snapshot "$UNMACOS_STATE/theme" > "$BATS_TEST_TMPDIR/before"
  run look draft set look.theme=nord
  [ "$status" -eq 0 ]
  [ "$(cat "$UNMACOS_STATE/theme/theme.name")" = nord ]
  [ -f "$UNMACOS_STATE/draft.toml" ]
  run look draft discard
  [ "$status" -eq 0 ]
  [ ! -e "$UNMACOS_STATE/draft.toml" ]
  snapshot "$UNMACOS_STATE/theme" > "$BATS_TEST_TMPDIR/after"
  diff "$BATS_TEST_TMPDIR/before" "$BATS_TEST_TMPDIR/after"
}

@test "draft set rejects an invalid value with the Setting's validation message" {
  run look draft set look.theme=no-such-theme
  [ "$status" -ne 0 ]
  [[ "$output" == *'look.theme: "no-such-theme" is not one of'* ]]
  [ ! -e "$UNMACOS_STATE/draft.toml" ]
}

@test "draft set rejects a Setting outside the Look" {
  run look draft set use_1password=true
  [ "$status" -ne 0 ]
  [ ! -e "$UNMACOS_STATE/draft.toml" ]
}

@test "draft set accumulates drafted keys across calls" {
  run look draft set look.theme=nord
  [ "$status" -eq 0 ]
  run look draft set look.corner_radius=7
  [ "$status" -eq 0 ]
  run grep -c . "$UNMACOS_STATE/draft.toml"
  [ "$output" = 2 ]
  [ "$(cat "$UNMACOS_STATE/theme/theme.name")" = nord ]
}

@test "draft save writes only the drafted keys into the Answers and clears the draft" {
  bash "$UNMACOS_SETTINGS" write "$HOME/.config/unmacos/setup.toml" look.corner_radius=3
  cp "$HOME/.config/unmacos/setup.toml" "$BATS_TEST_TMPDIR/answers-before"
  run look draft set look.theme=nord
  [ "$status" -eq 0 ]
  run look draft save
  [ "$status" -eq 0 ]
  [ ! -e "$UNMACOS_STATE/draft.toml" ]
  [ "$(bash "$UNMACOS_SETTINGS" get look.theme)" = nord ]
  [ "$(bash "$UNMACOS_SETTINGS" get look.corner_radius)" = 3 ]
  # the saved Look is what is rendered live now
  [ "$(cat "$UNMACOS_STATE/theme/theme.name")" = nord ]
  # only the drafted key changed in the Answers: the whole file differs by its theme line
  run diff "$BATS_TEST_TMPDIR/answers-before" "$HOME/.config/unmacos/setup.toml"
  [ "$status" -eq 1 ]
  changed="$(printf '%s\n' "$output" | grep '^[<>]')"
  [ "$(printf '%s\n' "$changed" | wc -l | tr -d ' ')" = 2 ]
  ! printf '%s\n' "$changed" | grep -v '^[<>] theme = '
  run look render "$BATS_TEST_TMPDIR/after-save"
  [ "$(cat "$BATS_TEST_TMPDIR/after-save/theme.name")" = nord ]
}

@test "a stale Draft Look is discarded by the next normal render" {
  mkdir -p "$UNMACOS_STATE"
  printf 'look.theme = "nord"\n' > "$UNMACOS_STATE/draft.toml"
  run look render "$BATS_TEST_TMPDIR/out"
  [ "$status" -eq 0 ]
  [ "$(cat "$BATS_TEST_TMPDIR/out/theme.name")" = tokyo-night ]
  [ ! -e "$UNMACOS_STATE/draft.toml" ]
}

@test "draft save of a Theme replaces a live theme.name so the saved Theme shows" {
  mkdir -p "$UNMACOS_STATE"
  printf 'everforest\n' > "$UNMACOS_STATE/theme.name"
  run look draft set look.theme=nord
  [ "$status" -eq 0 ]
  run look draft save
  [ "$status" -eq 0 ]
  [ "$(bash "$UNMACOS_SETTINGS" get look.theme)" = nord ]
  [ "$(cat "$UNMACOS_STATE/theme.name")" = nord ]
  [ "$(cat "$UNMACOS_STATE/theme/theme.name")" = nord ]
}

@test "a normal render that fails leaves a leftover Draft Look in place" {
  mkdir -p "$UNMACOS_STATE"
  printf 'look.theme = "nord"\n' > "$UNMACOS_STATE/draft.toml"
  UNMACOS_THEME=no-such-theme run look render "$BATS_TEST_TMPDIR/out"
  [ "$status" -ne 0 ]
  [[ "$output" == *"no theme 'no-such-theme'"* ]]
  [ -f "$UNMACOS_STATE/draft.toml" ]
}

# rift_gap FILE SECTION KEY: a number from Rift's rendered config
rift_gap() { awk -v sec="[settings.layout.gaps.$2]" -v key="$3" '$0 == sec {on=1; next} /^\[/ {on=0} on && $1 == key {print $3}' "$1"; }

# render_gaps GAP BORDER BAR_HEIGHT CHIP_HEIGHT: render with those Look values as a Draft Look
render_gaps() {
  mkdir -p "$UNMACOS_STATE"
  printf '[look]\nwindow_gap = %s\nborder_width = %s\nbar_height = %s\nchip_height = %s\n' "$1" "$2" "$3" "$4" > "$UNMACOS_STATE/draft.toml"
  look render --draft "$BATS_TEST_TMPDIR/rift"
}

@test "render: Rift's gaps are derived from window gap, border width and bar height" {
  # window gap, border, bar height, chip height -> inner, sides/bottom, top (no notch)
  local row g b h c inner side top
  for row in "4 6 44 30 16 10 47" "0 2 40 24 4 2 34" "8 3 52 36 14 11 55" "12 0 30 30 12 12 42"; do
    read -r g b h c inner side top <<<"$row"
    render_gaps "$g" "$b" "$h" "$c"
    f="$BATS_TEST_TMPDIR/rift/rift.toml"
    [ "$(rift_gap "$f" inner horizontal)" = "$inner" ]
    [ "$(rift_gap "$f" inner vertical)" = "$inner" ]
    [ "$(rift_gap "$f" outer left)" = "$side" ]
    [ "$(rift_gap "$f" outer right)" = "$side" ]
    [ "$(rift_gap "$f" outer bottom)" = "$side" ]
    [ "$(rift_gap "$f" outer top)" = "$top" ]
  done
}

@test "chezmoi apply links Rift's config to the rendered one and never writes its content" {
  unmacos_chezmoi_init
  run unmacos_chezmoi_dry_run
  [ "$status" -eq 0 ]
  run unmacos_chezmoi managed --include=symlinks
  [[ "$output" == *".config/rift/config.toml"* ]]
  run unmacos_chezmoi cat "$HOME/.config/rift/config.toml"
  [ "$output" = "$HOME/.local/state/unmacos/theme/rift.toml" ]
}

@test "render: the animation and focus Settings flow into Rift's config" {
  printf '[desktop]\nanimate = false\nmouse_hides_on_focus = false\n' >> "$HOME/.config/unmacos/setup.toml"
  run look render "$BATS_TEST_TMPDIR/out"
  [ "$status" -eq 0 ]
  grep -q '^animate = false$' "$BATS_TEST_TMPDIR/out/rift.toml"
  grep -q '^mouse_hides_on_focus = false$' "$BATS_TEST_TMPDIR/out/rift.toml"
  grep -q '^focus_follows_mouse = true$' "$BATS_TEST_TMPDIR/out/rift.toml"
}

# theme_script: the 50-theme script chezmoi apply would run, from the current Answers
theme_script() {
  unmacos_chezmoi_init >/dev/null
  unmacos_chezmoi cat "$HOME/.chezmoiscripts/50-theme.sh"
}

@test "chezmoi apply re-renders the Look when a Setting it reads changes" {
  local before
  before="$(theme_script)"
  [[ "$before" == *unmacos-theme-render* ]]
  # run_onchange reruns the theme script only when its rendered content changes
  printf '[desktop]\nanimate = false\n' >> "$HOME/.config/unmacos/setup.toml"
  [ "$(theme_script)" != "$before" ]
  # and again for a [look] Setting
  before="$(theme_script)"
  printf '[look]\ncorner_radius = 3\n' >> "$HOME/.config/unmacos/setup.toml"
  [ "$(theme_script)" != "$before" ]
}
