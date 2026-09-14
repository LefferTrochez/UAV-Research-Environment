function [AUTOPILOT_TUNED,GAIN_TABLE] = apply_controller_tuning_result(tuningResult)
narginchk(1,1);
if ~isstruct(tuningResult)
error('QuadrotorFramework:ControllerApplyInvalidResult','tuningResult must be a controller-tuning result structure.');
end
requiredFields = {'FinalAutopilot';'FinalValidationPassed';'CompletedStages';'Config'};
for fieldIndex = 1:numel(requiredFields)
fieldName = requiredFields{fieldIndex};
if ~isfield(tuningResult,fieldName)
error('QuadrotorFramework:ControllerApplyMissingField','Tuning result does not contain field "%s".',fieldName);
end
end
if ~isfield(tuningResult,'schemaVersion')
error('QuadrotorFramework:ControllerApplyMissingSchema','Tuning result does not contain schemaVersion. Controller-tuning schema 3.0 is required.');
end
resultSchema = double(tuningResult.schemaVersion);
if ~isscalar(resultSchema) || ~isfinite(resultSchema) || resultSchema < 3.0
error('QuadrotorFramework:ControllerApplyOldSchema','Controller-tuning result schema %.3g is not compatible. Schema 3.0 or newer is required.',resultSchema);
end
if ~isfield(tuningResult,'ControllerGainSchema')
error('QuadrotorFramework:ControllerApplyMissingGainSchema','Tuning result does not contain ControllerGainSchema.');
end
controllerGainSchema = string(tuningResult.ControllerGainSchema);
if controllerGainSchema ~= "3.0"
error('QuadrotorFramework:ControllerApplyGainSchema','Controller tuning result uses gain schema "%s". Gain schema 3.0 is required.',controllerGainSchema);
end
CFG = tuningResult.Config;
if ~isstruct(CFG)
error('QuadrotorFramework:ControllerApplyInvalidConfig','Controller tuning configuration is invalid.');
end
requiredConfigFields = {'numberOfStages';'stages';'modelName';'experiment';'totalTunableGains';'totalStageParameters';'policy'};
for fieldIndex = 1:numel(requiredConfigFields)
fieldName = requiredConfigFields{fieldIndex};
if ~isfield(CFG,fieldName)
error('QuadrotorFramework:ControllerApplyMissingConfigField','Controller tuning Config.%s is required.',fieldName);
end
end
if CFG.numberOfStages ~= 3
error('QuadrotorFramework:ControllerApplyStageCount','The final local C2/L3 campaign requires exactly 3 tuning stages. Result contains %d.',CFG.numberOfStages);
end
if CFG.totalTunableGains ~= 6
error('QuadrotorFramework:ControllerApplyConfiguredGainCount','The final local C2/L3 campaign requires exactly 6 unique tuned gains. Config contains %d.',CFG.totalTunableGains);
end
if CFG.totalStageParameters ~= 9
error('QuadrotorFramework:ControllerApplyStageParameterCount','The final local C2/L3 campaign requires exactly 9 stage parameter entries. Config contains %d.',CFG.totalStageParameters);
end
if ~isstruct(CFG.policy) || ~isfield(CFG.policy,'allowSequentialRetuning') || ~logical(CFG.policy.allowSequentialRetuning)
error('QuadrotorFramework:ControllerApplySequentialRetuning','The final local C2/L3 campaign requires sequential retuning to be enabled.');
end
if ~isstruct(CFG.experiment)
error('QuadrotorFramework:ControllerApplyExperimentConfig','Config.experiment must be a structure.');
end
if ~isfield(CFG.experiment,'controllerSet') || ~strcmpi(string(CFG.experiment.controllerSet),"C2")
error('QuadrotorFramework:ControllerApplyControllerSet','This application routine expects a C2 tuning result.');
end
if ~isfield(CFG.experiment,'plantModels') || ~isequal(double(CFG.experiment.plantModels(:).'),3)
error('QuadrotorFramework:ControllerApplyPlantModels','C2 tuning results must correspond to L3 only.');
end
if ~isfield(CFG.experiment,'trajectoryID') || double(CFG.experiment.trajectoryID) ~= 2
error('QuadrotorFramework:ControllerApplyTrajectory','C2 tuning results must correspond to trajectory 2.');
end
if ~isfield(CFG.experiment,'feedbackSource') || ~strcmpi(string(CFG.experiment.feedbackSource),"EST")
error('QuadrotorFramework:ControllerApplyFeedback','C2 tuning results must use EST controller feedback.');
end
if ~isfield(CFG.experiment,'metricStateSource') || ~strcmpi(string(CFG.experiment.metricStateSource),"TRUE")
error('QuadrotorFramework:ControllerApplyMetricState','C2 tuning performance metrics must use TRUE state.');
end
expectedStageObjectives = ["rate_pitch";"attitude_pitch";"joint_roll_pitch"];
expectedStagePaths = {["angularRate.pitch.Kp";"angularRate.pitch.Ki"];"attitude.pitch.Kp";["angularRate.roll.Kp";"angularRate.roll.Ki";"attitude.roll.Kp";"angularRate.pitch.Kp";"angularRate.pitch.Ki";"attitude.pitch.Kp"]};
for stageIndex = 1:CFG.numberOfStages
STAGE = CFG.stages(stageIndex);
if ~isfield(STAGE,'objectiveType') || lower(string(STAGE.objectiveType)) ~= expectedStageObjectives(stageIndex)
error('QuadrotorFramework:ControllerApplyStageObjective','Stage %d objectiveType does not match the final local C2/L3 campaign.',stageIndex);
end
if ~isfield(STAGE,'parameterPaths')
error('QuadrotorFramework:ControllerApplyStageParameterPaths','Config Stage %d does not contain parameterPaths.',stageIndex);
end
stagePaths = string(STAGE.parameterPaths(:));
expectedPaths = string(expectedStagePaths{stageIndex}(:));
if numel(stagePaths) ~= numel(expectedPaths) || ~all(stagePaths == expectedPaths)
error('QuadrotorFramework:ControllerApplyStagePathContract','Stage %d gain paths do not match the final local C2/L3 campaign.',stageIndex);
end
end
completedStages = double(tuningResult.CompletedStages);
if ~isscalar(completedStages) || ~isfinite(completedStages) || completedStages ~= round(completedStages)
error('QuadrotorFramework:ControllerApplyCompletedStagesValue','CompletedStages must be a finite integer scalar.');
end
if completedStages ~= CFG.numberOfStages
error('QuadrotorFramework:ControllerApplyIncompleteTuning','Controller tuning completed only %d of %d stages. The result will not be applied.',completedStages,CFG.numberOfStages);
end
validationPassed = tuningResult.FinalValidationPassed;
if ~isscalar(validationPassed) || ~(islogical(validationPassed) || isnumeric(validationPassed)) || ~isfinite(double(validationPassed)) || ~ismember(double(validationPassed),[0 1])
error('QuadrotorFramework:ControllerApplyValidationFlag','FinalValidationPassed must be a finite scalar logical value.');
end
validationPassed = logical(validationPassed);
if ~validationPassed
error('QuadrotorFramework:ControllerApplyValidationFailed','Final controller validation did not pass. The tuned controller will not be applied.');
end
if isfield(tuningResult,'FinalValidation') && isstruct(tuningResult.FinalValidation) && isfield(tuningResult.FinalValidation,'success')
detailedValidationPass = logical(tuningResult.FinalValidation.success);
if ~isscalar(detailedValidationPass) || ~detailedValidationPass
error('QuadrotorFramework:ControllerApplyDetailedValidation','FinalValidationPassed is true but FinalValidation does not report success.');
end
end
AUTOPILOT_RESULT = tuningResult.FinalAutopilot;
if ~isstruct(AUTOPILOT_RESULT)
error('QuadrotorFramework:ControllerApplyInvalidAutopilot','FinalAutopilot is not a valid AUTOPILOT structure.');
end
if ~isfield(AUTOPILOT_RESULT,'info') || ~isstruct(AUTOPILOT_RESULT.info)
error('QuadrotorFramework:ControllerApplyMissingAutopilotInfo','FinalAutopilot.info is required.');
end
if ~isfield(AUTOPILOT_RESULT.info,'controllerGainSchema') || string(AUTOPILOT_RESULT.info.controllerGainSchema) ~= "3.0"
error('QuadrotorFramework:ControllerApplyAutopilotGainSchema','FinalAutopilot must use controller gain schema 3.0.');
end
if ~isfield(AUTOPILOT_RESULT.info,'activeController') || ~strcmpi(string(AUTOPILOT_RESULT.info.activeController),"C2")
error('QuadrotorFramework:ControllerApplyActiveController','FinalAutopilot must have C2 active.');
end
if ~isfield(AUTOPILOT_RESULT,'controllerSets') || ~isstruct(AUTOPILOT_RESULT.controllerSets) || ~isfield(AUTOPILOT_RESULT.controllerSets,'C1') || ~isfield(AUTOPILOT_RESULT.controllerSets,'C2')
error('QuadrotorFramework:ControllerApplyControllerBanks','FinalAutopilot must contain controllerSets.C1 and controllerSets.C2.');
end
[GAIN_TABLE,AUTOPILOT_RESULT] = controller_tuning_gain_table(AUTOPILOT_RESULT);
if isempty(GAIN_TABLE)
error('QuadrotorFramework:ControllerApplyEmptyGainTable','Unable to obtain the final controller gain table.');
end
if height(GAIN_TABLE) ~= 16
error('QuadrotorFramework:ControllerApplyGainCount','Final controller contains %d active tunable gains. Exactly 16 are required.',height(GAIN_TABLE));
end
if any(~isfinite(GAIN_TABLE.EffectiveValue)) || any(GAIN_TABLE.EffectiveValue <= 0)
error('QuadrotorFramework:ControllerApplyInvalidGain','Final controller contains invalid active gain values.');
end
configuredPaths = strings(0,1);
for stageIndex = 1:CFG.numberOfStages
STAGE = CFG.stages(stageIndex);
stagePaths = string(STAGE.parameterPaths(:));
configuredPaths = [configuredPaths;stagePaths];
controller_tuning_gain_table(AUTOPILOT_RESULT,STAGE.parameterPaths);
end
if numel(configuredPaths) ~= CFG.totalStageParameters
error('QuadrotorFramework:ControllerApplyConfigStageParameterCount','The configured stages contain %d parameter entries. Exactly %d are required.',numel(configuredPaths),CFG.totalStageParameters);
end
uniqueConfiguredPaths = unique(configuredPaths,'stable');
if numel(uniqueConfiguredPaths) ~= CFG.totalTunableGains
error('QuadrotorFramework:ControllerApplyUniqueGainCount','The configured stages contain %d unique gains. Exactly %d are required.',numel(uniqueConfiguredPaths),CFG.totalTunableGains);
end
expectedUniquePaths = ["angularRate.roll.Kp";"angularRate.roll.Ki";"attitude.roll.Kp";"angularRate.pitch.Kp";"angularRate.pitch.Ki";"attitude.pitch.Kp"];
if ~all(ismember(expectedUniquePaths,uniqueConfiguredPaths)) || ~all(ismember(uniqueConfiguredPaths,expectedUniquePaths))
error('QuadrotorFramework:ControllerApplyGainContractMismatch','The tuning configuration does not describe the expected six roll/pitch gains.');
end
pathCounts = zeros(numel(expectedUniquePaths),1);
for pathIndex = 1:numel(expectedUniquePaths)
pathCounts(pathIndex) = nnz(configuredPaths == expectedUniquePaths(pathIndex));
end
if ~isequal(pathCounts,[1;1;1;2;2;2])
error('QuadrotorFramework:ControllerApplySequentialRetuningContract','The final local campaign requires roll gains once and pitch gains twice across the three stages.');
end
authoritativePaths = string(GAIN_TABLE.ParameterPath);
if ~all(ismember(uniqueConfiguredPaths,authoritativePaths))
error('QuadrotorFramework:ControllerApplyAuthoritativeGainContract','One or more configured tuning gains are not present in the final C2 controller gain table.');
end
if ~isfield(tuningResult,'FinalGainTable') || ~istable(tuningResult.FinalGainTable) || isempty(tuningResult.FinalGainTable)
error('QuadrotorFramework:ControllerApplyMissingFinalGainTable','A validated FinalGainTable is required for the final local C2/L3 campaign.');
end
savedGainTable = tuningResult.FinalGainTable;
requiredSavedColumns = {'ParameterPath';'InitialValue';'TunedValue'};
for columnIndex = 1:numel(requiredSavedColumns)
columnName = requiredSavedColumns{columnIndex};
if ~ismember(columnName,savedGainTable.Properties.VariableNames)
error('QuadrotorFramework:ControllerApplySavedGainColumn','Saved FinalGainTable does not contain required column "%s".',columnName);
end
end
if height(savedGainTable) ~= 16
error('QuadrotorFramework:ControllerApplySavedGainCount','Saved FinalGainTable must contain exactly 16 active C2 controller gains.');
end
savedPaths = string(savedGainTable.ParameterPath);
currentPaths = string(GAIN_TABLE.ParameterPath);
if ~isequal(savedPaths,currentPaths)
error('QuadrotorFramework:ControllerApplySavedGainOrder','Saved FinalGainTable and FinalAutopilot use different gain paths or ordering.');
end
savedValues = double(savedGainTable.TunedValue);
initialValues = double(savedGainTable.InitialValue);
effectiveValues = double(GAIN_TABLE.EffectiveValue);
difference = abs(savedValues-effectiveValues);
tolerance = max(1e-12,1e-10.*max(abs(effectiveValues),1));
if any(difference > tolerance)
error('QuadrotorFramework:ControllerApplySavedGainMismatch','Saved FinalGainTable does not match the gains contained in FinalAutopilot.');
end
nonTargetMask = ~ismember(savedPaths,uniqueConfiguredPaths);
nonTargetDifference = abs(savedValues(nonTargetMask)-initialValues(nonTargetMask));
nonTargetTolerance = max(1e-12,1e-10.*max(abs(initialValues(nonTargetMask)),1));
if any(nonTargetDifference > nonTargetTolerance)
error('QuadrotorFramework:ControllerApplyNonTargetGainChanged','At least one C2 gain outside the six-gain final-local tuning set changed. Result will not be applied.');
end
modelName = CFG.modelName;
if bdIsLoaded(modelName)
simulationStatus = get_param(modelName,'SimulationStatus');
if ~strcmpi(simulationStatus,'stopped')
error('QuadrotorFramework:ControllerApplyModelRunning','Model "%s" is currently running. Stop the simulation before applying tuned gains.',modelName);
end
end
currentAutopilotExists = evalin('base','exist(''AUTOPILOT'',''var'')');
if ~currentAutopilotExists
error('QuadrotorFramework:ControllerApplyMissingCurrentAutopilot','Base-workspace AUTOPILOT is required so that controller set C1 can be preserved.');
end
AUTOPILOT_CURRENT = evalin('base','AUTOPILOT');
if ~isstruct(AUTOPILOT_CURRENT)
error('QuadrotorFramework:ControllerApplyCurrentAutopilot','Current base-workspace AUTOPILOT is not a structure.');
end
if ~isfield(AUTOPILOT_CURRENT,'info') || ~isstruct(AUTOPILOT_CURRENT.info) || ~isfield(AUTOPILOT_CURRENT.info,'controllerGainSchema') || string(AUTOPILOT_CURRENT.info.controllerGainSchema) ~= "3.0"
error('QuadrotorFramework:ControllerApplyCurrentSchema','Current base-workspace AUTOPILOT must use controller gain schema 3.0.');
end
if ~isfield(AUTOPILOT_CURRENT,'controllerSets') || ~isstruct(AUTOPILOT_CURRENT.controllerSets) || ~isfield(AUTOPILOT_CURRENT.controllerSets,'C1') || ~isfield(AUTOPILOT_CURRENT.controllerSets,'C2')
error('QuadrotorFramework:ControllerApplyCurrentBanks','Current base-workspace AUTOPILOT must contain controllerSets.C1 and controllerSets.C2.');
end
if ~isfield(AUTOPILOT_CURRENT.info,'activeController') || ~strcmpi(string(AUTOPILOT_CURRENT.info.activeController),"C2")
error('QuadrotorFramework:ControllerApplyCurrentActiveController','Initialize the project with L3 so that C2 is active before applying a C2 tuning result.');
end
C1_BEFORE = AUTOPILOT_CURRENT.controllerSets.C1;
assignin('base','AUTOPILOT_BEFORE_CONTROLLER_TUNING_APPLY',AUTOPILOT_CURRENT);
AUTOPILOT_TUNED = AUTOPILOT_RESULT;
AUTOPILOT_TUNED.controllerSets.C1 = C1_BEFORE;
AUTOPILOT_TUNED.info.activeController = "C2";
if isfield(AUTOPILOT_TUNED.controllerSets.C2,'source')
AUTOPILOT_TUNED.info.controllerGainSource = AUTOPILOT_TUNED.controllerSets.C2.source;
end
if isfield(AUTOPILOT_TUNED.controllerSets.C2,'tuningCampaign')
AUTOPILOT_TUNED.info.controllerTuningCampaign = AUTOPILOT_TUNED.controllerSets.C2.tuningCampaign;
end
[GAIN_TABLE,AUTOPILOT_TUNED] = controller_tuning_gain_table(AUTOPILOT_TUNED);
if ~isequaln(AUTOPILOT_TUNED.controllerSets.C1,C1_BEFORE)
error('QuadrotorFramework:ControllerApplyC2Protection','Controller set C1 changed while applying the C2 tuning result.');
end
previousTuningActiveExists = evalin('base','exist(''CONTROLLER_TUNING_ACTIVE'',''var'')');
if previousTuningActiveExists
previousTuningActive = evalin('base','CONTROLLER_TUNING_ACTIVE');
else
previousTuningActive = [];
end
previousAppliedExists = evalin('base','exist(''CONTROLLER_TUNING_APPLIED'',''var'')');
if previousAppliedExists
previousApplied = evalin('base','CONTROLLER_TUNING_APPLIED');
else
previousApplied = [];
end
previousAppliedSetExists = evalin('base','exist(''CONTROLLER_TUNING_APPLIED_SET'',''var'')');
if previousAppliedSetExists
previousAppliedSet = evalin('base','CONTROLLER_TUNING_APPLIED_SET');
else
previousAppliedSet = [];
end
try
assignin('base','AUTOPILOT',AUTOPILOT_TUNED);
assignin('base','CONTROLLER_TUNING_ACTIVE',true);
assignin('base','CONTROLLER_TUNING_APPLIED',true);
assignin('base','CONTROLLER_TUNING_APPLIED_SET',"C2");
AUTOPILOT_VERIFY = evalin('base','AUTOPILOT');
[VERIFY_TABLE,AUTOPILOT_VERIFY] = controller_tuning_gain_table(AUTOPILOT_VERIFY);
if height(VERIFY_TABLE) ~= height(GAIN_TABLE)
error('QuadrotorFramework:ControllerApplyVerificationSize','Applied AUTOPILOT failed gain-table verification.');
end
if ~all(string(VERIFY_TABLE.ParameterPath) == string(GAIN_TABLE.ParameterPath))
error('QuadrotorFramework:ControllerApplyVerificationPaths','Applied AUTOPILOT gain paths do not match the validated tuning result.');
end
verificationDifference = abs(VERIFY_TABLE.EffectiveValue-GAIN_TABLE.EffectiveValue);
verificationTolerance = max(1e-12,1e-10.*max(abs(GAIN_TABLE.EffectiveValue),1));
if any(verificationDifference > verificationTolerance)
error('QuadrotorFramework:ControllerApplyVerification','Applied AUTOPILOT does not match the tuned C2 controller.');
end
if ~isequaln(AUTOPILOT_VERIFY.controllerSets.C1,C1_BEFORE)
error('QuadrotorFramework:ControllerApplyC2Verification','Controller set C1 changed during base-workspace application.');
end
tuningActiveVerify = evalin('base','CONTROLLER_TUNING_ACTIVE');
appliedVerify = evalin('base','CONTROLLER_TUNING_APPLIED');
appliedSetVerify = string(evalin('base','CONTROLLER_TUNING_APPLIED_SET'));
if ~logical(tuningActiveVerify) || ~logical(appliedVerify) || appliedSetVerify ~= "C2"
error('QuadrotorFramework:ControllerApplyFlagVerification','Controller protection flags were not written correctly.');
end
catch ME
assignin('base','AUTOPILOT',AUTOPILOT_CURRENT);
if previousTuningActiveExists
assignin('base','CONTROLLER_TUNING_ACTIVE',previousTuningActive);
else
evalin('base','clear(''CONTROLLER_TUNING_ACTIVE'')');
end
if previousAppliedExists
assignin('base','CONTROLLER_TUNING_APPLIED',previousApplied);
else
evalin('base','clear(''CONTROLLER_TUNING_APPLIED'')');
end
if previousAppliedSetExists
assignin('base','CONTROLLER_TUNING_APPLIED_SET',previousAppliedSet);
else
evalin('base','clear(''CONTROLLER_TUNING_APPLIED_SET'')');
end
error('QuadrotorFramework:ControllerApplyTransactionFailed','Tuned controller application failed and the previous workspace state was restored.\n\n%s',ME.message);
end
fprintf('\n');
fprintf('==============================================================\n');
fprintf(' VALIDATED C2 FINAL LOCAL CONTROLLER APPLIED — SCHEMA 3.0\n');
fprintf('==============================================================\n');
fprintf('Controller set:            C2\n');
fprintf('Plant models:              L3\n');
fprintf('Trajectory ID:             2\n');
fprintf('Controller feedback:       EST\n');
fprintf('Metric state source:       TRUE\n');
fprintf('Completed stages:          %d / %d\n',tuningResult.CompletedStages,CFG.numberOfStages);
fprintf('Active controller gains:   %d\n',height(GAIN_TABLE));
fprintf('Unique tuned gains:        %d\n',CFG.totalTunableGains);
fprintf('Stage parameter entries:   %d\n',CFG.totalStageParameters);
fprintf('Final validation:          PASS\n');
fprintf('Base workspace AUTOPILOT:  UPDATED\n');
fprintf('Controller gain schema:    3.0\n');
fprintf('Controller set C1:         PRESERVED\n');
fprintf('CONTROLLER_TUNING_APPLIED: TRUE\n');
fprintf('Applied set:               C2\n');
fprintf('InitFcn protection flag:   TRUE\n');
fprintf('Previous controller backup: AUTOPILOT_BEFORE_CONTROLLER_TUNING_APPLY\n');
fprintf('\n');
fprintf('Applied C2 controller gains:\n\n');
disp(GAIN_TABLE(:,{'Stage','Label','EffectiveValue'}));
fprintf('\n');
fprintf('==============================================================\n\n');
end
