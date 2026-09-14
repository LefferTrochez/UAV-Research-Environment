function [J, RESULT] = evaluate_controller_candidates_parallel( ...
    Z, ...
    CFG, ...
    STAGE, ...
    frozenAutopilot, ...
    baselineMetrics)
narginchk(5,5);
if ~isstruct(CFG)
    error('QuadrotorFramework:ControllerBatchInvalidCFG','CFG must be a structure.');
end
if ~isstruct(STAGE)
    error('QuadrotorFramework:ControllerBatchInvalidStage','STAGE must be a structure.');
end
if ~isstruct(frozenAutopilot)
    error('QuadrotorFramework:ControllerBatchInvalidAutopilot','frozenAutopilot must be a structure.');
end
if ~isfield(CFG,'schemaVersion') || double(CFG.schemaVersion) < 3.0
    error('QuadrotorFramework:ControllerBatchSchema','Controller tuning requires configuration schema 3.0 or newer.');
end
if ~isfield(CFG,'experiment') || ~isstruct(CFG.experiment)
    error('QuadrotorFramework:ControllerBatchExperiment','CFG.experiment is required.');
end
if ~isfield(CFG.experiment,'controllerSet') || ~strcmpi(string(CFG.experiment.controllerSet),"C2")
    error('QuadrotorFramework:ControllerBatchControllerSet','This evaluator is configured for controller set C2.');
end
if ~isfield(CFG.experiment,'plantModels') || ~isequal(double(CFG.experiment.plantModels(:).'),3)
    error('QuadrotorFramework:ControllerBatchPlantModels','C2 tuning must evaluate L3 only.');
end
if ~isfield(CFG.experiment,'trajectoryID') || double(CFG.experiment.trajectoryID) ~= 2
    error('QuadrotorFramework:ControllerBatchTrajectory','C2 tuning must use trajectory 2.');
end
if ~isfield(CFG.experiment,'feedbackSource') || ~strcmpi(string(CFG.experiment.feedbackSource),"EST")
    error('QuadrotorFramework:ControllerBatchFeedback','C2 tuning must use EST controller feedback.');
end
if ~isfield(CFG.experiment,'metricStateSource') || ~strcmpi(string(CFG.experiment.metricStateSource),"TRUE")
    error('QuadrotorFramework:ControllerBatchMetricState','Controller performance metrics must use TRUE state.');
end
if ~isfield(frozenAutopilot,'info') || ~isstruct(frozenAutopilot.info)
    error('QuadrotorFramework:ControllerBatchAutopilotInfo','frozenAutopilot.info is required.');
end
if ~isfield(frozenAutopilot.info,'controllerGainSchema') || string(frozenAutopilot.info.controllerGainSchema) ~= "3.0"
    error('QuadrotorFramework:ControllerBatchAutopilotSchema','frozenAutopilot must use controller gain schema 3.0.');
end
if ~isfield(frozenAutopilot.info,'activeController') || ~strcmpi(string(frozenAutopilot.info.activeController),"C2")
    error('QuadrotorFramework:ControllerBatchActiveController','frozenAutopilot must have controller set C2 active.');
end
if isempty(baselineMetrics)
    error('QuadrotorFramework:ControllerBatchMissingBaseline','baselineMetrics is required before controller candidate evaluation can begin.');
end
if ~isnumeric(Z) || isempty(Z)
    error('QuadrotorFramework:ControllerBatchInvalidCandidates','Candidate input Z must be a nonempty numeric array.');
end
if ~isfield(CFG,'cost') || ~isstruct(CFG.cost) || ~isfield(CFG.cost,'failurePenalty')
    error('QuadrotorFramework:ControllerBatchMissingFailurePenalty','CFG.cost.failurePenalty is required.');
end
if ~isscalar(CFG.cost.failurePenalty) || ~isnumeric(CFG.cost.failurePenalty) || ~isfinite(CFG.cost.failurePenalty) || CFG.cost.failurePenalty <= 0
    error('QuadrotorFramework:ControllerBatchInvalidFailurePenalty','CFG.cost.failurePenalty must be finite and positive.');
end
if ~isfield(CFG.experiment,'optimizationSeedOffset')
    error('QuadrotorFramework:ControllerBatchMissingOptimizationSeed','CFG.experiment.optimizationSeedOffset is required.');
end
optimizationSeedOffset = double(CFG.experiment.optimizationSeedOffset);
if ~isscalar(optimizationSeedOffset) || ~isfinite(optimizationSeedOffset)
    error('QuadrotorFramework:ControllerBatchInvalidOptimizationSeed','optimizationSeedOffset must be a finite scalar.');
end
requiredStageFields = {'id';'name';'objectiveType';'parameterPaths';'numberOfParameters';'lowerLog10Multiplier';'upperLog10Multiplier'};
for fieldIndex = 1:numel(requiredStageFields)
    fieldName = requiredStageFields{fieldIndex};
    if ~isfield(STAGE,fieldName)
        error('QuadrotorFramework:ControllerBatchStageField','Missing STAGE.%s.',fieldName);
    end
end
localValidateFinalLocalStageContract(STAGE);
numberOfParameters = double(STAGE.numberOfParameters);
if ~isscalar(numberOfParameters) || ~isfinite(numberOfParameters) || numberOfParameters < 1 || numberOfParameters ~= floor(numberOfParameters)
    error('QuadrotorFramework:ControllerBatchParameterCount','STAGE.numberOfParameters must be a positive integer.');
end
if numel(STAGE.parameterPaths) ~= numberOfParameters
    error('QuadrotorFramework:ControllerBatchStagePathCount','Stage "%s" contains %d parameter paths but declares %d parameters.',STAGE.name,numel(STAGE.parameterPaths),numberOfParameters);
end
try
    controller_tuning_gain_table(frozenAutopilot,STAGE.parameterPaths);
catch ME
    error('QuadrotorFramework:ControllerBatchGainContract','Stage "%s" contains a controller parameter that is not compatible with the current tuning gain schema.\n\n%s',STAGE.name,ME.message);
end
Z = double(Z);
if isvector(Z)
    if numel(Z) ~= numberOfParameters
        error('QuadrotorFramework:ControllerBatchCandidateSize','Candidate contains %d values, but stage "%s" requires %d parameters.',numel(Z),STAGE.name,numberOfParameters);
    end
    Z = reshape(Z,1,numberOfParameters);
elseif size(Z,2) == numberOfParameters
elseif size(Z,1) == numberOfParameters
    Z = Z.';
else
    error('QuadrotorFramework:ControllerBatchCandidateMatrix','Candidate matrix must have %d columns, one for each parameter of stage "%s".',numberOfParameters,STAGE.name);
end
numberOfCandidates = size(Z,1);
if numberOfCandidates < 1
    error('QuadrotorFramework:ControllerBatchNoCandidates','At least one controller candidate is required.');
end
if any(~isfinite(Z),'all')
    error('QuadrotorFramework:ControllerBatchNonfiniteCandidate','Controller candidate matrix contains NaN or Inf.');
end
lowerBounds = reshape(double(STAGE.lowerLog10Multiplier(:)),1,[]);
upperBounds = reshape(double(STAGE.upperLog10Multiplier(:)),1,[]);
if numel(lowerBounds) ~= numberOfParameters || numel(upperBounds) ~= numberOfParameters
    error('QuadrotorFramework:ControllerBatchBounds','Optimization bounds for stage "%s" do not match its parameter count.',STAGE.name);
end
if any(~isfinite(lowerBounds)) || any(~isfinite(upperBounds)) || any(lowerBounds >= upperBounds)
    error('QuadrotorFramework:ControllerBatchInvalidBounds','Stage "%s" contains invalid optimization bounds.',STAGE.name);
end
outsideBounds = any(Z < lowerBounds | Z > upperBounds,2);
J = CFG.cost.failurePenalty .* ones(numberOfCandidates,1);
template = localEmptyResult(CFG,STAGE);
RESULT = repmat(template,numberOfCandidates,1);
outsideIndices = find(outsideBounds);
for localIndex = 1:numel(outsideIndices)
    candidateIndex = outsideIndices(localIndex);
    RESULT(candidateIndex).success = false;
    RESULT(candidateIndex).cost = CFG.cost.failurePenalty;
    RESULT(candidateIndex).stageID = STAGE.id;
    RESULT(candidateIndex).stageName = string(STAGE.name);
    RESULT(candidateIndex).z = Z(candidateIndex,:).';
    RESULT(candidateIndex).messages = {'Candidate lies outside configured stage bounds.'};
end
validIndices = find(~outsideBounds);
if isempty(validIndices)
    return;
end
Zvalid = Z(validIndices,:);
[Jvalid,RESULTvalid] = evaluate_controller_candidate( ...
    Zvalid, ...
    CFG, ...
    STAGE, ...
    frozenAutopilot, ...
    baselineMetrics, ...
    'serial', ...
    optimizationSeedOffset, ...
    'baseline');
Jvalid = double(Jvalid(:));
if numel(Jvalid) ~= numel(validIndices)
    error('QuadrotorFramework:ControllerBatchObjectiveSize','Controller evaluator returned %d costs for %d candidates.',numel(Jvalid),numel(validIndices));
end
if numel(RESULTvalid) ~= numel(validIndices)
    error('QuadrotorFramework:ControllerBatchResultSize','Controller evaluator returned %d result structures for %d candidates.',numel(RESULTvalid),numel(validIndices));
end
for localIndex = 1:numel(RESULTvalid)
    RESULTvalid(localIndex) = localAnnotateResult(RESULTvalid(localIndex),CFG);
end
RESULTvalid = orderfields(RESULTvalid,template);
invalidCost = ~isfinite(Jvalid) | Jvalid < 0;
Jvalid(invalidCost) = CFG.cost.failurePenalty;
invalidIndices = find(invalidCost);
for localIndex = 1:numel(invalidIndices)
    resultIndex = invalidIndices(localIndex);
    RESULTvalid(resultIndex).success = false;
    RESULTvalid(resultIndex).cost = CFG.cost.failurePenalty;
    RESULTvalid(resultIndex).messages = [RESULTvalid(resultIndex).messages(:);{'Objective produced a nonfinite or negative cost.'}];
end
excessiveCost = Jvalid >= CFG.cost.failurePenalty;
Jvalid(excessiveCost) = CFG.cost.failurePenalty;
excessiveIndices = find(excessiveCost);
for localIndex = 1:numel(excessiveIndices)
    resultIndex = excessiveIndices(localIndex);
    RESULTvalid(resultIndex).success = false;
    RESULTvalid(resultIndex).cost = CFG.cost.failurePenalty;
end
J(validIndices) = Jvalid;
RESULT(validIndices) = RESULTvalid;
J = reshape(J,numberOfCandidates,1);
if numel(RESULT) ~= numberOfCandidates
    error('QuadrotorFramework:ControllerBatchFinalResultSize','Final RESULT array has an invalid size.');
end
end
function localValidateFinalLocalStageContract(STAGE)
stageId = double(STAGE.id);
objectiveType = lower(string(STAGE.objectiveType));
paths = string(STAGE.parameterPaths(:));
switch stageId
    case 1
        expectedObjective = "rate_pitch";
        expectedPaths = ["angularRate.pitch.Kp";"angularRate.pitch.Ki"];
    case 2
        expectedObjective = "attitude_pitch";
        expectedPaths = "attitude.pitch.Kp";
    case 3
        expectedObjective = "joint_roll_pitch";
        expectedPaths = ["angularRate.roll.Kp";"angularRate.roll.Ki";"attitude.roll.Kp";"angularRate.pitch.Kp";"angularRate.pitch.Ki";"attitude.pitch.Kp"];
    otherwise
        error('QuadrotorFramework:ControllerBatchStageID','Final local C2/L3 tuning supports exactly stages 1, 2, and 3.');
end
if objectiveType ~= expectedObjective
    error('QuadrotorFramework:ControllerBatchStageObjective','Stage %d must use objectiveType "%s", not "%s".',stageId,expectedObjective,objectiveType);
end
if numel(paths) ~= numel(expectedPaths) || ~all(paths == expectedPaths)
    error('QuadrotorFramework:ControllerBatchStageParameterContract','Stage %d parameter paths do not match the final local C2/L3 campaign.',stageId);
end
if numel(unique(paths)) ~= numel(paths)
    error('QuadrotorFramework:ControllerBatchDuplicateStageParameter','Stage %d contains duplicate gain paths.',stageId);
end
end
function R = localAnnotateResult(R,CFG)
R.controllerSet = string(CFG.experiment.controllerSet);
R.trajectoryID = double(CFG.experiment.trajectoryID);
R.feedbackSource = string(CFG.experiment.feedbackSource);
R.metricStateSource = string(CFG.experiment.metricStateSource);
if ~isfield(R,'plantModels') || isempty(R.plantModels)
    R.plantModels = double(CFG.experiment.plantModels(:));
end
if ~isfield(R,'plantWeights') || isempty(R.plantWeights)
    R.plantWeights = double(CFG.experiment.plantWeights(:));
end
if ~isfield(R,'runCosts')
    R.runCosts = [];
end
if ~isfield(R,'plantMeanCosts')
    R.plantMeanCosts = [];
end
end
function R = localEmptyResult(CFG,STAGE)
R = struct( ...
    'success',false, ...
    'cost',NaN, ...
    'stageID',double(STAGE.id), ...
    'stageName',string(STAGE.name), ...
    'z',[], ...
    'multipliers',[], ...
    'gainValues',[], ...
    'gainTable',table(), ...
    'metrics',[], ...
    'runSucceeded',[], ...
    'strictRunSucceeded',[], ...
    'metricsAvailable',[], ...
    'softBaselineAccepted',[], ...
    'strictMissionSuccess',false, ...
    'softBaselineUsed',false, ...
    'missionPolicy',"baseline", ...
    'messages',{{}}, ...
    'seedCosts',[], ...
    'plantModels',double(CFG.experiment.plantModels(:)), ...
    'plantWeights',double(CFG.experiment.plantWeights(:)), ...
    'runCosts',[], ...
    'plantMeanCosts',[], ...
    'controllerSet',string(CFG.experiment.controllerSet), ...
    'trajectoryID',double(CFG.experiment.trajectoryID), ...
    'feedbackSource',string(CFG.experiment.feedbackSource), ...
    'metricStateSource',string(CFG.experiment.metricStateSource));
end
