# contagionchannels 0.1.2 (2026-04-30)

* Address CRAN auto-check feedback on 0.1.1: arXiv preprint references
  in `DESCRIPTION` must use the arXiv DOI form
  `<doi:10.48550/arXiv.YYMM.NNNNN>`. Updated the Bhandari, Parida & Sahu
  (2026) reference accordingly. The CITATION entry now also exposes the
  arXiv DOI explicitly.

# contagionchannels 0.1.1 (2026-04-30)

* Address CRAN reviewer feedback: drop the `+ file LICENSE` qualifier
  from `License:` (kept as plain `GPL-3`) and remove the LICENSE file,
  per Uwe Ligges -- the auxiliary LICENSE file is reserved for cases
  where the base licence permits additional restrictions.
* Add the methodology preprint Bhandari, Parida & Sahu (2026),
  arXiv:2604.26546, to DESCRIPTION, CITATION, and README.

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
