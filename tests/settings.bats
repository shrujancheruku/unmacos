#!/usr/bin/env bats
# The Settings schema and how chezmoi merges Answers over its defaults.

load test_helper

setup() {
  unmacos_temp_home
  unmacos_stub_op
}

# Today's Answers file (flat keys, [keep], [desktop]) must keep rendering exactly the files it
# did before the schema. To change a rendered file on purpose, regenerate the golden file with
#   UNMACOS_UPDATE_GOLDEN=1 bats tests/settings.bats
# and say why in the commit message.
@test "today's Answers render the same files as before the schema (golden)" {
  unmacos_write_answers "$REPO_ROOT/tests/fixtures/answers-today.toml"
  unmacos_chezmoi_init
  unmacos_render_templated > "$BATS_TEST_TMPDIR/rendered.txt"
  if [[ -n "${UNMACOS_UPDATE_GOLDEN:-}" ]]; then
    cp "$BATS_TEST_TMPDIR/rendered.txt" "$REPO_ROOT/tests/golden/answers-today.txt"
  fi
  run diff -u "$REPO_ROOT/tests/golden/answers-today.txt" "$BATS_TEST_TMPDIR/rendered.txt"
  echo "$output"
  [ "$status" -eq 0 ]
}

# Helpers: answers writes an Answers file from stdin; value prints one value of chezmoi's
# merged data (the same data every template sees).
answers() {
  mkdir -p "$HOME/.config/unmacos"
  cat > "$HOME/.config/unmacos/setup.toml"
}

value() {
  unmacos_chezmoi execute-template "{{ $1 }}"
}

@test "default is used when the Answers omit a Setting" {
  answers <<'TOML'
name = "Test User"
email = "test@example.invalid"
use_1password = false
TOML
  unmacos_chezmoi_init
  [ "$(value .look.corner_radius)" = "8" ]
  [ "$(value .look.theme)" = "tokyo-night" ]
  [ "$(value .look.animate)" = "true" ]
  [ "$(value .keep.ai)" = "false" ]
  [ "$(value '.apps.groups | len')" = "0" ]
}

@test "an Answers value wins over the default" {
  answers <<'TOML'
name = "Ada Lovelace"
email = "ada@example.invalid"
use_1password = false
theme = "nord"
corner_radius = 4
apps = ["dev"]
[keep]
ai = true
[desktop]
animate = false
TOML
  unmacos_chezmoi_init
  [ "$(value .git.name)" = "Ada Lovelace" ]
  [ "$(value .look.theme)" = "nord" ]
  [ "$(value .look.corner_radius)" = "4" ]
  [ "$(value '.apps.groups | join ","')" = "dev" ]
  [ "$(value .keep.ai)" = "true" ]
  [ "$(value .look.animate)" = "false" ]
  # a Setting left out of a table that is there still gets its default
  [ "$(value .desktop.focus_follows_mouse)" = "true" ]
  [ "$(value .keep.glass)" = "false" ]
}

@test "the grouped Answers shape wins over a flat key" {
  answers <<'TOML'
name = "Test User"
email = "test@example.invalid"
use_1password = false
corner_radius = 4
[look]
corner_radius = 6
TOML
  unmacos_chezmoi_init
  [ "$(value .look.corner_radius)" = "6" ]
}

@test "a nested group key reaches a template" {
  answers <<'TOML'
name = "Test User"
email = "test@example.invalid"
use_1password = false
corner_radius = 4
[desktop]
animate = false
mouse_hides_on_focus = false
TOML
  unmacos_chezmoi_init
  # corner_radius reaches macOS's window corners on apply; the bar and Spotify read the
  # rendered Look instead (tests/look.bats)
  run unmacos_chezmoi cat "$HOME/.chezmoiscripts/40-no-ai-no-glass.sh"
  [[ "$output" == *"NSConvolutionOverride1 -float 4"* ]]
}

@test "a Setting marked ask is asked on init when the Answers omit it" {
  unmacos_chezmoi init \
    --promptString "Your name, for git commits=Pat" \
    --promptString "Your email, for git commits=pat@example.invalid" \
    --promptBool "Read secrets from 1Password=true" < /dev/null
  [ "$(value .git.name)" = "Pat" ]
  [ "$(value .git.email)" = "pat@example.invalid" ]
  [ "$(value .onepassword.enabled)" = "true" ]
}

# prefs.sh: what the setup scripts and theme commands source.
prefs_value() {  # prefs_value VAR [ENV...]: VAR's value after sourcing prefs.sh with ENV set
  local var="$1"; shift
  env "$@" bash -c '. "$HOME/.config/unmacos/prefs.sh"; printf %s "${'"$var"'-unset}"'
}

render_prefs() {
  unmacos_chezmoi cat "$HOME/.config/unmacos/prefs.sh" > "$BATS_TEST_TMPDIR/prefs.sh"
  mkdir -p "$HOME/.config/unmacos"
  cp "$BATS_TEST_TMPDIR/prefs.sh" "$HOME/.config/unmacos/prefs.sh"
}

@test "prefs.sh exports the Settings the schema marks with an env name" {
  answers <<'TOML'
name = "Test User"
email = "test@example.invalid"
use_1password = false
[look]
corner_radius = 5
[keep]
ai = true
TOML
  unmacos_chezmoi_init
  render_prefs
  [ "$(prefs_value UNMACOS_CORNER_RADIUS)" = "5" ]
  [ "$(prefs_value UNMACOS_KEEP_AI)" = "1" ]
  # a keep flag that is off is not exported at all
  [ "$(prefs_value UNMACOS_KEEP_GLASS)" = "unset" ]
}

@test "an env value already set wins over prefs.sh" {
  answers <<'TOML'
name = "Test User"
email = "test@example.invalid"
use_1password = false
[look]
corner_radius = 5
[keep]
ai = true
TOML
  unmacos_chezmoi_init
  render_prefs
  [ "$(prefs_value UNMACOS_CORNER_RADIUS UNMACOS_CORNER_RADIUS=3)" = "3" ]
  [ "$(prefs_value UNMACOS_KEEP_AI UNMACOS_KEEP_AI=0)" = "0" ]
  # a keep flag that is off can still be turned on for one run
  [ "$(prefs_value UNMACOS_KEEP_GLASS UNMACOS_KEEP_GLASS=1)" = "1" ]
}

# The schema is the only list of Settings, so keep it honest.
schema_json() {
  unmacos_chezmoi execute-template '{{ .settings | toJson }}'
}

@test "every Setting has the fields the wizard and the docs need" {
  run python3 - "$(schema_json)" <<'PY'
import json, sys
settings = json.loads(sys.argv[1])
seen = set()
for s in settings:
    where = f"{s.get('group')}.{s.get('key')}"
    for f in ("group", "key", "type", "default", "label", "help", "phase", "takes_effect"):
        assert f in s, f"{where}: missing {f}"
    assert where not in seen, f"{where}: listed twice"
    seen.add(where)
    assert s["type"] in ("bool", "int", "enum", "string", "list"), f"{where}: bad type"
    assert s["phase"] in ("install", "tune"), f"{where}: bad phase"
    assert s["takes_effect"].split(":")[0] in ("live", "apply", "restart", "logout"), f"{where}: bad takes_effect"
    if s["type"] == "enum":
        assert s["default"] in s["choices"], f"{where}: default not in choices"
    if s["type"] == "int":
        assert s["min"] <= s["default"] <= s["max"], f"{where}: default out of range"
PY
  echo "$output"
  [ "$status" -eq 0 ]
}

@test "the theme and app-group choices match the files on disk" {
  run python3 - "$(schema_json)" "$REPO_ROOT" <<'PY'
import json, os, sys
settings = {f"{s['group']}.{s['key']}": s for s in json.loads(sys.argv[1])}
root = sys.argv[2]
themes = sorted(os.listdir(f"{root}/home/dot_local/share/unmacos/themes"))
groups = sorted(f[:-len(".Brewfile")] for f in os.listdir(f"{root}/brew") if f.endswith(".Brewfile"))
assert sorted(settings["look.theme"]["choices"]) == themes, "look.theme choices differ from the themes folder"
assert sorted(settings["apps.groups"]["choices"]) == groups, "apps.groups choices differ from brew/*.Brewfile"
PY
  echo "$output"
  [ "$status" -eq 0 ]
}
