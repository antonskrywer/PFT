# Seitenbausteine des PFT. Alle Seiten stecken in einem div.pft-page; pft.js
# setzt dann die Klasse "pft" auf <body>, damit das CSS nur auf PFT-Seiten
# greift (wichtig in Batterien mit anderen Tests).

# Ressourcenpfad für die Bilder (inst/www/pft/img), wird in PFT() registriert
pft_www_prefix <- "pft_www"

pft_add_resource_path <- function() {
  shiny::addResourcePath(pft_www_prefix, system.file("www", "pft", package = "PFT"))
}

pft_img_url <- function(file) {
  paste0(pft_www_prefix, "/img/", file)
}

# CSS und JS als htmlDependency, damit sie auch in Batterien geladen werden
pft_design_dependency <- function() {
  htmltools::htmlDependency(
    name       = "pft-design",
    version    = as.character(utils::packageVersion("PFT")),
    src        = system.file("www", "pft", package = "PFT"),
    stylesheet = "pft.css",
    script     = "pft.js"
  )
}

pft_wrap <- function(..., class = NULL) {
  shiny::div(class = paste(c("pft-page", class), collapse = " "),
             pft_design_dependency(), ...)
}

# Textseite mit Titel und Weiter-Button
pft_text_page <- function(title_key = NULL, text_key, label = NULL) {
  psychTestR::one_button_page(
    pft_wrap(
      class = "pft-text",
      if (!is.null(title_key)) shiny::h3(class = "pft-title", psychTestR::i18n(title_key)),
      shiny::div(class = "pft-body", psychTestR::i18n(text_key))
    ),
    button_text = psychTestR::i18n("CONTINUE")
  )
}

# Antwortkarten A-E. `marks` (optional) ist ein benannter Vektor
# Buchstabe -> CSS-Klasse, z. B. für die Lösungsanzeige auf der Feedbackseite.
pft_option_cards <- function(files, interactive = TRUE, marks = character()) {
  cards <- lapply(seq_along(pft_options), function(k) {
    letter <- pft_options[k]
    content <- list(
      shiny::span(class = "pft-letter", letter),
      shiny::img(src = pft_img_url(files[k]), alt = letter, draggable = "false")
    )
    cls <- paste(c("pft-option", marks[letter][!is.na(marks[letter])]), collapse = " ")
    if (interactive) {
      shiny::tags$button(type = "button", class = cls, `data-choice` = letter,
                         role = "radio", `aria-checked` = "false",
                         `aria-label` = letter, content)
    } else {
      shiny::div(class = cls, content)
    }
  })
  shiny::div(class = "pft-options",
             role = if (interactive) "radiogroup",
             cards)
}

# UI einer Item-Seite (Haupttest und Beispiel-Item)
# item: Item-ID (1-20) oder "demo"; time_left: Restzeit in Sekunden oder NULL
pft_item_ui <- function(item, time_left = NULL, skip = TRUE, intro = NULL) {
  if (identical(item, "demo")) {
    task_file <- "Instructiontask.png"
    option_files <- paste0("InstructionAnswer", seq_along(pft_options), ".png")
  } else {
    task_file <- paste0("Task", item, ".png")
    option_files <- paste0("Task", item, "_Answer", seq_along(pft_options), ".png")
  }
  pft_wrap(
    class = "pft-item",
    `data-pft-item` = item,
    `data-pft-time-left` = if (!is.null(time_left)) format(round(time_left, 1), nsmall = 1),
    if (!is.null(time_left)) {
      shiny::div(class = "pft-timer", role = "timer",
                 shiny::span(class = "pft-timer-label", psychTestR::i18n("TIME_LEFT")),
                 shiny::span(class = "pft-timer-value", pft_format_time(time_left)))
    },
    if (!is.null(intro)) shiny::p(class = "pft-intro", intro),
    shiny::p(class = "pft-prompt", psychTestR::i18n("ITEM_PROMPT")),
    shiny::div(class = "pft-task",
               shiny::img(src = pft_img_url(task_file), alt = "", draggable = "false")),
    pft_option_cards(option_files),
    shiny::div(
      class = "pft-buttons",
      shiny::tags$button(id = "pft_continue", type = "button",
                         class = "btn btn-default pft-continue", disabled = NA,
                         psychTestR::i18n("CONTINUE")),
      if (skip) shiny::tags$button(id = "pft_skip", type = "button",
                                   class = "btn btn-default pft-skip",
                                   psychTestR::i18n("SKIP"))
    )
  )
}

pft_format_time <- function(seconds) {
  seconds <- max(0, ceiling(seconds))
  sprintf("%d:%02d", seconds %/% 60, seconds %% 60)
}

# pft.js schickt beim Klick auf Weiter/Überspringen bzw. bei Zeitablauf
# input$pft_response = list(item, action = "answer"/"skip"/"timeout",
# choice, rt [ms]).
pft_get_answer <- function(input, ...) {
  res <- input$pft_response
  if (is.null(res)) return(list(action = "none"))
  res
}

pft_item_page <- function(label, item, time_left = NULL, skip = TRUE, intro = NULL,
                          on_complete = NULL) {
  psychTestR::page(
    ui = pft_item_ui(item, time_left = time_left, skip = skip, intro = intro),
    label = label,
    get_answer = pft_get_answer,
    save_answer = FALSE,
    on_complete = on_complete
  )
}
