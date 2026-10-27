function eirpDensityDbwPerMHz = calculateBeamEirpDensity( ...
    relativePatternDb, powerOffsetDb, cfg, peakLimitDbwPerMHz)
%calculateBeamEirpDensity Set peak power BEFORE applying directional gain.
%   A PFD-controlled beam starts at its footprint-limited peak. Positive
%   uncertainty cannot exceed that ceiling; negative offsets back off power.
%   ODS changes pointing and thus its peak ceiling, never the PFD toward the
%   protected receiver. Fixed-EIRP mode is retained for explicit comparisons.

arguments
    relativePatternDb {mustBeNumeric,mustBeReal}
    powerOffsetDb {mustBeNumeric,mustBeReal,mustBeFinite}
    cfg (1,1) struct
    peakLimitDbwPerMHz {mustBeNumeric,mustBeReal} = []
end

if string(cfg.rf.powerControlMode) == "groundPfdLimited"
    assert(~isempty(peakLimitDbwPerMHz) && ...
        all(isfinite(peakLimitDbwPerMHz),"all"),"ODS:MissingPfdPeakLimit", ...
        "PFD mode requires a finite footprint-derived peak limit for every beam.");
    nominalPeak = peakLimitDbwPerMHz;
else
    nominalPeak = cfg.rf.eirpDensityDbwPerMHz;
    peakLimitDbwPerMHz = cfg.rf.maximumBeamEirpDensityDbwPerMHz;
end
commandedPeak = min(nominalPeak+powerOffsetDb,peakLimitDbwPerMHz);
eirpDensityDbwPerMHz = commandedPeak + relativePatternDb;
end
