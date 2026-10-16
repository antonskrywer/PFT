# data_raw/build_data.R
# Erzeugt data/pft_dict.rda aus data_raw/dicts/PFT_dict.csv.
# Working Directory = Paket-Root. Die CSV muss UTF-8-kodiert sein.
# Sprachen: en, de (Sie), de_f (Du).

pft_dict_raw <- utils::read.csv2("data_raw/dicts/PFT_dict.csv",
                                 encoding = "UTF-8", fileEncoding = "UTF-8",
                                 stringsAsFactors = FALSE, check.names = FALSE)
stopifnot(identical(names(pft_dict_raw), c("key", "en", "de", "de_f")),
          !anyDuplicated(pft_dict_raw$key),
          !anyNA(pft_dict_raw),
          all(nzchar(as.matrix(pft_dict_raw))))

pft_dict <- psychTestR::i18n_dict$new(pft_dict_raw)

dir.create("data", showWarnings = FALSE)
save(pft_dict, file = "data/pft_dict.rda", compress = "xz")
