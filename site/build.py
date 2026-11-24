#!/usr/bin/env python3
"""Build the UnMacOS website from site/src into _site (standard library only).

    python3 site/build.py            # build into _site/
    python3 -m http.server -d _site  # preview at http://localhost:8000/

Each page in src/ starts with a front-matter comment (title, description,
optional nav and schema) and is wrapped in src/_layout.html. Themes are read
from the repo's colors.toml files, so the site always lists the shipped ones.

Moving to a custom domain: change SITE_URL, add src/CNAME, rebuild.
"""
from __future__ import annotations

import datetime as dt
import html
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path
from urllib.parse import urlparse

SITE_URL = os.environ.get("SITE_URL", "https://shrujancheruku.github.io/unmacos/")
REPO_URL = "https://github.com/shrujancheruku/unmacos"
INSTALL_CMD = 'bash -c "$(curl -fsSL https://raw.githubusercontent.com/shrujancheruku/unmacos/main/install.sh)"'
# Optional, set once the services exist (left empty, nothing is emitted).
GOATCOUNTER_CODE = os.environ.get("GOATCOUNTER_CODE", "")  # e.g. "unmacos" for unmacos.goatcounter.com
GOOGLE_VERIFICATION = os.environ.get("GOOGLE_VERIFICATION", "")  # Search Console meta-tag token

HERE = Path(__file__).resolve().parent
REPO = HERE.parent
SRC = HERE / "src"
OUT = Path(os.environ.get("SITE_OUT", REPO / "_site"))
THEMES_DIR = REPO / "home/dot_local/share/unmacos/themes"
DEFAULT_DARK, DEFAULT_LIGHT = "tokyo-night", "catppuccin-latte"

NAV = [("", "Home"), ("themes/", "Themes"), ("keys/", "Keys"), ("install/", "Install"), ("compare/", "Compare")]


def git_version() -> str:
    try:
        return subprocess.check_output(
            ["git", "-C", str(REPO), "describe", "--tags", "--abbrev=0"], text=True, stderr=subprocess.DEVNULL
        ).strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return ""


def read_theme(path: Path) -> dict:
    text = path.read_text()
    m = re.search(r"^# UnMacOS theme: (.+)$", text, re.M)
    colors = dict(re.findall(r'^(\w+)\s*=\s*"([^"]*)"', text, re.M))
    return {"slug": path.parent.name, "name": m.group(1).strip() if m else path.parent.name, **colors}


def load_themes() -> list[dict]:
    themes = [read_theme(p) for p in sorted(THEMES_DIR.glob("*/colors.toml"))]
    order = {DEFAULT_DARK: 0}
    return sorted(themes, key=lambda t: (order.get(t["slug"], 1), t["name"].lower()))


# The handful of colours the site's CSS uses, keyed by CSS variable.
PALETTE_KEYS = {
    "bg": "background", "bg2": "lighter_background", "bg3": "dark_background",
    "fg": "foreground", "muted": "muted", "sel": "selection", "border": "border_inactive",
    "accent": "accent", "red": "red", "yellow": "yellow", "green": "green",
    "cyan": "cyan", "blue": "blue", "magenta": "magenta",
}


def palette(t: dict) -> dict:
    p = {k: t.get(v, "") for k, v in PALETTE_KEYS.items()}
    p["mode"] = t.get("mode", "dark")
    return p


def mock_svg(t: dict, name: str) -> str:
    """A small desktop preview in the theme's own colours. It's an image (the
    palette's real contrast is the point), so it carries a text label."""
    g = lambda k, d="accent": t.get(k, t[d])
    bg, bg2, fg, acc, sel = t["background"], g("lighter_background", "background"), t["foreground"], t["accent"], g("selection", "background")
    chip = lambda x, label, on=False: (
        f'<rect x="{x}" y="6" width="{12 + 7.3 * len(label):.0f}" height="18" rx="4" fill="{bg2}" stroke="{acc if on else sel}"/>'
        f'<text x="{x + 6}" y="19" fill="{acc if on else fg}">{label}</text>'
    )
    return (
        f'<svg class="theme-mock" viewBox="0 0 320 118" role="img" aria-label="{name} preview: bar, terminal and colours">'
        f'<rect width="320" height="118" fill="{bg}"/>'
        f'<g font-family="ui-monospace,SF Mono,Menlo,monospace" font-size="12">'
        + chip(8, "1", True) + chip(30, "2") + chip(52, "3") + chip(264, "22:50")
        + f'<rect x="8.5" y="32.5" width="303" height="78" rx="4" fill="none" stroke="{acc}"/>'
        f'<text x="18" y="54"><tspan fill="{g("green")}">❯</tspan><tspan fill="{fg}"> git status </tspan><tspan fill="{g("muted", "foreground")}"># clean</tspan></text>'
        f'<rect x="149" y="62" width="70" height="17" fill="{sel}"/>'
        f'<text x="18" y="75"><tspan fill="{g("red")}">error</tspan> <tspan fill="{g("yellow")}">warn</tspan> <tspan fill="{g("blue")}">info</tspan> <tspan x="153" fill="{fg}">selected</tspan></text>'
        f'<text x="18" y="96"><tspan fill="{g("magenta")}">local</tspan><tspan fill="{fg}"> theme = </tspan><tspan fill="{g("green")}">"{t["slug"]}"</tspan></text>'
        "</g></svg>"
    )


def themes_grid(themes: list[dict]) -> str:
    cards = []
    for t in themes:
        sw = "".join(
            f'<span style="background:{t[c]}" title="{c} {t[c]}"></span>'
            for c in ("red", "yellow", "green", "cyan", "blue", "magenta")
            if c in t
        )
        name = html.escape(t["name"])
        cards.append(
            f'''<article class="theme-card" id="{t['slug']}">
  {mock_svg(t, name)}
  <div class="theme-meta">
    <h3>{name}</h3>
    <p class="theme-mode">{t.get('mode', 'dark')} · accent <code>{t['accent']}</code></p>
    <div class="swatches">{sw}</div>
    <button class="btn-small" type="button" data-theme="{t['slug']}">Try it on this page</button>
  </div>
</article>'''
        )
    return "\n".join(cards)


FRONT = re.compile(r"\A<!--\n(.*?)\n-->\n", re.S)


def parse_page(text: str) -> tuple[dict, str]:
    m = FRONT.match(text)
    if not m:
        raise SystemExit("page is missing its front-matter comment")
    meta = {}
    for line in m.group(1).splitlines():
        k, _, v = line.partition(":")
        meta[k.strip()] = v.strip()
    return meta, text[m.end():]


def schema_for(kind: str, meta: dict, url: str, version: str, faq: list[tuple[str, str]]) -> list[dict]:
    if kind == "home":
        app = {
            "@context": "https://schema.org", "@type": "SoftwareApplication", "name": "UnMacOS",
            "description": meta["description"], "url": SITE_URL,
            "applicationCategory": "UtilitiesApplication", "operatingSystem": "macOS 15 or later (Apple silicon)",
            "license": "https://www.gnu.org/licenses/gpl-3.0.html", "isAccessibleForFree": True,
            "offers": {"@type": "Offer", "price": "0", "priceCurrency": "USD"},
            "downloadUrl": REPO_URL, "codeRepository": REPO_URL, "image": SITE_URL + "og.png",
            "author": {"@type": "Person", "name": "Shrujan Cheruku", "url": "https://github.com/shrujancheruku"},
        }
        if version:
            app["softwareVersion"] = version.lstrip("v")
        site = {"@context": "https://schema.org", "@type": "WebSite", "name": "UnMacOS", "url": SITE_URL}
        out = [app, site]
        if faq:
            out.append({
                "@context": "https://schema.org", "@type": "FAQPage",
                "mainEntity": [
                    {"@type": "Question", "name": q, "acceptedAnswer": {"@type": "Answer", "text": a}} for q, a in faq
                ],
            })
        return out
    if kind == "page":
        return [{
            "@context": "https://schema.org", "@type": "BreadcrumbList",
            "itemListElement": [
                {"@type": "ListItem", "position": 1, "name": "UnMacOS", "item": SITE_URL},
                {"@type": "ListItem", "position": 2, "name": meta.get("nav", meta["title"]), "item": url},
            ],
        }]
    return []


def extract_faq(body: str) -> list[tuple[str, str]]:
    """FAQ entries are <details class="faq"><summary>Q</summary><div>A</div></details>."""
    strip = lambda s: re.sub(r"\s+", " ", html.unescape(re.sub(r"<[^>]+>", "", s))).strip()
    return [(strip(q), strip(a)) for q, a in re.findall(
        r'<details class="faq">\s*<summary>(.*?)</summary>\s*<div>(.*?)</div>\s*</details>', body, re.S)]


def build() -> None:
    version = git_version()
    themes = load_themes()
    palettes = {t["slug"]: palette(t) for t in themes}
    names = {t["slug"]: t["name"] for t in themes}
    layout = (SRC / "_layout.html").read_text()
    grid = themes_grid(themes)
    base_path = urlparse(SITE_URL).path  # "/unmacos/" on github.io, "/" on a custom domain

    if OUT.exists():
        shutil.rmtree(OUT)
    shutil.copytree(SRC, OUT, ignore=shutil.ignore_patterns("_*", "*.html", ".DS_Store"))
    # Search engine ownership files (Google's google<id>.html) are served exactly as downloaded.
    for f in SRC.glob("google*.html"):
        shutil.copy2(f, OUT / f.name)

    (OUT / "themes.js").write_text(
        "// Generated by site/build.py from the repo's colors.toml files.\n"
        f"window.UNMACOS_THEMES={json.dumps(palettes, separators=(',', ':'))};\n"
        f"window.UNMACOS_THEME_NAMES={json.dumps(names, separators=(',', ':'))};\n"
    )

    head_boot = (
        "<script>(function(){try{var p=JSON.parse(localStorage.getItem('unmacos-palette')||'null');"
        "if(!p)return;var r=document.documentElement.style;for(var k in p)if(k!=='mode'&&k!=='slug')r.setProperty('--'+k,p[k]);"
        "document.documentElement.dataset.mode=p.mode;var m=document.querySelector('meta[name=theme-color]');"
        "if(m&&p.bg)m.content=p.bg;}catch(e){}})();</script>"
    )
    analytics = (
        f'<script data-goatcounter="https://{GOATCOUNTER_CODE}.goatcounter.com/count" async '
        'src="https://gc.zgo.at/count.js"></script>' if GOATCOUNTER_CODE else ""
    )
    verification = f'<meta name="google-site-verification" content="{GOOGLE_VERIFICATION}">' if GOOGLE_VERIFICATION else ""

    sitemap = []
    today = dt.date.today().isoformat()
    for src in sorted(SRC.rglob("*.html")):
        rel = src.relative_to(SRC)
        if rel.name.startswith("_") or (rel.parent == Path(".") and rel.name.startswith("google")):
            continue
        meta, body = parse_page(src.read_text())
        is_404 = rel.name == "404.html"
        path = "" if rel.as_posix() == "index.html" else rel.parent.as_posix() + "/"
        url = SITE_URL + path
        depth = len(rel.parts) - 1
        # 404.html is served at any missing path, so it needs absolute links.
        root = base_path if is_404 else ("../" * depth or "./")

        fill = lambda s: (s.replace("{{THEMES_GRID}}", grid)
                           .replace("{{THEME_COUNT}}", str(len(themes)))
                           .replace("{{INSTALL_CMD}}", html.escape(INSTALL_CMD))
                           .replace("{{REPO_URL}}", REPO_URL)
                           .replace("{{ROOT}}", root))
        body = fill(body)
        meta = {k: fill(v) for k, v in meta.items()}
        kind = meta.get("schema", "page")
        blocks = schema_for(kind, meta, url, version, extract_faq(body) if kind == "home" else [])
        schema = "\n".join(
            f'<script type="application/ld+json">{json.dumps(b, ensure_ascii=False)}</script>' for b in blocks
        )
        nav = "".join(
            f'<a href="{root}{href}"{" aria-current=page" if href == path else ""}>{label}</a>' for href, label in NAV
        )
        page = layout
        for key, value in {
            "title": html.escape(meta["title"]),
            "description": html.escape(meta["description"]),
            "canonical": "" if is_404 else f'<link rel="canonical" href="{url}">',
            "robots": '<meta name="robots" content="noindex">' if is_404 else "",
            "url": url, "root": root, "site": SITE_URL, "nav": nav, "schema": schema,
            "boot": head_boot, "analytics": analytics, "verification": verification,
            "repo": REPO_URL, "version": version or "", "year": str(dt.date.today().year),
            "body": body,
        }.items():
            page = page.replace("{{" + key + "}}", value)
        leftover = re.findall(r"\{\{\w+\}\}", page)
        if leftover:
            raise SystemExit(f"{rel}: unreplaced placeholders {leftover}")
        dest = OUT / rel
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(page)
        if not is_404:
            sitemap.append(f"  <url><loc>{url}</loc><lastmod>{today}</lastmod></url>")

    (OUT / "sitemap.xml").write_text(
        '<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'
        + "\n".join(sitemap) + "\n</urlset>\n"
    )
    (OUT / "robots.txt").write_text(f"User-agent: *\nAllow: /\n\nSitemap: {SITE_URL}sitemap.xml\n")
    (OUT / ".nojekyll").write_text("")
    print(f"Built {len(sitemap) + 1} pages and {len(themes)} themes into {OUT}", file=sys.stderr)


if __name__ == "__main__":
    build()
