# Changelog

## 1.1.1 — 2026-10-01

- Public-release documentation and distribution update; no numerical
  model, default assumption, random-seed, or ODS-search changes.
- Added a short getting-started guide, runtime and troubleshooting notes,
  privacy guidance, and a path-free Wallops GRB reference-results table.
- Clarified link-budget units, the empirical correction, and the difference
  between I/N availability and P.618 annual attenuation exceedance.
- Corrected interactive installation instructions to pass the selected map
  folder to both preflight and simulation; preflight does not persist it.
- Added release verification records and per-file SHA-256 inventory.
- Preserved the 1.1.0 engineering results and explicitly identified their
  provenance. Only release identifiers changed in executable model code.

## 1.1.0 — 2026-09-29

- Added an interactive/programmatic per-beam ground-PFD ceiling.
- Replaced protected-receiver clipping with a conservative whole-footprint
  peak-EIRP controller and explicit optional hardware ceiling.
- Recompute beam power after physical outer-zone retasking; apply power
  uncertainty at the peak before off-axis discrimination.
- Retained the receiver, traffic, propagation, ZA, constellation, and
  phase-diverse ODS-search assumptions. Fixed-power mode is an explicit
  comparison and no longer silently clips receiver PFD.
- Added controller audit tables, a reproducible four-ZA Wallops GRB driver,
  updated documentation, and class-based PFD/geometry/integration tests.

## 1.0.0 — 2026-09-09

- First public source release.
- Added a safe interactive and programmatic single-site entry point for DCS
  and GRB receivers, all three configured GOES boresights, antenna geometry,
  and a user-selected geographic ZA.
- Added DEM/geoid height resolution, P.618 lookup generation, phase-diverse
  multi-window pooling, deterministic lattice rotations, convergence checks,
  automatic fine-search expansion, auditable outputs, preflight checks, and
  release verification.
