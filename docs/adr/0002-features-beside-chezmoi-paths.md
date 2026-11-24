# A Feature is a folder beside chezmoi's paths, gated by .chezmoiignore

Each Feature lives in `home/dot_local/share/unmacos/features/<name>/` (manifest, hooks, templates), while the dotfiles it owns stay at their normal chezmoi source paths. The manifest lists those paths and `.chezmoiignore` leaves out the files of Features that aren't picked. chezmoi needs files at their target-derived paths, so a fully self-contained Feature folder would mean fighting chezmoi (symlinks, `.chezmoiexternal`, or a second copy step); the manifest gives one place to read a Feature without that.

## Consequences

- Turning a Feature off stops chezmoi managing its files but doesn't delete them; the Feature's `undo.sh` reverts what it changed, and brew packages are never uninstalled automatically.
