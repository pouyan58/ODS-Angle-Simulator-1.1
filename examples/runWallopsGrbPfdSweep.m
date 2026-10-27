function summary = runWallopsGrbPfdSweep(options)
%runWallopsGrbPfdSweep Run matched Wallops GRB cases at ZA 0/10/20/30 km.
%   Supply ItuDigitalMapsFolder or the MATLAB_ITU_MAPS_FOLDER environment
%   variable. Cached Wallops ground height is reused for reproducibility.
%   Each case uses the full default phase-diverse ensemble and writes a
%   separate timestamped output folder. Partial completion is saved after
%   every case; sweep_summary.csv contains the corresponding folder paths.

arguments
    options.ItuDigitalMapsFolder (1,1) string = ""
    options.OutputRoot (1,1) string = fullfile( ...
        fileparts(fileparts(mfilename("fullpath"))),"runs","wallops_grb_pfd_sweep")
    options.PfdLimitDbwM2MHz (1,1) {mustBeNumeric,mustBeReal,mustBeFinite} = -80
end

projectFolder = string(fileparts(fileparts(mfilename("fullpath"))));
originalPath = path;
cleanup = onCleanup(@() path(originalPath));
addpath(projectFolder);
if ~isfolder(options.OutputRoot)
    mkdir(options.OutputRoot);
end
zaRadiiKm = [0 10 20 30];
rows = cell(numel(zaRadiiKm),1);
for caseIdx = 1:numel(zaRadiiKm)
    fprintf("\nWALLOPS PFD SWEEP: case %d/%d, ZA %.0f km\n", ...
        caseIdx,numel(zaRadiiKm),zaRadiiKm(caseIdx));
    result = runOdsAngleSimulator(SiteName="Wallops Island", ...
        LatitudeDeg=37.94651,LongitudeDeg=-75.46210, ...
        AntennaDiameterM=16.4,AntennaHeightAglM=5, ...
        Service="GRB",GoesSatellite="GOES East", ...
        ZaRadiusKm=zaRadiiKm(caseIdx), ...
        PfdLimitDbwM2MHz=options.PfdLimitDbwM2MHz, ...
        DemGroundElevationM=9.465678215, ...
        ItuDigitalMapsFolder=options.ItuDigitalMapsFolder, ...
        OutputRoot=options.OutputRoot,RunLabel="ground_pfd_control");
    row = result.summary;
    row.RunStatus = string(result.status);
    row.OutputFolder = string(result.outputFolder);
    rows{caseIdx} = row;
    summary = vertcat(rows{1:caseIdx});
    writetable(summary,fullfile(options.OutputRoot,"sweep_summary.csv"));
    save(fullfile(options.OutputRoot,"sweep_summary.mat"),"summary","options");
end
disp(summary(:,["ZaRadiusKm","InnerAngleDeg","OuterAngleDeg", ...
    "RobustExceedancePercent","PercentileIOverNDb","Converged"]));
end
