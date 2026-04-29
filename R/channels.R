#' Construct the Five-Channel Composites
#'
#' Builds the five contagion-channel composites (Trade, Financial,
#' Geopolitical, Behavioural, Monetary Policy) from a data.frame of raw
#' channel proxies. The construction is engineered for orthogonal
#' identification: the trade composite uses log-returns of a broad
#' trade-weighted dollar index (genuinely time-varying), the behavioural
#' composite is orthogonalised against the financial composite to avoid
#' VIX-derivative contamination, and the monetary composite uses a
#' first-differenced policy rate to remove persistence-induced first-stage
#' F-inflation.
#'
#' @param proxy_grid A data.frame with the following columns aligned on the
#'   same daily date grid: \code{vix}, \code{hy_spread},
#'   \code{stress_index}, \code{usd_index}, \code{gpr},
#'   \code{geo_events}, \code{sentiment}, \code{fed_rate},
#'   \code{term_spread}, \code{qe_dummy}.
#' @return A data.frame with columns \code{Date}, \code{Trade},
#'   \code{Financial}, \code{Geopolitical}, \code{Behavioral}, and
#'   \code{Monetary_Policy}; each composite is z-scored within sample.
#' @references Stock, J. H., & Watson, M. W. (2018). Identification and
#'   Estimation of Dynamic Causal Effects in Macroeconomics Using External
#'   Instruments. Economic Journal, 128(610), 917-948.
#'   \doi{10.1111/ecoj.12593}.
#'
#'   Romer, C. D., & Romer, D. H. (2004). A New Measure of Monetary Shocks.
#'   American Economic Review, 94(4), 1055-1084.
#'   \doi{10.1257/0002828042002651}.
#' @examples
#' \donttest{
#' d <- load_paper_data()
#' ch <- build_channel_composites(d$proxies)
#' head(ch); cor(ch[, -1])
#' }
#' @export
build_channel_composites <- function(proxy_grid) {
  pg <- proxy_grid; n <- nrow(pg)

  # Trade composite: time-varying via DTWEXBGS daily log-returns
  usd <- pg$usd_index
  usd_ret <- c(0, diff(log(pmax(usd, 1e-9)))) * 100
  usd_ret[!is.finite(usd_ret)] <- 0
  trade <- zscore(usd_ret)

  # Financial composite: VIX + HY OAS + STLFSI4
  fin_z <- cbind(zscore(pg$vix), zscore(pg$hy_spread), zscore(pg$stress_index))
  financial <- rowMeans(fin_z, na.rm = TRUE)

  # Geopolitical composite: GPR + geo events
  geo_z <- cbind(zscore(pg$gpr), zscore(pg$geo_events))
  geopolitical <- rowMeans(geo_z, na.rm = TRUE)

  # Behavioural composite: SENTIMENT only, orthogonalised to financial
  beh_raw <- zscore(pg$sentiment)
  behavioral <- orthogonalise_residual(beh_raw, financial)

  # Monetary composite: first-differenced fed rate + term spread + QE dummy
  fed_diff <- c(0, diff(pg$fed_rate))
  fed_diff[!is.finite(fed_diff)] <- 0
  monetary <- (zscore(fed_diff) + zscore(pg$term_spread) + zscore(pg$qe_dummy)) / 3

  out <- data.frame(Date = pg$Date,
                    Trade = trade, Financial = financial,
                    Geopolitical = geopolitical, Behavioral = behavioral,
                    Monetary_Policy = monetary)
  out[is.na(out)] <- 0
  out
}
