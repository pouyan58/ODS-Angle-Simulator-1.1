function powerTable = buildPfdPowerTable(cfg)
%buildPfdPowerTable Bound one beam's free-space PFD everywhere on Earth.
%   The current spherical Earth, axisymmetric nonincreasing S.1528 pattern,
%   and uniform PFD ceiling reduce the footprint maximum to the meridian
%   containing nadir and the beam axis. At any Earth-directed look angle,
%   that meridian has the smallest off-axis angle and hence largest gain.
%   All look angles from nadir through the Earth limb are included.
%
%   Each scan/look cell uses the smallest possible off-axis angle, the
%   largest compensated sidelobe gain over the scan cell, and the shortest
%   range over the look cell. This bounds PFD ABOVE, so the resulting peak
%   EIRP limit is conservative even between grid points. No receiver gain,
%   clutter, atmospheric loss, traffic load, or empirical correction earns
%   additional transmit power. This is a PER-BEAM, not an aggregate, limit.

arguments
    cfg (1,1) struct
end

assert(cfg.beams.scanLossCompensationEnabled && ...
    string(cfg.beams.transmitPatternModel) == "ituRS1528LeoPerBeam", ...
    "ODS:PfdPattern", "PFD control requires the compensated S.1528 pattern.");
assert(isfinite(cfg.rf.pfdLimitDbwM2MHz) && ...
    isreal(cfg.rf.pfdLimitDbwM2MHz), "ODS:PfdLimit", ...
    "The per-beam PFD ceiling must be a finite real dBW/m^2/MHz value.");
scanStep = cfg.rf.pfdScanStepDeg;
lookStep = cfg.rf.pfdLookStepDeg;
assert(isfinite(scanStep) && scanStep > 0 && ...
    isfinite(lookStep) && lookStep > 0, "ODS:PfdGrid", ...
    "Both PFD bounding-cell angular steps must be positive and finite.");
earthRadiusM = 6378137;
scanEdges = unique([0:scanStep:cfg.beams.coneHalfAngleDeg, ...
    cfg.beams.coneHalfAngleDeg]);
scanLower = scanEdges(1:end-1).';
scanUpper = scanEdges(2:end).';
shellCount = numel(cfg.constellation.shells);
rows = cell(shellCount,1);
for shellIdx = 1:shellCount
    altitudeM = 1000*cfg.constellation.shells(shellIdx).altitudeKm;
    satelliteRadiusM = earthRadiusM + altitudeM;
    limbDeg = asind(earthRadiusM/satelliteRadiusM);
    assert(cfg.beams.coneHalfAngleDeg < limbDeg, "ODS:PfdEarthLimb", ...
        "The steering field of regard must remain inside the Earth limb.");
    lookEdges = unique([0:lookStep:limbDeg,limbDeg]);
    lookLower = lookEdges(1:end-1);
    lookUpper = lookEdges(2:end);
    rootTerm = sqrt(max(0,earthRadiusM^2 - ...
        satelliteRadiusM^2*sind(lookLower).^2));
    % Rationalized near intersection avoids subtraction cancellation.
    shortestRangeM = (satelliteRadiusM^2-earthRadiusM^2) ./ ...
        (satelliteRadiusM*cosd(lookLower) + rootTerm);
    spreadingDb = 10*log10(4*pi*shortestRangeM.^2);
    peakLimit = zeros(size(scanLower));
    boundLook = zeros(size(scanLower));
    for scanIdx = 1:numel(scanLower)
        minimumOffAxis = max(0,max(lookLower-scanUpper(scanIdx), ...
            scanLower(scanIdx)-lookUpper));
        [~,upperRelativeGain] = satelliteTransmitGain(minimumOffAxis, ...
            cfg.beams.spotHalfPowerRadiusDeg,scanUpper(scanIdx),cfg);
        [maximumTransferDb,limitingIdx] = max(upperRelativeGain-spreadingDb);
        peakLimit(scanIdx) = cfg.rf.pfdLimitDbwM2MHz - maximumTransferDb;
        boundLook(scanIdx) = lookLower(limitingIdx);
    end
    rowCount = numel(scanLower);
    rows{shellIdx} = table(repmat(shellIdx,rowCount,1), ...
        repmat(altitudeM/1000,rowCount,1),scanLower,scanUpper,peakLimit, ...
        min(peakLimit,cfg.rf.maximumBeamEirpDensityDbwPerMHz), ...
        boundLook,repmat(cfg.rf.pfdLimitDbwM2MHz,rowCount,1), ...
        VariableNames=["ShellIndex","AltitudeKm","ScanLowerDeg", ...
        "ScanUpperDeg","PfdPeakEirpLimitDbwPerMHz", ...
        "CommandedPeakLimitDbwPerMHz","BoundingLookLowerDeg", ...
        "PfdLimitDbwM2MHz"]);
end
powerTable = vertcat(rows{:});
end
