#' PFT Standalone
#'
#' Startet eine eigenständige Testsitzung für den Paper Folding Test. Die
#' Ergebnisse werden am Ende gespeichert, die Schlussseite zeigt die Anzahl
#' richtig gelöster Aufgaben.
#'
#' @param languages (Character vector) Verfügbare Sprachen: \code{"en"},
#'   \code{"de"} (Sie) und \code{"de_f"} (Du). Standard ist die erste; über
#'   den URL-Parameter \code{?language=de} lässt sich eine andere wählen.
#' @param dict (i18n_dict) Dictionary, Standard \code{\link{pft_dict}}.
#' @param admin_password (Character scalar) Passwort für das Admin-Panel.
#' @param researcher_email (Character scalar) Kontaktadresse für Probleme,
#'   erscheint im psychTestR-Fußbereich.
#' @param time_limit (Numeric scalar) Zeitlimit des Haupttests in Sekunden.
#' @param ... Weitere Argumente an \code{psychTestR::test_options()}.
#' @export
PFT_standalone <- function(languages = c("en", "de", "de_f"),
                           dict = PFT::pft_dict,
                           admin_password = "conifer",
                           researcher_email = NULL,
                           time_limit = pft_time_limit,
                           ...) {
  stopifnot(is.character(languages), all(languages %in% c("en", "de", "de_f")))
  label <- "PFT"
  elts <- psychTestR::join(
    PFT(label = label, dict = dict, time_limit = time_limit, feedback = FALSE),
    psychTestR::elt_save_results_to_disk(complete = TRUE),
    psychTestR::new_timeline(pft_result_page(label, final = TRUE), dict = dict)
  )
  title <- vapply(languages, function(lang) dict$translate("TITLE", lang), character(1))
  psychTestR::make_test(
    elts,
    opt = psychTestR::test_options(
      title = title,
      admin_password = admin_password,
      researcher_email = researcher_email,
      demo = FALSE,
      languages = languages,
      ...
    )
  )
}
