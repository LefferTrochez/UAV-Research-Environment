function run_icra_timing_statistics
clc
close all
N_REPEATS = 10;
RANDOM_SEED = 2027;
ALPHA = 0.05;
PAUSE_BETWEEN_RUNS_S = 0.50;
PAUSE_BETWEEN_LEVELS_S = 2.00;
CLEAR_SDI_AFTER_EACH_RUN = true;
SCRIPT_ROOT = fileparts(mfilename('fullpath'));
EXPERIMENT_ROOT = fullfile( ...
    SCRIPT_ROOT, ...
    'ICRA2027_Final_Experiments');
if ~isfolder(EXPERIMENT_ROOT)
    error('TimingStats:MissingExperimentFolder', ...
        'Experiment folder not found:\n%s',EXPERIMENT_ROOT);
end
addpath(EXPERIMENT_ROOT);
outputCSV = fullfile( ...
    SCRIPT_ROOT, ...
    'ICRA2027_Computational_Cost_Statistics.csv');
requiredFunctions = { ...
    'ttest2', ...
    'tinv', ...
    'lillietest', ...
    'ranksum', ...
    'anova1'};
missingFunctions = strings(0,1);
for i = 1:numel(requiredFunctions)
    if isempty(which(requiredFunctions{i}))
        missingFunctions(end+1,1) = string(requiredFunctions{i}); %#ok<AGROW>
    end
end
if ~isempty(missingFunctions)
    error('TimingStats:MissingStatisticsToolbox', ...
        ['Statistics and Machine Learning Toolbox is required.\n' ...
         'Missing functions: %s'], ...
        strjoin(missingFunctions,', '));
end
CFG = ICRA_experiment_config;
P = CFG.RunPlan;
controller = string(P.ControllerID);
plant = string(P.PlantCode);
traj = string(P.TrajectoryCode);
cond = string(P.DisturbanceID);
official = ...
    ((plant=="L1" | plant=="L2") & controller=="C1") | ...
    (plant=="L3" & controller=="C2");
keep = official & ...
       (traj=="T1" | traj=="T2") & ...
       (cond=="NOM" | cond=="DIST");
OFFICIAL = P(keep,:);
if height(OFFICIAL) ~= 12
    error('TimingStats:OfficialSubset', ...
        'Expected exactly 12 official configurations; found %d.', ...
        height(OFFICIAL));
end
OFFICIAL = sortOfficialConfigurations(OFFICIAL);
RAW = buildMeasurementPlan( ...
    OFFICIAL, ...
    N_REPEATS, ...
    RANDOM_SEED);
if isfile(outputCSV)
    fprintf('\nExisting timing CSV detected.\n');
    fprintf('Attempting checkpoint recovery...\n');
    previous = readtable( ...
        outputCSV, ...
        'TextType','string', ...
        'VariableNamingRule','preserve');
    RAW = mergeCheckpoint(RAW,previous,N_REPEATS);
    nRecovered = sum(RAW.Completed);
    fprintf('Recovered completed measurements: %d / %d\n', ...
        nRecovered,height(RAW));
else
    fprintf('\nNo previous timing checkpoint found.\n');
    fprintf('Starting a new timing campaign.\n');
end
RAW = clearDerivedStatistics(RAW);
interrupted = ~RAW.Completed & RAW.Status=="RUNNING";
RAW.Status(interrupted) = "INTERRUPTED";
atomicWriteTable(RAW,outputCSV);
fprintf('\n');
fprintf('==============================================================\n');
fprintf(' ICRA 2027 ROBUST COMPUTATIONAL COST EXPERIMENT\n');
fprintf('==============================================================\n');
fprintf('Official configurations:       12\n');
fprintf('Measured repetitions/config:   %d\n',N_REPEATS);
fprintf('Total measured simulations:    %d\n',height(RAW));
fprintf('Already completed:             %d\n',sum(RAW.Completed));
fprintf('Remaining:                     %d\n',sum(~RAW.Completed));
fprintf('Warm-up:                       1 per unfinished fidelity block\n');
fprintf('Execution organization:        L1 block -> L2 block -> L3 block\n');
fprintf('Scenario order within repeat:  RANDOMIZED\n');
fprintf('Checkpoint after every run:    YES\n');
fprintf('Resume after interruption:     YES\n');
fprintf('Statistics toolbox:            YES\n');
fprintf('Primary inferential test:      Welch t-test on log(time)\n');
fprintf('Variance diagnostic:           Brown-Forsythe\n');
fprintf('Nonparametric sensitivity:     Rank-sum\n');
fprintf('Multiple-test correction:      Holm\n');
fprintf('Alpha:                         %.3f\n',ALPHA);
fprintf('Output CSV:\n%s\n',outputCSV);
fprintf('==============================================================\n\n');
if all(RAW.Completed)
    fprintf('All raw timing measurements are already complete.\n');
    fprintf('Recomputing final statistics only.\n\n');
else
    fprintf(['IMPORTANT: keep the output CSV closed in Excel while this ' ...
             'campaign is running.\n\n']);
end
levels = ["L1","L2","L3"];
for levelIndex = 1:numel(levels)
    currentLevel = levels(levelIndex);
    pendingLevel = ...
        RAW.Level==currentLevel & ...
        ~RAW.Completed;
    if ~any(pendingLevel)
        fprintf('Level %s: all measurements already complete. Skipping.\n', ...
            currentLevel);
        continue
    end
    fprintf('\n');
    fprintf('==============================================================\n');
    fprintf(' STARTING FIDELITY BLOCK %s\n',currentLevel);
    fprintf(' Pending measurements: %d\n',sum(pendingLevel));
    fprintf('==============================================================\n');
    safeSimulinkCleanup(CLEAR_SDI_AFTER_EACH_RUN);
    pause(PAUSE_BETWEEN_LEVELS_S);
    warmupRow = OFFICIAL( ...
        string(OFFICIAL.PlantCode)==currentLevel & ...
        string(OFFICIAL.TrajectoryCode)=="T1" & ...
        string(OFFICIAL.DisturbanceID)=="NOM",:);
    if height(warmupRow) ~= 1
        error('TimingStats:WarmupLookup', ...
            'Could not uniquely identify warm-up configuration for %s.', ...
            currentLevel);
    end
    fprintf('\nWarm-up %s (excluded from statistics)...\n',currentLevel);
    try
        WARMUP = run_icra_experiment(CFG,warmupRow);
        if ~isfield(WARMUP,'Status') || ...
                ~isfield(WARMUP.Status,'SimulationCompleted') || ...
                ~logical(WARMUP.Status.SimulationCompleted)
            error('TimingStats:WarmupFailed', ...
                'Warm-up did not complete successfully for %s.', ...
                currentLevel);
        end
        fprintf('Warm-up %s complete.\n',currentLevel);
        clear WARMUP
        if CLEAR_SDI_AFTER_EACH_RUN
            safeClearSDI;
        end
        drawnow
        pause(PAUSE_BETWEEN_RUNS_S);
    catch ME
        atomicWriteTable(RAW,outputCSV);
        safeSimulinkCleanup(CLEAR_SDI_AFTER_EACH_RUN);
        fprintf(2,'\nWarm-up failed for %s.\n',currentLevel);
        fprintf(2,'Checkpoint preserved at:\n%s\n\n',outputCSV);
        rethrow(ME)
    end
    for repetitionIndex = 1:N_REPEATS
        repetitionRows = find( ...
            RAW.Level==currentLevel & ...
            RAW.Repeat==repetitionIndex);
        if isempty(repetitionRows)
            error('TimingStats:PlanError', ...
                'No rows found for %s repetition %d.', ...
                currentLevel,repetitionIndex);
        end
        [~,localOrder] = sort(RAW.RandomizationRank(repetitionRows));
        repetitionRows = repetitionRows(localOrder);
        fprintf('\n%s | repetition %d / %d\n', ...
            currentLevel,repetitionIndex,N_REPEATS);
        for localIndex = 1:numel(repetitionRows)
            rawIndex = repetitionRows(localIndex);
            if RAW.Completed(rawIndex)
                fprintf('  SKIP %s | already complete\n', ...
                    RAW.UniqueKey(rawIndex));
                continue
            end
            runRow = OFFICIAL( ...
                string(OFFICIAL.PlantCode)==RAW.Level(rawIndex) & ...
                string(OFFICIAL.TrajectoryCode)==RAW.Trajectory(rawIndex) & ...
                string(OFFICIAL.DisturbanceID)==RAW.Condition(rawIndex),:);
            if height(runRow) ~= 1
                error('TimingStats:RunLookup', ...
                    'Could not uniquely identify official run for %s.', ...
                    RAW.UniqueKey(rawIndex));
            end
            RAW.AttemptCount(rawIndex) = ...
                RAW.AttemptCount(rawIndex) + 1;
            RAW.Status(rawIndex) = "RUNNING";
            RAW.StartTimestamp(rawIndex) = timestampNow();
            RAW.EndTimestamp(rawIndex) = "";
            RAW.ErrorIdentifier(rawIndex) = "";
            RAW.ErrorMessage(rawIndex) = "";
            atomicWriteTable(RAW,outputCSV);
            fprintf('  RUN  %s | attempt %d\n', ...
                RAW.UniqueKey(rawIndex), ...
                RAW.AttemptCount(rawIndex));
            try
                RUN = run_icra_experiment(CFG,runRow);
                validateRunOutput(RUN,RAW.UniqueKey(rawIndex));
                executionTime = ...
                    double(RUN.Timing.ExecutionElapsedWallTime_s);
                simulatedDuration = ...
                    double(RUN.Timing.SimulatedDuration_s);
                realTimeFactor = ...
                    double(RUN.Timing.RealTimeFactor_RTF);
                if ~isfinite(executionTime) || executionTime <= 0
                    error('TimingStats:InvalidExecutionTime', ...
                        'Invalid execution time for %s.', ...
                        RAW.UniqueKey(rawIndex));
                end
                if ~isfinite(simulatedDuration) || simulatedDuration <= 0
                    error('TimingStats:InvalidSimulatedDuration', ...
                        'Invalid simulated duration for %s.', ...
                        RAW.UniqueKey(rawIndex));
                end
                if ~isfinite(realTimeFactor) || realTimeFactor <= 0
                    error('TimingStats:InvalidRTF', ...
                        'Invalid RTF for %s.', ...
                        RAW.UniqueKey(rawIndex));
                end
                RAW.ExecutionTime_s(rawIndex) = executionTime;
                RAW.SimulatedDuration_s(rawIndex) = simulatedDuration;
                RAW.RTF(rawIndex) = realTimeFactor;
                RAW.Completed(rawIndex) = true;
                RAW.Status(rawIndex) = "COMPLETE";
                RAW.EndTimestamp(rawIndex) = timestampNow();
                RAW.ErrorIdentifier(rawIndex) = "";
                RAW.ErrorMessage(rawIndex) = "";
                atomicWriteTable(RAW,outputCSV);
                fprintf(['       execution = %.3f s | RTF = %.4f | ' ...
                         'checkpoint saved\n'], ...
                    executionTime,realTimeFactor);
                clear RUN
                if CLEAR_SDI_AFTER_EACH_RUN
                    safeClearSDI;
                end
                drawnow
                pause(PAUSE_BETWEEN_RUNS_S);
            catch ME
                RAW.Completed(rawIndex) = false;
                RAW.Status(rawIndex) = "FAILED";
                RAW.EndTimestamp(rawIndex) = timestampNow();
                RAW.ErrorIdentifier(rawIndex) = string(ME.identifier);
                RAW.ErrorMessage(rawIndex) = sanitizeErrorMessage(ME.message);
                atomicWriteTable(RAW,outputCSV);
                safeSimulinkCleanup(CLEAR_SDI_AFTER_EACH_RUN);
                fprintf(2,'\nMEASURED RUN FAILED\n');
                fprintf(2,'Key: %s\n',RAW.UniqueKey(rawIndex));
                fprintf(2,'Checkpoint preserved at:\n%s\n\n',outputCSV);
                rethrow(ME)
            end
        end
    end
    fprintf('\nFidelity block %s complete.\n',currentLevel);
    safeSimulinkCleanup(CLEAR_SDI_AFTER_EACH_RUN);
    pause(PAUSE_BETWEEN_LEVELS_S);
end
if ~all(RAW.Completed)
    atomicWriteTable(RAW,outputCSV);
    error('TimingStats:IncompleteCampaign', ...
        ['Timing campaign is incomplete: %d / %d measurements remain.\n' ...
         'Run this function again to resume from the CSV checkpoint.'], ...
        sum(~RAW.Completed),height(RAW));
end
fprintf('\n');
fprintf('All %d raw measurements are complete.\n',height(RAW));
fprintf('Computing final statistical analysis...\n');
RAW = computeFinalStatistics(RAW,ALPHA);
atomicWriteTable(RAW,outputCSV);
summaryRows = RAW.SummaryRepresentative;
fprintf('\n');
fprintf('==============================================================\n');
fprintf(' COMPUTATIONAL COST STATISTICS COMPLETE\n');
fprintf('==============================================================\n');
fprintf('Measured repetitions/configuration: %d\n',N_REPEATS);
fprintf('Total measured simulations:         %d\n',height(RAW));
fprintf('Completed measurements:             %d\n',sum(RAW.Completed));
fprintf('Final CSV:\n%s\n',outputCSV);
fprintf('==============================================================\n\n');
disp(RAW(summaryRows,{ ...
    'Level', ...
    'Traj_Cond', ...
    'ExecutionMean_s', ...
    'ExecutionStd_s', ...
    'ExecutionCV_pct', ...
    'RTFMean', ...
    'RTFStd', ...
    'NormalityP_Log', ...
    'BrownForsytheP_Log', ...
    'Comparison_vs_L3', ...
    'WelchT_P_Log_Holm', ...
    'RankSumP_Holm', ...
    'L3SlowdownFactor'}))
fprintf('\nInterpretation guide:\n');
fprintf(['- Paper timing: ExecutionMean_s +/- ExecutionStd_s.\n' ...
         '- NormalityP_Log < %.3f: evidence against log-normality.\n' ...
         '- BrownForsytheP_Log < %.3f: evidence of unequal variances.\n' ...
         '- WelchT_P_Log_Holm < %.3f: significant cost difference vs L3.\n' ...
         '- RankSumP_Holm is a nonparametric sensitivity check.\n' ...
         '- L3SlowdownFactor > 1 means L3 is slower than that level.\n'], ...
    ALPHA,ALPHA,ALPHA);
fprintf('\nDone.\n');
end
function OFFICIAL = sortOfficialConfigurations(OFFICIAL)
trajKey = ones(height(OFFICIAL),1);
trajKey(string(OFFICIAL.TrajectoryCode)=="T2") = 2;
condKey = ones(height(OFFICIAL),1);
condKey(string(OFFICIAL.DisturbanceID)=="DIST") = 2;
levelKey = zeros(height(OFFICIAL),1);
levelKey(string(OFFICIAL.PlantCode)=="L1") = 1;
levelKey(string(OFFICIAL.PlantCode)=="L2") = 2;
levelKey(string(OFFICIAL.PlantCode)=="L3") = 3;
OFFICIAL.SortTrajectory = trajKey;
OFFICIAL.SortCondition = condKey;
OFFICIAL.SortLevel = levelKey;
OFFICIAL = sortrows( ...
    OFFICIAL, ...
    {'SortTrajectory','SortCondition','SortLevel'});
OFFICIAL.SortTrajectory = [];
OFFICIAL.SortCondition = [];
OFFICIAL.SortLevel = [];
end
function RAW = buildMeasurementPlan(OFFICIAL,N_REPEATS,RANDOM_SEED)
nConfigurations = height(OFFICIAL);
nRows = nConfigurations*N_REPEATS;
RowType = repmat("RAW",nRows,1);
Level = strings(nRows,1);
Controller = strings(nRows,1);
Trajectory = strings(nRows,1);
Condition = strings(nRows,1);
Traj_Cond = strings(nRows,1);
RunID = strings(nRows,1);
Repeat = zeros(nRows,1);
RandomizationRank = zeros(nRows,1);
UniqueKey = strings(nRows,1);
Completed = false(nRows,1);
AttemptCount = zeros(nRows,1);
Status = repmat("PENDING",nRows,1);
ExecutionTime_s = nan(nRows,1);
SimulatedDuration_s = nan(nRows,1);
RTF = nan(nRows,1);
StartTimestamp = strings(nRows,1);
EndTimestamp = strings(nRows,1);
ErrorIdentifier = strings(nRows,1);
ErrorMessage = strings(nRows,1);
SummaryRepresentative = false(nRows,1);
ExecutionMean_s = nan(nRows,1);
ExecutionStd_s = nan(nRows,1);
ExecutionMedian_s = nan(nRows,1);
ExecutionCV_pct = nan(nRows,1);
ExecutionCI95Low_s = nan(nRows,1);
ExecutionCI95High_s = nan(nRows,1);
RTFMean = nan(nRows,1);
RTFStd = nan(nRows,1);
NormalityP_Log = nan(nRows,1);
BrownForsytheP_Log = nan(nRows,1);
Comparison_vs_L3 = strings(nRows,1);
WelchT_t_Log = nan(nRows,1);
WelchT_df = nan(nRows,1);
WelchT_P_Log = nan(nRows,1);
WelchT_P_Log_Holm = nan(nRows,1);
RankSumP = nan(nRows,1);
RankSumP_Holm = nan(nRows,1);
HedgesG_Log = nan(nRows,1);
GeometricTimeRatio_vs_L3 = nan(nRows,1);
TimeRatioCI95Low = nan(nRows,1);
TimeRatioCI95High = nan(nRows,1);
L3SlowdownFactor = nan(nRows,1);
L3SlowdownCI95Low = nan(nRows,1);
L3SlowdownCI95High = nan(nRows,1);
RAW = table( ...
    RowType, ...
    Level, ...
    Controller, ...
    Trajectory, ...
    Condition, ...
    Traj_Cond, ...
    RunID, ...
    Repeat, ...
    RandomizationRank, ...
    UniqueKey, ...
    Completed, ...
    AttemptCount, ...
    Status, ...
    ExecutionTime_s, ...
    SimulatedDuration_s, ...
    RTF, ...
    StartTimestamp, ...
    EndTimestamp, ...
    ErrorIdentifier, ...
    ErrorMessage, ...
    SummaryRepresentative, ...
    ExecutionMean_s, ...
    ExecutionStd_s, ...
    ExecutionMedian_s, ...
    ExecutionCV_pct, ...
    ExecutionCI95Low_s, ...
    ExecutionCI95High_s, ...
    RTFMean, ...
    RTFStd, ...
    NormalityP_Log, ...
    BrownForsytheP_Log, ...
    Comparison_vs_L3, ...
    WelchT_t_Log, ...
    WelchT_df, ...
    WelchT_P_Log, ...
    WelchT_P_Log_Holm, ...
    RankSumP, ...
    RankSumP_Holm, ...
    HedgesG_Log, ...
    GeometricTimeRatio_vs_L3, ...
    TimeRatioCI95Low, ...
    TimeRatioCI95High, ...
    L3SlowdownFactor, ...
    L3SlowdownCI95Low, ...
    L3SlowdownCI95High);
stream = RandStream('mt19937ar','Seed',RANDOM_SEED);
levels = ["L1","L2","L3"];
rowCounter = 0;
for levelIndex = 1:numel(levels)
    level = levels(levelIndex);
    configIndices = find(string(OFFICIAL.PlantCode)==level);
    if numel(configIndices) ~= 4
        error('TimingStats:PlanConstruction', ...
            'Expected four official scenarios for %s.',level);
    end
    for repetitionIndex = 1:N_REPEATS
        randomOrder = randperm(stream,numel(configIndices));
        for rankIndex = 1:numel(randomOrder)
            configIndex = configIndices(randomOrder(rankIndex));
            rowCounter = rowCounter + 1;
            traj = string(OFFICIAL.TrajectoryCode(configIndex));
            cond = string(OFFICIAL.DisturbanceID(configIndex));
            if cond=="NOM"
                paperCond = "D0";
            else
                paperCond = "D1";
            end
            RAW.Level(rowCounter) = ...
                string(OFFICIAL.PlantCode(configIndex));
            RAW.Controller(rowCounter) = ...
                string(OFFICIAL.ControllerID(configIndex));
            RAW.Trajectory(rowCounter) = traj;
            RAW.Condition(rowCounter) = cond;
            RAW.Traj_Cond(rowCounter) = traj + "/" + paperCond;
            RAW.RunID(rowCounter) = ...
                string(OFFICIAL.RunID(configIndex));
            RAW.Repeat(rowCounter) = repetitionIndex;
            RAW.RandomizationRank(rowCounter) = rankIndex;
            RAW.UniqueKey(rowCounter) = ...
                RAW.Level(rowCounter) + "_" + ...
                traj + "_" + ...
                cond + "_R" + ...
                compose("%02d",repetitionIndex);
            RAW.SummaryRepresentative(rowCounter) = ...
                repetitionIndex==1;
        end
    end
end
if rowCounter ~= nRows
    error('TimingStats:PlanConstruction', ...
        'Internal measurement-plan size mismatch.');
end
RAW = sortrows(RAW,{'Level','Repeat','RandomizationRank'});
end
function RAW = mergeCheckpoint(RAW,previous,N_REPEATS)
required = { ...
    'RowType', ...
    'UniqueKey', ...
    'Completed', ...
    'AttemptCount', ...
    'Status', ...
    'ExecutionTime_s', ...
    'SimulatedDuration_s', ...
    'RTF', ...
    'StartTimestamp', ...
    'EndTimestamp', ...
    'ErrorIdentifier', ...
    'ErrorMessage'};
missing = setdiff(required,previous.Properties.VariableNames);
if ~isempty(missing)
    error('TimingStats:IncompatibleCheckpoint', ...
        ['Existing CSV is not compatible with this robust timing script.\n' ...
         'Missing columns: %s\n' ...
         'Rename or remove the old CSV before starting a new campaign.'], ...
        strjoin(string(missing),', '));
end
previous = previous(string(previous.RowType)=="RAW",:);
if isempty(previous)
    error('TimingStats:IncompatibleCheckpoint', ...
        'Existing CSV contains no RAW timing rows.');
end
if max(double(previous.Repeat)) ~= N_REPEATS
    error('TimingStats:RepeatMismatch', ...
        ['Existing CSV was created with a different repetition count.\n' ...
         'Expected %d repetitions.'],N_REPEATS);
end
if numel(unique(string(previous.UniqueKey))) ~= height(previous)
    error('TimingStats:DuplicateCheckpointKeys', ...
        'Existing CSV contains duplicate UniqueKey values.');
end
for i = 1:height(RAW)
    idx = find(string(previous.UniqueKey)==RAW.UniqueKey(i));
    if isempty(idx)
        continue
    end
    if numel(idx) ~= 1
        error('TimingStats:DuplicateCheckpointKeys', ...
            'Duplicate checkpoint key: %s',RAW.UniqueKey(i));
    end
    RAW.Completed(i) = logical(previous.Completed(idx));
    RAW.AttemptCount(i) = double(previous.AttemptCount(idx));
    RAW.Status(i) = string(previous.Status(idx));
    RAW.ExecutionTime_s(i) = double(previous.ExecutionTime_s(idx));
    RAW.SimulatedDuration_s(i) = double(previous.SimulatedDuration_s(idx));
    RAW.RTF(i) = double(previous.RTF(idx));
    RAW.StartTimestamp(i) = string(previous.StartTimestamp(idx));
    RAW.EndTimestamp(i) = string(previous.EndTimestamp(idx));
    RAW.ErrorIdentifier(i) = string(previous.ErrorIdentifier(idx));
    RAW.ErrorMessage(i) = string(previous.ErrorMessage(idx));
    if RAW.Completed(i)
        if ~isfinite(RAW.ExecutionTime_s(i)) || ...
                RAW.ExecutionTime_s(i)<=0 || ...
                ~isfinite(RAW.SimulatedDuration_s(i)) || ...
                RAW.SimulatedDuration_s(i)<=0 || ...
                ~isfinite(RAW.RTF(i)) || ...
                RAW.RTF(i)<=0
            fprintf(2, ...
                ['Checkpoint row %s was marked COMPLETE but contains ' ...
                 'invalid timing data. It will be rerun.\n'], ...
                RAW.UniqueKey(i));
            RAW.Completed(i) = false;
            RAW.Status(i) = "INVALID_CHECKPOINT";
        end
    end
end
end
function RAW = clearDerivedStatistics(RAW)
numericVars = { ...
    'ExecutionMean_s', ...
    'ExecutionStd_s', ...
    'ExecutionMedian_s', ...
    'ExecutionCV_pct', ...
    'ExecutionCI95Low_s', ...
    'ExecutionCI95High_s', ...
    'RTFMean', ...
    'RTFStd', ...
    'NormalityP_Log', ...
    'BrownForsytheP_Log', ...
    'WelchT_t_Log', ...
    'WelchT_df', ...
    'WelchT_P_Log', ...
    'WelchT_P_Log_Holm', ...
    'RankSumP', ...
    'RankSumP_Holm', ...
    'HedgesG_Log', ...
    'GeometricTimeRatio_vs_L3', ...
    'TimeRatioCI95Low', ...
    'TimeRatioCI95High', ...
    'L3SlowdownFactor', ...
    'L3SlowdownCI95Low', ...
    'L3SlowdownCI95High'};
for i = 1:numel(numericVars)
    RAW.(numericVars{i})(:) = NaN;
end
RAW.Comparison_vs_L3(:) = "";
end
function validateRunOutput(RUN,key)
if ~isstruct(RUN)
    error('TimingStats:InvalidRunOutput', ...
        'run_icra_experiment returned an invalid output for %s.',key);
end
if ~isfield(RUN,'Status') || ...
        ~isfield(RUN.Status,'SimulationCompleted') || ...
        ~logical(RUN.Status.SimulationCompleted)
    error('TimingStats:SimulationIncomplete', ...
        'Simulation did not complete successfully for %s.',key);
end
if ~isfield(RUN,'Timing')
    error('TimingStats:MissingTiming', ...
        'Timing structure missing for %s.',key);
end
requiredTiming = { ...
    'ExecutionElapsedWallTime_s', ...
    'SimulatedDuration_s', ...
    'RealTimeFactor_RTF'};
for i = 1:numel(requiredTiming)
    if ~isfield(RUN.Timing,requiredTiming{i})
        error('TimingStats:MissingTimingField', ...
            'Timing field %s missing for %s.', ...
            requiredTiming{i},key);
    end
end
end
function RAW = computeFinalStatistics(RAW,ALPHA)
RAW = clearDerivedStatistics(RAW);
if ~all(RAW.Completed)
    error('TimingStats:StatisticsBeforeCompletion', ...
        'Cannot compute final statistics before all raw runs complete.');
end
configKeys = unique( ...
    RAW.Level + "|" + RAW.Trajectory + "|" + RAW.Condition, ...
    'stable');
for configIndex = 1:numel(configKeys)
    idx = ...
        (RAW.Level + "|" + RAW.Trajectory + "|" + RAW.Condition) == ...
        configKeys(configIndex);
    x = double(RAW.ExecutionTime_s(idx));
    r = double(RAW.RTF(idx));
    n = numel(x);
    if n < 3
        error('TimingStats:InsufficientReplicates', ...
            'Insufficient timing replicates for %s.', ...
            configKeys(configIndex));
    end
    meanX = mean(x);
    stdX = std(x,0);
    medianX = median(x);
    cvX = 100*stdX/meanX;
    tCrit = tinv(1-ALPHA/2,n-1);
    semX = stdX/sqrt(n);
    ciLow = meanX - tCrit*semX;
    ciHigh = meanX + tCrit*semX;
    meanRTF = mean(r);
    stdRTF = std(r,0);
    logX = log(x);
    try
        [~,pNormal] = lillietest(logX,'Alpha',ALPHA);
    catch
        pNormal = NaN;
    end
    RAW.ExecutionMean_s(idx) = meanX;
    RAW.ExecutionStd_s(idx) = stdX;
    RAW.ExecutionMedian_s(idx) = medianX;
    RAW.ExecutionCV_pct(idx) = cvX;
    RAW.ExecutionCI95Low_s(idx) = ciLow;
    RAW.ExecutionCI95High_s(idx) = ciHigh;
    RAW.RTFMean(idx) = meanRTF;
    RAW.RTFStd(idx) = stdRTF;
    RAW.NormalityP_Log(idx) = pNormal;
end
trajectories = ["T1","T2"];
conditions = ["NOM","DIST"];
levels = ["L1","L2","L3"];
for trajectory = trajectories
    for condition = conditions
        zAll = [];
        groupAll = [];
        for levelIndex = 1:numel(levels)
            level = levels(levelIndex);
            idx = ...
                RAW.Level==level & ...
                RAW.Trajectory==trajectory & ...
                RAW.Condition==condition;
            x = log(double(RAW.ExecutionTime_s(idx)));
            center = median(x);
            z = abs(x-center);
            zAll = [zAll; z(:)]; %#ok<AGROW>
            groupAll = [groupAll; ...
                repmat(levelIndex,numel(z),1)]; %#ok<AGROW>
        end
        try
            pBF = anova1(zAll,groupAll,'off');
        catch
            pBF = NaN;
        end
        idxScenario = ...
            RAW.Trajectory==trajectory & ...
            RAW.Condition==condition;
        RAW.BrownForsytheP_Log(idxScenario) = pBF;
    end
end
for trajectory = trajectories
    for condition = conditions
        idxL3 = ...
            RAW.Level=="L3" & ...
            RAW.Trajectory==trajectory & ...
            RAW.Condition==condition;
        y = double(RAW.ExecutionTime_s(idxL3));
        logY = log(y);
        for level = ["L1","L2"]
            idx = ...
                RAW.Level==level & ...
                RAW.Trajectory==trajectory & ...
                RAW.Condition==condition;
            x = double(RAW.ExecutionTime_s(idx));
            logX = log(x);
            [~,pWelch,ciLog,statsWelch] = ...
                ttest2( ...
                    logX, ...
                    logY, ...
                    'Alpha',ALPHA, ...
                    'Vartype','unequal');
            pRank = ranksum(x,y);
            meanLogDifference = mean(logX)-mean(logY);
            ratio = exp(meanLogDifference);
            ratioCILow = exp(ciLog(1));
            ratioCIHigh = exp(ciLog(2));
            slowdown = 1/ratio;
            slowdownCILow = 1/ratioCIHigh;
            slowdownCIHigh = 1/ratioCILow;
            varianceAverage = ...
                (var(logX,0) + var(logY,0))/2;
            if varianceAverage > 0
                d = meanLogDifference/sqrt(varianceAverage);
            else
                d = NaN;
            end
            n1 = numel(logX);
            n2 = numel(logY);
            J = 1 - 3/(4*(n1+n2)-9);
            hedgesG = J*d;
            RAW.Comparison_vs_L3(idx) = level + "_vs_L3";
            RAW.WelchT_t_Log(idx) = statsWelch.tstat;
            RAW.WelchT_df(idx) = statsWelch.df;
            RAW.WelchT_P_Log(idx) = pWelch;
            RAW.RankSumP(idx) = pRank;
            RAW.HedgesG_Log(idx) = hedgesG;
            RAW.GeometricTimeRatio_vs_L3(idx) = ratio;
            RAW.TimeRatioCI95Low(idx) = ratioCILow;
            RAW.TimeRatioCI95High(idx) = ratioCIHigh;
            RAW.L3SlowdownFactor(idx) = slowdown;
            RAW.L3SlowdownCI95Low(idx) = slowdownCILow;
            RAW.L3SlowdownCI95High(idx) = slowdownCIHigh;
        end
    end
end
summaryComparisons = ...
    RAW.SummaryRepresentative & ...
    (RAW.Level=="L1" | RAW.Level=="L2");
summaryIndices = find(summaryComparisons);
rawWelchP = RAW.WelchT_P_Log(summaryIndices);
rawRankP = RAW.RankSumP(summaryIndices);
adjWelchP = holmCorrection(rawWelchP);
adjRankP = holmCorrection(rawRankP);
for i = 1:numel(summaryIndices)
    representativeIndex = summaryIndices(i);
    idxSameConfig = ...
        RAW.Level==RAW.Level(representativeIndex) & ...
        RAW.Trajectory==RAW.Trajectory(representativeIndex) & ...
        RAW.Condition==RAW.Condition(representativeIndex);
    RAW.WelchT_P_Log_Holm(idxSameConfig) = adjWelchP(i);
    RAW.RankSumP_Holm(idxSameConfig) = adjRankP(i);
end
end
function adjusted = holmCorrection(p)
p = double(p(:));
adjusted = nan(size(p));
valid = isfinite(p);
pv = p(valid);
if isempty(pv)
    return
end
[sortedP,order] = sort(pv);
m = numel(sortedP);
adjustedSorted = zeros(m,1);
runningMaximum = 0;
for i = 1:m
    candidate = (m-i+1)*sortedP(i);
    runningMaximum = max(runningMaximum,candidate);
    adjustedSorted(i) = min(1,runningMaximum);
end
restored = zeros(m,1);
restored(order) = adjustedSorted;
adjusted(valid) = restored;
end
function atomicWriteTable(T,outputCSV)
outputCSV = char(outputCSV);
tmpPath = [outputCSV '.tmp'];
cleanupObject = onCleanup(@() deleteIfExists(tmpPath));
try
    writetable( ...
        T, ...
        tmpPath, ...
        'FileType','text', ...
        'Delimiter',',');
    [ok,msg] = movefile(tmpPath,outputCSV,'f');
    if ~ok
        error('TimingStats:CheckpointMoveFailed', ...
            ['Could not replace the timing CSV checkpoint.\n' ...
             'Close the CSV in Excel and try again.\n' ...
             'System message: %s'],msg);
    end
catch ME
    delete(cleanupObject);
    deleteIfExists(tmpPath);
    rethrow(ME)
end
delete(cleanupObject);
end
function deleteIfExists(pathName)
if isfile(pathName)
    try
        delete(pathName);
    catch
    end
end
end
function safeSimulinkCleanup(clearSDI)
try
    bdclose('all');
catch
end
if clearSDI
    safeClearSDI;
end
drawnow
end
function safeClearSDI
try
    Simulink.sdi.clear;
catch
end
end
function s = timestampNow
try
    s = string(datetime( ...
        'now', ...
        'Format','yyyy-MM-dd HH:mm:ss.SSS'));
catch
    s = string(datestr(now,'yyyy-mm-dd HH:MM:SS.FFF'));
end
end
function s = sanitizeErrorMessage(messageText)
s = string(messageText);
s = replace(s,newline," ");
s = replace(s,char(13)," ");
s = strip(s);
end
