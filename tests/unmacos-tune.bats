#!/usr/bin/env bats
# unmacos-tune: the Tune phase. Tested at its command line with a scripted fake gum, on a copy of
# the source whose schema has extra tune-phase Settings. Reloads are off (UNMACOS_NO_RELOAD=1).

load test_helper

BIN="$REPO_ROOT/home/dot_local/bin"

tune() { /bin/bash "$BIN/executable_unmacos-tune" "$@"; }
look() { /bin/bash "$BIN/executable_unmacos-look" "$@"; }
saved() { /bin/bash "$BIN/executable_unmacos-settings" get "$1"; }

setup() {
  unmacos_temp_home
  export GIT_CONFIG_GLOBAL="$BATS_TEST_TMPDIR/no-gitconfig"
  export UNMACOS_SETTINGS="$BIN/executable_unmacos-settings"
  export UNMACOS_LOOK="$BIN/executable_unmacos-look"
  export UNMACOS_STATE="$BATS_TEST_TMPDIR/state"
  export UNMACOS_NO_RELOAD=1
  export UNMACOS_SHARE="$REPO_ROOT/home/dot_local/share/unmacos"
  export UNMACOS_CHEZMOI="$BATS_TEST_TMPDIR/chezmoi-log"
  unmacos_write_answers
  fixture_source
  stub_gum
  # a Look to be in place before Tune starts
  look render "$UNMACOS_STATE/theme" >/dev/null
}

# fixture_source: a copy of the source whose schema has more Settings: two live tune-phase ones in
# the look group, one live look Setting asked at install, one look Setting that needs its apps
# restarted, one install-phase Setting outside the Look and one live tune-phase Setting outside it. Tune lists all but the install-phase one outside
# the Look (it edits the whole Look, and every tune-phase Setting).
fixture_source() {
  local src="$BATS_TEST_TMPDIR/source"
  mkdir -p "$src"
  (cd "$REPO_ROOT" && git ls-files -co --exclude-standard | tar -cf - -T - ) | tar -xf - -C "$src"
  cat >> "$src/home/.chezmoidata/settings.toml" <<'TOML'

[[settings]]
group = "look"
key = "fixture_glow"
type = "int"
default = 4
min = 0
max = 20
label = "Fixture glow"
help = "A live Look Setting only the test knows."
phase = "tune"
takes_effect = "live"

[[settings]]
group = "look"
key = "fixture_frame"
type = "enum"
default = "thin"
choices = ["thin", "thick", "none"]
label = "Fixture frame"
help = "A live enum only the test knows."
phase = "tune"
takes_effect = "live"

[[settings]]
group = "look"
key = "fixture_tint"
type = "enum"
default = "cool"
choices = ["cool", "warm"]
label = "Fixture tint"
help = "A look Setting asked at install, still part of the Look."
phase = "install"
takes_effect = "live"

[[settings]]
group = "look"
key = "fixture_shadow"
type = "int"
default = 2
min = 0
max = 8
label = "Fixture shadow"
help = "A look Setting its apps pick up when they restart."
phase = "tune"
takes_effect = "restart:apps"

[[settings]]
group = "fixture"
key = "volume"
type = "int"
default = 5
min = 1
max = 11
label = "Fixture volume"
help = "An install-phase Setting outside the Look."
phase = "install"
takes_effect = "apply"

[[settings]]
group = "fixture"
key = "lights"
type = "int"
default = 3
min = 0
max = 9
label = "Fixture lights"
help = "A live tune-phase Setting outside the Look: it can't be a Draft Look."
phase = "tune"
takes_effect = "live"
TOML
  mkdir -p "$HOME/.local/share"
  ln -sfn "$src" "$HOME/.local/share/chezmoi"
  chezmoi --source "$src" --destination "$HOME" --no-tty --no-pager init
}

# stub_gum: a fake gum, as in unmacos-setup.bats. `gum style` echoes its text; every other command
# logs its arguments and the lines it was fed to $GUM_LOG and takes its next scripted reply from
# $GUM_REPLIES: one "STATUS|OUTPUT" per line (OUTPUT may contain \n).
stub_gum() {
  mkdir -p "$HOME/.local/bin"
  cat > "$HOME/.local/bin/gum" <<'STUB'
#!/bin/bash
cmd="$1"; shift
if [[ "$cmd" == style ]]; then
  while [[ $# -gt 0 ]]; do
    case "$1" in --border|--border-foreground|--padding|--margin|--foreground) shift 2 ;; --faint|--bold) shift ;; *) echo "$1"; shift ;; esac
  done
  exit 0
fi
echo "gum $cmd $*" >> "$GUM_LOG"
if [[ "$*" == *"is on your desktop"* ]]; then
  # what the desktop shows at the moment the user is asked to keep it
  cp "$UNMACOS_STATE/draft.toml" "$GUM_LOG.draft" 2>/dev/null || true
  # Ctrl-C at that prompt: the script and gum both get SIGINT
  if [[ -n "${GUM_INT:-}" ]]; then pkill -INT -f "$REPO_ROOT/home/dot_local/bin/executable_unmacos-tune"; sleep 1; exit 130; fi
  # GUM_HANG=<file>: gum ignores SIGHUP, as the real one does on a dead terminal; it writes its pid
  # to <file> and waits on this prompt
  if [[ -n "${GUM_HANG:-}" ]]; then trap '' HUP; echo $$ > "$GUM_HANG"; exec sleep 300; fi
fi
[[ "$cmd" == choose ]] && sed 's/^/  | /' >> "$GUM_LOG"
line="$(head -n 1 "$GUM_REPLIES")"
sed -i '' 1d "$GUM_REPLIES"
[[ -n "$line" ]] || { echo "no scripted reply for: gum $cmd $*" >&2; exit 99; }
printf '%b\n' "${line#*|}"
exit "${line%%|*}"
STUB
  chmod +x "$HOME/.local/bin/gum"
  export GUM_LOG="$BATS_TEST_TMPDIR/gum.log" GUM_REPLIES="$BATS_TEST_TMPDIR/replies"
  : > "$GUM_LOG"
  export UNMACOS_SETUP_UI=1 REPO_ROOT
}

replies() { printf '%s\n' "$@" > "$GUM_REPLIES"; }
draft_file() { echo "$UNMACOS_STATE/draft.toml"; }
# the rendered Look, byte for byte
snapshot() { (cd "$UNMACOS_STATE/theme" && find . -type f | sort | xargs shasum); }

@test "every tune-phase Setting in the schema is listed, by group, with no Tune code naming one" {
  replies '130|'
  run tune
  [ "$status" -eq 0 ]
  # the real ones and the fixtures, from the schema alone
  grep -q 'look · Corner radius: 8$' "$GUM_LOG"
  grep -q 'look · Animate windows into place: true$' "$GUM_LOG"
  grep -q 'look · Fixture shadow: 2  \[after restart\]' "$GUM_LOG"
  grep -q 'look · Fixture glow: 4$' "$GUM_LOG"
  grep -q 'look · Fixture frame: thin$' "$GUM_LOG"
  grep -q 'desktop · Dock size: 64  \[after logout\]' "$GUM_LOG"
  # the Look is all of group look, whatever the phase: the Theme and an install-phase look Setting
  grep -q 'look · Theme: ' "$GUM_LOG"
  grep -q 'look · Fixture tint: cool$' "$GUM_LOG"
  # an install-phase Setting outside the Look is not listed
  ! grep -q 'Fixture volume' "$GUM_LOG"
  ! grep -nE 'corner_radius|dock_size|fixture_|look\.theme' "$BIN/executable_unmacos-tune"
}

@test "picking a value applies a Draft Look at once, and Keep then Save makes it the Look" {
  # Fixture glow → 10, keep, then Save
  replies '0|look · Fixture glow: 4' '0|10' '0|Keep' '0|Save'
  run tune
  echo "$output"
  [ "$status" -eq 0 ]
  [ "$(saved look.fixture_glow)" = 10 ]
  [ ! -e "$(draft_file)" ]
  [[ "$output" == *"Saved"* ]]
}

@test "the Draft Look is on the desktop while the user decides" {
  replies '0|look · Fixture glow: 4' '0|10' '0|Keep' '130|'
  run tune
  [ "$status" -eq 0 ]
  grep -q 'fixture_glow = 10' "$GUM_LOG.draft"
}

@test "Esc after a preview leaves the saved Look and Answers as they were" {
  before="$(snapshot)"; answers="$(cat "$HOME/.config/unmacos/setup.toml")"
  replies '0|look · Fixture glow: 4' '0|10' '130|'
  run tune
  [ "$status" -eq 0 ]
  [[ "$output" == *"Nothing changed"* ]]
  [ ! -e "$(draft_file)" ]
  [ "$(snapshot)" = "$before" ]
  [ "$(cat "$HOME/.config/unmacos/setup.toml")" = "$answers" ]
  [ "$(saved look.fixture_glow)" = 4 ]
}

@test "Ctrl-C while a Draft Look is applied discards it" {
  before="$(snapshot)"
  export GUM_INT=1
  replies '0|look · Fixture glow: 4' '0|10'
  run tune
  # a real Ctrl-C ends it as cancelled (0) or interrupted (130); either way nothing is kept
  [ "$status" -eq 0 ] || [ "$status" -eq 130 ]
  grep -q 'fixture_glow = 10' "$GUM_LOG.draft"
  [ ! -e "$(draft_file)" ]
  [ "$(snapshot)" = "$before" ]
  [ "$(saved look.fixture_glow)" = 4 ]
}

# alive PID: running, not a zombie waiting for bats to reap it
alive() { local s; s="$(ps -o stat= -p "$1" 2>/dev/null)"; [[ -n "$s" && "$s" != Z* ]]; }

@test "a hangup while a preview is showing discards the Draft Look and leaves no Tune or gum running" {
  before="$(snapshot)"
  export GUM_HANG="$BATS_TEST_TMPDIR/gum.pid"
  replies '0|look · Fixture glow: 4' '0|10'
  # Tune in its own process group, as in a terminal: the hangup goes to the whole group
  set -m
  tune >/dev/null 2>&1 &
  pid=$!
  set +m
  for _ in $(seq 1 100); do [[ -s "$GUM_HANG" ]] && break; sleep 0.1; done
  [ -s "$GUM_HANG" ]
  gpid="$(cat "$GUM_HANG")"
  [ -e "$(draft_file)" ]
  # the terminal closes (tmux kill-session sends SIGHUP to the pane's process group)
  kill -HUP -- -"$pid"
  gone=0
  for _ in $(seq 1 100); do
    if ! alive "$pid" && ! alive "$gpid"; then gone=1; break; fi
    sleep 0.1
  done
  # never leave a stray gum behind, even when the check above fails
  alive "$gpid" && kill -KILL "$gpid" 2>/dev/null || true
  [ "$gone" = 1 ]
  [ ! -e "$(draft_file)" ]
  [ "$(snapshot)" = "$before" ]
  [ "$(saved look.fixture_glow)" = 4 ]
}

@test "Back after a preview puts the desktop back, and Discard keeps nothing" {
  before="$(snapshot)"
  replies '0|look · Fixture frame: thin' '0|thick' '0|Back' '0|Discard'
  run tune
  [ "$status" -eq 0 ]
  [[ "$output" == *"Nothing changed"* ]]
  [ ! -e "$(draft_file)" ]
  [ "$(snapshot)" = "$before" ]
  [ "$(saved look.fixture_frame)" = thin ]
}

@test "Try another replaces the preview; custom… takes a number in range" {
  replies '0|look · Fixture glow: 4' '0|10' '0|Try another' '0|custom…' '0|99' '0|7' '0|Keep' '0|Save'
  run tune
  echo "$output"
  [ "$status" -eq 0 ]
  [ "$(saved look.fixture_glow)" = 7 ]
  [[ "$output" == *"Enter a whole number from 0 to 20"* ]]
}

@test "the Theme is listed with its choices; picking one drafts look.theme, and Esc restores the Look" {
  before="$(snapshot)"
  current="$(saved look.theme)"
  replies "0|look · Theme: $current" '0|nord' '130|'
  run tune
  [ "$status" -eq 0 ]
  [[ "$output" == *"Nothing changed"* ]]
  # nord was on the desktop at the Keep prompt, and every Theme was offered
  grep -q 'theme = "nord"' "$GUM_LOG.draft"
  grep -q '  | gruvbox' "$GUM_LOG"
  # Esc: the saved Theme and its render are back, byte for byte
  [ ! -e "$(draft_file)" ]
  [ "$(snapshot)" = "$before" ]
  [ "$(saved look.theme)" = "$current" ]
}

@test "the Theme row shows the live Theme, and Back returns the desktop to it" {
  # the theme menu switched to gruvbox; the Answers still name another Theme
  echo gruvbox > "$UNMACOS_STATE/theme.name"
  look render "$UNMACOS_STATE/theme" >/dev/null
  before="$(snapshot)"
  replies '0|look · Theme: gruvbox' '0|nord' '0|Back' '0|Discard'
  run tune
  echo "$output"
  [ "$status" -eq 0 ]
  grep -q '  | look · Theme: gruvbox' "$GUM_LOG"
  [ "$(cat "$UNMACOS_STATE/theme/theme.name")" = gruvbox ]
  [ "$(snapshot)" = "$before" ]
}

@test "an install-phase look Setting is tuned like any other" {
  replies '0|look · Fixture tint: cool' '0|warm' '0|Keep' '0|Save'
  run tune
  [ "$status" -eq 0 ]
  [ "$(saved look.fixture_tint)" = warm ]
}

@test "a true/false Setting marks its default among on and off" {
  replies '0|look · Animate windows into place: true' '0|off' '0|Keep' '0|Discard'
  run tune
  [ "$status" -eq 0 ]
  grep -q '  | on (default)$' "$GUM_LOG"
  grep -q '  | off$' "$GUM_LOG"
}

@test "an enum offers its choices" {
  replies '0|look · Fixture frame: thin' '0|none' '0|Keep' '0|Save'
  run tune
  [ "$status" -eq 0 ]
  grep -q '  | thick' "$GUM_LOG"
  [ "$(saved look.fixture_frame)" = none ]
}

# stub_chezmoi: UNMACOS_CHEZMOI logs how it was run to $UNMACOS_CHEZMOI.out
stub_chezmoi() {
  printf '#!/bin/sh\necho "chezmoi $*" >> "%s.out"\n' "$UNMACOS_CHEZMOI" > "$UNMACOS_CHEZMOI"
  chmod +x "$UNMACOS_CHEZMOI"
}

@test "a Setting that isn't live shows its badge, is not previewed, and applies on Save" {
  stub_chezmoi
  # fixture shadow is restart:apps: no Keep prompt, no draft until Save
  replies '0|look · Fixture shadow: 2  [after restart]' '0|6' '0|Save'
  run tune
  echo "$output"
  [ "$status" -eq 0 ]
  ! grep -q 'is on your desktop' "$GUM_LOG"
  [[ "$output" == *"applies when you save (after restart)"* ]]
  [ "$(saved look.fixture_shadow)" = 6 ]
  # whatever isn't live also needs what chezmoi apply writes
  grep -q 'init --apply' "$UNMACOS_CHEZMOI.out"
}

@test "corner radius is previewed as a Draft Look, and Save also runs chezmoi apply for the window corners" {
  stub_chezmoi
  replies '0|look · Corner radius: 8' '0|12' '0|Keep' '0|Save'
  run tune
  echo "$output"
  [ "$status" -eq 0 ]
  grep -q 'corner_radius = 12' "$GUM_LOG.draft"
  [ "$(saved look.corner_radius)" = 12 ]
  # macOS's own window corners are written by chezmoi apply (NSConvolutionOverride)
  grep -q 'init --apply' "$UNMACOS_CHEZMOI.out"
}

@test "a live Look Setting with nothing to apply saves without chezmoi apply" {
  stub_chezmoi
  replies '0|look · Fixture glow: 4' '0|10' '0|Keep' '0|Save'
  run tune
  [ "$status" -eq 0 ]
  [ ! -e "$UNMACOS_CHEZMOI.out" ]
}

@test "a non-live Setting picked and then Esc is not saved" {
  answers="$(cat "$HOME/.config/unmacos/setup.toml")"
  replies '0|look · Fixture shadow: 2  [after restart]' '0|6' '130|'
  run tune
  [ "$status" -eq 0 ]
  [ "$(cat "$HOME/.config/unmacos/setup.toml")" = "$answers" ]
  [ ! -e "$(draft_file)" ]
}

@test "a Setting outside the Look is written to the Answers on Save and applied by chezmoi" {
  stub_chezmoi
  replies '0|desktop · Dock size: 64  [after logout]' '0|32' '0|Save'
  run tune
  echo "$output"
  [ "$status" -eq 0 ]
  [ "$(saved desktop.dock_size)" = 32 ]
  grep -q 'init --apply' "$UNMACOS_CHEZMOI.out"
}

@test "a live Setting outside the Look shows its badge, is not drafted, and is saved on Save" {
  stub_chezmoi
  before="$(snapshot)"
  replies '0|fixture · Fixture lights: 3  [on save]' '0|7' '0|Save'
  run tune
  echo "$output"
  [ "$status" -eq 0 ]
  grep -q 'fixture · Fixture lights: 3  \[on save\]' "$GUM_LOG"
  # not previewed: no Keep prompt, no Draft Look, the rendered Look untouched until chezmoi applies
  ! grep -q 'is on your desktop' "$GUM_LOG"
  [ ! -e "$GUM_LOG.draft" ]
  [ ! -e "$(draft_file)" ]
  [ "$(snapshot)" = "$before" ]
  [[ "$output" == *"Fixture lights = 7: applies when you save."* ]]
  [[ "$output" != *"()"* ]]
  [ "$(saved fixture.lights)" = 7 ]
  grep -q 'init --apply' "$UNMACOS_CHEZMOI.out"
}

@test "a live Setting outside the Look picked and then Discard is not saved" {
  answers="$(cat "$HOME/.config/unmacos/setup.toml")"
  replies '0|fixture · Fixture lights: 3  [on save]' '0|7' '0|Discard'
  run tune
  echo "$output"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Nothing changed"* ]]
  [ "$(cat "$HOME/.config/unmacos/setup.toml")" = "$answers" ]
  [ ! -e "$(draft_file)" ]
  [ "$(saved fixture.lights)" = 3 ]
}

@test "a Draft Look left behind by an earlier session is not saved by this one" {
  stub_chezmoi
  look draft set look.fixture_glow=15 >/dev/null
  replies '0|look · Fixture shadow: 2  [after restart]' '0|6' '0|Save'
  run tune
  [ "$status" -eq 0 ]
  [ "$(saved look.fixture_glow)" = 4 ]
  [ "$(saved look.fixture_shadow)" = 6 ]
}

@test "runs under /bin/bash 3.2 with no bashisms past it" {
  /bin/bash -n "$BIN/executable_unmacos-tune"
}

@test "the main menu has a Tune entry that runs unmacos-tune" {
  grep -q 'tune\\tTune the Look' "$REPO_ROOT/home/dot_config/television/cable/unmacos-main.toml"
  grep -qE '^    tune\)' "$BIN/executable_unmacos-menu"
  sed -n '/^    tune)/,/;;/p' "$BIN/executable_unmacos-menu" | grep -q 'unmacos-tune'
}
