# data_raw/crop_stimuli.R
# Schneidet den weißen Rand der Originalbilder in stimuli/ zu und legt sie
# unter inst/www/pft/img/ ab. Die Originale bleiben unverändert.
# Working Directory = Paket-Root.
#
# Hintergrund: Die Antwortbilder haben unterschiedlich große Leinwände und das
# Quadrat sitzt nicht immer mittig. Nach dem Zuschnitt umschließt jedes Bild
# nur noch die Zeichnung plus einen schmalen Rand, die Karten werden dadurch
# im Browser gleich groß dargestellt.
# Nebenbei: "Instructions .png" (mit Leerzeichen) wird zu "Instructions.png".

src_dir <- "stimuli"
out_dir <- "inst/www/pft/img"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# Anteil der Bildgröße, der als Rand um die Zeichnung stehen bleibt
margin_rel <- 0.04

crop_png <- function(src, dest) {
  a <- png::readPNG(src)
  if (length(dim(a)) == 2) a <- array(a, c(dim(a), 1))
  ch <- dim(a)[3]
  rgb <- if (ch >= 3) a[, , 1:3, drop = FALSE] else a[, , c(1, 1, 1), drop = FALSE]
  alpha <- if (ch %in% c(2, 4)) a[, , ch] else matrix(1, dim(a)[1], dim(a)[2])
  # Auf weißen Hintergrund legen (transparente Pixel -> weiß)
  for (k in 1:3) rgb[, , k] <- rgb[, , k] * alpha + (1 - alpha)
  lum <- (rgb[, , 1] + rgb[, , 2] + rgb[, , 3]) / 3
  ink <- lum < 0.6
  rows <- which(rowSums(ink) > 0)
  cols <- which(colSums(ink) > 0)
  if (!length(rows)) stop("Keine Zeichnung gefunden in ", src)
  m <- ceiling(margin_rel * max(length(rows), length(cols)) + 2)
  r <- max(1, min(rows) - m):min(dim(a)[1], max(rows) + m)
  c <- max(1, min(cols) - m):min(dim(a)[2], max(cols) + m)
  out <- rgb[r, c, , drop = FALSE]
  # Falls der Rand am Bildrand abgeschnitten wurde, weiß auffüllen
  pad <- function(img, top, bottom, left, right) {
    h <- dim(img)[1] + top + bottom
    w <- dim(img)[2] + left + right
    res <- array(1, c(h, w, 3))
    res[top + seq_len(dim(img)[1]), left + seq_len(dim(img)[2]), ] <- img
    res
  }
  out <- pad(out,
             top = max(0, m - (min(rows) - 1)), bottom = max(0, m - (dim(a)[1] - max(rows))),
             left = max(0, m - (min(cols) - 1)), right = max(0, m - (dim(a)[2] - max(cols))))
  png::writePNG(out, dest)
  invisible(dim(out)[1:2])
}

files <- list.files(src_dir, pattern = "\\.png$")
for (f in files) {
  dest_name <- gsub("\\s+", "", f)
  dims <- crop_png(file.path(src_dir, f), file.path(out_dir, dest_name))
  message(sprintf("%-28s -> %-26s %4d x %4d", f, dest_name, dims[2], dims[1]))
}
