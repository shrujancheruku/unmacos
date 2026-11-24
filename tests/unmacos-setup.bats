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
