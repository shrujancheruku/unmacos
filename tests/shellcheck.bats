#!/usr/bin/env bats
# Every shipped shell script passes shellcheck. Templated scripts are rendered
# with the fixture Answers first, so the check sees what chezmoi would run.

load test_helper

setup() {
  unmacos_temp_home
  unmacos_write_answers
  unmacos_chezmoi_init
}

@test "shellcheck passes on every shipped shell script" {
  run unmacos_shellcheck_shipped
  [ "$status" -eq 0 ]
}

@test "every shipped script is found, including templated ones" {
  run unmacos_shipped_scripts
  [ "$status" -eq 0 ]
  [[ "$output" == *"home/.chezmoiscripts/run_onchange_after_50-theme.sh.tmpl"* ]]
  [[ "$output" == *"home/dot_local/bin/executable_unmacos-setup"* ]]
  [[ "$output" == *"install.sh"* ]]
  # rendered goldens are expected output, not scripts: a golden borders.sh is never checked
  [[ "$output" != *"tests/golden"* ]]
}
