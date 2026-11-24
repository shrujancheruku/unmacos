# UnMacOS website

The static site at <https://shrujancheruku.github.io/unmacos/>, deployed to GitHub Pages by
`.github/workflows/pages.yml` on every push to `main` that touches `site/` or the themes.

```sh
python3 site/build.py              # builds into _site/ (standard library only)
python3 site/check.py              # checks every local link and asset
python3 -m http.server -d _site    # http://localhost:8000/
```

- `src/_layout.html` wraps every page: head tags, nav, footer.
- Each page in `src/` starts with a front-matter comment (`title`, `description`, optional `nav`
  and `schema`). Placeholders such as `{{THEME_COUNT}}` and `{{INSTALL_CMD}}` are filled at build.
- The themes page and the site's theme picker are generated from
  `home/dot_local/share/unmacos/themes/*/colors.toml`, so a new theme shows up on the next deploy.
- `build.py` also writes `sitemap.xml`, `robots.txt` and the JSON-LD (SoftwareApplication, FAQ from
  the home page's `<details class="faq">`, breadcrumbs).
- Media in `src/media/` are web versions of `docs/`: MP4 + WebM instead of GIF, WebP instead of PNG.
  Regenerate with ffmpeg and cwebp if the recordings change.

## Optional settings

Set as repository variables (Settings → Secrets and variables → Actions → Variables):

| Variable | Effect |
|---|---|
| `GOOGLE_VERIFICATION` | Adds the Google Search Console verification meta tag |
| `GOATCOUNTER_CODE` | Adds GoatCounter analytics (`<code>.goatcounter.com`) |

## Moving to a custom domain

1. Change `SITE_URL` in `build.py` to the new address, ending in `/`.
2. Add `src/CNAME` containing the bare domain (e.g. `unmacos.dev`).
3. Point DNS at GitHub Pages and set the domain in Settings → Pages, with HTTPS enforced.

GitHub redirects the old `github.io` address to the custom domain, so links and rankings carry over.
`robots.txt` only takes effect at a domain root, so it starts working after the move.
