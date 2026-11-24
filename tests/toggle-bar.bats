#!/usr/bin/env bats
# unmacos-toggle-bar --sync: fits Rift's tiling area to the bar. Tested at its command line
# with sketchybar and rift-cli stubbed; the side gap comes from the rendered Rift config.

load test_helper

TOGGLE="$REPO_ROOT/home/dot_local/bin/executable_unmacos-toggle-bar"

setup() {
  unmacos_temp_home
  export UNMACOS_STATE="$BATS_TEST_TMPDIR/state"
  mkdir -p "$BATS_TEST_TMPDIR/bin" "$UNMACOS_STATE/theme"
  export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
  export STUB_LOG="$BATS_TEST_TMPDIR/rift.log"
}

# stubs HIDDEN INSET: a bar that is hidden (on/off) and a main display whose usable area
# starts INSET px down (32 under a notch, 0 elsewhere)
stubs() {
  cat > "$BATS_TEST_TMPDIR/bin/sketchybar" <<STUB
#!/bin/bash
[[ "\$1" == --query ]] && echo '{"hidden":"$1","height":44,"y_offset":0}'
exit 0
STUB
  cat > "$BATS_TEST_TMPDIR/bin/rift-cli" <<STUB
#!/bin/bash
if [[ "\$2" == displays ]]; then echo '[{"frame":{"origin":{"x":0,"y":$2}}}]'; else echo "\$*" >> "\$STUB_LOG"; fi
STUB
  chmod +x "$BATS_TEST_TMPDIR/bin/"*
}

# rendered_rift SIDE: a rendered Rift config whose outer gaps are SIDE
rendered_rift() {
  printf '[settings.layout.gaps.outer]\ntop = 99\nleft = %s\nbottom = %s\nright = %s\n' "$1" "$1" "$1" > "$UNMACOS_STATE/theme/rift.toml"
}

@test "toggle-bar --sync: top gap fits the bar on an un-notched display, sides from the rendered config" {
  stubs off 0
  rendered_rift 5
  run bash "$TOGGLE" --sync
  [ "$status" -eq 0 ]
  # chips end at 0 + (44 + 30) / 2 = 37, plus the side gap 5
  [ "$(cat "$STUB_LOG")" = "execute config set-outer-gaps 42 5 5 5" ]
}

@test "toggle-bar --sync: a notched display's reserved 32px comes off the top gap" {
  stubs off 32
  rendered_rift 5
  run bash "$TOGGLE" --sync
  [ "$status" -eq 0 ]
  [ "$(cat "$STUB_LOG")" = "execute config set-outer-gaps 10 5 5 5" ]
}

@test "toggle-bar --sync: with the bar hidden the top gap is just the side gap" {
  stubs on 0
  rendered_rift 7
  run bash "$TOGGLE" --sync
  [ "$status" -eq 0 ]
  [ "$(cat "$STUB_LOG")" = "execute config set-outer-gaps 7 7 7 7" ]
}

@test "toggle-bar --sync: with no rendered config it falls back to gap 4 + border 6" {
  stubs on 0
  run bash "$TOGGLE" --sync
  [ "$status" -eq 0 ]
  [ "$(cat "$STUB_LOG")" = "execute config set-outer-gaps 10 10 10 10" ]
}
