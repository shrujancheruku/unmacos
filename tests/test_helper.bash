# Shared helpers for the bats tests. Load with `load test_helper` at the top of a .bats file.
#
# Every test gets a throwaway $HOME under BATS_TEST_TMPDIR, so chezmoi and the UnMacOS
# scripts never read or write the real home folder. Nothing here runs `chezmoi apply`
# for real: tests use --dry-run only.
#
# Functions:
#   unmacos_temp_home        point HOME and the XDG_* folders at a fresh temp home
#   unmacos_write_answers    copy tests/fixtures/setup.toml to ~/.config/unmacos/setup.toml
#                            (pass a path to write a different Answers file)
#   unmacos_chezmoi          run chezmoi against this checkout, into the temp home
#   unmacos_chezmoi_init     generate chezmoi's config from the checkout (never prompts:
#                            name, email and 1Password come from the Answers file)
#   unmacos_chezmoi_dry_run  `chezmoi apply --dry-run --verbose`; prints the would-be changes
#   unmacos_shipped_scripts  list every shipped shell script, relative to the repo root
#   unmacos_shellcheck_shipped
#                            shellcheck every shipped script; templated ones are rendered
#                            with the fixture Answers first

REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
export REPO_ROOT

unmacos_temp_home() {
  export HOME="$BATS_TEST_TMPDIR/home"
  export XDG_CONFIG_HOME="$HOME/.config"
  export XDG_CACHE_HOME="$HOME/.cache"
  export XDG_DATA_HOME="$HOME/.local/share"
  export XDG_STATE_HOME="$HOME/.local/state"
  mkdir -p "$HOME"
}

unmacos_write_answers() {
  local src="${1:-$REPO_ROOT/tests/fixtures/setup.toml}"
  mkdir -p "$HOME/.config/unmacos"
  cp "$src" "$HOME/.config/unmacos/setup.toml"
}

unmacos_chezmoi() {
  chezmoi --source "$REPO_ROOT" --destination "$HOME" --no-tty --no-pager "$@"
}

unmacos_chezmoi_init() {
  unmacos_chezmoi init
}

unmacos_chezmoi_dry_run() {
  unmacos_chezmoi apply --dry-run --verbose
}

unmacos_shipped_scripts() {
  local f
  cd "$REPO_ROOT" || return 1
  find home install.sh -type f | sort | while IFS= read -r f; do
    case "$f" in
      *.sh | *.sh.tmpl)
        printf '%s\n' "$f"
        ;;
      *)
        if head -n 1 "$f" | grep -qE '^#!.*(sh|bash)'; then
          printf '%s\n' "$f"
        fi
        ;;
    esac
  done
}

unmacos_shellcheck_shipped() {
  local tmp f out
  local files=()
  tmp="$(mktemp -d "$BATS_TEST_TMPDIR/rendered.XXXXXX")" || return 1
  while IFS= read -r f; do
    if [[ "$f" == *.tmpl ]]; then
      out="$tmp/${f%.tmpl}"
      mkdir -p "$(dirname "$out")"
      unmacos_chezmoi execute-template < "$REPO_ROOT/$f" > "$out" || return 1
      files+=("$out")
    else
      files+=("$REPO_ROOT/$f")
    fi
  done < <(unmacos_shipped_scripts)
  shellcheck -x "${files[@]}"
}

# unmacos_templated_sources: every templated source file (relative to the repo root) except
# chezmoi's own config template, which is covered by `chezmoi init`.
unmacos_templated_sources() {
  (cd "$REPO_ROOT" && find home -type f -name '*.tmpl' ! -path 'home/.chezmoi.toml.tmpl' | sort)
}

# unmacos_render_templated: what chezmoi would put on disk for every templated source, one
# "=== <target>" header then its contents. Scripts are included (never run). Content hashes
# (of themes, Brewfiles) and the temp $HOME are blanked so the golden file stays stable. Needs
# unmacos_chezmoi_init first, so the Answers are already merged.
unmacos_render_templated() {
  local src target
  while IFS= read -r src; do
    target="$(unmacos_chezmoi target-path "$REPO_ROOT/$src")" || return 1
    printf '=== %s\n' "${target#"$HOME"/}"
    unmacos_chezmoi cat "$target" | sed -E -e 's/[0-9a-f]{12,64}/<hash>/g' -e "s|$HOME|<home>|g" || return 1
    printf '\n'
  done < <(unmacos_templated_sources)
}

# unmacos_stub_op: put a fake 1Password CLI first on PATH, so templates that read a secret
# render without 1Password installed.
unmacos_stub_op() {
  mkdir -p "$BATS_TEST_TMPDIR/stubs"
  printf '#!/bin/sh\necho stub-op-secret\n' > "$BATS_TEST_TMPDIR/stubs/op"
  chmod +x "$BATS_TEST_TMPDIR/stubs/op"
  export PATH="$BATS_TEST_TMPDIR/stubs:$PATH"
}
