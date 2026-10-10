/* Story maps: a `.map-btn` (rendered from a ```map block) opens a popup with the map image,
   centred on the first point, pannable and zoomable (drag, wheel, pinch, buttons, keys).
   Several points are joined by a smooth bezier path. Styling lives in base.css + themes. */
(function () {
  "use strict";

  var NS = "http://www.w3.org/2000/svg";
  var MAX_SCALE = 1.5; // image pixels per CSS pixel
  var START_SCALE = 0.5;

  function el(tag, cls, parent) {
    var n = document.createElement(tag);
    if (cls) n.className = cls;
    if (parent) parent.appendChild(n);
    return n;
  }

  function svg(tag, attrs, parent) {
    var n = document.createElementNS(NS, tag);
    for (var k in attrs) n.setAttribute(k, attrs[k]);
    if (parent) parent.appendChild(n);
    return n;
  }

  function button(cls, label, text, parent) {
    var b = el("button", "map-ctl " + cls, parent);
    b.type = "button";
    b.setAttribute("aria-label", label);
    b.title = label;
    b.textContent = text;
    return b;
  }

  /* Catmull-Rom through the points, expressed as cubic beziers. */
  function pathData(p) {
    var d = "M" + p[0][0] + " " + p[0][1];
    for (var i = 0; i < p.length - 1; i++) {
      var a = p[i - 1] || p[i], b = p[i], c = p[i + 1], e = p[i + 2] || c;
      d += " C" + (b[0] + (c[0] - a[0]) / 6) + " " + (b[1] + (c[1] - a[1]) / 6) + " " +
        (c[0] - (e[0] - b[0]) / 6) + " " + (c[1] - (e[1] - b[1]) / 6) + " " + c[0] + " " + c[1];
    }
    return d;
  }

  function open(btn) {
    var W = +btn.dataset.w, H = +btn.dataset.h, pts = JSON.parse(btn.dataset.points);
    var dlg = el("dialog", "map-dialog", document.body);
    dlg.setAttribute("aria-label", "Hartă");
    var view = el("div", "map-view loading", dlg);
    view.tabIndex = 0;
    var stage = el("div", "map-stage", view);
    stage.style.width = W + "px";
    stage.style.height = H + "px";
    var img = el("img", "map-img", stage);
    img.alt = "";
    img.draggable = false;
    img.width = W;
    img.height = H;
    img.addEventListener("load", function () { view.classList.remove("loading"); });
    img.addEventListener("error", function () { view.classList.remove("loading"); view.classList.add("failed"); });
    img.src = btn.dataset.src;

    if (pts.length > 1) {
      var layer = svg("svg", { "class": "map-path", viewBox: "0 0 " + W + " " + H, width: W, height: H }, stage);
      var d = pathData(pts);
      svg("path", { "class": "halo", d: d }, layer);
      svg("path", { "class": "line", d: d }, layer);
    }

    var pins = el("div", "map-pins", view);
    var pinEls = pts.map(function (_, i) {
      var last = i === pts.length - 1 && pts.length > 1;
      var kind = i === 0 ? "start" : last ? "end" : "via";
      var n = el("div", "map-pin " + kind, pins);
      if (kind !== "via") n.innerHTML = '<svg viewBox="0 0 24 34" aria-hidden="true"><path d="M12 1.5C6.2 1.5 1.5 6 1.5 11.7 1.5 19.5 12 32.5 12 32.5s10.5-13 10.5-20.8C22.5 6 17.8 1.5 12 1.5z"/><circle cx="12" cy="11.8" r="4"/></svg>';
      return n;
    });

    var ctl = el("div", "map-controls", dlg);
    var close = button("map-close", "Închide harta", "×", dlg);
    var zin = button("map-zin", "Mărește", "+", ctl);
    var zout = button("map-zout", "Micșorează", "−", ctl);
    var fit = pts.length > 1 ? button("map-fit", "Arată tot traseul", "⤢", ctl) : null;

    var vw = 0, vh = 0, s = 1, tx = 0, ty = 0, minS = 0.1;

    function clampPos() {
      var w = W * s, h = H * s;
      tx = w <= vw ? (vw - w) / 2 : Math.min(0, Math.max(vw - w, tx));
      ty = h <= vh ? (vh - h) / 2 : Math.min(0, Math.max(vh - h, ty));
    }
    function render() {
      stage.style.transform = "translate(" + tx + "px," + ty + "px) scale(" + s + ")";
      for (var i = 0; i < pts.length; i++) {
        pinEls[i].style.transform = "translate(" + (tx + pts[i][0] * s) + "px," + (ty + pts[i][1] * s) + "px)";
      }
    }
    function limits() {
      minS = Math.max(vw / W, vh / H);
    }
    function setScale(ns, cx, cy) { // zoom keeping screen point (cx, cy) fixed
      ns = Math.min(Math.max(ns, minS), Math.max(MAX_SCALE, minS));
      tx = cx - (cx - tx) * (ns / s);
      ty = cy - (cy - ty) * (ns / s);
      s = ns;
      clampPos();
      render();
    }
    function centerOn(x, y, ns) {
      s = Math.min(Math.max(ns, minS), Math.max(MAX_SCALE, minS));
      tx = vw / 2 - x * s;
      ty = vh / 2 - y * s;
      clampPos();
      render();
    }
    function measure() {
      var r = view.getBoundingClientRect();
      vw = r.width; vh = r.height;
      limits();
    }

    // --- input ---
    var ptrs = new Map(), last = null;
    view.addEventListener("pointerdown", function (e) {
      view.setPointerCapture(e.pointerId);
      ptrs.set(e.pointerId, { x: e.clientX, y: e.clientY });
      view.classList.add("grabbing");
      last = null;
    });
    view.addEventListener("pointermove", function (e) {
      var p = ptrs.get(e.pointerId);
      if (!p) return;
      var r = view.getBoundingClientRect();
      if (ptrs.size === 1) {
        tx += e.clientX - p.x; ty += e.clientY - p.y;
        p.x = e.clientX; p.y = e.clientY;
        clampPos(); render();
      } else if (ptrs.size === 2) {
        p.x = e.clientX; p.y = e.clientY;
        var a = Array.from(ptrs.values());
        var dist = Math.hypot(a[0].x - a[1].x, a[0].y - a[1].y);
        var mx = (a[0].x + a[1].x) / 2 - r.left, my = (a[0].y + a[1].y) / 2 - r.top;
        if (last) {
          tx += mx - last.mx; ty += my - last.my;
          setScale(s * dist / last.dist, mx, my);
        }
        last = { dist: dist, mx: mx, my: my };
      }
    });
    function up(e) {
      ptrs.delete(e.pointerId);
      last = null;
      if (!ptrs.size) view.classList.remove("grabbing");
    }
    view.addEventListener("pointerup", up);
    view.addEventListener("pointercancel", up);
    view.addEventListener("wheel", function (e) {
      e.preventDefault();
      var r = view.getBoundingClientRect();
      var k = e.deltaMode === 1 ? 33 : 1;
      setScale(s * Math.exp(-e.deltaY * k * 0.0015), e.clientX - r.left, e.clientY - r.top);
    }, { passive: false });
    view.addEventListener("dblclick", function (e) {
      var r = view.getBoundingClientRect();
      setScale(s * 1.8, e.clientX - r.left, e.clientY - r.top);
    });
    view.addEventListener("keydown", function (e) {
      var step = 60, handled = true;
      if (e.key === "ArrowLeft") tx += step;
      else if (e.key === "ArrowRight") tx -= step;
      else if (e.key === "ArrowUp") ty += step;
      else if (e.key === "ArrowDown") ty -= step;
      else if (e.key === "+" || e.key === "=") return setScale(s * 1.4, vw / 2, vh / 2);
      else if (e.key === "-") return setScale(s / 1.4, vw / 2, vh / 2);
      else handled = false;
      if (handled) { e.preventDefault(); clampPos(); render(); }
    });
    zin.addEventListener("click", function () { setScale(s * 1.5, vw / 2, vh / 2); });
    zout.addEventListener("click", function () { setScale(s / 1.5, vw / 2, vh / 2); });
    if (fit) fit.addEventListener("click", function () {
      var x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity;
      pts.forEach(function (p) { x0 = Math.min(x0, p[0]); x1 = Math.max(x1, p[0]); y0 = Math.min(y0, p[1]); y1 = Math.max(y1, p[1]); });
      var pad = 0.8; // leave room for pins and the controls
      var ns = Math.min(vw * pad / Math.max(x1 - x0, 1), vh * pad / Math.max(y1 - y0, 1), 1);
      centerOn((x0 + x1) / 2, (y0 + y1) / 2, ns);
    });
    close.addEventListener("click", function () { dlg.close(); });
    dlg.addEventListener("click", function (e) { if (e.target === dlg) dlg.close(); }); // backdrop
    dlg.addEventListener("close", function () {
      ro.disconnect();
      document.documentElement.classList.remove("map-open");
      dlg.remove();
      btn.focus();
    });

    var ro = new ResizeObserver(function () {
      if (!vw) return;
      var cx = (vw / 2 - tx) / s, cy = (vh / 2 - ty) / s; // keep the same map point centred
      measure();
      centerOn(cx, cy, s);
    });

    document.documentElement.classList.add("map-open");
    dlg.showModal();
    measure();
    centerOn(pts[0][0], pts[0][1], START_SCALE);
    ro.observe(view);
    view.focus({ preventScroll: true });
  }

  document.addEventListener("click", function (e) {
    var b = e.target.closest && e.target.closest(".map-btn");
    if (b) open(b);
  });
})();
