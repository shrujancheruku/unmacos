#!/usr/bin/env bats
# Proves the harness: today's source applies (dry-run) with a fixture Answers file.

load test_helper

setup() {
  unmacos_temp_home
  unmacos_write_answers
  unmacos_chezmoi_init
}

@test "today's source applies in dry-run with a fixture Answers file" {
  run unmacos_chezmoi_dry_run
  [ "$status" -eq 0 ]
  [[ "$output" == *".config/unmacos/prefs.sh"* ]]
}

@test "fixture Answers reach the rendered files" {
  run unmacos_chezmoi_dry_run
  [ "$status" -eq 0 ]
  [[ "$output" == *"Test User"* ]]
}
