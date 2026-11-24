#!/usr/bin/env bats
# The Settings reference: docs/settings.md and the site's settings page, both generated from the
# Settings schema by site/build.py. Regenerate the file with `python3 site/build.py --docs`.

load test_helper

setup() {
  unmacos_temp_home
}

SCHEMA="$REPO_ROOT/home/.chezmoidata/settings.toml"
FIXTURES="$REPO_ROOT/tests/fixtures"

# every_setting prints "group key" for each Setting in the schema, in schema order.
every_setting() {
  python3 - "$SCHEMA" <<'PY'
import sys, tomllib
with open(sys.argv[1], "rb") as f:
    for s in tomllib.load(f)["settings"]:
        print(s["group"], s["key"])
PY
}

@test "docs/settings.md is current: regenerating it changes nothing" {
  run python3 "$REPO_ROOT/site/build.py" --docs --check
  echo "$output"
  [ "$status" -eq 0 ]
}

@test "the reference has one row for every Setting, in schema order" {
  run python3 - "$SCHEMA" "$REPO_ROOT/docs/settings.md" <<'PY'
import sys, tomllib
with open(sys.argv[1], "rb") as f:
    settings = tomllib.load(f)["settings"]
rows = [line for line in open(sys.argv[2]) if line.startswith("| ") and "`" in line]
keys = [line.split("|")[2].strip().strip("`") for line in rows]
assert len(rows) == len(settings), f"{len(rows)} rows for {len(settings)} Settings"
for row, s in zip(rows, settings):
    assert f"| {s['group']} | `{s['key']}` |" in row, f"row out of order or wrong: {row.strip()}"
PY
  echo "$output"
  [ "$status" -eq 0 ]
}

@test "a stale reference fails the check" {
  python3 "$REPO_ROOT/site/build.py" --docs --out "$BATS_TEST_TMPDIR/settings.md"
  echo "# a hand edit" >> "$BATS_TEST_TMPDIR/settings.md"
  run python3 "$REPO_ROOT/site/build.py" --docs --out "$BATS_TEST_TMPDIR/settings.md" --check
  echo "$output"
  [ "$status" -ne 0 ]
  [[ "$output" == *"stale"* ]]
}

@test "a Setting with no label fails the build and names it" {
  run python3 "$REPO_ROOT/site/build.py" --docs --schema "$FIXTURES/settings-missing-label.toml" --out "$BATS_TEST_TMPDIR/settings.md"
  echo "$output"
  [ "$status" -ne 0 ]
  [[ "$output" == *"look.theme"* ]]
  [[ "$output" == *"label"* ]]
}

@test "a Setting with no help fails the build and names it" {
  run python3 "$REPO_ROOT/site/build.py" --docs --schema "$FIXTURES/settings-missing-help.toml" --out "$BATS_TEST_TMPDIR/settings.md"
  echo "$output"
  [ "$status" -ne 0 ]
  [[ "$output" == *"look.theme"* ]]
  [[ "$output" == *"help"* ]]
}

@test "the site's settings page lists every Setting from the same schema" {
  run env SITE_OUT="$BATS_TEST_TMPDIR/site" python3 "$REPO_ROOT/site/build.py"
  echo "$output"
  [ "$status" -eq 0 ]
  page="$BATS_TEST_TMPDIR/site/install/settings/index.html"
  [ -f "$page" ]
  while read -r group key; do
    grep -q "data-setting=\"$group.$key\"" "$page" || {
      echo "missing from the settings page: $group.$key"
      return 1
    }
  done < <(every_setting)
  # and no placeholder is left in the page
  run grep -c '{{' "$page"
  [ "$output" = "0" ]
}
