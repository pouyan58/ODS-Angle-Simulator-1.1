classdef pfdPowerControlTest < matlab.unittest.TestCase
    %pfdPowerControlTest Geometry, power, input, and integration regressions.

    properties
        Config
        PowerTable
        ProjectFolder
    end

    methods (TestClassSetup)
        function configureFixture(testCase)
            root = string(fileparts(fileparts(mfilename("fullpath"))));
            testCase.ProjectFolder = root;
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(root));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(root,"src")));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(root,"config")));
            temporary = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            setup = runOdsAngleSimulator(LatitudeDeg=37.94651,LongitudeDeg=-75.4621, ...
                AntennaDiameterM=16.4,AntennaHeightAglM=5,Service="GRB", ...
                GoesSatellite="GOES East",ZaRadiusKm=30,PfdLimitDbwM2MHz=-80, ...
                DemGroundElevationM=9.465678215,OutputRoot=string(temporary.Folder),DryRun=true);
            testCase.Config = setup.config;
            testCase.PowerTable = buildPfdPowerTable(setup.config);
        end
    end

    methods (Test)
        function nadirMatchesFreeSpace(testCase)
            actual = [lookupPfdPeakEirp(0,1,testCase.PowerTable), ...
                lookupPfdPeakEirp(0,2,testCase.PowerTable)];
            expected = -80 + 10*log10(4*pi*[340e3 355e3].^2);
            testCase.verifyEqual(actual,expected,AbsTol=1e-9);
        end

        function pfdChangeScalesPower(testCase)
            cfg = testCase.Config;
            cfg.rf.pfdLimitDbwM2MHz = -75;
            raised = buildPfdPowerTable(cfg);
            testCase.verifyEqual(raised.PfdPeakEirpLimitDbwPerMHz - ...
                testCase.PowerTable.PfdPeakEirpLimitDbwPerMHz, ...
                5*ones(height(raised),1),AbsTol=1e-10);
        end

        function wholeEarthPfdBelowLimit(testCase)
            maximumPfd = sampleEarthPfd(testCase.Config,testCase.PowerTable);
            testCase.verifyLessThanOrEqual(maximumPfd,-80+1e-9);
            testCase.verifyGreaterThan(maximumPfd,-80.05);
        end

        function boundingGridConverges(testCase)
            cfg = testCase.Config;
            cfg.rf.pfdScanStepDeg = cfg.rf.pfdScanStepDeg/2;
            cfg.rf.pfdLookStepDeg = cfg.rf.pfdLookStepDeg/2;
            refined = buildPfdPowerTable(cfg);
            scan = (0.0125:0.1:59.9125).';
            difference = lookupPfdPeakEirp(scan,1,refined) - ...
                lookupPfdPeakEirp(scan,1,testCase.PowerTable);
            testCase.verifyGreaterThanOrEqual(min(difference),-1e-9);
            testCase.verifyLessThan(max(difference),0.03);
        end

        function retaskedGeometryChangesPeak(testCase)
            normalPeak = lookupPfdPeakEirp(55,1,testCase.PowerTable);
            retaskedPeak = lookupPfdPeakEirp(10,1,testCase.PowerTable);
            testCase.verifyGreaterThan(normalPeak,retaskedPeak);
            normal = calculateBeamEirpDensity(-3,0,testCase.Config,normalPeak);
            retasked = calculateBeamEirpDensity(-25,0,testCase.Config,retaskedPeak);
            testCase.verifyEqual(retasked-normal,retaskedPeak-normalPeak-22,AbsTol=1e-10);
        end

        function positiveErrorCannotErasePattern(testCase)
            actual = calculateBeamEirpDensity([-20 -40],[10 10],testCase.Config,[42 48]);
            testCase.verifyEqual(actual,[22 8],AbsTol=1e-10);
        end

        function negativePowerOffsetBacksOff(testCase)
            actual = calculateBeamEirpDensity([-20 -40],[-3 -6],testCase.Config,[42 48]);
            testCase.verifyEqual(actual,[19 2],AbsTol=1e-10);
        end

        function hardwareCeilingLimitsPeak(testCase)
            cfg = testCase.Config;
            cfg.rf.maximumBeamEirpDensityDbwPerMHz = 43;
            limited = buildPfdPowerTable(cfg);
            testCase.verifyLessThanOrEqual(max(limited.CommandedPeakLimitDbwPerMHz),43);
            testCase.verifyEqual(lookupPfdPeakEirp(60,1,limited),43,AbsTol=1e-10);
        end

        function invalidPfdRejected(testCase)
            testCase.verifyError(@() runOdsAngleSimulator(PfdLimitDbwM2MHz=1i), ...
                "MATLAB:validators:mustBeReal");
        end

        function missingPeakCannotNormalizeAtReceiver(testCase)
            testCase.verifyError(@() calculateBeamEirpDensity(-20,0,testCase.Config), ...
                "ODS:MissingPfdPeakLimit");
        end

        function aggregateIsNotClippedToOneBeam(testCase)
            cfg = testCase.Config;
            cfg.simulation.duration = seconds(20);
            cfg.simulation.monteCarloRuns = 1;
            cfg.propagation.enabled = false;
            cfg.receiver.protectionCriterionDb = 100;
            geometry = buildConstellationGeometry(cfg);
            realization = buildOdsRealizations(cfg,geometry,RandomSeed=123);
            powerMw = sum(10.^(realization.preMitigationPowerDbm/10),2);
            strongestMw = max(10.^(realization.preMitigationPowerDbm/10),[],2);
            testCase.verifyGreaterThan(max(powerMw-strongestMw),0);
            testCase.verifyTrue(all(powerMw >= strongestMw));
        end

        function existingReleaseChecks(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(testCase.ProjectFolder,"tests")));
            verifyOdsAngleSimulator();
            testCase.verifyTrue(true);
        end

        function endToEndSmoke(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(testCase.ProjectFolder,"tests")));
            verifyOdsAngleSimulator(RunSmokeSimulation=true);
            testCase.verifyTrue(true);
        end
    end
end

function maximumPfd = sampleEarthPfd(cfg,powerTable)
% Independent dense point sampler, including off-meridian ground rays.
earthRadius = 6378137;
maximumPfd = -Inf;
scans = [0 0.025 15.025 30.025 45.025 59.975 60];
for shellIdx = 1:numel(cfg.constellation.shells)
    satelliteRadius = earthRadius+1000*cfg.constellation.shells(shellIdx).altitudeKm;
    limb = asind(earthRadius/satelliteRadius);
    theta = (0:0.005:limb).';
    range = satelliteRadius*cosd(theta) - ...
        sqrt(max(0,earthRadius^2-satelliteRadius^2*sind(theta).^2));
    for scan = scans
        offAxis = acosd(max(-1,min(1,cosd(theta)*cosd(scan) + ...
            sind(theta)*sind(scan).*cosd([0 37 90 180]))));
        [~,relativeGain] = satelliteTransmitGain(offAxis,2,scan,cfg);
        peak = lookupPfdPeakEirp(scan,shellIdx,powerTable);
        pfd = peak+relativeGain-10*log10(4*pi*range.^2);
        maximumPfd = max(maximumPfd,max(pfd,[],"all"));
    end
end
end
