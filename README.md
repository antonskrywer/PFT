# PFT – Paper Folding Test for psychTestR

Online-Version des Paper Folding Test (Vz-2-BRACE) als R-Paket auf Basis von
[psychTestR](https://github.com/pmcharrison/psychTestR).

## Installation

```r
devtools::install_github("antonskrywer/PFT")
```

## Verwendung

```r
# Eigenständige Sitzung (Sprachen: en, de = Sie, de_f = Du)
PFT::PFT_standalone(languages = c("en", "de", "de_f"))

# Als Modul in einer Batterie
psychTestR::join(PFT::PFT(), ...)
```

## Ablauf

1. Willkommensseite, Instruktion
2. Beispiel-Item mit Rückmeldung (richtig/falsch) und Lösungsgrafik
3. Hinweisseite, dann Haupttest: 20 Items in der Reihenfolge
   1, 11, 2, 12, …, 10, 20, gemeinsames Zeitlimit von 6 Minuten mit Countdown
4. Übersprungene Items kommen ans Ende und werden erneut gezeigt, solange Zeit bleibt
5. Ergebnisseite: „You solved X out of 20 tasks correctly.“

## Gespeicherte Ergebnisse (Modul `PFT`)

| Feld | Bedeutung |
|---|---|
| `taskXX_answer` | gewählte Option A–E (`NA` ohne Antwort) |
| `taskXX_correct` | richtig/falsch (`NA` ohne Antwort) |
| `taskXX_skipped` | wie oft übersprungen |
| `taskXX_rt` | Bearbeitungszeit in s, summiert über alle Darbietungen |
| `score`, `n_answered`, `time_used`, `time_up`, `sequence` | Gesamtwerte |
| `demo_answer`, `demo_correct` | Beispiel-Item |

Nicht erreichte Items erscheinen nicht in den Ergebnissen.

## Entwicklung

- Texte: `data_raw/dicts/PFT_dict.csv`, danach `source("data_raw/build_data.R")`
- Bilder: Originale in `stimuli/`, zugeschnitten über `data_raw/crop_stimuli.R`
  nach `inst/www/pft/img/`
- Lösungsschlüssel und Reihenfolge: `R/items.R`
