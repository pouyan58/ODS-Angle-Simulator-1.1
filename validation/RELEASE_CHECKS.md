# Release verification — 1.1.1

Prepared on 1 October 2026 for the public source-ZIP distribution.

## Environment and dependencies

- Verified on Windows with MATLAB R2025b Update 4, version
  `25.2.0.3150157`.
- MATLAB dependency analysis identified MATLAB, Aerospace Toolbox, and
  Satellite Communications Toolbox (product versions 25.2).
- Installation preflight passed all seven checks: MATLAB release,
  satellite/propagation functions, geoid function, numerical functions,
  EGM96 geoid data, Java, and the four externally supplied P.618 map files.
- MATLAB licenses, map files, standards, and source publications are not
  redistributed in this package. Other operating systems/releases have
  not been independently verified.

## Code and tests

- Code Analyzer reported zero issues across all 30 MATLAB files. The
  metadata files changed for 1.1.1 were checked again after editing.
  See `code_analysis.csv`.
- All 13 existing class-based regression tests passed on the source
  release, including the bounded end-to-end smoke run.
  See `test_results.csv` for individual results and measured durations.
- An initial test failure exposed inconsistent release labels. The
  configuration, ensemble metadata, report heading, and test expectation
  now consistently identify 1.1.1. Numerical test thresholds were not
  relaxed, and test cases were not removed.
- All 30 MATLAB files were compared with the retained 1.1.0 ZIP after
  normalizing line endings and release identifiers. There were no other
  differences. The four 1.1.0 Wallops production results therefore remain
  the reference study; the full hours-long production sweep was not rerun
  for this documentation/distribution patch.
- Existing public entry points have validated arguments and MATLAB help.
  Cosmetic help-format and internal complexity refactoring were not part
  of this patch. Static analysis and these tests do not establish complete
  branch coverage or mathematical/physical validation of every model.

## Distribution checks

- Local Markdown links were checked; all referenced package files exist.
- Public files were scanned for developer user-directory paths, chat/workspace
  identifiers, obsolete prototype labels, and unfinished TODO/FIXME markers.
  No matches were found.
- The included reference table has four rows and excludes absolute output
  paths. Its original model-version column deliberately remains 1.1.0.
- Only source, documentation, original evidence tables, test fixtures,
  reference results, and release records are included. No private raw run
  directories, logs, proprietary digital maps, or third-party publications
  are included.
- `FILES_SHA256.csv` inventories every distributed file except itself.
  A companion `.sha256` file records the final ZIP hash.
- Final archive extraction, inventory verification, and the second 13-test
  run are recorded in the companion
  `GOES_DCS_GRB_ODS_Angle_Simulator_1.1.1.verification.json`, alongside the
  ZIP. That external record binds the clean-extraction checks to the final
  archive hash without changing the tested archive.

## Scope of readiness

Ready for distribution as an independent engineering sensitivity model,
subject to the README limitations and existing license/notices. This is
not regulatory certification, an operator-approved implementation, a
measurement validation, or a claim of guaranteed real-world protection.
No repository, website, package registry, or File Exchange upload is
performed by the local release-preparation workflow.
