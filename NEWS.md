# contagionchannels 0.1.0 (2026-04-29)

* First release.
* Implements the two-stage Wavelet-Quantile Transfer Entropy detection +
  multi-method structural channel attribution framework for cross-border
  financial contagion.
* Five identification strategies in the attribution layer: IV/2SLS,
  LASSO IV, local projections, heteroskedasticity-based identification,
  and Cinelli-Hazlett robustness-value sensitivity bounds.
* Bundled datasets: `g20_returns` (18 markets, 5,036 days),
  `channel_proxies` (14 raw proxies), `crisis_periods` (8 sub-periods).
* Three vignettes: `replication`, `methodology`, `custom_data`.
* Replication scripts in `inst/scripts/`.
