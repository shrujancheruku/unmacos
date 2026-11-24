#!/usr/bin/env python3
"""Check the built site: every local link, image, video and script resolves to a file in _site/."""
import re
import sys
from pathlib import Path
from urllib.parse import unquote, urlsplit

sys.path.insert(0, str(Path(__file__).resolve().parent))
from build import SITE_URL  # noqa: E402

OUT = Path(__file__).resolve().parent.parent / "_site"
BASE = urlsplit(SITE_URL).path  # e.g. /unmacos/ on github.io, / on a custom domain
ATTR = re.compile(r'\b(?:href|src|poster|data-src)="([^"]*)"')


def main() -> int:
    if not OUT.is_dir():
        print("No _site/: run site/build.py first", file=sys.stderr)
        return 1
    broken, checked = [], 0
    for page in sorted(OUT.rglob("*.html")):
        for ref in ATTR.findall(page.read_text()):
            parts = urlsplit(ref)
            if parts.scheme or ref.startswith(("#", "//", "mailto:")) or not parts.path:
                continue
            path = unquote(parts.path)
            if path.startswith("/"):  # root-relative, as on the 404 page
                if not path.startswith(BASE):
                    broken.append(f"{page.relative_to(OUT)}: {ref} (outside {BASE})")
                    continue
                target = (OUT / path[len(BASE):]).resolve()
            else:
                target = (page.parent / path).resolve()
            if target.is_dir():
                target = target / "index.html"
            checked += 1
            if not target.is_file() or (OUT not in target.parents and target != OUT):
                broken.append(f"{page.relative_to(OUT)}: {ref}")
    for b in broken:
        print(f"broken: {b}", file=sys.stderr)
    print(f"Checked {checked} local links, {len(broken)} broken")
    return 1 if broken else 0


if __name__ == "__main__":
    sys.exit(main())
