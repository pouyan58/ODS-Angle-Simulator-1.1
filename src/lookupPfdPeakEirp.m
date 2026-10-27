function peakEirp = lookupPfdPeakEirp(scanAngleDeg,shellIndex,powerTable)
%lookupPfdPeakEirp Select a conservative scan-cell peak-EIRP ceiling.
%   SCANANGLEDEG is an array for ONE constellation shell. The table covers
%   the closed steering interval; no interpolation can raise its ceiling.

arguments
    scanAngleDeg {mustBeNumeric,mustBeReal,mustBeFinite,mustBeNonnegative}
    shellIndex (1,1) {mustBeNumeric,mustBeReal,mustBeInteger,mustBePositive}
    powerTable table
end

shellRows = powerTable(powerTable.ShellIndex == shellIndex,:);
assert(~isempty(shellRows),"ODS:PfdShell","No PFD table exists for this shell.");
scanEdges = [shellRows.ScanLowerDeg;shellRows.ScanUpperDeg(end)];
assert(all(scanAngleDeg <= scanEdges(end)+1e-5,"all"), ...
    "ODS:PfdScanOutsideTable","A beam scan angle exceeds the PFD table.");
indices = discretize(min(double(scanAngleDeg),scanEdges(end)),scanEdges);
peakEirp = reshape(shellRows.CommandedPeakLimitDbwPerMHz(indices(:)), ...
    size(scanAngleDeg));
end
