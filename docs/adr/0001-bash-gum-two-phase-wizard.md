# The setup wizard is bash 3.2 + gum, in two phases

`install.sh` runs the wizard on a fresh Mac before Homebrew's bash or any desktop app exists, so the wizard is written for macOS's own bash 3.2 with gum and reads the Settings schema through `chezmoi execute-template`. Because nothing is installed yet, it runs in two phases: the Install phase (who you are, which Features, which Theme) before `chezmoi apply`, and the Tune phase (the Look, previewed live) on the installed desktop.

## Considered Options

- A compiled or Python TUI: richer forms and per-keystroke preview, but a dependency that has to exist before Homebrew does.
- One phase with a mock preview: works before install, but shows something other than the real desktop.
