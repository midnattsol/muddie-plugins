# Muddie plugins

Plugins for Muddie, a MUD client.
Each folder here is one plugin for one MUD: its scripts, its rules, and a
profile template that uses it.

Muddie downloads the plugins by itself. It reads `plugins.zip` from the
latest release of this repository, so there is nothing to install by hand.
Español: [README.es.md](README.es.md).

## Reinos de Leyenda

Its gauges, channels in tabs and map, over GMCP (type `consentir gmcp on` in
the game). Besides, to play by ear, each part in its own script, which can
be switched off alone in the editor:

- **Ways of playing** (`modes.luau`): original, combat, experience and idle,
  each reading more or less of the game. Changed with `modo` (the next),
  `modo xp`, `modo?`, or from the palette. `silencio`
  stops reading the game and reads it again.
- **Lists** (`history.luau`): what was said in the room (`hsala`), the tells
  (`htels`) and what happens in a fight (`heventos`), to go through and copy
  one. `r text` replies by telepathy to the last who told you; `rt` chooses
  whom.
- **Life** (`life.luau`): how much you lose or gain, warnings under half,
  30 % and 10 %, and the last changes (`hvida`). A hit of more than 200
  leaves the experience mode.
- **Who comes and goes** (`movement.luau`), said short and kept (`hmov`), and
  a target: the first of your `nick x`, or `obj name`; told when it is in the
  room.
- **Corrector** (`corrector.luau`): what other players write is read without
  annoying signs nor the race after the name, without changing what is shown.
- **Keys as in VipMud** (`keys.luau`), off until you switch them on with
  `teclasrl` or from the palette: Alt with u, i, o, j, k, l, 7, 8, 9, m,
  comma and period to walk (on the map too), Alt+1 and Alt+2 life and energy,
  F2 to F5 the last of each list and with Shift the list, F11 the mode and F12
  quiet.

## Contributing

How to make a plugin, step by step, and how to have an AI help:
[plugins.md](https://github.com/midnattsol/muddie/blob/main/docs/plugins.md),
with every function in
[scripting.md](https://github.com/midnattsol/muddie/blob/main/docs/scripting.md).


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
python3 tools/api.py     # checks the use of the API of Muddie, with luau-analyze
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
