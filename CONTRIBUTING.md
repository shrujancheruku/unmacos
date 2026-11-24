# Contributing to UnMacOS

Thanks for helping. Bug reports, theme fixes and small improvements are all welcome.

## Reporting a bug

Run `unmacos-doctor` first: it often names the fix. If it doesn't, open an
[issue](https://github.com/shrujancheruku/unmacos/issues/new/choose) with its output, your macOS
version and your Mac model. For questions and ideas, use
[Discussions](https://github.com/shrujancheruku/unmacos/discussions).

## Making a change

1. Fork the repo and work on a branch.
2. UnMacOS is a [chezmoi](https://www.chezmoi.io/) repo rooted at `home/`. Edit the source files
   there, then run `chezmoi apply` (or `chezmoi diff` first) to try them on your Mac.
3. Check `unmacos-doctor` still says *All good*.
4. Open a pull request describing what changed and how you tested it. Screenshots or a short
   recording help for anything visual.

Commit messages and PR titles follow [Conventional Commits](https://www.conventionalcommits.org/):
`feat(theme): …`, `fix(rift): …`, `docs: …`. Releases follow [Semantic Versioning](https://semver.org/).

## Tests

CI runs the tests on macOS for every push and pull request. To run them locally:

```sh
brew install bats-core shellcheck chezmoi
bats tests/
```

The tests never touch your real home folder. Each test gets a temporary `$HOME` with the fixture
answers in `tests/fixtures/setup.toml`, then runs `chezmoi apply --dry-run` against this checkout.
`tests/test_helper.bash` documents the helpers to use in new tests. shellcheck covers every shipped
shell script; templated scripts are rendered with the fixture answers before they are checked. A
finding you cannot fix gets a `# shellcheck disable=… # reason` comment next to it.

## Themes

A theme is one `colors.toml` in `home/dot_local/share/unmacos/themes/<name>/`, in Omarchy's
format. Check it in both the picker preview and a full switch (`unmacos-theme-render <name>`).
The website's themes page is generated from these files, so it updates on its own.

## Website

The site lives in `site/`. See [site/README.md](site/README.md) to build and preview it.

## Licence

By contributing you agree your work is released under the [GPL-3.0](LICENSE).
