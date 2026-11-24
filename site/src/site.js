// UnMacOS site: live theme switching, copy buttons, shortcut search.
(function () {
  "use strict";
  var KEY = "unmacos-palette";
  var themes = window.UNMACOS_THEMES || {};
  var names = window.UNMACOS_THEME_NAMES || {};
  var root = document.documentElement;
  var select = document.getElementById("theme-select");

  function store(fn) { try { return fn(); } catch (e) { return null; } }
  var saved = store(function () { return JSON.parse(localStorage.getItem(KEY) || "null"); });
  var prefersLight = window.matchMedia && matchMedia("(prefers-color-scheme: light)").matches;
  var current = (saved && saved.slug) || (prefersLight ? "catppuccin-latte" : "tokyo-night");

  function apply(slug, persist) {
    var p = themes[slug];
    if (!p) return;
    for (var k in p) if (k !== "mode") root.style.setProperty("--" + k, p[k]);
    root.dataset.mode = p.mode;
    var meta = document.querySelector('meta[name="theme-color"]');
    if (meta) meta.content = p.bg;
    current = slug;
    if (select) select.value = slug;
    if (persist) {
      var copy = { slug: slug };
      for (var c in p) copy[c] = p[c];
      store(function () { localStorage.setItem(KEY, JSON.stringify(copy)); });
    }
  }

  if (select) {
    select.innerHTML = "";
    Object.keys(themes).forEach(function (slug) {
      var o = document.createElement("option");
      o.value = slug;
      o.textContent = names[slug] || slug;
      select.appendChild(o);
    });
    select.value = current;
    select.addEventListener("change", function () { apply(select.value, true); });
  }

  document.addEventListener("click", function (e) {
    var t = e.target.closest("[data-theme]");
    if (t) {
      apply(t.getAttribute("data-theme"), true);
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
