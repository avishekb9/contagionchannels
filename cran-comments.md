## Resubmission

This is a resubmission of contagionchannels 0.1.3, addressing the
human-review feedback from Benjamin Altmann on 0.1.2:

> Please make sure that you do not change the user's options, par or
> working directory. If you really have to do so within functions,
> please ensure with an *immediate* call of on.exit() that the
> settings are reset when the function is exited.
> -> R/visualisation.R

Change in 0.1.3:

* `plot_qte_intensity()` (R/visualisation.R) -- the base-graphics
  fallback (used only when ggplot2 is not installed) called
  `graphics::par(mfrow = c(2, 1))` and tried to restore it manually
  with `par(mfrow = c(1, 1))` at the bottom of the branch. Replaced
  with the canonical idiom

      oldpar <- graphics::par(no.readonly = TRUE)
      on.exit(graphics::par(oldpar))

  placed *immediately* after entering the branch, so the user's
  graphical parameters are restored even if a downstream call errors.
  This is the only place in the package that mutates `par()`,
  `options()`, the working directory, or any other piece of user
  state -- a `grep` of R/ confirms the absence of `par(`, `options(`,
  `setwd(`, `Sys.setenv(`, `sink(`, etc., outside this single
  function.

For continuity, the prior resubmits had already addressed:
* 0.1.1 -> 0.1.2: arXiv reference in DESCRIPTION switched to the
  canonical `<doi:10.48550/arXiv.YYMM.NNNNN>` form.
* 0.1.0 -> 0.1.1: removed `+ file LICENSE` and the LICENSE file per
  Uwe Ligges (`License: GPL-3` only).

## Test environments
* local: Linux Ubuntu 22.04, R 4.1.2
* win-builder (R-devel and R-release)
* GitHub Actions: ubuntu-latest, macos-latest, windows-latest
  (R-release, R-devel, R-oldrel-1)

## R CMD check results
0 errors | 0 warnings | 1 note (NEW submission)

## Notes on the "Possibly misspelled words" entry

The auto-checker flags the following strings in DESCRIPTION; all are
correct spellings:

* Author surnames cited in the methodological references --
  Belloni, Chernozhukov, Cinelli, Hazlett, Jorda (the canonical ASCII
  rendering of "Jordà" used in the DESCRIPTION text), Oka, Rigobon,
  Schreiber, Whang.
* Author names of the present package -- Bhandari, Parida, Sahu.
* `heteroskedasticity` -- standard econometrics spelling (cf. White,
  H. 1980, *Econometrica* 48(4), p.819, which uses the "k" form
  throughout).

These are also recorded in `inst/WORDLIST` so that the
`spelling::spell_check_package()` workflow runs cleanly.

## Reverse dependencies
None -- first release.

## Other notes
The package contains daily-return data for 18 G20 equity markets and a
collection of channel-proxy time series compiled from public sources
(Yahoo Finance, FRED, Caldara-Iacoviello GPR data library). All datasets
total approximately 700 KB and are stored in the standard R `.rda`
format under `xz` compression.

Exported functions that use `parallel::mclapply` cap their `n_cores`
default at 2L per CRAN policy; users may raise this for production
runs. On Windows the implementation falls back to single-threaded
`lapply`.
