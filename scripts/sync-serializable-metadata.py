#!/usr/bin/env python3
"""
Scan every `@Serializable`-annotated Kotlin class under `back/` and merge the
reflection entries required by GraalVM `native-image` into the project's
`reachability-metadata.json`.

For each serializable type `pkg.Foo` two entries are added under
`reflection[]`:

    { "type": "pkg.Foo",           "fields":  [ { "name": "Companion" } ] }
    { "type": "pkg.Foo$Companion", "methods": [ { "name": "serializer",
                                                  "parameterTypes": [] } ] }

These entries give the kotlinx-serialization plugin the reflection access it
synthesises at runtime. The script is idempotent: existing entries are not
duplicated, and unrelated entries in the file are preserved.

Classes annotated with `@Serializable(with = ...)` are skipped because
kotlinx-serialization does not emit a synthetic `Companion.serializer()` for
them.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SOURCE_ROOT = REPO_ROOT / "back"
METADATA_FILE = (
    REPO_ROOT
    / "back/deploy/lambda/src/main/resources/META-INF/native-image/reachability-metadata.json"
)

PACKAGE_RE = re.compile(r"^\s*package\s+([\w.]+)", re.MULTILINE)
# Matches @Serializable (optionally with parentheses), any other annotations,
# optional visibility / class modifiers, then the declaration keyword and name.
DECLARATION_RE = re.compile(
    r"@Serializable(?P<args>\([^)]*\))?\s+"
    r"(?:@[\w.]+(?:\([^)]*\))?\s+)*"
    r"(?:public\s+|internal\s+|private\s+)?"
    r"(?:data\s+|sealed\s+|open\s+|abstract\s+|value\s+|enum\s+)*"
    r"(?:class|object)\s+"
    r"(?P<name>\w+)"
)


def iter_kotlin_sources(root: Path):
    for path in root.rglob("*.kt"):
        parts = set(path.parts)
        if "build" in parts or "test" in parts:
            continue
        yield path


def scan_serializable_types(root: Path) -> list[str]:
    types: set[str] = set()
    for path in iter_kotlin_sources(root):
        text = path.read_text(encoding="utf-8")
        if "@Serializable" not in text:
            continue
        package_match = PACKAGE_RE.search(text)
        package = package_match.group(1) if package_match else ""
        for match in DECLARATION_RE.finditer(text):
            args = match.group("args") or ""
            if "with" in args and "=" in args:
                # @Serializable(with = CustomSerializer::class) — no synthetic Companion.serializer()
                continue
            name = match.group("name")
            fqn = f"{package}.{name}" if package else name
            types.add(fqn)
    return sorted(types)


def build_entries(types: list[str]) -> list[dict]:
    entries: list[dict] = []
    for fqn in types:
        entries.append({"type": fqn, "fields": [{"name": "Companion"}]})
        entries.append(
            {
                "type": f"{fqn}$Companion",
                "methods": [{"name": "serializer", "parameterTypes": []}],
            }
        )
    return entries


def _merge_list(existing: list, new_items: list) -> int:
    added = 0
    for item in new_items:
        if item not in existing:
            existing.append(item)
            added += 1
    return added


def merge_reflection(reflection: list[dict], new_entries: list[dict]) -> tuple[int, int]:
    """Merge entries into reflection[], returning (new_types, added_members)."""
    by_type = {entry["type"]: entry for entry in reflection if "type" in entry}
    new_types = 0
    added_members = 0
    for entry in new_entries:
        key = entry["type"]
        current = by_type.get(key)
        if current is None:
            reflection.append(entry)
            by_type[key] = entry
            new_types += 1
            added_members += len(entry.get("fields", [])) + len(entry.get("methods", []))
            continue
        for section in ("fields", "methods"):
            incoming = entry.get(section)
            if incoming:
                added_members += _merge_list(current.setdefault(section, []), incoming)
    return new_types, added_members


def main() -> int:
    if not METADATA_FILE.exists():
        METADATA_FILE.parent.mkdir(parents=True, exist_ok=True)
        data: dict = {"reflection": []}
    else:
        data = json.loads(METADATA_FILE.read_text(encoding="utf-8"))
        if not isinstance(data, dict):
            print(f"error: {METADATA_FILE} root is not an object", file=sys.stderr)
            return 1

    reflection = data.setdefault("reflection", [])
    if not isinstance(reflection, list):
        print(f"error: {METADATA_FILE} reflection is not an array", file=sys.stderr)
        return 1

    types = scan_serializable_types(SOURCE_ROOT)
    entries = build_entries(types)
    new_types, added_members = merge_reflection(reflection, entries)

    METADATA_FILE.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")

    rel = METADATA_FILE.relative_to(REPO_ROOT)
    print(
        f"{len(types)} @Serializable classes scanned → {rel} "
        f"(+{new_types} new types, +{added_members} members merged)"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
