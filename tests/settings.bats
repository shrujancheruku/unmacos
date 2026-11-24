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
