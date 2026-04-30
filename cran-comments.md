## Resubmission

This is a resubmission of contagionchannels 0.1.2, addressing the
CRAN auto-check feedback received on the 0.1.1 incoming pre-test:

> The Description field contains
>   <arXiv:2604.26546>; the package is general-purpose and accommodates
> Please refer to arXiv e-prints via their arXiv DOI
> <doi:10.48550/arXiv.YYMM.NNNNN>.

Changes in 0.1.2:

* Replaced `<arXiv:2604.26546>` in DESCRIPTION with the canonical
  `<doi:10.48550/arXiv.2604.26546>` arXiv-DOI form.
* Mirrored the change in `inst/CITATION` (added an explicit `doi` field
  to the arXiv preprint bibentry).

For continuity, 0.1.1 had already addressed Uwe Ligges's earlier
feedback on 0.1.0 by removing `+ file LICENSE` and the LICENSE file.

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
