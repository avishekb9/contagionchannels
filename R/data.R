#' G20 Equity-Market Daily Log-Returns
#'
#' Daily log-return panel for 18 G20 equity-market indices spanning
#' 12 January 2006 through 18 March 2026, used in the paper replication.
#' The panel covers 5,036 trading days. Eight developed and ten emerging
#' markets are represented.
#'
#' @format An xts object with 5,036 rows and 18 columns:
#' \describe{
#'   \item{Argentina}{S&P/MERVAL log-returns}
#'   \item{Australia}{S&P/ASX 200 log-returns}
#'   \item{Brazil}{IBOVESPA log-returns}
#'   \item{Canada}{S&P/TSX Composite log-returns}
#'   \item{China}{Shanghai Composite log-returns}
#'   \item{France}{CAC 40 log-returns}
#'   \item{Germany}{DAX 40 log-returns}
#'   \item{India}{BSE SENSEX log-returns}
#'   \item{Indonesia}{IDX Composite log-returns}
#'   \item{Italy}{FTSE MIB log-returns}
#'   \item{Japan}{Nikkei 225 log-returns}
#'   \item{Mexico}{S&P/BMV IPC log-returns}
#'   \item{Russia}{IMOEX log-returns}
#'   \item{SouthAfrica}{JSE All Share log-returns}
#'   \item{SouthKorea}{KOSPI log-returns}
#'   \item{Turkey}{BIST 100 log-returns}
#'   \item{UK}{FTSE 100 log-returns}
#'   \item{USA}{S&P 500 log-returns}
#' }
#' @source Yahoo Finance and Investing.com aggregator.
#' @examples
#' data(g20_returns)
#' dim(g20_returns); head(g20_returns[, 1:5])
"g20_returns"

#' Channel-Proxy Daily Series
#'
#' Daily-frequency channel-proxy series aligned on the G20 trading-day
#' grid, used as inputs to \code{\link{build_channel_composites}}. Values
#' are forward-filled where lower-frequency data are available.
#'
#' @format A data.frame with 5,036 rows and 14 columns:
#' \describe{
#'   \item{Date}{Trading date}
#'   \item{vix}{CBOE Volatility Index level}
#'   \item{hy_spread}{ICE BofA US High-Yield Option-Adjusted Spread}
#'   \item{stress_index}{St. Louis Fed Financial Stress Index (STLFSI4)}
#'   \item{usd_index}{Federal Reserve Broad Trade-Weighted Dollar Index (DTWEXBGS)}
#'   \item{gpr}{Caldara-Iacoviello Geopolitical Risk Index}
#'   \item{geo_events}{Geopolitical-events indicator}
#'   \item{vix_slope}{VIX-VIX3M term-structure slope}
#'   \item{fear_proxy}{Daily absolute change in VIX}
#'   \item{sentiment}{University of Michigan Consumer Sentiment Index}
#'   \item{fed_rate}{Effective Federal Funds Rate}
#'   \item{dgs10}{10-year Treasury yield}
#'   \item{term_spread}{10-year minus 3-month Treasury yield spread}
#'   \item{qe_dummy}{Quantitative-easing program indicator (binary)}
#' }
#' @source Federal Reserve Economic Data (FRED), Yahoo Finance,
#'   Caldara-Iacoviello GPR data library.
#' @examples
#' data(channel_proxies)
#' summary(channel_proxies[, c("vix","gpr","fed_rate")])
"channel_proxies"

#' Crisis Sub-Period Definitions
#'
#' A named list of length-two character vectors specifying the start and
#' end dates of the eight crisis sub-periods analysed in the paper.
#'
#' @format A named list with eight elements:
#' \describe{
#'   \item{PreCrisis}{Pre-Crisis Baseline (12 Jan 2006 - 31 Jul 2007)}
#'   \item{GFC}{Global Financial Crisis (1 Aug 2007 - 30 Jun 2009)}
#'   \item{ESDC}{European Sovereign Debt Crisis (1 Dec 2009 - 30 Jun 2012)}
#'   \item{CSC}{Chinese Stock Crash (15 Jun 2015 - 31 Dec 2016)}
#'   \item{PreCOVID}{Pre-COVID interval (1 Jan 2017 - 31 Jan 2020)}
#'   \item{COVID}{COVID-19 Pandemic (1 Feb 2020 - 31 Dec 2021)}
#'   \item{RusUkr}{Russia-Ukraine episode (1 Feb 2022 - 31 Dec 2023)}
#'   \item{MidEastTariffs}{Middle-East tensions and tariffs (1 Jan 2024 - 18 Mar 2026)}
#' }
#' @examples
#' data(crisis_periods)
#' crisis_periods$GFC
"crisis_periods"

#' contagionchannels: Detection and Attribution of Cross-Border Financial
#' Contagion Channels
#'
#' The package implements a two-stage framework for the joint detection-
#' and-attribution of cross-border financial contagion. Stage one detects
#' directional information flows between equity markets via Wavelet-Quantile
#' Transfer Entropy. Stage two attributes each significant directional link
#' to one of five mutually exclusive transmission channels through a
#' multi-method structural identification architecture.
#'
#' @section Main functions:
#' \itemize{
#'   \item \code{\link{compute_wqte_matrix}} - Stage 1 pairwise WQTE.
#'   \item \code{\link{build_channel_composites}} - construct channel composites.
#'   \item \code{\link{iv_2sls_attribute}} - Stage 2 IV/2SLS attribution.
#'   \item \code{\link{lasso_iv_attribute}} - LASSO IV variant.
#'   \item \code{\link{local_projections}} - Jorda (2005) local projections.
#'   \item \code{\link{rigobon_id}} - heteroskedasticity-based identification.
#'   \item \code{\link{cinelli_hazlett_rv}} - robustness-value sensitivity.
#'   \item \code{\link{run_contagion_pipeline}} - top-level wrapper.
#' }
#'
#' @section Bundled data:
#' \code{\link{g20_returns}}, \code{\link{channel_proxies}},
#' \code{\link{crisis_periods}}.
#'
#' @section Vignettes:
#' \itemize{
#'   \item \code{vignette("replication")} - reproduces every paper figure
#'      and table.
#'   \item \code{vignette("methodology")} - methodology overview.
#'   \item \code{vignette("custom_data")} - using with custom datasets.
#' }
#'
#' @keywords internal
"_PACKAGE"
