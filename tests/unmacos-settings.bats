#!/usr/bin/env bats
# unmacos-settings: the only thing that reads or writes Answers. Tested at its command line
# (list, get, validate, write), always under macOS's own bash 3.2.

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
}

# answers: write an Answers file from stdin to $BATS_TEST_TMPDIR/a.toml
answers() { cat > "$BATS_TEST_TMPDIR/a.toml"; }

# --- validate -------------------------------------------------------------------

@test "validate accepts a good Answers file" {
  answers <<'TOML'
[look]
theme = "nord"
corner_radius = 4
[desktop]
animate = false
[apps]
groups = ["dev", "media"]
TOML
  run settings validate "$BATS_TEST_TMPDIR/a.toml"
  echo "$output"
  [ "$status" -eq 0 ]
}

@test "validate rejects a wrong type, naming the Setting" {
  answers <<'TOML'
[look]
animate = "yes"
TOML
  run settings validate "$BATS_TEST_TMPDIR/a.toml"
  echo "$output"
  [ "$status" -ne 0 ]
  [[ "$output" == *"look.animate"* ]]
  [[ "$output" == *"true or false"* ]]
}

@test "validate rejects a number out of range, naming the Setting" {
  answers <<'TOML'
[look]
corner_radius = 30
TOML
  run settings validate "$BATS_TEST_TMPDIR/a.toml"
  echo "$output"
  [ "$status" -ne 0 ]
  [[ "$output" == *"look.corner_radius"* ]]
  [[ "$output" == *"30"* ]]
  [[ "$output" == *"24"* ]]
}

@test "validate rejects an unknown choice, naming the Setting and the choices" {
  answers <<'TOML'
[look]
theme = "neon-pink"
[apps]
groups = ["dev", "toys"]
TOML
  run settings validate "$BATS_TEST_TMPDIR/a.toml"
  echo "$output"
  [ "$status" -ne 0 ]
  [[ "$output" == *"look.theme"* ]]
  [[ "$output" == *"neon-pink"* ]]
  [[ "$output" == *"tokyo-night"* ]]
  [[ "$output" == *"apps.groups"* ]]
  [[ "$output" == *"toys"* ]]
}

@test "validate reports every problem, not just the first" {
  answers <<'TOML'
[look]
corner_radius = -1
theme = "neon-pink"
TOML
  run settings validate "$BATS_TEST_TMPDIR/a.toml"
  [ "$status" -ne 0 ]
  [[ "$output" == *"look.corner_radius"* ]]
  [[ "$output" == *"look.theme"* ]]
}

@test "validate warns about unknown keys and still passes" {
  answers <<'TOML'
colour = "blue"
[look]
theme = "nord"
sparkle = true
[mystery]
x = 1
TOML
  run settings validate "$BATS_TEST_TMPDIR/a.toml"
  echo "$output"
  [ "$status" -eq 0 ]
  [[ "$output" == *"colour"* ]]
  [[ "$output" == *"look.sparkle"* ]]
  [[ "$output" == *"mystery"* ]]
}

@test "validate accepts today's flat Answers keys without warning" {
  run settings validate "$REPO_ROOT/tests/fixtures/answers-today.toml"
  echo "$output"
  [ "$status" -eq 0 ]
  [[ "$output" != *warning* ]]
}

@test "validate fails on a file that is not TOML or does not exist" {
  printf 'this is = = not toml\n' > "$BATS_TEST_TMPDIR/bad.toml"
  run settings validate "$BATS_TEST_TMPDIR/bad.toml"
  [ "$status" -ne 0 ]
  run settings validate "$BATS_TEST_TMPDIR/missing.toml"
  [ "$status" -ne 0 ]
}

# --- list and get ------------------------------------------------------------------

@test "get prints a Setting's value, the default when the Answers omit it" {
  answers <<'TOML'
[look]
theme = "nord"
TOML
  [ "$(settings get --from "$BATS_TEST_TMPDIR/a.toml" look.theme)" = "nord" ]
  [ "$(settings get --from "$BATS_TEST_TMPDIR/a.toml" look.corner_radius)" = "8" ]
  [ "$(settings get --from "$BATS_TEST_TMPDIR/a.toml" look.animate)" = "true" ]
}

@test "get reads today's flat Answers keys" {
  [ "$(settings get --from "$REPO_ROOT/tests/fixtures/answers-today.toml" look.theme)" != "" ]
  answers <<'TOML'
theme = "gruvbox"
apps = ["dev", "media"]
TOML
  [ "$(settings get --from "$BATS_TEST_TMPDIR/a.toml" look.theme)" = "gruvbox" ]
  [ "$(settings get --from "$BATS_TEST_TMPDIR/a.toml" apps.groups)" = $'dev\nmedia' ]
}

@test "get fails for a Setting that does not exist" {
  run settings get no.such
  [ "$status" -ne 0 ]
  [[ "$output" == *"no.such"* ]]
}

@test "get fails on an Answers file with a wrong value" {
  answers <<'TOML'
[look]
corner_radius = 99
TOML
  run settings get --from "$BATS_TEST_TMPDIR/a.toml" look.theme
  [ "$status" -ne 0 ]
  [[ "$output" == *"look.corner_radius"* ]]
}

@test "list prints every Setting as TOML, and --long adds the label" {
  run settings list --from "$BATS_TEST_TMPDIR/none.toml"
  [ "$status" -eq 0 ]
  [[ "$output" == *'look.theme = "tokyo-night"'* ]]
  [[ "$output" == *'look.corner_radius = 8'* ]]
  [[ "$output" == *'apps.groups = []'* ]]
  [[ "$output" == *'keep.ai = false'* ]]
  run settings list --long keep --from "$BATS_TEST_TMPDIR/none.toml"
  [ "$status" -eq 0 ]
  [[ "$output" == *$'keep.ai\tfalse\tKeep Apple Intelligence on'* ]]
  [[ "$output" != *look.theme* ]]
}

# --- write ------------------------------------------------------------------------

@test "a Setting equal to its default is written as a commented line with its help" {
  run settings write - --from "$BATS_TEST_TMPDIR/none.toml"
  echo "$output"
  [ "$status" -eq 0 ]
  [[ "$output" == *$'\n[look]\n'* ]]
  [[ "$output" == *"# corner_radius = 8   # Roundness of bar chips"* ]]
  [[ "$output" == *"# theme = \"tokyo-night\"   # The colours of the whole desktop"* ]]
  # no Setting has a value line
  [ -z "$(printf '%s\n' "$output" | grep -E '^[a-z_]+ = ' || true)" ]
}

@test "only Settings that differ from their default get a value, grouped by table" {
  run settings write - --from "$BATS_TEST_TMPDIR/none.toml" look.theme=nord look.corner_radius=8
  echo "$output"
  [ "$status" -eq 0 ]
  [[ "$output" == *$'[look]\n'*'theme = "nord"   # '* ]]
  [[ "$output" == *"# corner_radius = 8   # "* ]]
  [ "$(printf '%s\n' "$output" | grep -cE '^[a-z_]+ = ')" -eq 1 ]
}

@test "write then read round-trips every Setting type" {
  settings write "$BATS_TEST_TMPDIR/out.toml" --from "$BATS_TEST_TMPDIR/none.toml" \
    git.name='Ada "the Countess" Lovelace' git.email=ada@example.invalid \
    onepassword.enabled=true look.theme=nord look.corner_radius=0 \
    apps.groups=dev,media apps.skip='some-app,other-app' look.animate=false
  cat "$BATS_TEST_TMPDIR/out.toml"
  settings validate "$BATS_TEST_TMPDIR/out.toml"
  get() { settings get --from "$BATS_TEST_TMPDIR/out.toml" "$1"; }
  [ "$(get git.name)" = 'Ada "the Countess" Lovelace' ]       # string, with quotes
  [ "$(get git.email)" = "ada@example.invalid" ]
  [ "$(get onepassword.enabled)" = "true" ]                    # bool
  [ "$(get look.theme)" = "nord" ]                             # enum
  [ "$(get look.corner_radius)" = "0" ]                        # int (0 is not the default)
  [ "$(get apps.groups)" = $'dev\nmedia' ]                     # list
  [ "$(get apps.skip)" = $'some-app\nother-app' ]
  [ "$(get look.animate)" = "false" ]
  # what was not changed stays default
  [ "$(get keep.ai)" = "false" ]
  [ "$(get desktop.focus_follows_mouse)" = "true" ]
}

@test "write reads the Answers it writes back unchanged (a second write is identical)" {
  settings write "$BATS_TEST_TMPDIR/one.toml" --from "$BATS_TEST_TMPDIR/none.toml" \
    look.theme=gruvbox apps.groups=dev bar.weather=Oslo
  settings write "$BATS_TEST_TMPDIR/two.toml" --from "$BATS_TEST_TMPDIR/one.toml"
  diff "$BATS_TEST_TMPDIR/one.toml" "$BATS_TEST_TMPDIR/two.toml"
}

@test "write refuses a bad value and leaves the file alone" {
  printf 'keep = me\n' > "$BATS_TEST_TMPDIR/out.toml"
  run settings write "$BATS_TEST_TMPDIR/out.toml" --from "$BATS_TEST_TMPDIR/none.toml" look.corner_radius=99
  [ "$status" -ne 0 ]
  [[ "$output" == *"look.corner_radius"* ]]
  run settings write "$BATS_TEST_TMPDIR/out.toml" --from "$BATS_TEST_TMPDIR/none.toml" look.corner_radius=wide
  [ "$status" -ne 0 ]
  run settings write "$BATS_TEST_TMPDIR/out.toml" --from "$BATS_TEST_TMPDIR/none.toml" look.animate=maybe
  [ "$status" -ne 0 ]
  run settings write "$BATS_TEST_TMPDIR/out.toml" --from "$BATS_TEST_TMPDIR/none.toml" no.such=1
  [ "$status" -ne 0 ]
  [ "$(cat "$BATS_TEST_TMPDIR/out.toml")" = "keep = me" ]
}

@test "write can rewrite the Answers file it reads, migrating flat keys to tables" {
  cp "$REPO_ROOT/tests/fixtures/answers-today.toml" "$BATS_TEST_TMPDIR/a.toml"
  before="$(settings list --from "$BATS_TEST_TMPDIR/a.toml")"
  settings write "$BATS_TEST_TMPDIR/a.toml" --from "$BATS_TEST_TMPDIR/a.toml"
  [ "$(settings list --from "$BATS_TEST_TMPDIR/a.toml")" = "$before" ]
  [ "$(stat -f %Lp "$BATS_TEST_TMPDIR/a.toml")" = "600" ]
}

@test "chezmoi data fills in the Settings asked at init, unless --no-data" {
  unmacos_chezmoi init \
    --promptString "Your name, for git commits=Prompted Name" \
    --promptString "Your email, for git commits=prompted@example.invalid" \
    --promptBool "Read secrets from 1Password=false" < /dev/null
  [ "$(settings get --from "$BATS_TEST_TMPDIR/none.toml" git.name)" = "Prompted Name" ]
  [ "$(settings get --no-data --from "$BATS_TEST_TMPDIR/none.toml" git.name)" = "" ]
}
