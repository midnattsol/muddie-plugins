#!/usr/bin/env python3
"""Check that the scripts use the API of Muddie as it is.

The definitions of the API, tools/muddie.d.luau, are a copy of
docs/muddie.d.luau of Muddie: copy it again when the plugins ask for a newer
Muddie. luau-analyze, which takes no definitions, is given them before each
script, as local names.

Only what is of the API is told of: a function or a field there is not, a
value it does not take, a line compared with a text. The scripts need no type
annotations.

Usage: api.py [script.luau ...]   (default: every script of every plugin)
Needs luau-analyze in the PATH. Exits 1 with one line per problem.
"""

import re
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEFINITIONS = Path(__file__).resolve().parent / "muddie.d.luau"
TOLD = re.compile(
    r"Unknown global"
    r"|not found in table '(Gauges|Kind|Panels|Channels|Sounds?|Session|MapTable|Gmcp|Msdp|Mssp|Line|Made)'"
    r"|Cannot compare unrelated types 'Line'"
    r"|Expected this to be .*\"never\""
    r"|of table 'Session' is read-only"
    r"|SyntaxError"
)


def as_locals(definitions: str) -> str:
    """The definitions as code: each name declared, a local of its type."""
    text = re.sub(r"(?m)^declare function (\w+)\(", r"local \1: (", definitions)
    text = re.sub(
        r"(?m)^(local \w+: \(.*\)): (.+)$", r"\1 -> \2 = nil :: any", text
    )
    lines: list[str] = []
    declared = None
    for line in text.split("\n"):
        if declared is not None and line.startswith("    &"):
            declared += "\n" + line
            continue
        if declared is not None:
            lines.append(declared + " = nil :: any")
            declared = None
        match = re.match(r"declare (\w+): (.*)", line)
        if match:
            declared = f"local {match[1]}: {match[2]}"
        else:
            lines.append(line)
    if declared is not None:
        lines.append(declared + " = nil :: any")
    return "\n".join(lines)


def problems(script: Path, before: str) -> list[str]:
    shift = before.count("\n") + 1
    with tempfile.TemporaryDirectory() as folder:
        file = Path(folder) / "script.luau"
        file.write_text(before + "\n" + script.read_text(encoding="utf-8"), encoding="utf-8")
        done = subprocess.run(
            ["luau-analyze", "--mode=strict", str(file)],
            capture_output=True,
            text=True,
            check=False,
        )
    found = []
    for line in (done.stdout + done.stderr).splitlines():
        match = re.match(r".*script\.luau\((\d+),(\d+)\): (.*)", line)
        if match and TOLD.search(match[3]):
            row = int(match[1]) - shift
            where = f"{script}:{row}" if row > 0 else f"{DEFINITIONS} (line {match[1]} as locals)"
            found.append(f"{where}: {match[3]}")
    return found


def main() -> int:
    scripts = [Path(name) for name in sys.argv[1:]]
    if not scripts:
        scripts = sorted(ROOT.glob("*/*.luau"))
        scripts = [script for script in scripts if script.parent.name != "tools"]
    if not scripts:
        print("no scripts to check", file=sys.stderr)
        return 1
    before = as_locals(DEFINITIONS.read_text(encoding="utf-8"))
    try:
        found = [problem for script in scripts for problem in problems(script, before)]
    except FileNotFoundError:
        print("luau-analyze is not in the PATH", file=sys.stderr)
        return 1
    for problem in found:
        print(f"error: {problem}", file=sys.stderr)
    if found:
        return 1
    print(f"ok: {len(scripts)} script(s) checked against the API")
    return 0


if __name__ == "__main__":
    sys.exit(main())
