// UnMacOS site: live theme switching, copy buttons, shortcut search.
(function () {
  "use strict";
  var KEY = "unmacos-palette";
  var themes = window.UNMACOS_THEMES || {};
  var names = window.UNMACOS_THEME_NAMES || {};
  var root = document.documentElement;
  var select = document.getElementById("theme-select");

  // A picked theme is saved as {slug, ...palette}. The boot script in <head> paints that copy
  // before this file loads (no flash); here it is re-applied from themes.js, so a palette that
  // changed in a later deploy updates, and a theme that no longer exists falls back to the system.
  // With nothing picked ("system"), the site follows prefers-color-scheme, live.
  var SYSTEM = "system";
  var DARK = "tokyo-night", LIGHT = "catppuccin-latte";
  var media = window.matchMedia ? matchMedia("(prefers-color-scheme: light)") : null;

  function store(fn) { try { return fn(); } catch (e) { return null; } }
  var saved = store(function () { return JSON.parse(localStorage.getItem(KEY) || "null"); });
  var choice = saved && themes[saved.slug] ? saved.slug : SYSTEM;
  if (saved && choice === SYSTEM) store(function () { localStorage.removeItem(KEY); });

  function systemSlug() { return media && media.matches ? LIGHT : DARK; }

  function paint(slug) {
    var p = themes[slug];
    if (!p) return;
    for (var k in p) if (k !== "mode") root.style.setProperty("--" + k, p[k]);
    root.style.removeProperty("--slug"); // left by older saved copies
    root.dataset.mode = p.mode;
    var meta = document.querySelector('meta[name="theme-color"]');
    if (meta) meta.content = p.bg;
  }

  function choose(slug, persist) {
    if (slug !== SYSTEM && !themes[slug]) return;
    choice = slug;
    paint(slug === SYSTEM ? systemSlug() : slug);
    if (select) select.value = slug;
    if (!persist) return;
    store(function () {
      if (slug === SYSTEM) { localStorage.removeItem(KEY); return; }
      var copy = { slug: slug };
      for (var c in themes[slug]) copy[c] = themes[slug][c];
      localStorage.setItem(KEY, JSON.stringify(copy));
    });
  }

  if (select) {
    select.innerHTML = "";
    var auto = document.createElement("option");
    auto.value = SYSTEM;
    auto.textContent = "Match system";
    select.appendChild(auto);
    Object.keys(themes).forEach(function (slug) {
      var o = document.createElement("option");
      o.value = slug;
      o.textContent = names[slug] || slug;
      select.appendChild(o);
    });
    select.addEventListener("change", function () { choose(select.value, true); });
  }
  choose(choice, false);
  if (media) {
    var follow = function () { if (choice === SYSTEM) paint(systemSlug()); };
    if (media.addEventListener) media.addEventListener("change", follow); else if (media.addListener) media.addListener(follow);
  }

  document.addEventListener("click", function (e) {
    var t = e.target.closest("[data-theme]");
    if (t) {
      choose(t.getAttribute("data-theme"), true);
      return;
    }
    var c = e.target.closest("[data-copy]");
    if (c) {
      var src = document.getElementById(c.getAttribute("data-copy"));
      if (!src || !navigator.clipboard) return;
      navigator.clipboard.writeText(src.textContent.trim()).then(function () {
        var label = c.textContent;
        c.textContent = "Copied";
        setTimeout(function () { c.textContent = label; }, 1600);
      });
    }
  });

  // Shortcut search on the keys page.
  var search = document.getElementById("keys-search");
  if (search) {
    search.addEventListener("input", function () {
      var q = search.value.trim().toLowerCase();
      document.querySelectorAll(".keys-group").forEach(function (g) {
        var any = false;
        g.querySelectorAll("tbody tr").forEach(function (tr) {
          var hit = !q || tr.textContent.toLowerCase().indexOf(q) !== -1;
          tr.hidden = !hit;
          any = any || hit;
        });
        g.hidden = !any;
      });
    });
    document.addEventListener("keydown", function (e) {
      if (e.key === "/" && document.activeElement !== search) { e.preventDefault(); search.focus(); }
    });
  }

  // Respect reduced motion: show the poster and let people press play.
  var still = window.matchMedia && matchMedia("(prefers-reduced-motion: reduce)").matches;
  if (still) {
    document.querySelectorAll("video[autoplay]").forEach(function (v) { v.pause(); v.controls = true; });
  }

  // Below-the-fold recordings load only when they scroll into view.
  function loadVideo(v) {
    v.querySelectorAll("source[data-src]").forEach(function (s) { s.src = s.getAttribute("data-src"); s.removeAttribute("data-src"); });
    v.load();
    if (still) v.controls = true; else v.play().catch(function () { v.controls = true; });
  }
  // The hero recording (data-defer) waits for the page to finish loading so
  // its poster paints first and the video doesn't compete with the page.
  document.querySelectorAll("video[data-defer]").forEach(function (v) {
    var go = function () { setTimeout(function () { loadVideo(v); }, 300); };
    if (document.readyState === "complete") go(); else window.addEventListener("load", go);
  });
  var lazy = document.querySelectorAll("video.lazy:not([data-defer])");
  if ("IntersectionObserver" in window) {
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) { if (e.isIntersecting) { loadVideo(e.target); io.unobserve(e.target); } });
    }, { rootMargin: "200px" });
    lazy.forEach(function (v) { io.observe(v); });
  } else {
    lazy.forEach(loadVideo);
  }
})();
