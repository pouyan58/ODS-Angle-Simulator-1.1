function geometry = prepareBeamPowerControl(cfg,geometry)
%prepareBeamPowerControl Attach normal and retasked footprint-power limits.
%   Circular shell height and scan angle determine range to the served
%   footprint; the range to the protected station never sets beam power.

arguments
    cfg (1,1) struct
    geometry (1,1) struct
end

if string(cfg.rf.powerControlMode) ~= "groundPfdLimited"
    geometry.beamPeakEirpLimitDbwPerMHz = ...
        cfg.rf.maximumBeamEirpDensityDbwPerMHz + ...
        zeros(size(geometry.beamScanAngleDeg));
    geometry.outerRetaskedPeakEirpLimitDbwPerMHz = ...
        cfg.rf.maximumBeamEirpDensityDbwPerMHz + ...
        zeros(size(geometry.outerRetaskedBeamScanAngleDeg));
    return
end
powerTable = buildPfdPowerTable(cfg);
geometry.beamPeakEirpLimitDbwPerMHz = ...
    zeros(size(geometry.beamScanAngleDeg));
geometry.outerRetaskedPeakEirpLimitDbwPerMHz = ...
    NaN(size(geometry.outerRetaskedBeamScanAngleDeg));
for shellIdx = 1:numel(cfg.constellation.shells)
    satelliteMask = geometry.satelliteShellIndex == shellIdx;
    geometry.beamPeakEirpLimitDbwPerMHz(satelliteMask,:) = ...
        lookupPfdPeakEirp(geometry.beamScanAngleDeg(satelliteMask,:), ...
        shellIdx,powerTable);
    retaskedScan = double(geometry.outerRetaskedBeamScanAngleDeg(:,satelliteMask));
    validTarget = geometry.outerRetaskFeasible(:,satelliteMask) & ...
        isfinite(retaskedScan) & retaskedScan <= cfg.beams.coneHalfAngleDeg+1e-5;
    retaskedPeak = NaN(size(retaskedScan));
    retaskedPeak(validTarget) = lookupPfdPeakEirp( ...
        retaskedScan(validTarget),shellIdx,powerTable);
    geometry.outerRetaskedPeakEirpLimitDbwPerMHz(:,satelliteMask) = retaskedPeak;
end
geometry.summary.powerControlMode = cfg.rf.powerControlMode;
geometry.summary.pfdLimitDbwM2MHz = cfg.rf.pfdLimitDbwM2MHz;
geometry.summary.minimumNormalPeakEirpDbwPerMHz = ...
    min(geometry.beamPeakEirpLimitDbwPerMHz,[],"all");
geometry.summary.maximumNormalPeakEirpDbwPerMHz = ...
    max(geometry.beamPeakEirpLimitDbwPerMHz,[],"all");
geometry.summary.pfdScope = "Per beam, free space, uniform spherical-ground ceiling";
end
