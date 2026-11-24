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
  [[ "$output" == *'name = "Test User"'* ]]
  [[ "$output" == *'email = "test@example.invalid"'* ]]
  [[ "$output" == *'use_1password = false'* ]]
  [[ "$output" == *'theme = "tokyo-night"'* ]]
  [[ "$output" == *'weather = "auto"'* ]]
  [[ "$output" == *'# corner_radius = 8 '* ]]
  [[ "$output" == *'apps = []'* ]]
  [[ "$output" == *'apps_skip = []'* ]]
  [[ "$output" == *$'[keep]\nai = false\nglass = false'* ]]
  [[ "$output" == *$'[desktop]\nanimate = true\nfocus_follows_mouse = true'* ]]
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
  [[ "$output" == *'theme = "nord"'* ]]
  [[ "$output" == *'weather = "Oslo"'* ]]
  [[ "$output" == *'# corner_radius = 6 '* ]]
  [[ "$output" == *$'[desktop]\nanimate = false\n'* ]]
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
