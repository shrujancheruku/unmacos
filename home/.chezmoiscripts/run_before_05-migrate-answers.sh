#!/bin/bash
# UnMacOS: move an Answers file in the old format (flat keys, personal = true) to the grouped one,
# keeping the original beside it as setup.toml.bak. Runs before everything else on every apply,
# without asking anything; an Answers file that is already grouped is left alone.
set -euo pipefail
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
answers="${UNMACOS_SETUP_FILE:-$HOME/.config/unmacos/setup.toml}"
[[ -f "$answers" ]] || exit 0
# the copy in the source folder: ~/.local/bin/unmacos-settings may not be installed yet
source_dir="${CHEZMOI_SOURCE_DIR:-$(chezmoi source-path)}"
/bin/bash "$source_dir/dot_local/bin/executable_unmacos-settings" migrate "$answers"
