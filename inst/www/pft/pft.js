// PFT-Design und Item-Logik
// - setzt body.pft, solange eine PFT-Seite angezeigt wird (CSS greift nur dann)
// - Antwortkarten: Auswahl markieren und ändern, "Weiter" erst nach Auswahl
// - Weiter/Überspringen schicken input$pft_response und blättern weiter
// - Countdown; bei 0:00 wird die Seite mit action = "timeout" abgeschickt
(function () {
  // Wird über die htmlDependency jeder PFT-Seite geladen -> nur einmal initialisieren
  if (window.pftDesignLoaded) return;
  window.pftDesignLoaded = true;

  var timerId = null;

  function stopTimer() {
    if (timerId !== null) {
      clearInterval(timerId);
      timerId = null;
    }
  }

  function formatTime(ms) {
    var s = Math.max(0, Math.ceil(ms / 1000));
    var m = Math.floor(s / 60);
    s = s % 60;
    return m + ":" + (s < 10 ? "0" : "") + s;
  }

  function submit(page, action) {
    if (page.dataset.pftSubmitted) return;
    page.dataset.pftSubmitted = "1";
    stopTimer();
    var selected = page.querySelector(".pft-option.pft-selected");
    var response = {
      item: page.dataset.pftItem,
      action: action,
      choice: action === "answer" && selected ? selected.dataset.choice : null,
      rt: Math.round(performance.now() - Number(page.dataset.pftShown))
    };
    page.classList.add("pft-locked");
    Shiny.setInputValue("pft_response", response, { priority: "event" });
    trigger_button(action === "skip" ? "pft_skip" : "pft_continue");
  }

  function initItem(page) {
    page.dataset.pftShown = String(performance.now());
    var cont = page.querySelector("#pft_continue");

    page.querySelectorAll("button.pft-option").forEach(function (opt) {
      opt.addEventListener("click", function () {
        if (page.dataset.pftSubmitted) return;
        page.querySelectorAll(".pft-option").forEach(function (o) {
          o.classList.remove("pft-selected");
          o.setAttribute("aria-checked", "false");
        });
        opt.classList.add("pft-selected");
        opt.setAttribute("aria-checked", "true");
        if (cont) cont.disabled = false;
      });
    });
    if (cont) cont.addEventListener("click", function () {
      if (!page.querySelector(".pft-option.pft-selected")) return;
      submit(page, "answer");
    });
    var skip = page.querySelector("#pft_skip");
    if (skip) skip.addEventListener("click", function () { submit(page, "skip"); });

    // Countdown (nur Haupttest). Die Restzeit kommt vom Server und wird ab
    // dem Seitenaufbau heruntergezählt.
    stopTimer();
    var left = page.dataset.pftTimeLeft;
    if (left !== undefined) {
      var deadline = performance.now() + Number(left) * 1000;
      var display = page.querySelector(".pft-timer-value");
      var timer = page.querySelector(".pft-timer");
      var tick = function () {
        var rest = deadline - performance.now();
        if (display) display.textContent = formatTime(rest);
        if (timer) timer.classList.toggle("pft-timer-low", rest <= 30000);
        if (rest <= 0) submit(page, "timeout");
      };
      tick();
      if (!page.dataset.pftSubmitted) timerId = setInterval(tick, 250);
    }
  }

  function decorate() {
    var page = document.querySelector(".pft-page");
    document.body.classList.toggle("pft", !!page);
    if (!page) {
      stopTimer();
      return;
    }
    if (page.dataset.pftInit) return;
    page.dataset.pftInit = "1";
    if (page.classList.contains("pft-item")) initItem(page);
  }

  function start() {
    decorate();
    new MutationObserver(decorate).observe(document.body, { childList: true, subtree: true });
  }
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", start);
  else start();
})();
