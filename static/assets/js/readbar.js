/* Reading bar: hamburger dropdown with "+ Font" / "- Font" / "+ Margin" / "- Margin". Each setting is a delta in px
   kept in localStorage and applied through a CSS variable (--font-delta, --margin-delta; see .has-readbar in base.css). */
(function () {
  "use strict";
  var root = document.documentElement;
  var bar = document.getElementById("readbar");
  if (!bar) return;
  var btn = bar.querySelector(".readbar-btn");
  var drop = bar.querySelector(".readbar-drop");
  // font: px added to the root font size. margin: px added to the side margins (negative = tighter, down to ~2px).
  var opts = { font: { step: 1, min: -4, max: 12 }, margin: { step: 6, min: -18, max: 36 } };

  function clamp(o, d) { return Math.max(o.min, Math.min(o.max, d)); }
  function read(name) {
    try { var d = parseInt(localStorage.getItem("dw:" + name + "-delta"), 10); return isNaN(d) ? 0 : clamp(opts[name], d); } catch (e) { return 0; }
  }
  function apply(name) {
    var o = opts[name];
    root.style.setProperty("--" + name + "-delta", o.v + "px");
    try { localStorage.setItem("dw:" + name + "-delta", String(o.v)); } catch (e) { /* storage blocked: still works until reload */ }
    drop.querySelector("[data-" + name + '="1"]').disabled = o.v >= o.max;
    drop.querySelector("[data-" + name + '="-1"]').disabled = o.v <= o.min;
  }
  function toggle(open) {
    drop.hidden = !open;
    btn.setAttribute("aria-expanded", open ? "true" : "false");
  }

  Object.keys(opts).forEach(function (name) { opts[name].v = read(name); apply(name); });
  btn.addEventListener("click", function () { toggle(drop.hidden); });
  drop.addEventListener("click", function (e) {
    var b = e.target.closest("button");
    if (!b || b.disabled) return;
    Object.keys(opts).forEach(function (name) {
      var dir = b.getAttribute("data-" + name);
      if (dir === null) return;
      opts[name].v = clamp(opts[name], opts[name].v + opts[name].step * parseInt(dir, 10));
      apply(name);
    });
  });
  document.addEventListener("click", function (e) { if (!drop.hidden && !bar.querySelector(".readbar-menu").contains(e.target)) toggle(false); });
  document.addEventListener("keydown", function (e) { if (e.key === "Escape" && !drop.hidden) { toggle(false); btn.focus(); } });
})();
