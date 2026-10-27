# Reference results and release verification

## Model provenance

The four Wallops GRB production runs completed on 30 September 2026 using
release 1.1.0, MATLAB R2025b Update 4 (`25.2.0.3150157`), and the real P.618
map bundle. Release 1.1.1 changes documentation, distribution records, and
release-identification metadata only. It does not change numerical model
code, default physical assumptions, random seeds, or search logic.

The production ensemble was not rerun for this documentation-only patch.
The existing 13-test suite is rerun for release verification, including
from a clean archive extraction. Test fixtures use synthetic atmosphere
and are not the source of the engineering angles below.

## Wallops GRB reference cases

Site: 37.94651° N, −75.46210° E; 16.4 m dish; 5 m AGL phase-center height;
GOES-East nominal longitude −75.2°; GRB at 1686.6 MHz with 10.9 MHz receiver
bandwidth; G/T 15.2 dB/K. The cached orthometric ground height is
9.465678215 m. The per-beam PFD ceiling is −80 dBW/m²/MHz, uniform over
elevation, with no additional hardware EIRP ceiling. All remaining
assumptions are those documented in the main README.

| ZA (km) | Inner (°) | Outer (°) | Robust exceedance (%) | Robust percentile I/N (dB) | Windows | Hours per realization |
|---:|---:|---:|---:|---:|---:|---:|
| 0 | 3.0 | 41.5 | 4.99884 | −6.00064 | 24 | 48 |
| 10 | 2.5 | 35.5 | 4.98032 | −6.02402 | 24 | 48 |
| 20 | 0.0 | 23.0 | 4.99603 | −6.00381 | 28 | 56 |
| 30 | 0.0 | 5.0 | 4.98032 | −6.01603 | 24 | 48 |

Angles are from the receive boresight. All cases met the configured
−6 dB I/N / 95% availability criterion, were feasible, converged, and had
no nonphysical search-boundary flag. The ranking rule minimizes
`inner + outer`, with ties favoring smaller outer angle. The 0.5° search
grid does not support sub-0.5° precision. Zero inner angle is not a claim
of zero interference or 100% protection.

All four share timing/seed-plan identifier `COMMON-E0DB1749D5E1DC96`.
The 20 km case needed an additional four-window batch, so final exposure
lengths differ. Results are close to the protection threshold and include
the provisional cross-band empirical correction; no added operational
safety margin or independent measured validation is implied.

`wallops_grb_pfd80_reference.csv` preserves selected numerical fields from
the completed study and its original model-version identifier. Absolute
paths, raw local configuration files, and private run folders are omitted.
Reproduce the study with `examples/runWallopsGrbPfdSweep.m`, supplying your
licensed P.618 maps. Differences in MATLAB, maps, or configuration can
change results; do not force new outputs to match this table.

## Release checks

- `code_analysis.csv`: Code Analyzer results for all 30 MATLAB files.
- `test_results.csv`: the 13 existing class-based regression test results.
- `RELEASE_CHECKS.md`: environment, dependency, clean-extraction, integrity,
  and distribution checks performed for this release.
- `../FILES_SHA256.csv`: SHA-256 for every distributed file except the
  inventory itself. The companion archive checksum verifies the
  integrity of the entire downloaded ZIP, including the inventory; it is
  an integrity checksum, not a digital signature of publisher identity.

Test execution checks nadir power, ceiling scaling, whole-footprint PFD,
grid refinement, steering, peak-before-pattern power limiting, hardware
limits, invalid inputs, linear aggregation, existing release checks, and
end-to-end output generation. Passing these tests is not evidence of
measured RF compliance. Full coverage of every code branch, cross-platform
behavior, GUI interactions, and every user-input combination is not claimed.
