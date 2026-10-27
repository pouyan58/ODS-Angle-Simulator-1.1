# GOES DCS/GRB ODS Angle Simulator

**Public source release 1.1.1 — 1 October 2026.** Start with
[QUICKSTART.md](QUICKSTART.md). This release packages the PFD-controlled
model with installation guidance, tests, and reference results; it does
not change the numerical model used for the four Wallops runs in 1.1.0.

This MATLAB project estimates the inner and outer angular limits of a two-zone Operational Data Sharing (ODS) avoidance cone for a protected GOES Data Collection System (DCS) or GOES Rebroadcast (GRB) receive station. The user supplies the site, antenna, service, GOES pointing assignment, geographic zone-avoidance (ZA) radius, and per-beam ground power-flux-density (PFD) ceiling. The simulator then evaluates a reproducible, phase-diverse ensemble of synthetic LEO constellation passes and reports the smallest feasible modeled ODS angle pair under the configured ranking rule.

Angles are measured from the selected GOES antenna boresight, **not from zenith**:

- outside the outer angle, modeled D2D operation is unchanged;
- between the inner and outer angles, protected-carrier spot beams are retasked away from the protected site; and
- inside the inner angle, the satellite's protected-carrier transmission is shut down in the model.

This is an engineering sensitivity model. It is not an official NOAA, NTIA, FCC, NRAO, NSF, ITU, MathWorks, or satellite-operator product; it is not a frequency-coordination determination; and it does not represent an operator commitment or a validated operational constellation.

## Release baseline

The public baseline fixes the following headline assumptions:

| Item | Public baseline |
|---|---:|
| D2D band | 1675–1695 MHz |
| Transmit power control | Geometry-dependent peak EIRP constrained by the user-entered per-beam ground-PFD ceiling |
| PFD example used in the Wallops sweep | −80 dBW/m²/MHz, uniform across elevation angles |
| Additional hardware EIRP ceiling | None by default (`Inf`); optional explicit ceiling |
| LEO constellation | 325 satellites at 340 km/53° plus 325 at 355 km/43° |
| Spot beams | 30 per satellite |
| Steering field of regard | 60° from nadir |
| Individual spot radius | 2° satellite-view half-power radius |
| Contributor rule | Linear power sum of all visible, eligible active links |
| LEO visibility floor | Geometric horizon, 0° elevation |
| Protection criterion | I/N at or below −6 dB at 95% modeled availability |
| Time resolution | 2 seconds |
| Monte Carlo realizations | 4 |
| Initial/minimum/maximum windows | 12 / 24 / 48 |
| Window duration | 2 hours of scored samples per window |
| Final angular grid | 0.5° |

The seven prompted input groups (eight entered values because site latitude and longitude are entered separately) do not silently change the remaining assumptions. Programmatic advanced overrides can deliberately change selected controls, but any such change creates a different study baseline and should be documented with the result. Release 1.1.0 replaces receiver-local PFD clipping with physical beam-level power control; results are not numerically interchangeable with the fixed-EIRP release.

## Requirements

The release was developed for MATLAB R2025b. The code directly uses functions from these MathWorks products:

- MATLAB;
- Aerospace Toolbox (`geoidheight`, plus geoid data available to that function); and
- Satellite Communications Toolbox (`satelliteScenario`, `walkerDelta`, `p618Config`, `p618PropagationLosses`).

An internet connection is normally needed once per new U.S. site for the default USGS 3DEP point-elevation query. An offline, previously recorded ground-elevation value can be supplied for reproducible reruns. For a site outside the coverage of the configured DEM service, supply an authoritative local orthometric ground height with `DemGroundElevationM`; the program does not select a worldwide DEM automatically.

The ITU-R P.618 digital-map files required by `p618PropagationLosses` are not redistributed with this project. Download the map bundle appropriate for your MATLAB release using the instructions on the [MathWorks `p618PropagationLosses` page](https://www.mathworks.com/help/satcom/ref/p618propagationlosses.html), extract it, and either:

1. pass its folder to `runOdsAngleSimulator` with `ItuDigitalMapsFolder=...`; or
2. set the `MATLAB_ITU_MAPS_FOLDER` environment variable before starting the run.

For the R2025b workflow, the selected folder must contain the required P.618 map files at its top level (`maps.mat`, `p836.mat`, `p837.mat`, and `p840.mat`). Do not commit licensed map files to a public repository; `data/itu_maps/` is ignored for that reason.

## Quick start: interactive run

1. Extract or clone the complete release folder.
2. Start MATLAB.
3. Change the MATLAB current folder to the release root—the folder containing `runOdsAngleSimulator.m`.
4. Make the P.618 maps available as described above.
5. Preflight the installation:

```matlab
mapFolder = string(uigetdir(pwd,"Select the extracted P.618 map folder"));
assert(mapFolder ~= "0","Select a map folder before continuing.");
checkOdsInstallation(ItuDigitalMapsFolder=mapFolder,ThrowOnFailure=true);
```

6. Run:

```matlab
results = runOdsAngleSimulator(ItuDigitalMapsFolder=mapFolder);
```

The preflight call does not save the folder selection. Pass the same
`mapFolder` to the simulation as shown. If you instead configured
`MATLAB_ITU_MAPS_FOLDER`, calling `runOdsAngleSimulator` without a map-folder
argument uses that environment setting. Extract the package into a writable
folder, or set `OutputRoot` to a separate writable folder.

The program prompts for seven numbered input groups:

1. site location: (a) protected-site latitude in degrees, north positive, and (b) longitude in degrees, east positive (western longitudes are negative);
2. antenna diameter in metres;
3. antenna feed/phase-center height above local ground in metres;
4. service, `DCS` or `GRB`;
5. pointing assignment, GOES East, GOES West, or GOES Backup;
6. geographic ZA radius in kilometres; and
7. per-beam ground-PFD ceiling in dBW/m²/MHz (for example, `-80`).

The request describes one receive antenna at one site. The antenna height is the feed or phase-center height above ground, not the site's elevation above mean sea level.

Latitude must be in `[−90, 90]`, longitude in `[−180, 180]`, diameter and AGL height must be positive, and ZA must be in `[0, 180)` km for the current 180 km retasking rule.

The simulator validates the entries, resolves site heights, verifies that the selected nominal GOES position is above the site's geometric horizon, generates a site-specific atmospheric lookup, runs the multi-window ensemble, and displays the primary ODS result. A timestamped output folder preserves the full audit trail.

## Programmatic run

For scripted or reproducible use, supply all site inputs as name-value arguments. The following example represents a DCS antenna at Wallops pointing at GOES East with a 30 km ZA:

```matlab
results = runOdsAngleSimulator( ...
    LatitudeDeg=37.94651, ...
    LongitudeDeg=-75.46210, ...
    AntennaDiameterM=16.4, ...
    AntennaHeightAglM=5, ...
    Service="DCS", ...
    GoesSatellite="GOES East", ...
    ZaRadiusKm=30, ...
    PfdLimitDbwM2MHz=-80, ...
    ItuDigitalMapsFolder="C:\path\to\P618-maps");
```

For an offline rerun, use the ground orthometric elevation captured in an earlier run:

```matlab
results = runOdsAngleSimulator( ...
    LatitudeDeg=37.94651, ...
    LongitudeDeg=-75.46210, ...
    AntennaDiameterM=16.4, ...
    AntennaHeightAglM=5, ...
    Service="DCS", ...
    GoesSatellite="GOES East", ...
    ZaRadiusKm=30, ...
    PfdLimitDbwM2MHz=-80, ...
    DemGroundElevationM=9.47, ...
    ItuDigitalMapsFolder="C:\path\to\P618-maps");
```

Use the exact cached value from `site_heights.csv`, rather than the rounded illustrative value above, when numerical reproducibility matters.

The returned structure contains the primary angles, the full result row, convergence history, the window manifest, a forcing identifier, convergence status, and the output-folder location. Run `help runOdsAngleSimulator` for the definitive name-value interface in the installed release.

### Optional name-value controls

The entry point also exposes the controls below for audited sensitivity studies. Defaults are the public baseline unless noted.

| Option | Default | Meaning |
|---|---:|---|
| `SiteName` | coordinate-based name | Human-readable label stored with the run |
| `OutputRoot` | `runs` under the release | Parent folder for the unique timestamped run folder |
| `RunLabel` | empty | Optional filesystem-safe suffix for the case ID |
| `ProtectionCriterionDb` | −6 | I/N threshold in dB |
| `PrimaryAvailabilityPercent` | 95 | Required I/N sample availability; allowed exceedance is `100 - availability` (does not automatically retune the separately configured P.618 annual exceedance) |
| `PfdLimitDbwM2MHz` | Prompt if omitted | Uniform ground-PFD ceiling per beam, in dBW/m²/MHz; must be finite and real |
| `PowerControlMode` | `"groundPfdLimited"` | Beam-level PFD control; `"fixedEirp"` enables a separate fixed-power comparison without PFD clipping |
| `MaximumBeamEirpDensityDbwPerMHz` | `Inf` | Optional additional hardware peak-EIRP-density ceiling; `Inf` means the study is PFD-limited only |
| `BeamEirpDensityDbwPerMHz` | 43 | Used **only** in explicit `"fixedEirp"` comparison mode; does not limit PFD-controlled beams |
| `DemGroundElevationM` | `NaN` | Cached ground orthometric height; `NaN` requests USGS EPQS |
| `DemEndpoint` | USGS EPQS v1 URL | Alternate point-elevation service endpoint |
| `DemTimeoutSeconds` | 30 | DEM request timeout |
| `GeoidModel` | `EGM96` | `EGM96` or `EGM2008`; EGM2008 needs its MathWorks geoid-data add-on |
| `ItuDigitalMapsFolder` | empty | Explicit folder containing all required P.618 maps |
| `AtmosphericLookupFile` | empty | Reuse and copy a validated lookup instead of generating one |
| `InitialWindowCount` | 12 | Windows used by the initial pooled coarse and fine searches |
| `MinimumWindowCount` | 24 | Earliest checkpoint at which convergence may be declared |
| `MaximumWindowCount` | 48 | Maximum cumulative windows |
| `WindowBatchSize` | 4 | Number of windows added between convergence checks |
| `ConvergenceToleranceDeg` | 1 | Maximum change in either primary angle for a stable batch |
| `RequiredStableBatches` | 2 | Consecutive stable additions required |
| `FineHalfWidthDeg` | 10 | Initial half-width around coarse strict/practical optima |
| `ReferenceEpoch` | 2026-08-01 00:00 UTC | Absolute Walker and ensemble reference epoch |
| `TimeStepSec` | 2 | Geometry, demand, and I/N sample interval |
| `WindowDurationSec` | 7200 | Scored duration per window |
| `WarmupSec` | 120 | Unscored history before each window |
| `FutureGuardSec` | 16 | Unscored future geometry for entry prediction; must cover latency plus clock allowance |
| `MonteCarloRuns` | 4 | Stochastic realizations pooled and robustly combined |
| `BaseGeometrySeed` | 16751695 | Seed base for geometry/lattice phase |
| `BaseTrafficSeed` | 91675169 | Seed base for demand, load, and uncertainties |
| `SaveCheckpoints` | `false` | Save large stage/checkpoint MAT-files |
| `DryRun` | `false` | Resolve/validate inputs and heights, write setup artifacts, but skip P.618 generation and ODS simulation |

`AtmosphericLookupFile` must contain finite, nonnegative `ElevationDeg` and `TotalAtmosphericLossDb` columns, with strictly increasing elevation support from at least 5° through 90°. A reused lookup is valid only for the same site, service frequency, antenna, station height, availability assumptions, MATLAB implementation, and map dataset under which it was generated.

The initial window count must be at least 12. Initial, minimum, and maximum counts must be compatible with the batch size, and `initial <= minimum <= maximum`. Window duration and both guard durations must be integer multiples of the time step.

Changing one of these options can invalidate the public baseline and may require related settings or documentation to change too. The generated `configuration.json` is the authoritative record of what the engine actually used.

## What the program writes

Every run receives its own output directory. The principal artifacts are:

| File | Purpose |
|---|---|
| `run_report.txt` | Human-readable result and status; start here |
| `ods_results.csv` | Primary result plus strict and practical diagnostics |
| `result.csv` | Single-case copy of the primary result row |
| `ODS_Angle_Results.xlsx` | Results, convergence, window, and memory tables in one workbook |
| `ods_angle_convergence.png` | Inner and outer angles versus accumulated window count |
| `pooled_angle_search.csv` | Every final-grid angle pair and its modeled performance |
| `convergence_history.csv` | Cumulative angle and feasibility checkpoints |
| `window_manifest.csv` | UTC windows and deterministic geometry/traffic seeds |
| `configuration.json` | Fully resolved model configuration used for the run |
| `assumptions.csv` | Compact, machine-readable baseline summary |
| `user_inputs.csv` | Resolved user inputs, boresight geometry, receiver values, and public baseline controls |
| `input_configuration.mat` | Original request, fully resolved configuration, and entry-point options |
| `site_heights.csv` | DEM, AGL, orthometric, geoid, and ellipsoidal height chain |
| `dem_response.json` | Raw or cached DEM provenance record |
| `atmospheric_lookup.csv` | Site/service/elevation-specific P.618 attenuation lookup |
| `pfd_power_control.csv` | Conservative peak-EIRP ceilings for every shell/scan cell; includes optional hardware limiting |
| `memory_log.csv` | Per-window geometry-memory diagnostics |
| `evidence_manifest.csv` | Package-relative evidence files used by the run |
| `ods_ensemble_results.mat` | MATLAB result tables, plan, options, and status |

Intermediate checkpoint MAT-files are disabled by default because they can be large. Advanced runs can enable `SaveCheckpoints` when calling `runOdsEnsemble` directly.

## Reading the answer correctly

`OuterAngleDeg` and `InnerAngleDeg` are radii of cones centered on the selected GOES boresight. A valid pair always has `InnerAngleDeg <= OuterAngleDeg`.

The public baseline's primary result is the practical 95%-availability pair. A result should be treated as a completed modeled answer only when all of the following are true:

```text
Feasible == true
Converged == true
SearchBoundaryFlag == false
```

Important result fields are:

- `Feasible`: the selected pair satisfies both practical protection tests across the configured robust Monte Carlo statistic.
- `RobustExceedancePercent`: the 95th percentile across Monte Carlo realizations of the fraction of scored time samples for which I/N is greater than −6 dB. It must be no greater than 5%.
- `PercentileIOverNDb`: the 95th percentile across Monte Carlo realizations of each realization's 95th-time-percentile I/N. It must be no greater than −6 dB.
- `Converged`: after at least 24 windows, both selected angles changed by at most 1° over two successive four-window additions.
- `SearchBoundaryFlag`: the selected solution remains on a nonphysical local fine-search boundary. Treat it as provisional and widen/review the search.
- `InnerAtPhysicalMinimum`: the selected inner angle is 0°. This is a legitimate physical lower bound, not automatically a search failure.
- `OuterAtVisibleSkyLimit`: the selected outer angle reaches the largest geometrically visible angular separation from boresight. In this result, essentially the entire modeled visible sky lies inside the outer action region.
- `StrictOuterAngleDeg`, `StrictInnerAngleDeg`, and `StrictWorstExceedancePercent`: zero-exceedance diagnostics. They are not the public baseline's primary 95%-availability result.

If no pair satisfies the primary protection rule, the code returns the least-exceeding candidate with `Feasible=false`. That row is a diagnostic, not a protective ODS recommendation. If the maximum of 48 windows is reached before angle stability, the answer is marked provisional even if its current pair is feasible.

To bound memory, the streaming accumulator keeps exact threshold counts and a bounded upper tail rather than every historical I/N value. `convergence_history.csv` can therefore show `NaN` for numerical percentile I/N at earlier cumulative prefixes while retaining exact feasibility and exceedance tests there. The selected final prefix has a numerical percentile.

The grid step is 0.5°. Results therefore do not support sub-0.5° precision.

## How the model works

### 1. Site height and boresight

The default height workflow queries the USGS 3D Elevation Program Elevation Point Query Service for ground orthometric height `H_ground`. It adds the user-entered antenna feed height above ground and converts to WGS 84 ellipsoidal height with EGM96 geoid undulation `N`:

```text
H_antenna = H_ground + h_AGL
h_ellipsoid = H_antenna + N
```

Ellipsoidal height is used to place the station in Earth-centered, Earth-fixed geometry. Antenna orthometric height is passed to the P.618 propagation calculation.

The DEM is used only for the station's point elevation and vertical datum conversion. The simulator does **not** ray-trace terrain, construct a local horizon mask, or model blockage by terrain, vegetation, or buildings.

The receive-antenna boresight is the line from the protected site to a nominal geostationary point over the equator. The configured nominal east-positive longitudes are:

| Selection | Longitude |
|---|---:|
| GOES East | −75.2° |
| GOES West | −137.0° |
| GOES Backup | −104.7° |

These are fixed scenario coordinates, not live GOES ephemerides or operational-status data.

### 2. Receiver signal and noise

The two service profiles are:

| Quantity | DCS | GRB |
|---|---:|---:|
| Center frequency | 1679.9 MHz | 1686.6 MHz |
| Receiver bandwidth | 0.4 MHz | 10.9 MHz |
| Reference plane | Antenna terminals | One worst-case co-polar antenna-terminal chain |

Both profiles use a common GOES-R site G/T assumption of 15.2 dB/K and 70% aperture efficiency. For the entered diameter `D` and service wavelength `lambda`, the simulator calculates:

```text
Gmax = 10 log10[eta (pi D/lambda)^2]  dBi
Tsys = 10^[(Gmax - G/T)/10]           K
N = k Tsys B                          W
```

Using the same G/T for DCS and GRB makes system noise temperature depend on antenna diameter and frequency; bandwidth then makes the DCS and GRB integrated noise powers different. The 15.2 dB/K value is a documented GRB reception requirement and is deliberately extended to the DCS profile here as a common-site engineering assumption. It should be replaced with measured service-specific G/T when available.

The receive pattern is the size-dependent ITU-R S.580-6 envelope with the APEREC015 Appendix 8 small-`D/lambda` extension where applicable. No −27 dBi or other ad hoc far-backlobe cutoff is applied. S.580 is a design-objective/reference envelope, not the measured pattern of the user's antenna.

### 3. Synthetic LEO geometry

The constellation is an engineering Walker-Delta baseline, not an operational catalog:

- shell 1: 325 satellites, 340 km circular altitude, 53° inclination, 13 planes, phasing 1;
- shell 2: 325 satellites, 355 km circular altitude, 43° inclination, 13 planes, phasing 1; and
- reference epoch: 2026-08-01 00:00:00 UTC.

MATLAB generates two-body Walker geometry anchored to the common reference epoch. There are no TLEs, orbit-fit errors, drag, J2 perturbations, maneuvers, failures, or current deployment state. A LEO satellite is eligible whenever it is at or above the site's 0° geometric horizon. There is no +5° elevation restriction.

The maximum possible ODS separation is also clipped to visible-sky geometry. With the baseline 0° LEO elevation floor, the implemented limit is `min(180°, 180° - GOES_boresight_elevation)`. It depends on the elevation of the selected GOES boresight and is not universally 90°; a value above 90° covers directions beyond the boresight-to-zenith hemisphere and toward the opposite horizon.

### 4. Spot beams, spectrum, and traffic

Every LEO satellite has 30 snapshot steering positions in a 60°-from-nadir field of regard. `evidence/beam_packing_layout.csv` defines a normalized triangular close-packed center layout. It is scaled on the spherical Earth for each shell. A deterministic rigid rotation changes lattice phase from pass to pass without translating centers outside the field of regard or violating the nominal nonoverlap constraint.

The packing cells and RF spots are different concepts. Each RF spot has a fixed 2° satellite-view half-power radius, independent of the geometric packed-cell radius. Consequently, the 30 nominal centers are a synthetic snapshot lattice, not a claim of continuous commercial service coverage.

Each active spot has its own geometry-dependent peak-EIRP ceiling. The controller selects the largest peak EIRP consistent with the entered **per-beam, free-space, ground-PFD limit everywhere on the modeled spherical Earth**, optionally limited further by a hardware ceiling. Projected-aperture cosine scan loss remains compensated. A 3 dB Gaussian power offset is applied at the beam peak; positive excursions are clipped there **before** applying off-axis discrimination, while negative excursions reduce power. This does not raise a sidelobe independently of the rest of its beam.

Off-boresight transmit discrimination follows the ITU-R S.1528-0 LEO reference envelope with:

- 2° half-power radius;
- −6.75 dB near-sidelobe cross point;
- 0 dBi absolute far-out pattern level for the configured 38 dBi reference peak (−38 dB relative discrimination before other terms); and
- no additional off-axis mask-margin credit.

This is a reference envelope, not a measured or operator-filed beam pattern.

Four contiguous 5 MHz carriers cover 1675–1695 MHz and are assigned cyclically across the 30 spots. Rectangular spectral overlap is used; transmitter and receiver filter skirts, adjacent-channel selectivity, nonlinearities, and receiver compression are not modeled.

For GRB, the 1681.15–1692.05 MHz rectangular receive band overlaps the four carriers by `[0, 3.85, 5.00, 2.05]` MHz, so 22 of 30 spot indices have nonzero overlap. For DCS, the established baseline assigns the full 0.4 MHz receiver bandwidth to the first carrier and treats the other overlaps as zero, so 8 of 30 spot indices are cochannel. This DCS convention should not be mistaken for a detailed receive-filter model.

Each receiver-overlapping physical spot gets an independent two-state offered-demand process:

- mean active probability: 0.20;
- mean on time: 30 seconds;
- mean off time: 120 seconds;
- mean active load: 0.60;
- load standard deviation: 0.15;
- minimum active load: 0.20; and
- maximum active load: 1.00.

At the 2-second baseline step, transition probabilities are `min(1, dt/30)` for active-to-off and `min(1, dt/120)` for off-to-active. Active load follows a bounded first-order random process with correlation coefficient `exp(-dt/30)`. The random-stream treatment is:

| Quantity | Baseline draw and support |
|---|---|
| Offered demand | Independent by receiver-overlapping spot and satellite; evolves every time step |
| Scheduled load | Independent innovation by spot and satellite; temporally correlated and clipped to 0.20–1.00 while active |
| EIRP uncertainty | Zero-mean 3 dB Gaussian draw per beam, satellite, window, and realization; constant within that window; positive values cannot exceed the geometry/hardware peak ceiling and negative values back off the whole beam |
| Ephemeris-angle error | Zero-mean 0.05° Gaussian draw per satellite, window, and realization; constant within that window |
| Protected-antenna pointing error | Zero-mean 0.10° Gaussian draw per time sample, window, and realization; common across satellites at that sample |

There is no demand map, population map, actual user location, network scheduler, handover, or service-driven steering. Every visible satellite can couple through the main lobe or sidelobes of every active receiver-overlapping spot. All eligible powers are summed linearly; there is no strongest-satellite or nearest-satellite limit.

### 5. Geographic zone avoidance

ZA is a surface-distance exclusion around the protected station. If a modeled spot's served-user/beam center is inside the user-entered radius, that spot's offered demand is suppressed and is not reassigned. ZA does not remove a satellite merely because its sub-satellite point is inside the zone, and it does not suppress sidelobe coupling from active beams centered outside the zone.

The current retasking model requires the ZA radius to be nonnegative and less than the 180 km outer-retask target distance. A zero-kilometre ZA is allowed and represents no geographic demand exclusion.

### 6. Link budget and propagation

For each scheduled, spectrally overlapping spot, the simulator first determines its allowable peak EIRP from the whole ground footprint. It then applies the transmit pattern toward the protected site, spherical spreading, receive effective area, overlap bandwidth, scheduled load, and propagation losses. **There is no clipping or power normalization at the protected receiver, and the aggregate is not clipped to the per-beam PFD limit.**

For ground point `q`, let `g_b(q)` be the beam's relative EIRP pattern in dB (zero on its boresight), `R_b(q)` its slant range in metres, and `S_limit` the user-entered PFD in dBW/m²/MHz. Before uncertainty and load:

```text
E_peak_limit,b = min over visible ground q of
                 [S_limit + 10 log10(4 pi R_b(q)^2) - g_b(q)]
E_peak,b = min(E_peak_limit,b, E_hardware_limit)
E_command,b = E_peak,b + min(power_offset_b, 0)
```

The current uniform ceiling, spherical Earth (radius 6,378,137 m), circular shells, and axisymmetric nonincreasing S.1528 envelope allow the full footprint to be bounded on the meridian containing nadir and the beam axis. At each satellite look angle, this meridian has maximum transmit gain; ranges are the same at other azimuths. The computation includes all Earth-directed look angles through the limb, not just the main lobe or nominal coverage cells.

`buildPfdPowerTable` uses 0.05° scan cells and 0.02° ground-look cells. Within each cell it combines the smallest possible off-axis angle, the largest compensated relative sidelobe gain, and the shortest slant range. This gives an **upper bound on PFD**, rather than just checking isolated samples. The resulting piecewise-constant EIRP limits are conservative; `lookupPfdPeakEirp` does not interpolate above them. Numerical tests independently sample ground directions and halve both grid steps. The bounds rely on the current monotone, axisymmetric, compensated pattern; a measured asymmetric array pattern or elevation-dependent PFD mask needs a different controller.

The ground-PFD controller credits **none** of the atmospheric, clutter, receiver-pattern, traffic-load, or provisional empirical attenuation. Those effects reduce the calculated receiver interference separately; they never justify increasing the commanded beam power. A runtime receiver-link check detects PFD violations rather than concealing them with clipping.

At −80 dBW/m²/MHz, nadir beam-center EIRPs are 41.62 dBW/MHz at 340 km and 42.00 dBW/MHz at 355 km. Off-nadir beams can require more than 43 dBW/MHz. The full-footprint controller can choose slightly less than a beam-center-only calculation because the maximum PFD need not lie exactly on the beam axis.

These are **engineering assumptions**, inspired by the supplied SpaceX Schedule S and transferred to a hypothetical 1675–1695 MHz service. The uniform user-entered ceiling is not the full filed elevation-dependent mask; lower-elevation Schedule S entries are not silently added. The limit is per beam, not per satellite or constellation aggregate. Unless the optional hardware ceiling is supplied, there is no additional EIRP ceiling and no shared spacecraft RF-power budget. Operating at the allowed envelope is an interference sensitivity scenario, not a claimed operator service-power control law.

In compact form, for one active overlapping beam before aggregation:

```text
PFD = E_command,b + g_b(theta_tx) - 10 log10(4 pi R_site^2)
Aeff = 10^(G_rx_dBi(theta_rx)/10) lambda^2 / (4 pi)
I_dBW = PFD + C_empirical + 10 log10(Aeff/1 m^2)
        + 10 log10(B_overlap/1 MHz) + 10 log10(load)
        - L_atmosphere - L_clutter - L_implementation - L_polarization
```

`PFD` is in dBW/m²/MHz; `E_command,b` is in dBW/MHz; `g_b` is relative
transmit gain in dB; `R_site` and `lambda` are in metres. `G_rx_dBi` is
receive gain in dBi and `Aeff` is effective receiving area in square metres.
`B_overlap` is the actual transmitter/receiver overlap bandwidth, expressed
in MHz when taking its ratio to 1 MHz. `load` is a unitless fraction.
`C_empirical` is the nonpositive, distance-dependent correction described
below; each `L` is a positive loss in dB. Convert `I_dBW` to dBm by adding
30, or to watts as `10^(I_dBW/10)`, before summing physical powers. The code
incorporates `C_empirical` into directional link EIRP; the expression above
separates it for clarity. It is never credited by the PFD power controller.

The link uses worst-case co-polar coupling (0 dB polarization loss) and a fixed 1 dB implementation loss.

Outer-zone retasking changes the served direction. Its new scan angle selects a new footprint-limited peak EIRP before the transmit gain toward the protected receiver is calculated. A beam already centered at least 180 km from the protected site retains its original pointing and power. Inner-zone protected-carrier shutdown still gives zero modeled power; all other operation remains unchanged. In the circular-shell snapshot lattice, normal slot scan angles and power ceilings may be constant in time even though the satellite moves; power changes between slots/shells and when retasking changes scan geometry.

Atmospheric attenuation is generated at 1° elevation increments from 5° through 90° using MATLAB's ITU-R P.618 implementation. It includes the returned total attenuation from gaseous, cloud, rain, and tropospheric-scintillation components at 5% annual exceedance. Interpolation is shape-preserving. Visible links from 0° through 5° use the 5° lookup value; the model does not extrapolate below its lookup floor.

Local clutter uses the ITU-R P.2108-inspired open/rural height-gain expression in the implementation. Its representative clutter height is 10 m. The term is zero for an antenna at or above 10 m AGL and increases below 10 m. It is not a site-specific land-cover or building model.

An additional provisional, NRAO-informed satellite-sidelobe correction is transferred from 1990–1995 MHz test observations into this 1675–1695 MHz engineering study. It ramps linearly from 0 dB at a 30 km beam-center distance to −18 dB at 150 km and remains −18 dB beyond 150 km. The ramp distances are absolute and independent of the user-entered ZA. This is a cross-service calibration assumption—not an NRAO endorsement, not a direct measurement of the modeled DCS/GRB case, and not a substitute for band- and operator-specific antenna data.

### 7. ODS action logic

The instantaneous ODS angle is the angular separation between the protected antenna's fixed GOES boresight and each LEO satellite direction at the protected site.

The model includes:

- 15 seconds of command latency;
- 1 second of clock uncertainty;
- explicit 16-second look-ahead using the smaller of current and predicted entry angle;
- 0.5° exit hysteresis;
- 0.05° one-sigma ephemeris-angle uncertainty;
- 0.10° one-sigma pointing uncertainty; and
- clamping of perturbed directions to the visible sky.

The 120-second pre-window guard initializes traffic, prediction, and hysteresis before scored samples. A 16-second future guard supports prediction at the analysis-window end. Guard samples affect state but are excluded from I/N statistics.

For a candidate pair `(outer, inner)`:

- `angle > outer`: no ODS action;
- `inner < angle <= outer`: each affected protected-carrier spot centered inside 180 km is retasked to the feasible point on or beyond the 180 km boundary that gives the conservative highest residual gain, then transmit gain is recomputed; a spot already centered at least 180 km away is unchanged; and
- `angle <= inner`: protected-carrier spot power from that satellite is removed exactly in the mathematical model.

The baseline has no imposed minimum outer angle. Retasking receives no fixed mitigation credit: residual interference comes from the recomputed beam geometry and pattern. The inner action is idealized exact shutdown of modeled protected-carrier power; command failures, residual emissions, and hardware turn-off transients have zero probability in the public baseline.

If the 180 km target is not geometrically feasible inside the satellite's modeled field of regard, the implementation does not invent additional attenuation; the unretasked geometry is retained unless the entire coverage disk is already outside the target distance.

### 8. I/N statistics and angle selection

For each two-second scored sample, all eligible active beam powers are summed linearly and divided by the calculated receiver noise power. The simulator tracks four Monte Carlo realizations. It pools raw time statistics across all selected windows **within each realization**; it does not select an angle separately for each window and average the answers.

The practical candidate passes only if both of these robust conditions hold:

1. the 95th percentile across runs of the per-run fraction of samples above −6 dB I/N is no more than 5%; and
2. the 95th percentile across runs of the per-run 95th-time-percentile I/N is no more than −6 dB.

Among feasible pairs with `0 <= inner <= outer`, the public baseline minimizes:

```text
score = outer angle + inner angle
```

The service-impact weight is zero. Ties are broken by smaller outer angle and then smaller inner angle. The algorithm therefore minimizes the sum of the two angles; it does not exclusively minimize outer angle or exclusively minimize inner angle.

The coarse search uses `[0, 0.5, 1, 2, 3, 5:5:180]` degrees, clipped to the site's visible sky. The fine search covers both the strict and practical coarse optima with a 0.5° grid, initially extending 10° around them. If a selected result reaches a nonphysical edge of that local band, the program expands the band and deterministically replays the accumulated windows rather than silently accepting an edge result. Physical boundaries—0° and the visible-sky limit—are reported separately.

### 9. Phase-diverse ensemble and convergence

A single short Walker epoch can favor or penalize a site because of the arbitrary constellation lattice phase. The public workflow reduces that artifact in seven ways:

1. all geometry is anchored to one absolute reference epoch instead of resetting the Walker lattice at every window;
2. the first 12 two-hour windows cover all twelve even UTC start hours exactly once;
3. windows occur on noncontiguous constellation phases across successive days;
4. deterministic coprime hour/block strides avoid repeatedly sampling one local-time pattern;
5. each satellite's 30-center lattice receives a reproducible, service-neutral rigid rotation keyed by geometry seed, persistent satellite ID, and global orbital revolution;
6. geometry, traffic, load, and uncertainty drivers are recorded through deterministic seeds and a forcing ID; and
7. cumulative windows continue in four-window batches until angle stability is demonstrated or the maximum is reached.

Each window contributes 2 hours at a 2-second step, or 3,600 scored samples per realization. The first 12 windows therefore provide 24 pooled hours per realization. The run cannot declare convergence before 24 windows (48 pooled hours). It converges only after both primary angles change by no more than 1° over two successive four-window additions, while the primary pair remains feasible and the fine search remains resolved. The maximum is 48 windows (96 pooled hours per realization).

Starting at the default reference epoch, the first 12 UTC start hours are `00, 14, 04, 18, 08, 22, 12, 02, 16, 06, 20, 10` on successive dates. Later 12-window blocks use an additional deterministic block offset so an extended convergence run does not replay the same date/hour pairings.

For one-based window index `j`, the default manifest records geometry seed `16751695 + 104729*(j-1)` and traffic seed `91675169 + 130363*(j-1)`. A SHA-256-derived `ForcingId` summarizes the reference epoch, maximum plan length, timing, guards, base seeds, and stratification policy. Java support is required only for this deterministic identifier.

The forcing design reduces—but cannot prove elimination of—epoch, lattice, finite-sample, traffic, or model-form sensitivity.

## Reproducing and auditing a run

For a defensible comparison:

1. use the same release and MATLAB version;
2. use the same P.618 map bundle;
3. reuse the exact cached ground elevation rather than making a new network query;
4. keep the reference epoch, seed schedule, window plan, and baseline configuration unchanged;
5. compare `ForcingId` values before attributing differences to site inputs;
6. require `Feasible`, `Converged`, and no `SearchBoundaryFlag`; and
7. retain the entire output folder, especially `configuration.json`, `window_manifest.csv`, `site_heights.csv`, and `atmospheric_lookup.csv`.

The deterministic forcing ID identifies the timing and seed plan, not every configuration field. Compare the full configuration as well as the forcing ID.

## Changing the baseline

The supported public inputs are the seven interactive input groups. Advanced assumptions live in `config/defaultOdsConfig.m`; ensemble controls live in `runOdsEnsemble.m` and `buildOdsEnsemblePlan.m`.

Common advanced changes include:

| Assumption | Configuration field or option |
|---|---|
| Power-control mode | `PowerControlMode` / `cfg.rf.powerControlMode` |
| Optional hardware peak-EIRP ceiling | `MaximumBeamEirpDensityDbwPerMHz` / `cfg.rf.maximumBeamEirpDensityDbwPerMHz` |
| Fixed-EIRP comparison only | `BeamEirpDensityDbwPerMHz` / `cfg.rf.eirpDensityDbwPerMHz` |
| I/N threshold | `cfg.receiver.protectionCriterionDb` |
| Availability | `cfg.reporting.practicalAvailabilityPercent`, corresponding exceedance and receiver metadata |
| Beam count/layout | `cfg.beams.numberPerSatellite`, layout CSV, resource mapping |
| Field of regard | `cfg.beams.coneHalfAngleDeg` and dependent geometry |
| RF spot radius | `cfg.beams.spotHalfPowerRadiusDeg` |
| Traffic | `cfg.resources.*DutyCycle`, on/off durations, load mean/sigma/minimum |
| Per-beam ground-PFD ceiling | `PfdLimitDbwM2MHz` / `cfg.rf.pfdLimitDbwM2MHz` |
| PFD bounding resolution | `cfg.rf.pfdScanStepDeg`, `cfg.rf.pfdLookStepDeg` |
| Antenna envelope | `cfg.antenna.model` and associated pattern implementation |
| Propagation | `cfg.propagation.*`, `cfg.rf.implementationLossDb`, polarization loss |
| NRAO-informed correction | `cfg.calibration.*` |
| Retask distance and timing | `cfg.ods.outerMinimumBeamCenterDistanceKm`, latency, clock, hysteresis |
| Constellation | `cfg.constellation.shells` |
| Monte Carlo/window limits | `MonteCarloRuns`, `InitialWindowCount`, `MinimumWindowCount`, `MaximumWindowCount` in `runOdsEnsemble` |

Do not change one derived field in isolation. Prefer `ProtectionCriterionDb`
and `PrimaryAvailabilityPercent` at the public entry point: these update
the receiver/search thresholds and allowed sample exceedance consistently.
P.618 annual attenuation exceedance is a **separate propagation assumption**
and is not automatically changed by the I/N-availability option. Review it
separately for the intended weather scenario; it need not equal the allowed
I/N exceedance. Changing beam count also requires a matching packing layout
and carrier assignment. After a baseline change, update the release
identifier, assumptions documentation, and validation tests.

## Known limitations

- The output is a model-dependent sensitivity result, not a regulatory protection contour or operational instruction.
- The constellation is synthetic Walker geometry and does not represent current spacecraft, TLEs, deployment, station keeping, or availability.
- The user-entered uniform per-beam PFD ceiling, saturated-envelope power strategy, traffic, and uncertainty distributions are engineering assumptions requiring operator validation. No aggregate-PFD controller or total spacecraft RF budget is modeled.
- The transmit and receive patterns are reference envelopes, not measured antenna patterns.
- The beam scheduler is synthetic and service-neutral. It has no real user distribution, demand forecast, gateway constraints, handovers, frequency coordination, or operator beam-management logic.
- Rectangular spectral overlap omits transmitter masks, out-of-band emissions, receiver filter skirts, blocking, intermodulation, and frontend compression.
- Worst-case co-polar coupling is assumed; polarization mismatch and time-varying polarization are omitted.
- The DEM supplies only one point height. Terrain diffraction, local horizon blockage, buildings, vegetation, and detailed clutter maps are omitted.
- P.618 annual statistics are used as a deterministic elevation lookup, not a time-correlated weather process jointly sampled with satellite traffic.
- The 0°–5° atmosphere uses the 5° lookup value. Very-low-elevation propagation is therefore simplified.
- The −18 dB, 30–150 km NRAO-informed transfer is provisional and cross-band. It is not validation of DCS or GRB protection.
- GOES boresights use fixed nominal longitudes and a spherical nominal GEO radius, not live ephemerides.
- The idealized inner action removes protected-carrier power exactly; residual emissions and implementation failures are omitted.
- Four Monte Carlo runs and at most 48 windows do not characterize all rare events. `Converged` means only that the selected angle pair met the configured finite-window stability test.
- A 0.5° grid limits the reported angular resolution.

## Project layout

```text
runOdsAngleSimulator.m          Public interactive/programmatic entry point
checkOdsInstallation.m         Dependency and P.618-map preflight
runOdsEnsemble.m               Multi-window search, pooling, convergence, outputs
buildOdsEnsemblePlan.m         Deterministic UTC window and seed plan
resolveSiteHeights.m           USGS DEM and EGM96 height resolution
generateP618AtmosphericLookup.m  P.618 elevation-loss lookup
configureOdsZaRadius.m         Consistent ZA configuration
config/                        Baseline configuration builder
src/                           Geometry, traffic, RF, ODS, and search engine
evidence/                      Small source/provenance tables used by the model
tests/                         Release checks and synthetic propagation fixture
references/SOURCES.md          Source and standards map
THIRD_PARTY_NOTICES.md         Third-party terms and data notices
LICENSE                        MIT license for original release code/documentation
CITATION.cff                   Software citation metadata
QUICKSTART.md                  Installation and first-run guide
validation/                    Test records and path-free reference results
FILES_SHA256.csv               Integrity inventory (excludes itself)
```

## Tests

From the release root, run:

```matlab
addpath("tests")
verifyOdsAngleSimulator
```

To include a bounded end-to-end plumbing smoke test:

```matlab
verifyOdsAngleSimulator(RunSmokeSimulation=true)
```

These checks use dry-run validation and a synthetic atmospheric fixture, so they do not require the P.618 map bundle and do not validate engineering angle values. Use `checkOdsInstallation` separately to verify the real P.618 maps. Full production runs are computationally substantial.

The class-based PFD regression suite includes the legacy checks and an end-to-end smoke run:

```matlab
testResults = runtests("tests/pfdPowerControlTest.m");
assert(all([testResults.Passed]));
```

It checks nadir free-space arithmetic, the 5 dB response to a 5 dB ceiling change, dense whole-Earth directional sampling, halved scan/look-cell resolution, hardware limiting, peak-before-pattern uncertainty, retasking, linear aggregation, invalid inputs, and output generation. The geometric controller bounds the current modeled Earth surface; this is not measured compliance validation.

### Reproduce the four Wallops GRB PFD cases

```matlab
addpath("examples");
summary = runWallopsGrbPfdSweep( ...
    ItuDigitalMapsFolder="C:\path\to\P618-maps", ...
    PfdLimitDbwM2MHz=-80);
```

This runs the 16.4 m Wallops dish (37.94651°, −75.46210°), GRB, GOES-East at −75.2°, 5 m feed height, and ZA radii `[0 10 20 30]` km. It reuses the recorded 9.465678215 m orthometric ground height and EGM96 geoid conversion, retains the full 2-second / 4-realization / 12–48-window settings, and writes `sweep_summary.csv` with links represented as output-folder paths. Per-case spreadsheets and complete run records remain in their own timestamped folders. All four cases share timing/seed plans; their convergence stopping windows can differ.

The completed reference results are documented in
[validation/README.md](validation/README.md), with a machine-readable
[reference table](validation/wallops_grb_pfd80_reference.csv).
They are numerical regression references, not independent measurements.

## Runtime, troubleshooting, and privacy

- A full production study can take hours. The four reference cases together
  took approximately 4 hours 18 minutes on the development machine; this is
  an observation, not a runtime guarantee. MATLAB prints window/search
  progress. `DryRun=true` checks setup but produces no ODS angles.
- If MATLAB cannot find the entry point, change the current folder to the
  extracted release root. Avoid `addpath(genpath(...))` over collections of
  historical simulator releases: duplicate function names can select the
  wrong model. Use `which runOdsAngleSimulator -all` to diagnose this.
- If maps are missing, select the extracted directory whose top level
  contains `maps.mat`, `p836.mat`, `p837.mat`, and `p840.mat`. The maps and
  MATLAB product licenses are external requirements, not included downloads.
- If the DEM query fails or does not cover a site, supply a trusted ground
  **orthometric** elevation through `DemGroundElevationM`. Do not supply
  antenna AGL height or an ellipsoidal elevation in that field.
- If GOES is below the horizon, select a visible nominal slot; do not bypass
  the check to obtain a numerical answer.
- A nonconverged or infeasible result is provisional. Inspect
  `convergence_history.csv`, `run_report.txt`, and the complete configuration
  before changing the model or extending the study.
- The default DEM request transmits the entered coordinates to USGS EPQS.
  Supplying cached elevation avoids that request. The simulator includes
  no analytics or automatic result upload.
- Generated run files contain site coordinates and can contain absolute
  local paths in configuration, MATLAB data, and sweep summaries. Inspect
  and redact those fields before distributing your own results. The public
  reference table excludes local paths; private raw run folders are not
  included in the release archive.
- When reporting a reproducibility issue, include the release/MATLAB version,
  toolbox versions, error identifier, relevant non-sensitive configuration,
  forcing ID, and convergence status. Do not send licensed map bundles.

The source ZIP is not a standalone executable or an installable `.mltbx`.
Windows with MATLAB R2025b Update 4 was verified for this release; other
operating systems and MATLAB releases have not been independently tested.
The original MIT license and third-party exclusions are unchanged.

## Sources, licensing, and citation

See [references/SOURCES.md](references/SOURCES.md) for the source map, [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for redistribution notes, and [CITATION.cff](CITATION.cff) for software citation metadata. ITU recommendations, MathWorks products and support data, NOAA/NRAO publications, and USGS services are referenced—not relicensed or bundled by this project.

Original code and documentation in this release are provided under the [MIT License](LICENSE), subject to the exclusions and notices described in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
