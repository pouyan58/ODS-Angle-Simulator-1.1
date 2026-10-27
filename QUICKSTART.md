# Getting started

GOES DCS/GRB ODS Angle Simulator — public source release 1.1.1.

This is MATLAB source code, not a standalone application. Read the
[README](README.md) for all assumptions, equations, configuration options,
output definitions, and limitations before interpreting a result.

## 1. Install the prerequisites

Use MATLAB R2025b or later with Aerospace Toolbox and Satellite
Communications Toolbox. This release was verified on Windows with R2025b
Update 4. EGM96 geoid data and MATLAB Java support must be available.

Obtain the P.618 digital maps following the
[MathWorks instructions](https://www.mathworks.com/help/satcom/ref/p618propagationlosses.html).
They are not included in the source ZIP. The extracted map directory must
contain `maps.mat`, `p836.mat`, `p837.mat`, and `p840.mat` at its top level.

Extract the simulator into a writable directory. In MATLAB, change the
current folder to the directory containing `runOdsAngleSimulator.m`.
Do not add multiple historical releases to the MATLAB path.

## 2. Check the installation

In the MATLAB Command Window:

```matlab
mapFolder = string(uigetdir(pwd,"Select the extracted P.618 map folder"));
assert(mapFolder ~= "0","Select a map folder before continuing.");
checkOdsInstallation(ItuDigitalMapsFolder=mapFolder,ThrowOnFailure=true);
```

All checks should pass. For noninteractive use, set `mapFolder` to your
actual map-directory path instead of using the folder-selection dialog.

## 3. Run the interactive simulator

```matlab
results = runOdsAngleSimulator(ItuDigitalMapsFolder=mapFolder);
```

Enter the seven requested groups:

| Input | Units or choices |
|---|---|
| Site latitude and longitude | Degrees; north/east positive |
| Dish diameter | Metres |
| Antenna phase-center height above ground | Metres, not site elevation |
| Receive service | DCS or GRB |
| Nominal GOES boresight | East, West, or Backup |
| Geographic ZA radius | Kilometres, `0 <= ZA < 180` |
| Per-beam ground PFD ceiling | dBW/m²/MHz; for example `-80` |

The default criterion is I/N ≤ −6 dB at 95% modeled availability.
The default satellite model has 30 spots within 60° of nadir and adjusts
each beam's peak EIRP to satisfy the entered uniform PFD limit. The limit
is per beam, not a cap on aggregate receiver interference.

Expect a substantial calculation. One full site case can take an hour or
more; adaptive convergence and hardware affect duration. Keep MATLAB
running. Do not substitute the small test fixture for real propagation data
when producing engineering results.

## 4. Find and interpret the output

The program prints its output folder, also available as:

```matlab
results.outputFolder
results.summary
```

By default, results are placed under `runs/` inside the extracted release.
Set `OutputRoot` to another writable directory when needed. Start with
`run_report.txt` or `ODS_Angle_Results.xlsx` in the case folder.

The angles are cone radii **from the selected GOES antenna boresight**,
not zenith or horizon elevation angles. Require `Feasible=true`,
`Converged=true`, and `SearchBoundaryFlag=false` before treating the
primary angle pair as a completed modeled result. An inner angle of 0°
means no separate inner shutdown cone was required by that modeled
criterion; it does not mean zero interference.

## 5. Reproduce the Wallops example

This is a full four-case GRB study, not a quick demo:

```matlab
addpath("examples");
summary = runWallopsGrbPfdSweep( ...
    ItuDigitalMapsFolder=mapFolder,PfdLimitDbwM2MHz=-80);
```

The study uses the 16.4 m Wallops antenna, 5 m AGL height, GOES-East,
and ZA radii 0, 10, 20, and 30 km. It reuses a recorded ground elevation.
See [the reference results](validation/README.md) for the prior completed
study and its numerical/model limitations.

## 6. Verify the code without a full production study

```matlab
testResults = runtests("tests/pfdPowerControlTest.m");
assert(all([testResults.Passed]));
```

These 13 checks include a bounded synthetic-propagation smoke run. They
verify arithmetic and software behavior, not measured antenna performance
or real-world interference compliance. They do not require the P.618 maps,
but they do require the MATLAB products and geoid support listed above.

## Privacy and permitted use

The default ground-elevation query sends the site's latitude/longitude to
USGS EPQS. For an offline run, provide a trusted orthometric ground height
using `DemGroundElevationM`; examples are in the README. Review your output
files before sharing because they contain coordinates and may contain local
paths. The package does not upload simulation results automatically.

The simulator is an independent engineering sensitivity model, not an
agency-endorsed or operator-validated protection tool. The existing MIT
license applies to original code/documentation; required proprietary
software, maps, standards, and publications are excluded. See
[LICENSE](LICENSE), [NOTICE.md](NOTICE.md), and
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
