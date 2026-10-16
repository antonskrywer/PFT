test_that("Schlüssel und Reihenfolge sind vollständig", {
  expect_length(pft_key, 20)
  expect_true(all(pft_key %in% pft_options))
  expect_equal(pft_item_order, c(1, 11, 2, 12, 3, 13, 4, 14, 5, 15,
                                 6, 16, 7, 17, 8, 18, 9, 19, 10, 20))
  expect_equal(pft_time_limit, 360)
})

test_that("alle Bilder liegen im Paket", {
  img <- system.file("www", "pft", "img", package = "PFT")
  files <- c(paste0("Task", 1:20, ".png"),
             as.vector(outer(1:20, 1:5, function(i, k) paste0("Task", i, "_Answer", k, ".png"))),
             "Instructiontask.png", paste0("InstructionAnswer", 1:5, ".png"),
             "Instructions.png")
  expect_true(all(file.exists(file.path(img, files))))
})

test_that("Dictionary enthält alle Schlüssel in allen Sprachen", {
  keys <- c("TITLE", "CONTINUE", "SKIP", "WELCOME_TITLE", "WELCOME_TEXT",
            "INSTRUCTION_TITLE", "INSTRUCTION_TEXT", "ITEM_PROMPT", "DEMO_INTRO",
            "DEMO_CORRECT", "DEMO_INCORRECT", "DEMO_SOLUTION", "DEMO_EXPLANATION",
            "START_TEXT", "TIME_LEFT", "RESULT", "RESULTS_SAVED")
  for (lang in c("en", "de", "de_f")) {
    for (key in keys) expect_true(nzchar(pft_dict$translate(key, lang)), info = paste(key, lang))
  }
  expect_match(pft_dict$translate("RESULT", "en"), "{{n_correct}}", fixed = TRUE)
})

# Warteschlange und Ergebnisse mit simulierten lokalen Variablen prüfen
with_fake_locals <- function(code, t_start = Sys.time()) {
  env <- new.env()
  env$locals <- list(queue = pft_item_order, records = list(), sequence = character(),
                     time_up = FALSE, t_start = t_start)
  local_mocked_bindings(
    get_local = function(key, state) env$locals[[key]],
    set_local = function(key, value, state) env$locals[[key]] <- value,
    .package = "psychTestR"
  )
  code(env)
}

test_that("Antworten und Überspringen aktualisieren die Warteschlange", {
  with_fake_locals(function(env) {
    pft_register_response(list(item = "1", action = "answer", choice = "A", rt = 2000), NULL, 360)
    expect_equal(env$locals$queue[1], 11)
    expect_true(env$locals$records[["1"]]$correct)
    expect_equal(env$locals$records[["1"]]$rt, 2)

    pft_register_response(list(item = "11", action = "skip", rt = 1000), NULL, 360)
    expect_equal(env$locals$queue[1], 2)
    expect_equal(tail(env$locals$queue, 1), 11)
    expect_equal(env$locals$records[["11"]]$skipped, 1L)

    pft_register_response(list(item = "2", action = "answer", choice = "A", rt = 500), NULL, 360)
    expect_false(env$locals$records[["2"]]$correct)

    # Antwort für ein anderes Item als das aktuelle wird ignoriert
    pft_register_response(list(item = "7", action = "answer", choice = "A", rt = 500), NULL, 360)
    expect_equal(env$locals$queue[1], 12)

    # Übersprungenes Item später beantwortet: RT wird summiert
    env$locals$queue <- c(11, env$locals$queue[env$locals$queue != 11])
    pft_register_response(list(item = "11", action = "answer", choice = "C", rt = 3000), NULL, 360)
    expect_true(env$locals$records[["11"]]$correct)
    expect_equal(env$locals$records[["11"]]$rt, 4)
    expect_equal(env$locals$sequence, c("1:A", "11:skip", "2:A", "11:C"))
  })
})

test_that("Zeitablauf beendet den Test ohne Eintrag", {
  with_fake_locals(function(env) {
    pft_register_response(list(item = "1", action = "timeout", rt = 360000), NULL, 360)
    expect_true(env$locals$time_up)
    expect_length(env$locals$records, 0)
  })
  # Antwort lange nach Ablauf der Zeit zählt nicht
  with_fake_locals(function(env) {
    pft_register_response(list(item = "1", action = "answer", choice = "A", rt = 1), NULL, 360)
    expect_true(env$locals$time_up)
    expect_length(env$locals$records, 0)
  }, t_start = Sys.time() - 400)
})
