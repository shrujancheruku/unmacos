#!/usr/bin/env bats
# Updating a Mac that was set up before the Settings schema: its chezmoi config still holds the
# old flat data (name, theme, [data.keep]) and its Answers file the old flat keys.
#
# The source is a throwaway git repo: its first commit is this checkout with the old config
# template (tests/fixtures/chezmoi.toml.tmpl-before-settings-schema, the one at 3ebf572), the
# second is this checkout as it is. chezmoi inits at the first, then updates to the second.
# Nothing is applied for real: a chezmoi shim first on PATH turns every apply into a dry run.

load test_helper

setup() {
  unmacos_temp_home
  export GIT_CONFIG_GLOBAL="$BATS_TEST_TMPDIR/no-gitconfig"
  BIN="$HOME/.local/bin"
  mkdir -p "$BIN"
  # the wizard puts ~/.local/bin first on PATH, so the shims go there
  printf '#!/bin/sh\necho stub-op-secret\n' > "$BIN/op"
  cat > "$BIN/chezmoi" <<SH
#!/bin/bash
# chezmoi, never applying for real: apply and update are dry runs; init --apply is init, then a
# dry-run apply
real="$(command -v chezmoi)"
case "\$1" in
  init) a=(); for x in "\$@"; do [[ "\$x" == --apply ]] || a+=("\$x"); done
        [[ " \$* " == *" --apply "* ]] || exec "\$real" "\$@"
        "\$real" "\${a[@]}" && exec "\$real" apply --dry-run --no-tty ;;
  apply|update) exec "\$real" "\$@" --dry-run ;;
  *) exec "\$real" "\$@" ;;
esac
SH
  chmod +x "$BIN/op" "$BIN/chezmoi"
  export PATH="$BIN:$PATH"
  make_source_before_and_after
  SRC="$HOME/.local/share/chezmoi"
  git clone -q "$BATS_TEST_TMPDIR/origin" "$SRC"
  git -C "$SRC" reset -q --hard HEAD~1
  # set up as it was before the Settings schema
  unmacos_write_answers "$REPO_ROOT/tests/fixtures/answers-today.toml"
  chezmoi init --no-tty < /dev/null
  [ "$(chezmoi execute-template '{{ .theme }}')" = nord ]
}

# make_source_before_and_after: $BATS_TEST_TMPDIR/origin, with the two commits described above
make_source_before_and_after() {
  local o="$BATS_TEST_TMPDIR/origin" blob
  git init -q -b main "$o"
  g() { GIT_DIR="$o/.git" GIT_WORK_TREE="$REPO_ROOT" git -c user.name=t -c user.email=t@example.invalid "$@"; }
  g add -A
  blob="$(g hash-object -w "$REPO_ROOT/tests/fixtures/chezmoi.toml.tmpl-before-settings-schema")"
  g update-index --cacheinfo "100644,$blob,home/.chezmoi.toml.tmpl"
  g commit -q -m before
  g add -A
  g commit -q -m after
  g reset -q   # the index matches the second commit
}

menu() { /bin/bash "$REPO_ROOT/home/dot_local/bin/executable_unmacos-menu" "$@"; }

@test "the menu's Update brings a Mac set up before the Settings schema up to date, without asking" {
  run menu update < /dev/null
  echo "$output"
  [ "$status" -eq 0 ]
  [ "$(git -C "$SRC" log -1 --format=%s)" = after ]
  # the config was made again from the new template, and the Answers were migrated
  [ "$(chezmoi execute-template '{{ .look.theme }}/{{ .git.name }}/{{ .look.corner_radius }}')" = "nord/Test User/4" ]
  cmp "$REPO_ROOT/tests/fixtures/answers-today.toml" "$HOME/.config/unmacos/setup.toml.bak"
  ! grep -q '^theme' "$HOME/.config/unmacos/setup.toml"
  # and everything renders
  run chezmoi apply --no-tty < /dev/null
  echo "$output"
  [ "$status" -eq 0 ]
}

@test "plain chezmoi apply after pulling says to run unmacos-setup --yes" {
  chezmoi git pull -- --ff-only -q
  run chezmoi apply --no-tty < /dev/null
  echo "$output"
  [ "$status" -ne 0 ]
  [[ "$output" == *"unmacos-setup --yes"* ]]
  [[ "$output" != *"map has no entry"* ]]
}

@test "plain chezmoi update says to run unmacos-setup --yes" {
  run chezmoi update --no-tty < /dev/null
  echo "$output"
  [ "$status" -ne 0 ]
  [[ "$output" == *"unmacos-setup --yes"* ]]
}
