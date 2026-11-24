# Muddie plugins

Plugins for Muddie, a MUD client.
Each folder here is one plugin for one MUD: its scripts, its rules, and a
profile template that uses it.

Muddie downloads the plugins by itself. It reads `plugins.zip` from the
latest release of this repository, so there is nothing to install by hand.
Español: [README.es.md](README.es.md).

## Contributing

A plugin is a folder at the top level with:

- `plugin.toml`: the name, a short description (`about`), the MUDs it is for
  (`hosts` and `names`), and `muddie`, the oldest Muddie version that can
  install it, as `X.Y.Z`.
- `rules.toml` and `template.toml`: the rules it sets up and the profile
  template for the MUD.
- one or more `*.luau` scripts.

Nothing else, and no folders inside the plugin folder. Before you open a
pull request, run:

```sh
python3 tools/check.py   # checks every plugin folder
python3 tools/pack.py    # builds plugins.zip in the repository root
```

Both need Python 3.11 or later. Commit messages follow
[Conventional Commits](https://www.conventionalcommits.org/).

## Releases

Releases are made by [release-please](https://github.com/googleapis/release-please-action).
Merging a commit to `main` updates a release pull request. Merging that pull
request creates the release and its tag, and CI uploads `plugins.zip` to it.

## Licence

Licensed under either of

- Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE))
- MIT license ([LICENSE-MIT](LICENSE-MIT))

at your option.
