# Lösungsschlüssel aus Paperfolding_AnswerKey.docx (Teil 1: Items 1-10,
# Teil 2: Items 11-20). Antwortbild TaskX_AnswerK.png entspricht Option
# LETTERS[K].
pft_key <- c(
  "A", "D", "B", "D", "B", "E", "A", "C", "E", "E",
  "C", "B", "A", "E", "B", "A", "E", "D", "D", "C"
)

# Lösung des Beispiel-Items (Instructiontask.png)
pft_demo_key <- "C"

# Beide Teile in einem Block, abwechselnd: 1, 11, 2, 12, ..., 10, 20
pft_item_order <- as.vector(rbind(1:10, 11:20))

# Bearbeitungszeit des Haupttests in Sekunden (2 x 3 Minuten)
pft_time_limit <- 360

pft_options <- LETTERS[1:5]
