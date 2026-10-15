/* Reading bar: hamburger dropdown with "+ Font" / "- Font". The delta (px added to the root font size)
   is kept in localStorage and applied through --font-delta (see .has-readbar in base.css). */
(function () {
  "use strict";
  var KEY = "dw:font-delta", STEP = 1, MIN = -4, MAX = 12;
  var root = document.documentElement;
  var bar = document.getElementById("readbar");
  if (!bar) return;
  var btn = bar.querySelector(".readbar-btn");
  var drop = bar.querySelector(".readbar-drop");

  function read() {
    try { var d = parseInt(localStorage.getItem(KEY), 10); return isNaN(d) ? 0 : Math.max(MIN, Math.min(MAX, d)); } catch (e) { return 0; }
  }
  var delta = read();
  function apply() {
    root.style.setProperty("--font-delta", delta + "px");
    try { localStorage.setItem(KEY, String(delta)); } catch (e) { /* storage blocked: still works until reload */ }
    drop.querySelector('[data-font="1"]').disabled = delta >= MAX;
    drop.querySelector('[data-font="-1"]').disabled = delta <= MIN;
  }
  function toggle(open) {
    drop.hidden = !open;
    btn.setAttribute("aria-expanded", open ? "true" : "false");
  }

  apply();
  btn.addEventListener("click", function () { toggle(drop.hidden); });
  drop.addEventListener("click", function (e) {
    var b = e.target.closest("[data-font]");
    if (!b || b.disabled) return;
    delta = Math.max(MIN, Math.min(MAX, delta + STEP * parseInt(b.getAttribute("data-font"), 10)));
    apply();
  });
  document.addEventListener("click", function (e) { if (!drop.hidden && !bar.querySelector(".readbar-menu").contains(e.target)) toggle(false); });
  document.addEventListener("keydown", function (e) { if (e.key === "Escape" && !drop.hidden) { toggle(false); btn.focus(); } });
})();
