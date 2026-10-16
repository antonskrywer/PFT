#' Paper Folding Test (Modul)
#'
#' Modul-Funktion für den Paper Folding Test (Vz-2-BRACE) zur Einbindung in
#' eine psychTestR-Timeline oder Batterie. Für eigenständige Testsitzungen
#' siehe \code{\link{PFT_standalone}()}.
#'
#' Ablauf: Willkommensseite, Instruktion, Beispiel-Item mit Rückmeldung und
#' Lösungsgrafik, Hinweisseite, danach der Haupttest. Beide Teile der
#' Papierversion laufen in einem Block in der Reihenfolge 1, 11, 2, 12, ...,
#' 10, 20 mit einem gemeinsamen Zeitlimit (Standard: 6 Minuten, sichtbarer
#' Countdown). Übersprungene Items kommen ans Ende der Warteschlange und
#' werden erneut gezeigt, solange Zeit bleibt. Bei Zeitablauf endet der Test
#' sofort.
#'
#' Gespeichert wird (im Modul \code{label}) für jedes Item, das mindestens
#' einmal beantwortet oder übersprungen wurde:
#' \describe{
#'   \item{\code{taskXX_answer}}{gewählte Option (A-E), \code{NA} ohne Antwort}
#'   \item{\code{taskXX_correct}}{\code{TRUE}/\code{FALSE}, \code{NA} ohne Antwort}
#'   \item{\code{taskXX_skipped}}{wie oft das Item übersprungen wurde (0 = nie)}
#'   \item{\code{taskXX_rt}}{Bearbeitungszeit in Sekunden, summiert über alle
#'     Darbietungen des Items}
#' }
#' Items, die vor Zeitablauf nicht erreicht wurden, fehlen in den Ergebnissen.
#' Außerdem: \code{score} (Anzahl richtiger Antworten), \code{n_answered},
#' \code{time_used} (Sekunden), \code{time_up} (Zeit abgelaufen),
#' \code{sequence} (Darbietungsprotokoll, z. B. \code{"1:A 11:skip 2:D"}) sowie
#' \code{demo_answer} und \code{demo_correct} für das Beispiel-Item.
#'
#' @param label (Character scalar) Modul-Label, unter dem die Ergebnisse
#'   gespeichert werden.
#' @param dict (i18n_dict) Dictionary, Standard \code{\link{pft_dict}}.
#' @param time_limit (Numeric scalar) Zeitlimit des Haupttests in Sekunden.
#' @param feedback (Boolean) Am Ende eine Seite mit dem Ergebnis zeigen
#'   ("You solved X out of 20 tasks correctly.").
#' @export
PFT <- function(label = "PFT",
                dict = PFT::pft_dict,
                time_limit = pft_time_limit,
                feedback = TRUE) {
  stopifnot(is.character(label), length(label) == 1L,
            is.numeric(time_limit), length(time_limit) == 1L, time_limit > 0)
  pft_add_resource_path()
  psychTestR::join(
    psychTestR::begin_module(label),
    psychTestR::new_timeline(psychTestR::join(
      pft_text_page("WELCOME_TITLE", "WELCOME_TEXT"),
      pft_instruction_page(),
      pft_demo_page(),
      pft_demo_feedback_page(),
      pft_text_page(NULL, "START_TEXT"),
      pft_main_test(time_limit, label),
      if (feedback) pft_result_page(label, final = FALSE)
    ), dict = dict),
    psychTestR::end_module()
  )
}

# ---- Instruktion ----

# Text plus das Beispiel-Item als (nicht anklickbare) Abbildung, damit
# "oben" und "darunter" im Text einen Bezug haben
pft_instruction_page <- function() {
  psychTestR::one_button_page(
    pft_wrap(
      class = "pft-text pft-instruction",
      shiny::h3(class = "pft-title", psychTestR::i18n("INSTRUCTION_TITLE")),
      shiny::div(class = "pft-body", psychTestR::i18n("INSTRUCTION_TEXT")),
      shiny::div(class = "pft-task",
                 shiny::img(src = pft_img_url("Instructiontask.png"), alt = "")),
      pft_option_cards(paste0("InstructionAnswer", seq_along(pft_options), ".png"),
                       interactive = FALSE)
    ),
    button_text = psychTestR::i18n("CONTINUE")
  )
}

# ---- Beispiel-Item ----

pft_demo_page <- function() {
  psychTestR::reactive_page(function(state, ...) {
    pft_item_page(
      label = "demo",
      item = "demo",
      skip = FALSE,
      intro = psychTestR::i18n("DEMO_INTRO"),
      on_complete = function(answer, state, ...) {
        choice <- if (identical(answer$action, "answer")) answer$choice else NA_character_
        psychTestR::set_local("demo_answer", choice, state)
        psychTestR::save_result(state, "demo_answer", choice)
        psychTestR::save_result(state, "demo_correct", identical(choice, pft_demo_key))
      }
    )
  })
}

pft_demo_feedback_page <- function() {
  psychTestR::reactive_page(function(state, ...) {
    choice <- psychTestR::get_local("demo_answer", state)
    correct <- identical(choice, pft_demo_key)
    marks <- c(stats::setNames("pft-correct", pft_demo_key))
    if (!correct && !is.null(choice) && !is.na(choice)) {
      marks[choice] <- "pft-wrong"
    }
    psychTestR::one_button_page(
      pft_wrap(
        class = "pft-text pft-demo-feedback",
        shiny::p(class = paste("pft-verdict", if (correct) "pft-verdict-correct" else "pft-verdict-wrong"),
                 psychTestR::i18n(if (correct) "DEMO_CORRECT" else "DEMO_INCORRECT")),
        shiny::div(class = "pft-task",
                   shiny::img(src = pft_img_url("Instructiontask.png"), alt = "")),
        pft_option_cards(paste0("InstructionAnswer", seq_along(pft_options), ".png"),
                         interactive = FALSE, marks = marks),
        shiny::div(class = "pft-body", psychTestR::i18n("DEMO_SOLUTION")),
        shiny::div(class = "pft-explanation",
                   shiny::img(src = pft_img_url("Instructions.png"), alt = "")),
        shiny::div(class = "pft-body", psychTestR::i18n("DEMO_EXPLANATION"))
      ),
      button_text = psychTestR::i18n("CONTINUE")
    )
  })
}

# ---- Haupttest ----

pft_time_left <- function(state, time_limit) {
  start <- psychTestR::get_local("t_start", state)
  time_limit - as.numeric(difftime(Sys.time(), start, units = "secs"))
}

pft_main_test <- function(time_limit, label) {
  psychTestR::join(
    psychTestR::code_block(function(state, ...) {
      psychTestR::set_local("queue", pft_item_order, state)
      psychTestR::set_local("records", list(), state)
      psychTestR::set_local("sequence", character(), state)
      psychTestR::set_local("time_up", FALSE, state)
      psychTestR::set_local("t_start", Sys.time(), state)
    }),
    psychTestR::while_loop(
      test = function(state, ...) {
        length(psychTestR::get_local("queue", state)) > 0 &&
          !isTRUE(psychTestR::get_local("time_up", state)) &&
          pft_time_left(state, time_limit) > 0
      },
      logic = psychTestR::reactive_page(function(state, ...) {
        item <- psychTestR::get_local("queue", state)[1]
        pft_item_page(
          label = "item",
          item = item,
          time_left = pft_time_left(state, time_limit),
          skip = TRUE,
          on_complete = function(answer, state, ...) {
            pft_register_response(answer, state, time_limit)
          }
        )
      })
    ),
    psychTestR::code_block(function(state, ...) pft_save_results(state, label))
  )
}

# Verarbeitet eine Antwort aus der Item-Seite und aktualisiert die
# Warteschlange. Antworten, die mehr als `grace` Sekunden nach Ablauf der Zeit
# eintreffen (z. B. nach einem Verbindungsabbruch), zählen nicht.
pft_register_response <- function(answer, state, time_limit, grace = 5) {
  queue <- psychTestR::get_local("queue", state)
  item <- queue[1]
  action <- answer$action
  if (is.null(action) || !identical(as.character(answer$item), as.character(item))) {
    return(invisible())
  }
  if (identical(action, "timeout") || pft_time_left(state, time_limit) < -grace) {
    psychTestR::set_local("time_up", TRUE, state)
    return(invisible())
  }
  if (!action %in% c("answer", "skip")) return(invisible())
  if (identical(action, "answer") && !isTRUE(answer$choice %in% pft_options)) return(invisible())

  records <- psychTestR::get_local("records", state)
  key <- as.character(item)
  rec <- records[[key]]
  if (is.null(rec)) rec <- list(answer = NA_character_, correct = NA, skipped = 0L, rt = 0)
  rt <- suppressWarnings(as.numeric(answer$rt))
  if (length(rt) == 1L && !is.na(rt)) rec$rt <- rec$rt + rt / 1000

  if (identical(action, "answer")) {
    rec$answer <- answer$choice
    rec$correct <- identical(answer$choice, pft_key[item])
    queue <- queue[-1]
    entry <- paste0(item, ":", answer$choice)
  } else {
    rec$skipped <- rec$skipped + 1L
    queue <- c(queue[-1], item)
    entry <- paste0(item, ":skip")
  }
  records[[key]] <- rec
  psychTestR::set_local("records", records, state)
  psychTestR::set_local("queue", queue, state)
  psychTestR::set_local("sequence", c(psychTestR::get_local("sequence", state), entry), state)
  invisible()
}

pft_save_results <- function(state, label) {
  records <- psychTestR::get_local("records", state)
  start <- psychTestR::get_local("t_start", state)
  items <- sort(as.integer(names(records)))
  for (item in items) {
    rec <- records[[as.character(item)]]
    prefix <- sprintf("task%02d_", item)
    psychTestR::save_result(state, paste0(prefix, "answer"), rec$answer)
    psychTestR::save_result(state, paste0(prefix, "correct"), rec$correct)
    psychTestR::save_result(state, paste0(prefix, "skipped"), rec$skipped)
    psychTestR::save_result(state, paste0(prefix, "rt"), round(rec$rt, 3))
  }
  score <- sum(vapply(records, function(r) isTRUE(r$correct), logical(1)))
  n_answered <- sum(vapply(records, function(r) !is.na(r$answer), logical(1)))
  psychTestR::save_result(state, "score", score)
  psychTestR::save_result(state, "n_answered", n_answered)
  psychTestR::save_result(state, "time_used",
                          round(as.numeric(difftime(Sys.time(), start, units = "secs")), 1))
  psychTestR::save_result(state, "time_up", isTRUE(psychTestR::get_local("time_up", state)) ||
                            length(psychTestR::get_local("queue", state)) > 0)
  psychTestR::save_result(state, "sequence",
                          paste(psychTestR::get_local("sequence", state), collapse = " "))
  # Global, damit die Ergebnisseite auch nach end_module() darauf zugreifen kann
  psychTestR::set_global(pft_score_global(label), score, state)
}

pft_score_global <- function(label) paste0("pft_score.", label)

# Ergebnisseite: in Batterien mit Weiter-Button, im Standalone als Schlussseite
pft_result_page <- function(label, final = FALSE) {
  psychTestR::reactive_page(function(state, ...) {
    score <- psychTestR::get_global(pft_score_global(label), state)
    if (is.null(score)) score <- 0L
    content <- pft_wrap(
      class = "pft-text pft-result",
      shiny::h3(class = "pft-title",
                psychTestR::i18n("RESULT", sub = c(n_correct = score, n_items = length(pft_key)))),
      if (final) shiny::div(class = "pft-body", psychTestR::i18n("RESULTS_SAVED"))
    )
    if (final) {
      psychTestR::final_page(content)
    } else {
      psychTestR::one_button_page(content, button_text = psychTestR::i18n("CONTINUE"))
    }
  })
}
