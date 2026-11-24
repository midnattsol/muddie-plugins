#!/usr/bin/env python3
"""Build plugins.zip: one top-level folder per plugin.

Only plugin.toml, rules.toml, template.toml and *.luau files are packed.
Entries are sorted and carry a fixed timestamp and permissions, so the
same sources always give the same bytes. The plugins are checked first
with check.py, and nothing is written when a check fails.

Usage: pack.py [output.zip]   (default: plugins.zip in the repository root)
Exits 1 with a message on error. Standard library only.
"""

import sys
import zipfile
from pathlib import Path

sys.dont_write_bytecode = True  # keep tools/__pycache__ out of the repository
sys.path.insert(0, str(Path(__file__).resolve().parent))

import check  # noqa: E402

FIXED_TIME = (1980, 1, 1, 0, 0, 0)  # the earliest time a zip can hold
FILE_MODE = 0o644


def packed_files(folder: Path) -> list[Path]:
    names = ["plugin.toml", "rules.toml", "template.toml"]
    names += sorted(path.name for path in folder.glob("*.luau"))
    return [folder / name for name in names]


def main() -> int:
    if sys.version_info < (3, 11):
        print("pack.py needs Python 3.11 or later", file=sys.stderr)
        return 1

    root = Path(__file__).resolve().parent.parent
    output = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else root / "plugins.zip"

    folders, errors = check.check_plugins(root)
    if errors:
        for error in errors:
            print(f"error: {error}", file=sys.stderr)
        print("nothing packed: fix the problems above first", file=sys.stderr)
        return 1

    entries: list[tuple[str, Path]] = []
    for folder in folders:
        for path in packed_files(folder):
            entries.append((f"{folder.name}/{path.name}", path))
    entries.sort(key=lambda entry: entry[0])

    try:
        with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED) as archive:
            for arcname, path in entries:
                info = zipfile.ZipInfo(arcname, date_time=FIXED_TIME)
                info.compress_type = zipfile.ZIP_DEFLATED
                info.external_attr = FILE_MODE << 16
                archive.writestr(info, path.read_bytes(), compresslevel=9)
    except OSError as error:
        print(f"error: cannot write {output}: {error}", file=sys.stderr)
        return 1

    print(f"ok: wrote {output} with {len(entries)} file(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
