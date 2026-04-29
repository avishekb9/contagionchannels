# =============================================================================
#  DATASET.R — build the bundled .rda files in /data from the source XLSX
#  files in /inst/extdata. Run once via `Rscript data-raw/DATASET.R` from
#  the package root, or via `usethis::use_data(g20_returns, overwrite = TRUE)`.
# =============================================================================

suppressMessages({
  library(readxl); library(zoo); library(xts)
})

PKG_ROOT <- if (file.exists(file.path(getwd(), "DESCRIPTION"))) getwd() else
            normalizePath(file.path(getwd(), ".."))

# --- 1. G20 returns ----------------------------------------------------------
g20_path <- file.path(PKG_ROOT, "inst", "extdata", "G20.xlsx")
g20 <- suppressMessages(read_excel(g20_path))
g20_dates <- as.Date(g20$Date, format = "%d/%m/%Y")
g20_returns <- xts(as.matrix(g20[, -1]), order.by = g20_dates)
g20_returns <- na.omit(g20_returns)
storage.mode(g20_returns) <- "double"

# --- 2. Channel proxies -----------------------------------------------------
read_proxy <- function(s, path) {
  d <- suppressMessages(read_excel(path, sheet = s, col_names = FALSE, skip = 4))
  if (ncol(d) < 2) return(data.frame(Date = as.Date(character(0)), val = numeric(0)))
  dcol <- d[[1]]; vcol <- d[[2]]
  dnum <- suppressWarnings(as.numeric(dcol))
  if (all(is.finite(dnum)) && stats::median(dnum, na.rm = TRUE) > 30000 &&
      stats::median(dnum, na.rm = TRUE) < 60000) {
    dt <- as.Date("1899-12-30") + as.integer(dnum)
  } else dt <- suppressWarnings(as.Date(dcol))
  data.frame(Date = dt, val = suppressWarnings(as.numeric(vcol)))
}

cp_path <- file.path(PKG_ROOT, "inst", "extdata", "channel_proxies.xlsx")
sheet_to_col <- c(FIN_vix = "vix", FIN_hy_spread = "hy_spread",
                  FIN_stress_index = "stress_index", TRA_usd_index = "usd_index",
                  GEO_gpr = "gpr", GEO_geo_events = "geo_events",
                  BEH_vix_slope = "vix_slope", BEH_fear_proxy = "fear_proxy",
                  BEH_sentiment = "sentiment", MON_fed_rate = "fed_rate",
                  MON_dgs10 = "dgs10", MON_term_spread = "term_spread",
                  MON_qe_dummy = "qe_dummy")

all_dates <- as.Date(zoo::index(g20_returns))
channel_proxies <- data.frame(Date = all_dates)
for (s in names(sheet_to_col)) {
  d <- read_proxy(s, cp_path)
  v <- d$val[match(all_dates, d$Date)]
  v <- zoo::na.locf(v, na.rm = FALSE)
  v <- zoo::na.locf(v, na.rm = FALSE, fromLast = TRUE)
  channel_proxies[[sheet_to_col[s]]] <- v
}
channel_proxies$qe_dummy[is.na(channel_proxies$qe_dummy)] <- 0

# --- 3. Crisis periods ------------------------------------------------------
crisis_periods <- list(
  PreCrisis        = c("2006-01-12", "2007-07-31"),
  GFC              = c("2007-08-01", "2009-06-30"),
  ESDC             = c("2009-12-01", "2012-06-30"),
  CSC              = c("2015-06-15", "2016-12-31"),
  PreCOVID         = c("2017-01-01", "2020-01-31"),
  COVID            = c("2020-02-01", "2021-12-31"),
  RusUkr           = c("2022-02-01", "2023-12-31"),
  MidEastTariffs   = c("2024-01-01", "2026-03-18"))

# --- 4. Save to /data -------------------------------------------------------
data_dir <- file.path(PKG_ROOT, "data")
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)
save(g20_returns,     file = file.path(data_dir, "g20_returns.rda"),     compress = "xz")
save(channel_proxies, file = file.path(data_dir, "channel_proxies.rda"), compress = "xz")
save(crisis_periods,  file = file.path(data_dir, "crisis_periods.rda"),  compress = "xz")
cat(sprintf("Saved 3 datasets to %s\n", data_dir))
