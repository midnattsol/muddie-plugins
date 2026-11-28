#!/usr/bin/env python3
"""Check every plugin folder of this repository.

A plugin folder is a top-level directory that is not hidden and not
`tools`. Each must hold only plugin.toml, rules.toml, template.toml and
at least one .luau script, with no folders inside it. Exits 1 with one
line per problem when anything is wrong, 0 otherwise.

Needs Python 3.11 or later (tomllib). Standard library only.
"""

import re
import sys
import tomllib
from pathlib import Path

REQUIRED = ("plugin.toml", "rules.toml", "template.toml")
VERSION = re.compile(r"^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$")
NON_PLUGIN_DIRS = {"tools"}


def plugin_folders(root: Path) -> list[Path]:
    return sorted(
        path
        for path in root.iterdir()
        if path.is_dir()
        and not path.name.startswith(".")
        and path.name not in NON_PLUGIN_DIRS
    )


def load_toml(path: Path, errors: list[str]) -> dict | None:
    try:
        with path.open("rb") as file:
            return tomllib.load(file)
    except (tomllib.TOMLDecodeError, OSError) as error:
        errors.append(f"{path}: does not parse: {error}")
        return None


def non_empty_text(value: object) -> bool:
    return isinstance(value, str) and value.strip() != ""


def check_manifest(path: Path, errors: list[str]) -> None:
    manifest = load_toml(path, errors)
    if manifest is None:
        return

    if not non_empty_text(manifest.get("name")):
        errors.append(f"{path}: 'name' must be a non-empty string")

    about = manifest.get("about")
    about_ok = non_empty_text(about) or (
        isinstance(about, dict)
        and len(about) > 0
        and all(non_empty_text(text) for text in about.values())
    )
    if not about_ok:
        errors.append(
            f"{path}: 'about' must be a non-empty string or a table of strings"
        )

    hosts = manifest.get("hosts")
    names = manifest.get("names")
    hosts_ok = isinstance(hosts, list) and len(hosts) > 0
    names_ok = isinstance(names, list) and len(names) > 0
    if not (hosts_ok or names_ok):
        errors.append(f"{path}: needs 'hosts' or 'names' as a non-empty list")
    for key, values in (("hosts", hosts), ("names", names)):
        if values is not None and not (
            isinstance(values, list) and all(non_empty_text(v) for v in values)
        ):
            errors.append(f"{path}: '{key}' must be a list of non-empty strings")

    sounds = manifest.get("sounds")
    if sounds is not None and not (
        isinstance(sounds, str) and sounds.startswith("https://")
    ):
        errors.append(f"{path}: 'sounds' must be the https address of a folder")

    muddie = manifest.get("muddie")
    if not isinstance(muddie, str) or not VERSION.match(muddie):
        errors.append(f"{path}: 'muddie' must be a version X.Y.Z, got {muddie!r}")


def check_folder(folder: Path, errors: list[str]) -> None:
    for entry in sorted(folder.iterdir()):
        if entry.is_dir():
            errors.append(f"{entry}: folders are not allowed inside a plugin")
        elif entry.name in REQUIRED:
            continue
        elif entry.suffix == ".luau" and entry.is_file():
            continue
        else:
            errors.append(f"{entry}: unexpected file in a plugin")

    for name in REQUIRED:
        if not (folder / name).is_file():
            errors.append(f"{folder / name}: missing")

    if not any(folder.glob("*.luau")):
        errors.append(f"{folder}: needs at least one .luau script")

    if (folder / "plugin.toml").is_file():
        check_manifest(folder / "plugin.toml", errors)
    if (folder / "rules.toml").is_file():
        load_toml(folder / "rules.toml", errors)
    if (folder / "template.toml").is_file():
        load_toml(folder / "template.toml", errors)


def check_plugins(root: Path) -> tuple[list[Path], list[str]]:
    """Return the plugin folders found and every problem in them."""
    errors: list[str] = []
    folders = plugin_folders(root)
    if not folders:
        errors.append(f"{root}: no plugin folders found")
    for folder in folders:
        check_folder(folder, errors)
    return folders, errors


def main() -> int:
    if sys.version_info < (3, 11):
        print("check.py needs Python 3.11 or later (tomllib)", file=sys.stderr)
        return 1

    root = (
        Path(sys.argv[1]).resolve()
        if len(sys.argv) > 1
        else Path(__file__).resolve().parent.parent
    )
    folders, errors = check_plugins(root)
    if errors:
        for error in errors:
            print(f"error: {error}", file=sys.stderr)
        print(f"{len(errors)} problem(s) found", file=sys.stderr)
        return 1
    names = ", ".join(folder.name for folder in folders)
    print(f"ok: {len(folders)} plugin(s) checked: {names}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
