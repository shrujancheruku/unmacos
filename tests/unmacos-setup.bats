#!/usr/bin/env bats
# unmacos-setup (the wizard) through its non-interactive path: --yes --no-apply loads the saved
# Answers, fills the rest from chezmoi's data and the Settings schema, and saves them.

load test_helper

# use_source DIR: make DIR the chezmoi source the wizard finds (~/.local/share/chezmoi).
use_source() {
  mkdir -p "$HOME/.local/share"
  ln -sfn "$1" "$HOME/.local/share/chezmoi"
}

wizard() {
  # /bin/bash: the wizard runs on macOS's own bash 3.2
  /bin/bash "$REPO_ROOT/home/dot_local/bin/executable_unmacos-setup" "$@"
}

setup() {
  unmacos_temp_home
  # no global git config: name and email must come from the Answers
  export GIT_CONFIG_GLOBAL="$BATS_TEST_TMPDIR/no-gitconfig"
}

# Answers with only who you are: no theme, weather, corner radius, apps, [keep] or [desktop]
answers_without_apps() {
  mkdir -p "$HOME/.config/unmacos"
  cat > "$HOME/.config/unmacos/setup.toml" <<'TOML'
name = "Test User"
email = "test@example.invalid"
use_1password = false
TOML
}

@test "--yes --no-apply with Answers that omit apps saves the schema's defaults" {
  use_source "$REPO_ROOT"
  answers_without_apps
  unmacos_chezmoi_init
  run wizard --yes --no-apply
  echo "$output"
  [ "$status" -eq 0 ]
  run cat "$HOME/.config/unmacos/setup.toml"
  echo "$output"
  [[ "$output" == *$'[git]\n'*'name = "Test User"'* ]]
  [[ "$output" == *'email = "test@example.invalid"'* ]]
  # everything at its default is a commented line, not a value
  [[ "$output" == *'# enabled = false '* ]]
  [[ "$output" == *'# theme = "tokyo-night" '* ]]
  [[ "$output" == *'# weather = "auto" '* ]]
  [[ "$output" == *'# corner_radius = 8 '* ]]
  [[ "$output" == *'# groups = [] '* ]]
  [[ "$output" == *'# ai = false '* ]]
  [[ "$output" == *'# animate = true '* ]]
}

@test "--yes --no-apply takes the defaults from the schema, not from the wizard" {
  # a copy of the source whose schema has other defaults
  local src="$BATS_TEST_TMPDIR/source"
  mkdir -p "$src"
  (cd "$REPO_ROOT" && git ls-files -co --exclude-standard | tar -cf - -T - ) | tar -xf - -C "$src"
  perl -0pi -e 's/(key = "theme"\ntype = "enum"\ndefault = )"tokyo-night"/$1"nord"/;
                s/(key = "weather"\ntype = "string"\ndefault = )"auto"/$1"Oslo"/;
                s/(key = "corner_radius"\ntype = "int"\ndefault = )8/${1}6/;
                s/(key = "animate"\ntype = "bool"\ndefault = )true/${1}false/' \
    "$src/home/.chezmoidata/settings.toml"
  use_source "$src"
  answers_without_apps
  chezmoi --source "$src" --destination "$HOME" --no-tty --no-pager init
  run wizard --yes --no-apply
  echo "$output"
  [ "$status" -eq 0 ]
  run cat "$HOME/.config/unmacos/setup.toml"
  echo "$output"
  [[ "$output" == *'# theme = "nord" '* ]]
  [[ "$output" == *'# weather = "Oslo" '* ]]
  [[ "$output" == *'# corner_radius = 6 '* ]]
  [[ "$output" == *'# animate = false '* ]]
}

@test "--yes --no-apply with no Answers file reads name and email from chezmoi's data" {
  use_source "$REPO_ROOT"
  unmacos_chezmoi init \
    --promptString "Your name, for git commits=Prompted Name" \
    --promptString "Your email, for git commits=prompted@example.invalid" \
    --promptBool "Read secrets from 1Password=false" < /dev/null
  run wizard --yes --no-apply
  echo "$output"
  [ "$status" -eq 0 ]
  run cat "$HOME/.config/unmacos/setup.toml"
  [[ "$output" == *'name = "Prompted Name"'* ]]
  [[ "$output" == *'email = "prompted@example.invalid"'* ]]
}

# --- --yes, --import, --export ---------------------------------------------------------------

# saved: the setting's value in the saved Answers
saved() { /bin/bash "$REPO_ROOT/home/dot_local/bin/executable_unmacos-settings" get --no-data "$1"; }

@test "--yes keeps the saved Answers and leaves no per-Setting code behind" {
  use_source "$REPO_ROOT"
  mkdir -p "$HOME/.config/unmacos"
  cat > "$HOME/.config/unmacos/setup.toml" <<'TOML'
[git]
name = "Ada"
email = "ada@example.invalid"
[onepassword]
enabled = false
[look]
theme = "nord"
corner_radius = 4
[apps]
groups = ["dev"]
skip = ["lazygit"]
[keep]
firefox = true
TOML
  unmacos_chezmoi_init
  run wizard --yes --no-apply
  echo "$output"
  [ "$status" -eq 0 ]
  [ "$(saved look.theme)" = "nord" ]
  [ "$(saved look.corner_radius)" = "4" ]
  [ "$(saved apps.groups)" = "dev" ]
  [ "$(saved apps.skip)" = "lazygit" ]
  [ "$(saved keep.firefox)" = "true" ]
  [ "$(saved keep.ai)" = "false" ]
  [ "$(stat -f %Lp "$HOME/.config/unmacos/setup.toml")" = "600" ]
}

@test "--yes takes this Mac's live theme and weather" {
  use_source "$REPO_ROOT"
  answers_without_apps
  unmacos_chezmoi_init
  mkdir -p "$HOME/.local/state/unmacos"
  echo gruvbox > "$HOME/.local/state/unmacos/theme.name"
  echo Oslo > "$HOME/.local/state/unmacos/weather.location"
  run wizard --yes --no-apply
  [ "$status" -eq 0 ]
  [ "$(saved look.theme)" = "gruvbox" ]
  [ "$(saved bar.weather)" = "Oslo" ]
}

@test "--import FILE replaces the saved Answers with FILE's, ignoring chezmoi's data" {
  use_source "$REPO_ROOT"
  answers_without_apps
  unmacos_chezmoi_init
  cat > "$BATS_TEST_TMPDIR/other.toml" <<'TOML'
name = "Grace"
email = "grace@example.invalid"
theme = "gruvbox"
corner_radius = 12
apps = ["media"]
[desktop]
animate = false
TOML
  run wizard --import "$BATS_TEST_TMPDIR/other.toml" --no-apply
  echo "$output"
  [ "$status" -eq 0 ]
  [ "$(saved git.name)" = "Grace" ]
  [ "$(saved git.email)" = "grace@example.invalid" ]
  [ "$(saved look.theme)" = "gruvbox" ]
  [ "$(saved look.corner_radius)" = "12" ]
  [ "$(saved apps.groups)" = "media" ]
  [ "$(saved desktop.animate)" = "false" ]
  [ "$(saved onepassword.enabled)" = "false" ]
}

@test "--import refuses a file with a wrong value and saves nothing" {
  use_source "$REPO_ROOT"
  answers_without_apps
  before="$(cat "$HOME/.config/unmacos/setup.toml")"
  printf 'name = "G"\nemail = "g@example.invalid"\ncorner_radius = 99\n' > "$BATS_TEST_TMPDIR/bad.toml"
  run wizard --import "$BATS_TEST_TMPDIR/bad.toml" --no-apply
  [ "$status" -ne 0 ]
  [[ "$output" == *"look.corner_radius"* ]]
  [ "$(cat "$HOME/.config/unmacos/setup.toml")" = "$before" ]
  run wizard --import "$BATS_TEST_TMPDIR/missing.toml" --no-apply
  [ "$status" -ne 0 ]
}

@test "--import reads Answers grouped in tables too" {
  use_source "$REPO_ROOT"
  answers_without_apps
  printf 'name = "G"\nemail = "g@example.invalid"\n[look]\ntheme = "nord"\n[apps]\ngroups = ["dev"]\n' > "$BATS_TEST_TMPDIR/ok.toml"
  run wizard --import "$BATS_TEST_TMPDIR/ok.toml" --no-apply
  echo "$output"
  [ "$status" -eq 0 ]
}

@test "--export prints the Answers with this Mac's live theme and weather" {
  use_source "$REPO_ROOT"
  answers_without_apps
  unmacos_chezmoi_init
  mkdir -p "$HOME/.local/state/unmacos"
  echo kanagawa > "$HOME/.local/state/unmacos/theme.name"
  echo "" > "$HOME/.local/state/unmacos/weather.location"
  run wizard --export
  echo "$output"
  [ "$status" -eq 0 ]
  [[ "$output" == *'name = "Test User"'* ]]
  [[ "$output" == *'theme = "kanagawa"'* ]]
  [[ "$output" == *'# weather = "auto" '* ]]
}

@test "--export FILE writes a private file that --import reads back" {
  use_source "$REPO_ROOT"
  answers_without_apps
  unmacos_chezmoi_init
  run wizard --export "$BATS_TEST_TMPDIR/out.toml"
  echo "$output"
  [ "$status" -eq 0 ]
  [ "$(stat -f %Lp "$BATS_TEST_TMPDIR/out.toml")" = "600" ]
  rm "$HOME/.config/unmacos/setup.toml"
  run wizard --import "$BATS_TEST_TMPDIR/out.toml" --no-apply
  [ "$status" -eq 0 ]
  [ "$(saved git.name)" = "Test User" ]
}

@test "the wizard has no per-Setting load or write code" {
  ! grep -nE 'a_(keep|desktop)_|KEEP_KEYS|DESKTOP_KEYS|keep_label|desktop_label|write_answers|^load\(\)' \
    "$REPO_ROOT/home/dot_local/bin/executable_unmacos-setup"
}

# --- Install phase: the questions come from the Settings schema ----------------------------------

# source_with_fixture: a copy of the source whose schema has one more install-phase Setting
# (and one tune-phase one the wizard must not ask), placed in its own group between the others.
source_with_fixture() {
  local src="$BATS_TEST_TMPDIR/source"
  mkdir -p "$src"
  (cd "$REPO_ROOT" && git ls-files -co --exclude-standard | tar -cf - -T - ) | tar -xf - -C "$src"
  cat >> "$src/home/.chezmoidata/settings.toml" <<'TOML'

[[settings]]
group = "fixture"
key = "volume"
type = "int"
default = 5
min = 1
max = 11
label = "Fixture volume"
help = "A Setting only the test knows."
phase = "install"
takes_effect = "apply"

[[settings]]
group = "fixture"
key = "tuned"
type = "string"
default = "x"
label = "Fixture tuned later"
help = "Tune phase: not asked at install."
phase = "tune"
takes_effect = "live"
TOML
  use_source "$src"
  chezmoi --source "$src" --destination "$HOME" --no-tty --no-pager init
}

@test "--questions lists the install-phase questions in schema order with the gum input for each type" {
  use_source "$REPO_ROOT"
  answers_without_apps
  unmacos_chezmoi_init
  run wizard --questions
  echo "$output"
  [ "$status" -eq 0 ]
  expected="git	git.name	gum input	Your name, for git commits
git	git.email	gum input	Your email, for git commits
look	look.theme	gum choose	Theme
apps	apps.groups	gum choose --no-limit	Extra apps to install
apps	apps.skip	gum choose --no-limit	Apps to leave out
onepassword	onepassword.enabled	gum confirm	Read secrets from 1Password
keep	keep.ai	gum choose --no-limit	Keep Apple Intelligence on
keep	keep.glass	gum choose --no-limit	Keep Liquid Glass on
keep	keep.wallpaper	gum choose --no-limit	Keep my wallpaper
keep	keep.accent	gum choose --no-limit	Keep macOS's accent colours
keep	keep.firefox	gum choose --no-limit	Keep Firefox as it is
keep	keep.firefox_wallpaper	gum choose --no-limit	Keep Firefox's new tab page
keep	keep.spotify	gum choose --no-limit	Keep Spotify as it is
keep	keep.orca	gum choose --no-limit	Keep Orca's colours"
  [ "$output" = "$expected" ]
}

@test "a new install-phase Setting in the schema appears in the question list with no wizard edit" {
  answers_without_apps
  source_with_fixture
  run wizard --questions
  echo "$output"
  [ "$status" -eq 0 ]
  [[ "$output" == *$'\nfixture\tfixture.volume\tgum input\tFixture volume' ]]
  # the tune-phase one is not asked
  [[ "$output" != *"fixture.tuned"* ]]
  # groups stay in schema order: the new group comes after keep, the last one before it
  [[ "$output" == *$'keep.orca\tgum choose --no-limit\tKeep Orca\'s colours\nfixture\t'* ]]
}

# stub_gum: a fake gum. `gum style` echoes its arguments; every other command logs its arguments
# to $GUM_LOG and takes its next scripted reply from $GUM_REPLIES: one "STATUS|OUTPUT" per line
# (OUTPUT may contain \n). A missing reply is a test failure (status 99).
stub_gum() {
  # the wizard puts ~/.local/bin first on PATH, so that is where the fake goes
  mkdir -p "$HOME/.local/bin"
  cat > "$HOME/.local/bin/gum" <<'STUB'
#!/bin/bash
cmd="$1"; shift
if [[ "$cmd" == style ]]; then
  # the flags with a value come first; print the rest
  while [[ $# -gt 0 ]]; do
    case "$1" in --border|--border-foreground|--padding|--margin|--foreground) shift 2 ;; --faint|--bold) shift ;; *) echo "$1"; shift ;; esac
  done
  exit 0
fi
echo "gum $cmd $*" >> "$GUM_LOG"
line="$(head -n 1 "$GUM_REPLIES")"
sed -i '' 1d "$GUM_REPLIES"
[[ -n "$line" ]] || { echo "no scripted reply for: gum $cmd $*" >&2; exit 99; }
printf '%b\n' "${line#*|}"
exit "${line%%|*}"
STUB
  chmod +x "$HOME/.local/bin/gum"
  export GUM_LOG="$BATS_TEST_TMPDIR/gum.log" GUM_REPLIES="$BATS_TEST_TMPDIR/replies"
  : > "$GUM_LOG"
  export UNMACOS_SETUP_UI=1
}

replies() { printf '%s\n' "$@" > "$GUM_REPLIES"; }

@test "cancelling a question leaves the Answers untouched" {
  use_source "$REPO_ROOT"
  answers_without_apps
  unmacos_chezmoi_init
  before="$(cat "$HOME/.config/unmacos/setup.toml")"
  stub_gum
  # name, email, then Esc on the theme
  replies '0|Ada' '0|ada@example.invalid' '130|'
  run wizard --no-apply
  echo "$output"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Nothing changed"* ]]
  [ "$(cat "$HOME/.config/unmacos/setup.toml")" = "$before" ]
  [ ! -e "$HOME/.config/unmacos/setup.toml.new" ]
}

@test "declining the final confirmation leaves the Answers untouched" {
  use_source "$REPO_ROOT"
  answers_without_apps
  unmacos_chezmoi_init
  before="$(cat "$HOME/.config/unmacos/setup.toml")"
  stub_gum
  replies '0|Ada' '0|ada@example.invalid' '0|nord' '0|' '1|' '0|' '1|'
  run wizard --no-apply
  echo "$output"
  [ "$status" -eq 0 ]
  [ "$(cat "$HOME/.config/unmacos/setup.toml")" = "$before" ]
}

@test "the wizard asks with the matching gum input, saves the answers and lists the changed Settings by label" {
  use_source "$REPO_ROOT"
  answers_without_apps
  unmacos_chezmoi_init
  stub_gum
  # name, email, theme, app groups (dev), skip some? no, 1Password? yes, keep: Firefox, save? yes
  replies '0|Ada' '0|ada@example.invalid' '0|nord' '0|dev — Developer tools' '1|' '0|' \
    "0|Keep Firefox as it is" '0|'
  run wizard --no-apply
  echo "$output"
  [ "$status" -eq 0 ]
  [ "$(saved look.theme)" = "nord" ]
  [ "$(saved apps.groups)" = "dev" ]
  [ "$(saved onepassword.enabled)" = "true" ]
  [ "$(saved keep.firefox)" = "true" ]
  [ "$(saved keep.ai)" = "false" ]
  # the summary names what changed by label, and not what did not
  [[ "$output" == *"Theme: tokyo-night → nord"* ]]
  [[ "$output" == *"Keep Firefox as it is: no → yes"* ]]
  [[ "$output" != *"Keep Liquid Glass on:"* ]]
  run cat "$GUM_LOG"
  echo "$output"
  [[ "$output" == *"gum input --header Your name, for git commits"* ]]
  [[ "$output" == *"gum choose --height 14 --header Theme"* ]]
  [[ "$output" == *"gum confirm"*"Read secrets from 1Password"* ]]
  [[ "$output" == *"gum choose --no-limit"*"Tick to keep"* ]]
}

@test "an install-phase int Setting from the schema is asked with gum input, in range" {
  answers_without_apps
  source_with_fixture
  stub_gum
  # name, email, theme, groups (none), 1Password no, keep nothing, volume: 99 (too big), then 7; save
  replies '0|Ada' '0|ada@example.invalid' '0|tokyo-night' '0|' '1|' '0|' '0|99' '0|7' '0|'
  run wizard --no-apply
  echo "$output"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Fixture volume: 5 → 7"* ]]
  [ "$(saved fixture.volume)" = "7" ]
  run cat "$GUM_LOG"
  [[ "$output" == *"gum input --header Fixture volume (1 to 11)"* ]]
}
