"""Append a timestamped bullet to the Logg section of today's daily note."""

import datetime
import os
import sys
from pathlib import Path

SECTION = "## Logg"


def main(vault: Path, text: str) -> None:
    text = " ".join(text.split())
    if not text:
        sys.exit("Nothing to log")

    now = datetime.datetime.now()
    note = vault / "Daily" / f"{now:%Y-%m-%d}.md"
    if note.exists():
        lines = note.read_text().splitlines()
    else:
        # Match what Obsidian would create when opening today's note.
        template = vault / "Templates" / "Daily.md"
        lines = template.read_text().splitlines() if template.exists() else []

    entry = f"- {now:%H:%M} - {text}"
    if SECTION in (line.strip() for line in lines):
        start = next(i for i, line in enumerate(lines) if line.strip() == SECTION)
        end = next(
            (i for i in range(start + 1, len(lines)) if lines[i].startswith("#")),
            len(lines),
        )
        # Insert after the last non-blank line so spacing before the next heading stays.
        last = max(
            (i for i in range(start, end) if lines[i].strip()),
            default=start,
        )
        lines.insert(last + 1, entry)
    else:
        lines += ["", SECTION, "", entry]

    note.parent.mkdir(parents=True, exist_ok=True)
    tmp = note.with_name(f".{note.name}.tmp")
    tmp.write_text("\n".join(lines) + "\n")
    os.replace(tmp, note)
    print(f"Logged to {note.stem}")


if __name__ == "__main__":
    main(Path(sys.argv[1]).expanduser(), " ".join(sys.argv[2:]))
