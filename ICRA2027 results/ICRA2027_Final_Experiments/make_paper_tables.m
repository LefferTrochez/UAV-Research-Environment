clearvars -except CFG
clc
if ~exist('CFG','var') || ~isstruct(CFG)
    CFG = ICRA_experiment_config;
end
R = char(CFG.Paths.ResultsRoot);
tablesDir = fullfile(R,'tables');
outDir = fullfile(R,'paper_tables');
if ~exist(outDir,'dir')
    mkdir(outDir);
end
experimentRoot = fileparts(R);
frameworkRoot = fileparts(experimentRoot);
realResultsRoot = fullfile(frameworkRoot,'Real_Flight_TLOG','results');
outputExcel = fullfile(outDir,'ICRA2027_Final_Paper_Tables.xlsx');
missionFile    = fullfile(tablesDir,'ICRA_Mission_Metrics.csv');
controllerFile = fullfile(tablesDir,'ICRA_Controller_Diagnostics.csv');
actuationFile  = fullfile(tablesDir,'ICRA_Actuation_Metrics.csv');
costFile       = fullfile(tablesDir,'ICRA_Computational_Cost.csv');
assertFile(missionFile);
assertFile(controllerFile);
assertFile(actuationFile);
assertFile(costFile);
for traj = ["T1","T2"]
    realFile = fullfile(realResultsRoot,"REAL_" + traj,'experiment_data.mat');
    if ~exist(realFile,'file')
        error('PaperTables:MissingRealData', ...
            ['Missing REAL result:\n%s\n\n' ...
             'Run run_real_flight_analysis_updated first.'],realFile);
    end
end
M = readtable(missionFile,'VariableNamingRule','preserve');
C = readtable(controllerFile,'VariableNamingRule','preserve');
A = readtable(actuationFile,'VariableNamingRule','preserve');
K = readtable(costFile,'VariableNamingRule','preserve');
M = selectOfficial(M);
C = selectOfficial(C);
A = selectOfficial(A);
K = selectOfficial(K);
validateOfficialTable(M,'Mission metrics');
validateOfficialTable(C,'Controller diagnostics');
validateOfficialTable(A,'Actuation metrics');
validateOfficialTable(K,'Computational cost');
validateColumns(M,{ ...
    'PlantCode_ICRA','TrajectoryCode_ICRA','DisturbanceID_ICRA', ...
    'TruePathLength_m','PathTrackingRMSE_m'},'Mission metrics');
validateColumns(C,{ ...
    'PlantCode_ICRA','TrajectoryCode_ICRA','DisturbanceID_ICRA', ...
    'MissionStartTime_s','NavigationEndTime_s','NavigationDuration_s', ...
    'RollSelectedTrackingRMSE_deg','PitchSelectedTrackingRMSE_deg', ...
    'YawSelectedTrackingRMSE_deg', ...
    'pSelectedTrackingRMSE_rad_s','qSelectedTrackingRMSE_rad_s', ...
    'rSelectedTrackingRMSE_rad_s'},'Controller diagnostics');
validateColumns(A,{ ...
    'PlantCode_ICRA','TrajectoryCode_ICRA','DisturbanceID_ICRA', ...
    'PeakMotorSpeed_rad_s'},'Actuation metrics');
validateColumns(K,{ ...
    'PlantCode_ICRA','TrajectoryCode_ICRA','DisturbanceID_ICRA', ...
    'ExecutionElapsedWallTime_s','RealTimeFactor_RTF'},'Computational cost');
levels = ["L1","L2","L3"];
trajs  = ["T1","T2"];
conds  = ["NOM","DIST"];
sharedNames = { ...
    'Level', ...
    'Traj_Cond', ...
    'PathLength_m', ...
    'RollRMS_deg', ...
    'PitchRMS_deg', ...
    'YawExcursionRMS_deg', ...
    'pRMS_rad_s', ...
    'qRMS_rad_s', ...
    'rRMS_rad_s', ...
    'TrajectoryDuration_s'};
sharedRows = cell(0,numel(sharedNames));
realRateAudit = strings(0,2);
simSignalAudit = strings(0,4);
for it = 1:numel(trajs)
    traj = trajs(it);
    for ic = 1:numel(conds)
        cond = conds(ic);
        for il = 1:numel(levels)
            lev = levels(il);
            m = getRow(M,lev,traj,cond);
            c = getRow(C,lev,traj,cond);
            tStart = requireFiniteScalar(c.MissionStartTime_s, ...
                sprintf('%s %s %s MissionStartTime_s',lev,traj,cond));
            tEnd = requireFiniteScalar(c.NavigationEndTime_s, ...
                sprintf('%s %s %s NavigationEndTime_s',lev,traj,cond));
            duration = requirePositiveScalar(c.NavigationDuration_s, ...
                sprintf('%s %s %s NavigationDuration_s',lev,traj,cond));
            obs = getSimulationStateMetrics(R,lev,traj,cond,tStart,tEnd);
            pathLength = requirePositiveScalar(m.TruePathLength_m, ...
                sprintf('%s %s %s TruePathLength_m',lev,traj,cond));
            row = { ...
                char(lev), ...
                char(traj + "/" + cond), ...
                pathLength, ...
                obs.RollRMS_deg, ...
                obs.PitchRMS_deg, ...
                obs.YawExcursionRMS_deg, ...
                obs.pRMS_rad_s, ...
                obs.qRMS_rad_s, ...
                obs.rRMS_rad_s, ...
                duration};
            sharedRows(end+1,:) = row; %#ok<SAGROW>
            simSignalAudit(end+1,:) = [traj,lev,string(obs.AttitudeSource),string(obs.RateSource)]; %#ok<SAGROW>
        end
    end
    realFile = fullfile(realResultsRoot,"REAL_" + traj,'experiment_data.mat');
    obs = getRealObservableMetrics(realFile,traj);
    row = { ...
        'REAL', ...
        char(traj + "/REAL"), ...
        obs.PathLength_m, ...
        obs.RollRMS_deg, ...
        obs.PitchRMS_deg, ...
        obs.YawExcursionRMS_deg, ...
        obs.pRMS_rad_s, ...
        obs.qRMS_rad_s, ...
        obs.rRMS_rad_s, ...
        obs.TrajectoryDuration_s};
    sharedRows(end+1,:) = row; %#ok<SAGROW>
    realRateAudit(end+1,:) = [traj,string(obs.RateSource)]; %#ok<SAGROW>
end
SIM_REAL_SHARED = cell2table(sharedRows,'VariableNames',sharedNames);
if height(SIM_REAL_SHARED) ~= 14
    error('PaperTables:UnexpectedSharedRows', ...
        'SIM_REAL_Shared must contain exactly 14 rows; found %d.', ...
        height(SIM_REAL_SHARED));
end
assertCompleteNumericColumns(SIM_REAL_SHARED,sharedNames(3:end),'SIM_REAL_Shared');
simNames = { ...
    'Level', ...
    'Traj_Cond', ...
    'PathRMSE_m', ...
    'RollTrackingRMSE_deg', ...
    'PitchTrackingRMSE_deg', ...
    'YawTrackingRMSE_deg', ...
    'BodyRateTrackingRMSE_rad_s', ...
    'PeakMotorSpeed_rad_s', ...
    'ExecutionTime_s', ...
    'RTF'};
simRows = cell(0,numel(simNames));
for it = 1:numel(trajs)
    traj = trajs(it);
    for ic = 1:numel(conds)
        cond = conds(ic);
        for il = 1:numel(levels)
            lev = levels(il);
            m = getRow(M,lev,traj,cond);
            c = getRow(C,lev,traj,cond);
            a = getRow(A,lev,traj,cond);
            k = getRow(K,lev,traj,cond);
            pathRMSE = requireNonnegativeScalar(m.PathTrackingRMSE_m, ...
                sprintf('%s %s %s PathTrackingRMSE_m',lev,traj,cond));
            rollRMSE = requireNonnegativeScalar(c.RollSelectedTrackingRMSE_deg, ...
                sprintf('%s %s %s RollSelectedTrackingRMSE_deg',lev,traj,cond));
            pitchRMSE = requireNonnegativeScalar(c.PitchSelectedTrackingRMSE_deg, ...
                sprintf('%s %s %s PitchSelectedTrackingRMSE_deg',lev,traj,cond));
            yawRMSE = requireNonnegativeScalar(c.YawSelectedTrackingRMSE_deg, ...
                sprintf('%s %s %s YawSelectedTrackingRMSE_deg',lev,traj,cond));
            pRMSE = requireNonnegativeScalar(c.pSelectedTrackingRMSE_rad_s, ...
                sprintf('%s %s %s pSelectedTrackingRMSE_rad_s',lev,traj,cond));
            qRMSE = requireNonnegativeScalar(c.qSelectedTrackingRMSE_rad_s, ...
                sprintf('%s %s %s qSelectedTrackingRMSE_rad_s',lev,traj,cond));
            rRMSE = requireNonnegativeScalar(c.rSelectedTrackingRMSE_rad_s, ...
                sprintf('%s %s %s rSelectedTrackingRMSE_rad_s',lev,traj,cond));
            bodyRateRMSE = sqrt(pRMSE.^2 + qRMSE.^2 + rRMSE.^2);
            peakMotor = requirePositiveScalar(a.PeakMotorSpeed_rad_s, ...
                sprintf('%s %s %s PeakMotorSpeed_rad_s',lev,traj,cond));
            executionTime = requirePositiveScalar(k.ExecutionElapsedWallTime_s, ...
                sprintf('%s %s %s ExecutionElapsedWallTime_s',lev,traj,cond));
            rtf = requirePositiveScalar(k.RealTimeFactor_RTF, ...
                sprintf('%s %s %s RealTimeFactor_RTF',lev,traj,cond));
            row = { ...
                char(lev), ...
                char(traj + "/" + cond), ...
                pathRMSE, ...
                rollRMSE, ...
                pitchRMSE, ...
                yawRMSE, ...
                bodyRateRMSE, ...
                peakMotor, ...
                executionTime, ...
                rtf};
            simRows(end+1,:) = row; %#ok<SAGROW>
        end
    end
end
SIM_PAPER_METRICS = cell2table(simRows,'VariableNames',simNames);
if height(SIM_PAPER_METRICS) ~= 12
    error('PaperTables:UnexpectedSimRows', ...
        'SIM_Paper_Metrics must contain exactly 12 rows; found %d.', ...
        height(SIM_PAPER_METRICS));
end
assertCompleteNumericColumns(SIM_PAPER_METRICS,simNames(3:end),'SIM_Paper_Metrics');
outputExcel = writeWorkbookRobust(SIM_REAL_SHARED,SIM_PAPER_METRICS,outputExcel);
fprintf('\n');
fprintf('==============================================================\n');
fprintf(' FINAL ICRA 2027 PAPER TABLES GENERATED\n');
fprintf('==============================================================\n');
fprintf('Excel:\n%s\n\n',outputExcel);
fprintf('Sheet 1: SIM_REAL_Shared   -> %d rows x %d columns\n', ...
    height(SIM_REAL_SHARED),width(SIM_REAL_SHARED));
fprintf('Sheet 2: SIM_Paper_Metrics -> %d rows x %d columns\n', ...
    height(SIM_PAPER_METRICS),width(SIM_PAPER_METRICS));
fprintf('\nSIM signal sources used in Table 1:\n');
for i = 1:size(simSignalAudit,1)
    fprintf('  %s/%s -> attitude=%s, rates=%s\n', ...
        simSignalAudit(i,1),simSignalAudit(i,2), ...
        simSignalAudit(i,3),simSignalAudit(i,4));
end
fprintf('\nREAL body-rate source audit:\n');
for i = 1:size(realRateAudit,1)
    fprintf('  %s -> %s\n',realRateAudit(i,1),realRateAudit(i,2));
end
fprintf('\nMetric safeguards:\n');
fprintf('  - SIM path length uses TruePathLength_m (not noisy accumulated estimate).\n');
fprintf('  - Yaw comparison uses excursion RMS relative to initial yaw.\n');
fprintf('  - p/q/r shared metrics are state RMS, not tracking RMSE.\n');
fprintf('  - BodyRateTrackingRMSE = sqrt(pRMSE^2 + qRMSE^2 + rRMSE^2).\n');
fprintf('  - Any NaN/Inf paper metric stops execution before Excel is written.\n');
fprintf('  - No REAL PWM -> rotor-speed conversion is performed.\n');
fprintf('  - REAL table metrics use the complete stored trajectory window; no plotting trim is applied.\n');
fprintf('==============================================================\n\n');
disp(SIM_REAL_SHARED)
disp(SIM_PAPER_METRICS)
function assertFile(filePath)
    if ~exist(filePath,'file')
        error('PaperTables:MissingInputFile','Required file not found: %s',filePath);
    end
end
function validateColumns(T,names,label)
    missing = names(~ismember(names,T.Properties.VariableNames));
    if ~isempty(missing)
        error('PaperTables:MissingColumns', ...
            '%s is missing required columns: %s',label,strjoin(missing,', '));
    end
end
function T = selectOfficial(T)
    required = {'PlantCode_ICRA','ControllerID_ICRA', ...
        'TrajectoryCode_ICRA','DisturbanceID_ICRA'};
    validateColumns(T,required,'Input table');
    level = string(T.PlantCode_ICRA);
    ctrl  = string(T.ControllerID_ICRA);
    traj  = string(T.TrajectoryCode_ICRA);
    cond  = string(T.DisturbanceID_ICRA);
    official = ...
        (level=="L1" & ctrl=="C1") | ...
        (level=="L2" & ctrl=="C1") | ...
        (level=="L3" & ctrl=="C2");
    keep = official & ...
        (traj=="T1" | traj=="T2") & ...
        (cond=="NOM" | cond=="DIST");
    T = T(keep,:);
end
function validateOfficialTable(T,label)
    if height(T) ~= 12
        error('PaperTables:UnexpectedOfficialSubset', ...
            '%s should contain exactly 12 official rows; found %d.', ...
            label,height(T));
    end
    levels = ["L1","L2","L3"];
    trajs = ["T1","T2"];
    conds = ["NOM","DIST"];
    for it = 1:numel(trajs)
        for ic = 1:numel(conds)
            for il = 1:numel(levels)
                idx = string(T.PlantCode_ICRA)==levels(il) & ...
                      string(T.TrajectoryCode_ICRA)==trajs(it) & ...
                      string(T.DisturbanceID_ICRA)==conds(ic);
                if nnz(idx) ~= 1
                    error('PaperTables:DuplicateOrMissingRun', ...
                        '%s: expected one row for %s %s %s, found %d.', ...
                        label,levels(il),trajs(it),conds(ic),nnz(idx));
                end
            end
        end
    end
end
function r = getRow(T,level,traj,cond)
    idx = string(T.PlantCode_ICRA)==string(level) & ...
          string(T.TrajectoryCode_ICRA)==string(traj) & ...
          string(T.DisturbanceID_ICRA)==string(cond);
    if nnz(idx) ~= 1
        error('PaperTables:RunLookupFailed', ...
            'Expected one row for %s %s %s; found %d.', ...
            string(level),string(traj),string(cond),nnz(idx));
    end
    r = T(idx,:);
end
function x = requireFiniteScalar(x,label)
    x = double(x);
    if ~isscalar(x) || ~isfinite(x)
        error('PaperTables:InvalidMetric','%s is not a finite scalar.',label);
    end
end
function x = requireNonnegativeScalar(x,label)
    x = requireFiniteScalar(x,label);
    if x < 0
        error('PaperTables:InvalidMetric','%s must be >= 0; found %.9g.',label,x);
    end
end
function x = requirePositiveScalar(x,label)
    x = requireFiniteScalar(x,label);
    if x <= 0
        error('PaperTables:InvalidMetric','%s must be > 0; found %.9g.',label,x);
    end
end
function assertCompleteNumericColumns(T,names,label)
    for i = 1:numel(names)
        name = names{i};
        x = T.(name);
        if ~isnumeric(x)
            error('PaperTables:UnexpectedColumnType', ...
                '%s.%s must be numeric.',label,name);
        end
        bad = ~isfinite(x);
        if any(bad)
            rows = find(bad);
            details = strings(0,1);
            for j = 1:numel(rows)
                rr = rows(j);
                details(end+1) = sprintf('row %d (%s, %s)', ...
                    rr,string(T.Level(rr)),string(T.Traj_Cond(rr))); %#ok<AGROW>
            end
            error('PaperTables:IncompletePaperTable', ...
                '%s has missing/invalid values in %s: %s', ...
                label,name,strjoin(details,', '));
        end
    end
end
function ctrl = officialController(level)
    switch string(level)
        case {"L1","L2"}
            ctrl = 'C1';
        case "L3"
            ctrl = 'C2';
        otherwise
            error('PaperTables:UnknownLevel','Unknown level: %s',string(level));
    end
end
function obs = getSimulationStateMetrics(resultsRoot,level,traj,cond,tStart,tEnd)
    ctrl = officialController(level);
    runID = sprintf('%s_%s_%s_%s',ctrl,char(traj),char(level),char(cond));
    canonicalFile = fullfile(resultsRoot,'runs',runID,'processed','canonical_signals.mat');
    if ~exist(canonicalFile,'file')
        error('PaperTables:MissingCanonicalFile', ...
            'Missing canonical file:\n%s',canonicalFile);
    end
    S = load(canonicalFile,'CANONICAL');
    if ~isfield(S,'CANONICAL')
        error('PaperTables:MissingCanonicalStruct', ...
            'CANONICAL not found in %s.',canonicalFile);
    end
    [E,attSource] = getUsableCanonicalWindow( ...
        S.CANONICAL,'Euler',{'Selected','Estimated','True'}, ...
        tStart,tEnd,3,false,canonicalFile);
    [W,rateSource] = getUsableCanonicalWindow( ...
        S.CANONICAL,'AngularRate',{'Selected','Estimated','True'}, ...
        tStart,tEnd,3,true,canonicalFile);
    obs = struct();
    obs.RollRMS_deg = requireNonnegativeScalar(rmsFinite(rad2deg(E(:,1))), ...
        sprintf('%s %s %s RollRMS',level,traj,cond));
    obs.PitchRMS_deg = requireNonnegativeScalar(rmsFinite(rad2deg(E(:,2))), ...
        sprintf('%s %s %s PitchRMS',level,traj,cond));
    obs.YawExcursionRMS_deg = requireNonnegativeScalar(yawExcursionRMS(E(:,3)), ...
        sprintf('%s %s %s YawExcursionRMS',level,traj,cond));
    obs.pRMS_rad_s = requireNonnegativeScalar(rmsFinite(W(:,1)), ...
        sprintf('%s %s %s pRMS',level,traj,cond));
    obs.qRMS_rad_s = requireNonnegativeScalar(rmsFinite(W(:,2)), ...
        sprintf('%s %s %s qRMS',level,traj,cond));
    obs.rRMS_rad_s = requireNonnegativeScalar(rmsFinite(W(:,3)), ...
        sprintf('%s %s %s rRMS',level,traj,cond));
    obs.AttitudeSource = attSource;
    obs.RateSource = rateSource;
end
function [D,source] = getUsableCanonicalWindow(CANONICAL,signalName,groups, ...
        tStart,tEnd,minCols,requireInformative,filePath)
    D = [];
    source = "NOT_AVAILABLE";
    failureNotes = strings(0,1);
    for i = 1:numel(groups)
        g = groups{i};
        if ~isfield(CANONICAL,g) || ~isstruct(CANONICAL.(g)) || ...
                ~isfield(CANONICAL.(g),signalName)
            failureNotes(end+1) = string(g) + ": missing"; %#ok<AGROW>
            continue
        end
        sig = CANONICAL.(g).(signalName);
        [candidate,ok,reason] = trySignalWindowData(sig,tStart,tEnd,minCols);
        if ~ok
            failureNotes(end+1) = string(g) + ": " + reason; %#ok<AGROW>
            continue
        end
        if requireInformative && ~isInformativeMatrix(candidate)
            failureNotes(end+1) = string(g) + ": non-informative"; %#ok<AGROW>
            continue
        end
        D = candidate;
        source = string(g);
        return
    end
    error('PaperTables:CanonicalSignalUnavailable', ...
        ['No usable %s signal was found in %s for window [%.6f, %.6f] s.\n' ...
         'Tried: %s'], ...
        signalName,filePath,tStart,tEnd,strjoin(failureNotes,' | '));
end
function [D,ok,reason] = trySignalWindowData(sig,tStart,tEnd,minCols)
    D = [];
    ok = false;
    reason = "invalid signal";
    if ~isstruct(sig) || ~isfield(sig,'Time_s') || ~isfield(sig,'Data')
        reason = "missing Time_s/Data";
        return
    end
    t = double(sig.Time_s(:));
    X = double(sig.Data);
    if size(X,1) ~= numel(t) && size(X,2) == numel(t)
        X = X.';
    end
    if size(X,1) ~= numel(t)
        reason = "Time/Data length mismatch";
        return
    end
    if size(X,2) < minCols
        reason = sprintf('only %d columns',size(X,2));
        return
    end
    mask = isfinite(t) & t >= tStart & t <= tEnd;
    X = X(mask,1:minCols);
    X = X(all(isfinite(X),2),:);
    if size(X,1) < 2
        reason = "fewer than 2 finite samples";
        return
    end
    D = X;
    ok = true;
    reason = "OK";
end
function tf = isInformativeMatrix(X)
    X = double(X);
    X = X(isfinite(X));
    tf = ~isempty(X) && max(abs(X)) > 1e-8;
end
function obs = getRealObservableMetrics(realFile,traj)
    vars = { ...
        'REAL_TRAJECTORY_RESULTS', ...
        'REAL_TRAJECTORY_DATA', ...
        'REAL_ANGULAR_RATE_RESULTS', ...
        'REAL_ANGULAR_RATE_DATA', ...
        'REAL_DATA'};
    S = loadExistingVariables(realFile,vars);
    obs = struct( ...
        'PathLength_m',NaN, ...
        'RollRMS_deg',NaN, ...
        'PitchRMS_deg',NaN, ...
        'YawExcursionRMS_deg',NaN, ...
        'pRMS_rad_s',NaN, ...
        'qRMS_rad_s',NaN, ...
        'rRMS_rad_s',NaN, ...
        'TrajectoryDuration_s',NaN, ...
        'RateSource',"NOT_AVAILABLE", ...
        'ComparisonStart_s',NaN, ...
        'ComparisonEnd_s',NaN, ...
        'TrimLeading_s',0.0);
    tStart = getStructScalar(S,'REAL_TRAJECTORY_RESULTS','StartTime_s',NaN);
    tEnd = getStructScalar(S,'REAL_TRAJECTORY_RESULTS','EndTime_s',NaN);
    if (~isfinite(tStart) || ~isfinite(tEnd) || tEnd <= tStart) && ...
            isfield(S,'REAL_TRAJECTORY_DATA') && istable(S.REAL_TRAJECTORY_DATA)
        T = S.REAL_TRAJECTORY_DATA;
        if ismember('TLOG_Time_s',T.Properties.VariableNames)
            tt = double(T.TLOG_Time_s);
            tt = tt(isfinite(tt));
            if numel(tt) >= 2
                tStart = tt(1);
                tEnd = tt(end);
            end
        end
    end
    if ~isfinite(tStart) || ~isfinite(tEnd) || tEnd <= tStart
        error('PaperTables:RealWindowUnavailable', ...
            'Could not determine a valid REAL trajectory window in %s.',realFile);
    end
    trimLeading_s = 0.0;
    comparisonStart_s = tStart;
    comparisonEnd_s = tEnd;
    obs.PathLength_m = NaN;
    obs.TrajectoryDuration_s = comparisonEnd_s - comparisonStart_s;
    if isfield(S,'REAL_TRAJECTORY_DATA') && istable(S.REAL_TRAJECTORY_DATA)
        T = S.REAL_TRAJECTORY_DATA;
        if all(ismember({'North_m','East_m','Down_m'},T.Properties.VariableNames))
            P = [double(T.North_m),double(T.East_m),double(T.Down_m)];
            if ismember('TLOG_Time_s',T.Properties.VariableNames)
                tt = double(T.TLOG_Time_s);
                keep = isfinite(tt) & ...
                    tt >= comparisonStart_s & tt <= comparisonEnd_s;
                P = P(keep,:);
            end
            P = P(all(isfinite(P),2),:);
            if size(P,1) >= 2
                obs.PathLength_m = pathLength3D(P);
            end
        end
    end
    if ~isfinite(obs.PathLength_m)
        obs.PathLength_m = getStructScalar( ...
            S,'REAL_TRAJECTORY_RESULTS','PathLength_m',NaN);
    end
    obs.ComparisonStart_s = comparisonStart_s;
    obs.ComparisonEnd_s = comparisonEnd_s;
    obs.TrimLeading_s = trimLeading_s;
    obs.PathLength_m = requirePositiveScalar(obs.PathLength_m, ...
        ['REAL comparison PathLength_m in ' realFile]);
    obs.TrajectoryDuration_s = requirePositiveScalar(obs.TrajectoryDuration_s, ...
        ['REAL comparison TrajectoryDuration_s in ' realFile]);
    [roll,pitch,yaw,ok] = getRealAttitudeSamples( ...
        S,comparisonStart_s,comparisonEnd_s);
    if ~ok
        error('PaperTables:RealAttitudeUnavailable', ...
            'No valid REAL roll/pitch/yaw samples in trajectory window: %s',realFile);
    end
    obs.RollRMS_deg = requireNonnegativeScalar(rmsFinite(rad2deg(roll)), ...
        ['REAL RollRMS in ' realFile]);
    obs.PitchRMS_deg = requireNonnegativeScalar(rmsFinite(rad2deg(pitch)), ...
        ['REAL PitchRMS in ' realFile]);
    obs.YawExcursionRMS_deg = requireNonnegativeScalar(yawExcursionRMS(yaw), ...
        ['REAL YawExcursionRMS in ' realFile]);
    [p,q,r,source,ok] = getRealBodyRateSamples(S,comparisonStart_s,comparisonEnd_s);
    if ~ok
        error('PaperTables:RealRatesUnavailable', ...
            ['No informative REAL p/q/r stream was found in the trajectory ' ...
             'window. Refusing to write blank/false-zero paper metrics.\nFile: %s'], ...
            realFile);
    end
    obs.pRMS_rad_s = requireNonnegativeScalar(rmsFinite(p), ...
        ['REAL pRMS in ' realFile]);
    obs.qRMS_rad_s = requireNonnegativeScalar(rmsFinite(q), ...
        ['REAL qRMS in ' realFile]);
    obs.rRMS_rad_s = requireNonnegativeScalar(rmsFinite(r), ...
        ['REAL rRMS in ' realFile]);
    obs.RateSource = source;
end
function S = loadExistingVariables(matFile,varNames)
    info = whos('-file',matFile);
    available = string({info.name});
    wanted = string(varNames);
    loadNames = cellstr(wanted(ismember(wanted,available)));
    if isempty(loadNames)
        error('PaperTables:EmptyRealMat', ...
            'No expected REAL variables were found in %s.',matFile);
    end
    S = load(matFile,loadNames{:});
end
function [roll,pitch,yaw,ok] = getRealAttitudeSamples(S,tStart,tEnd)
    roll = []; pitch = []; yaw = []; ok = false;
    if ~isfield(S,'REAL_DATA') || ~isstruct(S.REAL_DATA) || ...
            ~isfield(S.REAL_DATA,'State') || ~isstruct(S.REAL_DATA.State) || ...
            ~isfield(S.REAL_DATA.State,'Attitude') || ...
            ~istable(S.REAL_DATA.State.Attitude)
        return
    end
    T = S.REAL_DATA.State.Attitude;
    required = {'Time_s','Roll_rad','Pitch_rad','Yaw_rad'};
    if ~all(ismember(required,T.Properties.VariableNames))
        return
    end
    mask = timeMask(double(T.Time_s),tStart,tEnd);
    roll = double(T.Roll_rad(mask));
    pitch = double(T.Pitch_rad(mask));
    yaw = double(T.Yaw_rad(mask));
    valid = isfinite(roll) & isfinite(pitch) & isfinite(yaw);
    roll = roll(valid);
    pitch = pitch(valid);
    yaw = yaw(valid);
    ok = numel(roll) >= 2;
end
function [p,q,r,source,ok] = getRealBodyRateSamples(S,tStart,tEnd)
    p = []; q = []; r = [];
    source = "NOT_AVAILABLE";
    ok = false;
    if isfield(S,'REAL_ANGULAR_RATE_DATA') && istable(S.REAL_ANGULAR_RATE_DATA)
        T = S.REAL_ANGULAR_RATE_DATA;
        if all(ismember({'P_rad_s','Q_rad_s','R_rad_s'},T.Properties.VariableNames))
            if ismember('TLOG_Time_s',T.Properties.VariableNames)
                mask = timeMask(double(T.TLOG_Time_s),tStart,tEnd);
            else
                mask = true(height(T),1);
            end
            [p0,q0,r0,ok0] = cleanRateSamples( ...
                double(T.P_rad_s(mask)),double(T.Q_rad_s(mask)),double(T.R_rad_s(mask)));
            if ok0 && isInformativeRateStream(p0,q0,r0)
                p=p0; q=q0; r=r0; source="REAL_ANGULAR_RATE_DATA"; ok=true; return
            end
        end
    end
    if isfield(S,'REAL_DATA') && isstruct(S.REAL_DATA) && ...
            isfield(S.REAL_DATA,'State') && isstruct(S.REAL_DATA.State) && ...
            isfield(S.REAL_DATA.State,'AngularRate') && ...
            istable(S.REAL_DATA.State.AngularRate)
        T = S.REAL_DATA.State.AngularRate;
        if all(ismember({'Time_s','P_rad_s','Q_rad_s','R_rad_s'},T.Properties.VariableNames))
            mask = timeMask(double(T.Time_s),tStart,tEnd);
            [p0,q0,r0,ok0] = cleanRateSamples( ...
                double(T.P_rad_s(mask)),double(T.Q_rad_s(mask)),double(T.R_rad_s(mask)));
            if ok0 && isInformativeRateStream(p0,q0,r0)
                p=p0; q=q0; r=r0; source="STATE_ANGULAR_RATE"; ok=true; return
            end
        end
    end
    informative = getStructLogical(S,'REAL_ANGULAR_RATE_RESULTS','TelemetryInformative',false);
    if informative
        pp = getStructScalar(S,'REAL_ANGULAR_RATE_RESULTS','pRMS_rad_s',NaN);
        qq = getStructScalar(S,'REAL_ANGULAR_RATE_RESULTS','qRMS_rad_s',NaN);
        rr = getStructScalar(S,'REAL_ANGULAR_RATE_RESULTS','rRMS_rad_s',NaN);
        if all(isfinite([pp qq rr])) && max(abs([pp qq rr])) > 1e-8
            p=pp; q=qq; r=rr; source="ANGULAR_RATE_RESULTS_RMS"; ok=true; return
        end
    end
    [p,q,r,source,ok] = getRealIMUGyroSamples(S,tStart,tEnd);
end
function [p,q,r,source,ok] = getRealIMUGyroSamples(S,tStart,tEnd)
    p = []; q = []; r = [];
    source = "NOT_AVAILABLE";
    ok = false;
    if ~isfield(S,'REAL_DATA') || ~isstruct(S.REAL_DATA) || ...
            ~isfield(S.REAL_DATA,'Sensor') || ~isstruct(S.REAL_DATA.Sensor)
        return
    end
    candidates = {'IMU1','IMU2','IMU3'};
    for i = 1:numel(candidates)
        name = candidates{i};
        if ~isfield(S.REAL_DATA.Sensor,name) || ~istable(S.REAL_DATA.Sensor.(name))
            continue
        end
        T = S.REAL_DATA.Sensor.(name);
        required = {'Time_s','GyroX_rad_s','GyroY_rad_s','GyroZ_rad_s'};
        if ~all(ismember(required,T.Properties.VariableNames))
            continue
        end
        mask = timeMask(double(T.Time_s),tStart,tEnd);
        [p0,q0,r0,ok0] = cleanRateSamples( ...
            double(T.GyroX_rad_s(mask)), ...
            double(T.GyroY_rad_s(mask)), ...
            double(T.GyroZ_rad_s(mask)));
        if ok0 && isInformativeRateStream(p0,q0,r0)
            p=p0; q=q0; r=r0;
            source = string(name) + "_GYRO";
            ok=true;
            return
        end
    end
end
function [p,q,r,ok] = cleanRateSamples(p,q,r)
    p = double(p(:));
    q = double(q(:));
    r = double(r(:));
    n = min([numel(p),numel(q),numel(r)]);
    if n < 2
        p=[]; q=[]; r=[]; ok=false; return
    end
    p=p(1:n); q=q(1:n); r=r(1:n);
    valid = isfinite(p) & isfinite(q) & isfinite(r);
    p=p(valid); q=q(valid); r=r(valid);
    ok = numel(p) >= 2;
end
function tf = isInformativeRateStream(p,q,r)
    x = [double(p(:));double(q(:));double(r(:))];
    x = x(isfinite(x));
    tf = ~isempty(x) && max(abs(x)) > 1e-8;
end
function mask = timeMask(t,tStart,tEnd)
    t = double(t(:));
    mask = isfinite(t) & t >= tStart & t <= tEnd;
end
function value = getStructScalar(S,varName,fieldName,defaultValue)
    value = defaultValue;
    if ~isstruct(S) || ~isfield(S,varName)
        return
    end
    X = S.(varName);
    if ~isstruct(X) || ~isfield(X,fieldName)
        return
    end
    candidate = X.(fieldName);
    if isnumeric(candidate) && isscalar(candidate) && isfinite(candidate)
        value = double(candidate);
    elseif islogical(candidate) && isscalar(candidate)
        value = double(candidate);
    end
end
function value = getStructLogical(S,varName,fieldName,defaultValue)
    value = logical(defaultValue);
    if ~isstruct(S) || ~isfield(S,varName)
        return
    end
    X = S.(varName);
    if ~isstruct(X) || ~isfield(X,fieldName)
        return
    end
    candidate = X.(fieldName);
    if islogical(candidate) && isscalar(candidate)
        value = candidate;
    elseif isnumeric(candidate) && isscalar(candidate) && isfinite(candidate)
        value = logical(candidate);
    end
end
function value = rmsFinite(x)
    x = double(x(:));
    x = x(isfinite(x));
    if isempty(x)
        value = NaN;
    else
        value = sqrt(mean(x.^2));
    end
end
function value = yawExcursionRMS(yaw_rad)
    yaw_rad = double(yaw_rad(:));
    yaw_rad = yaw_rad(isfinite(yaw_rad));
    if isempty(yaw_rad)
        value = NaN;
        return
    end
    y = unwrap(yaw_rad);
    y = y - y(1);
    value = rmsFinite(rad2deg(y));
end
function L = pathLength3D(P)
    P = double(P);
    P = P(all(isfinite(P),2),:);
    if size(P,1) < 2 || size(P,2) < 3
        L = NaN;
        return
    end
    d = diff(P(:,1:3),1,1);
    L = sum(sqrt(sum(d.^2,2)),'omitnan');
end
function actualOutput = writeWorkbookRobust(Tshared,Tsim,requestedOutput)
    requestedOutput = char(requestedOutput);
    [outDir,baseName,ext] = fileparts(requestedOutput);
    if isempty(ext)
        ext = '.xlsx';
        requestedOutput = fullfile(outDir,[baseName ext]);
    end
    if ~exist(outDir,'dir')
        mkdir(outDir);
    end
    tmpExcel = [tempname '.xlsx'];
    cleanupObj = onCleanup(@()cleanupTempWorkbook(tmpExcel)); %#ok<NASGU>
    try
        writetable(Tshared,tmpExcel, ...
            'Sheet','SIM_REAL_Shared', ...
            'WriteMode','overwritesheet');
        writetable(Tsim,tmpExcel, ...
            'Sheet','SIM_Paper_Metrics', ...
            'WriteMode','overwritesheet');
    catch ME
        error('PaperTables:TemporaryExcelWriteFailed', ...
            ['MATLAB could not create the temporary workbook.\n' ...
             'Original error: %s'],ME.message);
    end
    [ok,msg] = tryInstallWorkbook(tmpExcel,requestedOutput);
    if ok
        actualOutput = requestedOutput;
        return
    end
    stamp = datestr(now,'yyyymmdd_HHMMSS');
    fallback = fullfile(outDir,sprintf('%s_%s%s',baseName,stamp,ext));
    [ok2,msg2] = tryInstallWorkbook(tmpExcel,fallback);
    if ~ok2
        error('PaperTables:ExcelInstallFailed', ...
            ['Workbook generation succeeded but could not be copied to the ' ...
             'results folder.\nCanonical target error: %s\nFallback error: %s'], ...
            msg,msg2);
    end
    actualOutput = fallback;
    warning('PaperTables:WorkbookLocked', ...
        ['Canonical workbook appears open/locked. A complete timestamped ' ...
         'workbook was generated instead:\n%s'],actualOutput);
end
function [ok,msg] = tryInstallWorkbook(tmpExcel,target)
    ok=false;
    msg='';
    if exist(target,'file')
        try
            delete(target);
        catch ME
            msg=ME.message;
            return
        end
    end
    try
        [status,moveMsg] = movefile(tmpExcel,target,'f');
        if status
            ok=true;
        else
            msg=moveMsg;
        end
    catch ME
        msg=ME.message;
    end
end
function cleanupTempWorkbook(tmpExcel)
    if exist(tmpExcel,'file')
        try
            delete(tmpExcel);
        catch
        end
    end
end
