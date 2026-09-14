function CFG = controller_tuning_config()
CFG = struct();
CFG.schemaVersion = 3.0;
CFG.campaignProfile = "C2_FINAL_LOCAL_ROLL_PITCH_EST_TRAJECTORY2_L3";
CFG.modelName = 'UAV_Research_Environment';
CFG.autopilotParameterFile = 'UAV_autopilot.m';
CFG.output.rootFolder = 'Results_C2';
CFG.policy.tuneInsideOut = true;
CFG.policy.freezeAfterEachStage = true;
CFG.policy.keepBaselineIfNoImprovement = true;
CFG.policy.allowZeroGainActivation = false;
CFG.policy.allowSequentialRetuning = true;
CFG.policy.minimumImprovementFraction = 0.005;
CFG.policy.runParallelPreflightEachStage = false;
CFG.policy.validateEachStage = false;
CFG.policy.serialBestCheckEachStage = true;
CFG.policy.finalValidationRequired = true;
CFG.policy.maximumMissionCostDegradationFraction = 0.01;
CFG.policy.maximumWorstPlantCostDegradationFraction = 0.01;
CFG.policy.innerLoopGainLowerMultiplier = 0.10;
CFG.policy.innerLoopGainUpperMultiplier = 1.30;
CFG.policy.outerLoopGainLowerMultiplier = 0.10;
CFG.policy.outerLoopGainUpperMultiplier = 1.30;
CFG.policy.stageValidationMode = "MISSION_GATE_ONLY";
CFG.policy.finalValidationMode = "STRICT_MULTI_SEED";
if CFG.policy.minimumImprovementFraction < 0 || CFG.policy.minimumImprovementFraction >= 1
    error('QuadrotorFramework:ControllerTuningImprovementThreshold','minimumImprovementFraction must lie in [0,1).');
end
if CFG.policy.maximumMissionCostDegradationFraction < 0 || CFG.policy.maximumWorstPlantCostDegradationFraction < 0
    error('QuadrotorFramework:ControllerTuningDegradationLimits','Stage degradation limits must be nonnegative.');
end
if CFG.policy.innerLoopGainLowerMultiplier <= 0 || CFG.policy.innerLoopGainUpperMultiplier <= CFG.policy.innerLoopGainLowerMultiplier || CFG.policy.outerLoopGainLowerMultiplier <= 0 || CFG.policy.outerLoopGainUpperMultiplier <= CFG.policy.outerLoopGainLowerMultiplier
    error('QuadrotorFramework:ControllerTuningGainMultiplierLimits','Gain multiplier limits are invalid.');
end
CFG.experiment.controllerSet = "C2";
CFG.experiment.plantModels = 3;
CFG.experiment.plantWeights = 1;
CFG.experiment.plantAggregation = "weighted_mean";
CFG.experiment.disturbancesEnabled = false;
CFG.experiment.operatorMode = uint8(1);
CFG.experiment.trajectoryID = 2;
CFG.experiment.feedbackSource = "EST";
CFG.experiment.metricStateSource = "TRUE";
CFG.experiment.requireEstimatedFeedback = true;
CFG.experiment.estimatedFeedbackTolerance_m = 1e-6;
CFG.experiment.estimatedFeedbackRelativeTolerance = 0.05;
CFG.experiment.estimatedFeedbackMaximumLag_s = 0.05;
CFG.experiment.optimizationSeedOffset = 0;
CFG.validation.stageSeedOffsets = 37;
CFG.validation.finalSeedOffsets = [37;91;151];
CFG.validation.seedOffsets = CFG.validation.stageSeedOffsets;
CFG.simulation.metricSampleRate_Hz = 200;
CFG.simulation.disablePacing = true;
CFG.simulation.useAutomaticProtocolStopTime = true;
CFG.simulation.stopTime_s = [];
CFG.simulation.requireMissionCompletion = true;
CFG.simulation.requireLanded = true;
CFG.simulation.rejectFailsafe = true;
CFG.cost.failurePenalty = 1e4;
CFG.cost.softMissionPenalty = 5.0;
CFG.cost.minimumNormalization = 1e-12;
CFG.cost.parameterRegularizationWeight = 0.01;
CFG.cost.joint.rateWeight = 0.50;
CFG.cost.joint.attitudeWeight = 0.50;
if abs(CFG.cost.joint.rateWeight + CFG.cost.joint.attitudeWeight - 1.0) > 1e-12
    error('QuadrotorFramework:ControllerJointWeights','Joint roll-pitch weights must sum to one.');
end
CFG.cost.tracking.rmse = 0.55;
CFG.cost.tracking.p95 = 0.20;
CFG.cost.tracking.controlEffort = 0.10;
CFG.cost.tracking.controlVariation = 0.05;
CFG.cost.tracking.saturation = 0.10;
trackingWeightSum = CFG.cost.tracking.rmse + CFG.cost.tracking.p95 + CFG.cost.tracking.controlEffort + CFG.cost.tracking.controlVariation + CFG.cost.tracking.saturation;
if abs(trackingWeightSum - 1.0) > 1e-12
    error('QuadrotorFramework:ControllerTrackingWeights','Controller tracking weights must sum to 1.');
end
CFG.cost.position.rmse = 0.30;
CFG.cost.position.p95 = 0.15;
CFG.cost.position.maximumError = 0.10;
CFG.cost.position.waypointArrival = 0.10;
CFG.cost.position.holdRMSE = 0.10;
CFG.cost.position.overshoot = 0.20;
CFG.cost.position.controlVariation = 0.05;
positionWeightSum = CFG.cost.position.rmse + CFG.cost.position.p95 + CFG.cost.position.maximumError + CFG.cost.position.waypointArrival + CFG.cost.position.holdRMSE + CFG.cost.position.overshoot + CFG.cost.position.controlVariation;
if abs(positionWeightSum - 1.0) > 1e-12
    error('QuadrotorFramework:ControllerPositionWeights','Controller position weights must sum to 1.');
end
CFG.optimizer.method = 'surrogateopt';
CFG.optimizer.useParallel = false;
CFG.optimizer.batchSize = 1;
CFG.optimizer.parallelUseFastRestart = false;
CFG.optimizer.display = 'iter';
CFG.optimizer.randomSeed = 2027;
if isempty(which('surrogateopt'))
    error('QuadrotorFramework:ControllerSurrogateOptUnavailable',['surrogateopt is not available. Global Optimization Toolbox ','is required for automatic controller tuning.']);
end
CFG.baseline.expectedC2.rollRateKp = 20.0;
CFG.baseline.expectedC2.rollRateKi = 36.105;
CFG.baseline.expectedC2.rollAttitudeKp = 5.0;
CFG.baseline.expectedC2.pitchRateKp = 34.026;
CFG.baseline.expectedC2.pitchRateKi = 114.83;
CFG.baseline.expectedC2.pitchAttitudeKp = 23.9692345015116;
CFG.search.pitchRateKpAbsolute = [5.0 40.0];
CFG.search.pitchRateKiAbsolute = [20.0 120.0];
CFG.search.pitchAttitudeKpAbsolute = [3.0 25.0];
CFG.search.jointRefinementMultiplier = [0.80 1.20];
S1 = struct();
S1.id = 1;
S1.name = "Pitch Angular Rate";
S1.key = "pitch_angular_rate";
S1.objectiveType = "rate_pitch";
S1.parameterPaths = {'angularRate.pitch.Kp';'angularRate.pitch.Ki'};
S1.parameterLabels = {'Pitch Rate Kp';'Pitch Rate Ki'};
S1.lowerLog10Multiplier = [log10(CFG.search.pitchRateKpAbsolute(1)/CFG.baseline.expectedC2.pitchRateKp);log10(CFG.search.pitchRateKiAbsolute(1)/CFG.baseline.expectedC2.pitchRateKi)];
S1.upperLog10Multiplier = [log10(CFG.search.pitchRateKpAbsolute(2)/CFG.baseline.expectedC2.pitchRateKp);log10(CFG.search.pitchRateKiAbsolute(2)/CFG.baseline.expectedC2.pitchRateKi)];
S1.initialPoint = [log10(20.0/CFG.baseline.expectedC2.pitchRateKp);log10(40.0/CFG.baseline.expectedC2.pitchRateKi)];
S1.maxFunctionEvaluations = 6;
S2 = struct();
S2.id = 2;
S2.name = "Pitch Attitude";
S2.key = "pitch_attitude";
S2.objectiveType = "attitude_pitch";
S2.parameterPaths = {'attitude.pitch.Kp'};
S2.parameterLabels = {'Pitch Attitude Kp'};
S2.lowerLog10Multiplier = log10(CFG.search.pitchAttitudeKpAbsolute(1)/CFG.baseline.expectedC2.pitchAttitudeKp);
S2.upperLog10Multiplier = log10(CFG.search.pitchAttitudeKpAbsolute(2)/CFG.baseline.expectedC2.pitchAttitudeKp);
S2.initialPoint = log10(10.0/CFG.baseline.expectedC2.pitchAttitudeKp);
S2.maxFunctionEvaluations = 4;
S3 = struct();
S3.id = 3;
S3.name = "Joint Roll-Pitch Refinement";
S3.key = "joint_roll_pitch_refinement";
S3.objectiveType = "joint_roll_pitch";
S3.parameterPaths = {'angularRate.roll.Kp';'angularRate.roll.Ki';'attitude.roll.Kp';'angularRate.pitch.Kp';'angularRate.pitch.Ki';'attitude.pitch.Kp'};
S3.parameterLabels = {'Roll Rate Kp';'Roll Rate Ki';'Roll Attitude Kp';'Pitch Rate Kp';'Pitch Rate Ki';'Pitch Attitude Kp'};
S3.lowerLog10Multiplier = log10(CFG.search.jointRefinementMultiplier(1))*ones(6,1);
S3.upperLog10Multiplier = log10(CFG.search.jointRefinementMultiplier(2))*ones(6,1);
S3.initialPoint = zeros(6,1);
S3.maxFunctionEvaluations = 8;
CFG.stages = [S1;S2;S3];
CFG.numberOfStages = numel(CFG.stages);
for stageIndex = 1:CFG.numberOfStages
    numberOfParameters = numel(CFG.stages(stageIndex).parameterPaths);
    CFG.stages(stageIndex).numberOfParameters = numberOfParameters;
    if ~isfield(CFG.stages(stageIndex),'initialPoint') || isempty(CFG.stages(stageIndex).initialPoint)
        CFG.stages(stageIndex).initialPoint = zeros(numberOfParameters,1);
    else
        CFG.stages(stageIndex).initialPoint = double(CFG.stages(stageIndex).initialPoint(:));
    end
    CFG.stages(stageIndex).minSurrogatePoints = numberOfParameters + 1;
    lower = double(CFG.stages(stageIndex).lowerLog10Multiplier(:));
    upper = double(CFG.stages(stageIndex).upperLog10Multiplier(:));
    initialPoint = double(CFG.stages(stageIndex).initialPoint(:));
    if numel(lower) ~= numberOfParameters || numel(upper) ~= numberOfParameters || numel(initialPoint) ~= numberOfParameters
        error('QuadrotorFramework:ControllerStageBounds','Bounds or initial point do not match parameter count for stage "%s".',CFG.stages(stageIndex).name);
    end
    if any(~isfinite(lower)) || any(~isfinite(upper)) || any(lower >= upper)
        error('QuadrotorFramework:ControllerStageBoundsInvalid','Invalid optimization bounds for stage "%s".',CFG.stages(stageIndex).name);
    end
    if any(~isfinite(initialPoint)) || any(initialPoint < lower) || any(initialPoint > upper)
        error('QuadrotorFramework:ControllerStageInitialPoint','Initial point is outside the optimization bounds for stage "%s".',CFG.stages(stageIndex).name);
    end
    if CFG.stages(stageIndex).minSurrogatePoints > CFG.stages(stageIndex).maxFunctionEvaluations
        error('QuadrotorFramework:ControllerStageBudget',['Stage "%s" has fewer evaluations than required ','surrogate points.'],CFG.stages(stageIndex).name);
    end
    if CFG.stages(stageIndex).maxFunctionEvaluations < numberOfParameters + 2
        error('QuadrotorFramework:ControllerStageTooShort',['Stage "%s" does not provide enough evaluations for ','a meaningful optimization.'],CFG.stages(stageIndex).name);
    end
end
allParameterPaths = strings(0,1);
for stageIndex = 1:CFG.numberOfStages
    allParameterPaths = [allParameterPaths;string(CFG.stages(stageIndex).parameterPaths(:))];
end
CFG.totalStageParameters = numel(allParameterPaths);
CFG.totalTunableGains = numel(unique(allParameterPaths));
expectedTunablePaths = sort(["angularRate.roll.Kp";"angularRate.roll.Ki";"attitude.roll.Kp";"angularRate.pitch.Kp";"angularRate.pitch.Ki";"attitude.pitch.Kp"]);
actualTunablePaths = sort(unique(allParameterPaths));
if CFG.totalTunableGains ~= 6 || ~isequal(actualTunablePaths,expectedTunablePaths)
    error('QuadrotorFramework:ControllerTunableGainContract','The final C2/L3 campaign must tune exactly the six roll/pitch gains defined by the validated local search.');
end
if CFG.totalStageParameters ~= 9
    error('QuadrotorFramework:ControllerSequentialRetuningContract','The three-stage C2/L3 campaign must contain 9 stage parameter entries with six unique gains.');
end
CFG.validation.finalOnly = false;
CFG.validation.controllerSet = CFG.experiment.controllerSet;
CFG.validation.plantModels = CFG.experiment.plantModels;
CFG.validation.plantWeights = CFG.experiment.plantWeights;
CFG.validation.trajectoryID = CFG.experiment.trajectoryID;
CFG.validation.feedbackSource = CFG.experiment.feedbackSource;
CFG.validation.metricStateSource = CFG.experiment.metricStateSource;
CFG.validation.requireAllSeeds = true;
CFG.validation.requireMissionCompletion = true;
CFG.validation.requireNoFailsafe = true;
CFG.validation.requireLanded = true;
CFG.output.resultFile = 'Controller_Tuning_C2_Result.mat';
CFG.output.stageResultsFile = 'Controller_Tuning_C2_Stages.mat';
CFG.output.gainTableFile = 'Controller_Tuning_C2_Gains.csv';
CFG.output.validationFile = 'Controller_Tuning_C2_Validation.mat';
CFG.output.checkpointFile = 'Controller_Tuning_C2_Checkpoint.mat';
if ~isscalar(CFG.optimizer.batchSize) || ~isfinite(CFG.optimizer.batchSize) || CFG.optimizer.batchSize < 1 || CFG.optimizer.batchSize ~= floor(CFG.optimizer.batchSize)
    error('QuadrotorFramework:ControllerBatchSize','Optimizer batchSize must be a positive integer.');
end
if ~isscalar(CFG.optimizer.randomSeed) || ~isfinite(CFG.optimizer.randomSeed) || CFG.optimizer.randomSeed < 0 || CFG.optimizer.randomSeed ~= floor(CFG.optimizer.randomSeed)
    error('QuadrotorFramework:ControllerRandomSeed','Optimizer randomSeed must be a nonnegative integer.');
end
stageSeeds = double(CFG.validation.stageSeedOffsets(:));
finalSeeds = double(CFG.validation.finalSeedOffsets(:));
if isempty(stageSeeds) || isempty(finalSeeds)
    error('QuadrotorFramework:ControllerValidationSeeds','Stage and final validation seed lists must not be empty.');
end
if any(~isfinite(stageSeeds)) || numel(unique(stageSeeds)) ~= numel(stageSeeds) || any(~isfinite(finalSeeds)) || numel(unique(finalSeeds)) ~= numel(finalSeeds)
    error('QuadrotorFramework:ControllerValidationSeedContract','Validation seeds must be finite and unique within each validation set.');
end
if any(stageSeeds == double(CFG.experiment.optimizationSeedOffset)) || any(finalSeeds == double(CFG.experiment.optimizationSeedOffset))
    error('QuadrotorFramework:ControllerSeedLeakage','Validation seeds must be independent from the optimization seed.');
end
if ~all(ismember(stageSeeds,finalSeeds))
    error('QuadrotorFramework:ControllerStageFinalSeedContract','Every stage-validation seed must also be included in final validation.');
end
if ~strcmpi(string(CFG.experiment.controllerSet),"C2")
    error('QuadrotorFramework:ControllerTuningControllerSet','This configuration is reserved for C2 tuning.');
end
if ~isequal(double(CFG.experiment.plantModels(:).'),3)
    error('QuadrotorFramework:ControllerTuningPlantModels','C2 tuning must use L3 only.');
end
if numel(CFG.experiment.plantWeights) ~= numel(CFG.experiment.plantModels) || any(~isfinite(CFG.experiment.plantWeights)) || any(CFG.experiment.plantWeights < 0) || abs(sum(CFG.experiment.plantWeights)-1) > 1e-12
    error('QuadrotorFramework:ControllerTuningPlantWeights','Plant weights must be finite, nonnegative, and sum to one.');
end
if CFG.experiment.trajectoryID ~= 2
    error('QuadrotorFramework:ControllerTuningTrajectory','C2 tuning must use trajectory 2.');
end
if ~strcmpi(CFG.experiment.feedbackSource,"EST")
    error('QuadrotorFramework:ControllerTuningFeedback','Controller tuning must use EST feedback.');
end
if ~strcmpi(CFG.experiment.metricStateSource,"TRUE")
    error('QuadrotorFramework:ControllerTuningMetricState','Controller performance metrics must use TRUE state.');
end
CFG.totalRequestedFunctionEvaluations = sum([CFG.stages.maxFunctionEvaluations]);
fprintf('\n');
fprintf('==============================================================\n');
fprintf(' CONTROLLER C2 FINAL LOCAL L3 TUNING CONFIGURATION\n');
fprintf('==============================================================\n');
fprintf('Schema version:             %.1f\n',CFG.schemaVersion);
fprintf('Campaign profile:          %s\n',CFG.campaignProfile);
fprintf('Stages:                    %d\n',CFG.numberOfStages);
fprintf('Unique tunable gains:      %d\n',CFG.totalTunableGains);
fprintf('Stage parameter entries:   %d\n',CFG.totalStageParameters);
fprintf('Requested evaluations:     %d\n',CFG.totalRequestedFunctionEvaluations);
fprintf('Optimizer:                 %s\n',CFG.optimizer.method);
fprintf('Parallel simulations:      %d\n',CFG.optimizer.useParallel);
fprintf('Fast Restart:              %d\n',CFG.optimizer.parallelUseFastRestart);
fprintf('Stage validation:          1-SEED MISSION SAFETY GATE\n');
fprintf('Final validation:          3-SEED STRICT\n');
fprintf('Max mission degradation:   %.1f %%\n',100*CFG.policy.maximumMissionCostDegradationFraction);
fprintf('Controller set:            %s\n',CFG.experiment.controllerSet);
fprintf('Controller feedback:       %s\n',CFG.experiment.feedbackSource);
fprintf('Metric state source:       %s\n',CFG.experiment.metricStateSource);
fprintf('Trajectory ID:             %d\n',CFG.experiment.trajectoryID);
fprintf('Plant models:              L3\n');
fprintf('Disturbances:              %d\n',CFG.experiment.disturbancesEnabled);
fprintf('Stage seeds:               %s\n',mat2str(double(CFG.validation.stageSeedOffsets(:).')));
fprintf('Final seeds:               %s\n',mat2str(double(CFG.validation.finalSeedOffsets(:).')));
fprintf('Roll baseline:             Kp_rate %.3f | Ki_rate %.3f | Kp_att %.3f\n',CFG.baseline.expectedC2.rollRateKp,CFG.baseline.expectedC2.rollRateKi,CFG.baseline.expectedC2.rollAttitudeKp);
fprintf('Pitch baseline:            Kp_rate %.3f | Ki_rate %.3f | Kp_att %.3f\n',CFG.baseline.expectedC2.pitchRateKp,CFG.baseline.expectedC2.pitchRateKi,CFG.baseline.expectedC2.pitchAttitudeKp);
fprintf('Pitch rate Kp search:      [%.3f %.3f]\n',CFG.search.pitchRateKpAbsolute(1),CFG.search.pitchRateKpAbsolute(2));
fprintf('Pitch rate Ki search:      [%.3f %.3f]\n',CFG.search.pitchRateKiAbsolute(1),CFG.search.pitchRateKiAbsolute(2));
fprintf('Pitch attitude search:     [%.3f %.3f]\n',CFG.search.pitchAttitudeKpAbsolute(1),CFG.search.pitchAttitudeKpAbsolute(2));
fprintf('Joint refinement:          [%.2fx %.2fx]\n',CFG.search.jointRefinementMultiplier(1),CFG.search.jointRefinementMultiplier(2));
fprintf('==============================================================\n');
for stageIndex = 1:CFG.numberOfStages
    fprintf('%d. %-28s | %d gains | %2d eval | %d surrogate pts\n',CFG.stages(stageIndex).id,CFG.stages(stageIndex).name,CFG.stages(stageIndex).numberOfParameters,CFG.stages(stageIndex).maxFunctionEvaluations,CFG.stages(stageIndex).minSurrogatePoints);
end
fprintf('==============================================================\n\n');
end
