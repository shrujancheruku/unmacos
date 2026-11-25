#!/usr/bin/env bats
# Migrating an Answers file from today's format (flat keys, [keep], [desktop], apps, apps_skip,
# use_1password, the old personal = true) to the grouped shape. Tested at the command line
# (unmacos-settings migrate, and the first read of the real Answers file), and through chezmoi.
#
# tests/golden/answers-migrated.toml is the expected result for tests/fixtures/answers-today.toml.
# To change it on purpose, regenerate it with
#   UNMACOS_UPDATE_GOLDEN=1 bats tests/migrate.bats
# review the diff by hand, and say why in the commit message.

load test_helper

settings() {
  /bin/bash "$REPO_ROOT/home/dot_local/bin/executable_unmacos-settings" "$@"
}

setup() {
  unmacos_temp_home
  # the command finds the Settings schema through chezmoi's source directory
  mkdir -p "$HOME/.local/share"
  ln -sfn "$REPO_ROOT" "$HOME/.local/share/chezmoi"
  export GIT_CONFIG_GLOBAL="$BATS_TEST_TMPDIR/no-gitconfig"
  OLD="$BATS_TEST_TMPDIR/setup.toml"
}

@test "today's Answers migrate to the expected new file (golden)" {
  cp "$REPO_ROOT/tests/fixtures/answers-today.toml" "$OLD"
  run settings migrate "$OLD"
  echo "$output"
  [ "$status" -eq 0 ]
  if [[ -n "${UNMACOS_UPDATE_GOLDEN:-}" ]]; then
    cp "$OLD" "$REPO_ROOT/tests/golden/answers-migrated.toml"
  fi
  run diff -u "$REPO_ROOT/tests/golden/answers-migrated.toml" "$OLD"
  echo "$output"
  [ "$status" -eq 0 ]
}

@test "a backup of the original is kept next to it" {
  cp "$REPO_ROOT/tests/fixtures/answers-today.toml" "$OLD"
  run settings migrate "$OLD"
  [ "$status" -eq 0 ]
  [[ "$output" == *"setup.toml.bak"* ]]
  cmp "$REPO_ROOT/tests/fixtures/answers-today.toml" "$OLD.bak"
  [ "$(stat -f %Lp "$OLD.bak")" = "600" ]
}

@test "personal = true becomes all the app groups once, then disappears" {
  cp "$REPO_ROOT/tests/fixtures/answers-personal.toml" "$OLD"
  run settings migrate "$OLD"
  echo "$output"
  [ "$status" -eq 0 ]
  ! grep -q 'personal' "$OLD"
  grep -qxE 'groups = \["dev", "apps", "media", "games", "appstore"\] .*' "$OLD"
  # the choice is now an ordinary Setting: dropping a group sticks
  settings write "$OLD" --from "$OLD" apps.groups=dev
  [ "$(settings get --from "$OLD" apps.groups)" = "dev" ]
  ! grep -q 'personal' "$OLD"
}

@test "personal = true does not override apps the file lists itself" {
  printf 'personal = true\napps = ["dev"]\n' > "$OLD"
  run settings migrate "$OLD"
  [ "$status" -eq 0 ]
  [ "$(settings get --from "$OLD" apps.groups)" = "dev" ]
}

@test "personal is not reported as an unknown key" {
  run settings validate "$REPO_ROOT/tests/fixtures/answers-personal.toml"
  echo "$output"
  [ "$status" -eq 0 ]
  [[ "$output" != *"not a Setting"* ]]
}

@test "migrating an already migrated file changes nothing" {
  cp "$REPO_ROOT/tests/fixtures/answers-today.toml" "$OLD"
  settings migrate "$OLD"
  cp "$OLD" "$BATS_TEST_TMPDIR/after-first"
  run settings migrate "$OLD"
  echo "$output"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
  cmp "$OLD" "$BATS_TEST_TMPDIR/after-first"
  # no second backup either
  [ "$(ls "$BATS_TEST_TMPDIR" | grep -c '^setup.toml.bak')" -eq 1 ]
}

@test "a file that is already grouped is left byte for byte as it is" {
  printf '# my notes\n[look]\ntheme="nord"\n' > "$OLD"
  cp "$OLD" "$BATS_TEST_TMPDIR/before"
  run settings migrate "$OLD"
  [ "$status" -eq 0 ]
  cmp "$OLD" "$BATS_TEST_TMPDIR/before"
  [ ! -e "$OLD.bak" ]
}

@test "a file with a wrong value is not migrated" {
  printf 'corner_radius = 99\n' > "$OLD"
  run settings migrate "$OLD"
  echo "$output"
  [ "$status" -ne 0 ]
  [[ "$output" == *"look.corner_radius"* ]]
  [ "$(cat "$OLD")" = "corner_radius = 99" ]
  [ ! -e "$OLD.bak" ]
}

@test "migrating keeps every value" {
  cp "$REPO_ROOT/tests/fixtures/answers-today.toml" "$OLD"
  before="$(settings list --no-data --from "$OLD")"
  settings migrate "$OLD"
  [ "$(settings list --no-data --from "$OLD")" = "$before" ]
}

@test "a second backup does not overwrite the first" {
  cp "$REPO_ROOT/tests/fixtures/answers-today.toml" "$OLD"
  settings migrate "$OLD"
  printf 'theme = "gruvbox"\n' > "$OLD"
  settings migrate "$OLD"
  cmp "$REPO_ROOT/tests/fixtures/answers-today.toml" "$OLD.bak"
  [ "$(cat "$OLD.bak.2")" = 'theme = "gruvbox"' ]
}

# --- the first read of the real Answers file ------------------------------------------------

@test "the first read of the Answers file migrates it" {
  mkdir -p "$HOME/.config/unmacos"
  cp "$REPO_ROOT/tests/fixtures/answers-today.toml" "$HOME/.config/unmacos/setup.toml"
  run settings get look.theme
  echo "$output"
  [ "$status" -eq 0 ]
  [[ "$output" == *"nord"* ]]
  cmp "$REPO_ROOT/tests/fixtures/answers-today.toml" "$HOME/.config/unmacos/setup.toml.bak"
  diff -u "$REPO_ROOT/tests/golden/answers-migrated.toml" "$HOME/.config/unmacos/setup.toml"
}

@test "the wizard's own calls (--from the Answers file, write, list) migrate it too" {
  mkdir -p "$HOME/.config/unmacos"
  A="$HOME/.config/unmacos/setup.toml"
  cp "$REPO_ROOT/tests/fixtures/answers-today.toml" "$A"
  run settings write "$A" --no-data --from "$A" look.theme=gruvbox
  [ "$status" -eq 0 ]
  cmp "$REPO_ROOT/tests/fixtures/answers-today.toml" "$A.bak"
  ! grep -q '^use_1password' "$A"
  [ "$(settings get --no-data --from "$A" look.theme)" = "gruvbox" ]
  [ "$(settings get --no-data --from "$A" onepassword.enabled)" = "true" ]
}

@test "a read of some other file does not touch it" {
  cp "$REPO_ROOT/tests/fixtures/answers-today.toml" "$OLD"
  run settings get --from "$OLD" look.theme
  [ "$status" -eq 0 ]
  cmp "$REPO_ROOT/tests/fixtures/answers-today.toml" "$OLD"
  [ ! -e "$OLD.bak" ]
}

@test "validate only checks, it does not migrate" {
  mkdir -p "$HOME/.config/unmacos"
  A="$HOME/.config/unmacos/setup.toml"
  cp "$REPO_ROOT/tests/fixtures/answers-today.toml" "$A"
  run settings validate "$A"
  [ "$status" -eq 0 ]
  cmp "$REPO_ROOT/tests/fixtures/answers-today.toml" "$A"
}

@test "a read of a missing Answers file migrates nothing and succeeds" {
  run settings get look.theme
  [ "$status" -eq 0 ]
  [ ! -e "$HOME/.config/unmacos/setup.toml" ]
}

@test "a read still works when the Answers file cannot be migrated (folder not writable)" {
  mkdir -p "$HOME/.config/unmacos"
  A="$HOME/.config/unmacos/setup.toml"
  cp "$REPO_ROOT/tests/fixtures/answers-today.toml" "$A"
  chmod 500 "$HOME/.config/unmacos"
  run settings get look.theme
  chmod 700 "$HOME/.config/unmacos"
  echo "$output"
  [ "$status" -eq 0 ]
  [[ "$output" == *"nord"* ]]
  cmp "$REPO_ROOT/tests/fixtures/answers-today.toml" "$A"
}

# --- chezmoi -------------------------------------------------------------------------------

@test "chezmoi reads personal = true as every app group, until the file is migrated" {
  unmacos_write_answers "$REPO_ROOT/tests/fixtures/answers-personal.toml"
  unmacos_chezmoi_init
  [ "$(unmacos_chezmoi execute-template '{{ .apps.groups | join "," }}')" = "dev,apps,media,games,appstore" ]
}

@test "chezmoi apply migrates an old Answers file without prompting" {
  unmacos_write_answers "$REPO_ROOT/tests/fixtures/answers-today.toml"
  A="$HOME/.config/unmacos/setup.toml"
  unmacos_chezmoi_init
  # run only the migrate script (a target argument limits what apply touches); stdin is closed,
  # so any prompt would fail
  run unmacos_chezmoi apply --force "$HOME/.chezmoiscripts/05-migrate-answers.sh" < /dev/null
  echo "$output"
  [ "$status" -eq 0 ]
  cmp "$REPO_ROOT/tests/fixtures/answers-today.toml" "$A.bak"
  diff -u "$REPO_ROOT/tests/golden/answers-migrated.toml" "$A"
}

@test "chezmoi apply leaves a migrated Answers file alone" {
  unmacos_write_answers "$REPO_ROOT/tests/golden/answers-migrated.toml"
  A="$HOME/.config/unmacos/setup.toml"
  unmacos_chezmoi_init
  run unmacos_chezmoi apply --force "$HOME/.chezmoiscripts/05-migrate-answers.sh" < /dev/null
  echo "$output"
  [ "$status" -eq 0 ]
  cmp "$REPO_ROOT/tests/golden/answers-migrated.toml" "$A"
  [ ! -e "$A.bak" ]
}

@test "chezmoi apply without an Answers file does nothing to migrate" {
  run unmacos_chezmoi apply --force "$HOME/.chezmoiscripts/05-migrate-answers.sh" < /dev/null
  echo "$output"
  [ "$status" -eq 0 ]
  [ ! -e "$HOME/.config/unmacos/setup.toml" ]
}

# --- Settings that moved group (the schema's moved_from) ------------------------------------------

@test "desktop.animate in older Answers moves to look.animate on migrate, keeping a backup" {
  printf '[look]\ntheme = "nord"\n\n[desktop]\nanimate = false\nfocus_follows_mouse = false\n' > "$OLD"
  run settings migrate "$OLD"
  echo "$output"
  [ "$status" -eq 0 ]
  [[ "$output" == *"setup.toml.bak"* ]]
  [ "$(settings get --from "$OLD" look.animate)" = false ]
  [ "$(settings get --from "$OLD" desktop.focus_follows_mouse)" = false ]
  # the old key is gone from [desktop], and nothing warns about it any more
  ! sed -n '/^\[desktop\]/,/^\[/p' "$OLD" | grep -q '^animate'
  run settings list --from "$OLD"
  [[ "$output" != *"warning"* ]]
}

@test "an un-migrated desktop.animate is read as look.animate, with no unknown-key warning" {
  printf '[desktop]\nanimate = false\n' > "$OLD"
  run settings get --from "$OLD" look.animate
  echo "$output"
  [ "$status" -eq 0 ]
  [ "$output" = false ]
}

@test "look.animate wins over a leftover desktop.animate" {
  printf '[look]\nanimate = true\n\n[desktop]\nanimate = false\n' > "$OLD"
  [ "$(settings get --from "$OLD" look.animate 2>/dev/null)" = true ]
}

@test "chezmoi reads an un-migrated desktop.animate as .look.animate" {
  mkdir -p "$HOME/.config/unmacos"
  printf 'name = "T"\nemail = "t@example.invalid"\nuse_1password = false\n[desktop]\nanimate = false\n' > "$HOME/.config/unmacos/setup.toml"
  unmacos_chezmoi_init
  [ "$(unmacos_chezmoi execute-template '{{ .look.animate }}')" = false ]
}
