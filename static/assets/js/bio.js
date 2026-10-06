/* Character bio: the `.bio-btn` opens the <dialog> it controls (rendered by partials/bio.html). */
(function () {
  "use strict";
  document.addEventListener("click", function (e) {
    var b = e.target.closest && e.target.closest(".bio-btn");
    if (b) {
      var d = document.getElementById(b.getAttribute("aria-controls"));
      document.documentElement.classList.add("bio-open");
      d.showModal();
      d.scrollTop = 0;
      return;
    }
    var d = e.target.closest && e.target.closest(".bio-dialog");
    if (e.target === d || (e.target.closest && e.target.closest(".bio-close"))) d.close(); // backdrop or ×
  });
  document.addEventListener("close", function (e) {
    if (e.target.classList && e.target.classList.contains("bio-dialog")) document.documentElement.classList.remove("bio-open");
  }, true);
})();
