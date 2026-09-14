function [GAIN_TABLE,AUTOPILOT_OUT] = controller_tuning_gain_table(AUTOPILOT_IN,parameterPaths,newValues)
if nargin < 1 || isempty(AUTOPILOT_IN)
error('QuadrotorFramework:ControllerGainTableMissingAutopilot','AUTOPILOT structure is required.');
end
if ~isstruct(AUTOPILOT_IN)
error('QuadrotorFramework:ControllerGainTableInvalidAutopilot','AUTOPILOT must be a structure.');
end
AUTOPILOT_OUT = AUTOPILOT_IN;
canonicalPaths = {'angularRate.roll.Kp';'angularRate.roll.Ki';'angularRate.pitch.Kp';'angularRate.pitch.Ki';'angularRate.yaw.Kp';'angularRate.yaw.Ki';'attitude.roll.Kp';'attitude.pitch.Kp';'yaw.angle.Kp';'vertical.velocity.Kp';'vertical.altitude.Kp';'horizontal.velocity.x.Kp';'horizontal.velocity.x.Kd';'horizontal.velocity.y.Kp';'horizontal.position.north.Kp';'horizontal.position.east.Kp'};
canonicalBankFields = {'rollRateKp';'rollRateKi';'pitchRateKp';'pitchRateKi';'yawRateKp';'yawRateKi';'rollAttitudeKp';'pitchAttitudeKp';'yawAngleKp';'verticalVelocityKp';'verticalPositionKp';'xVelocityKp';'xVelocityKd';'yVelocityKp';'northPositionKp';'eastPositionKp'};
canonicalLabels = {'Angular Rate Roll Kp';'Angular Rate Roll Ki';'Angular Rate Pitch Kp';'Angular Rate Pitch Ki';'Angular Rate Yaw Kp';'Angular Rate Yaw Ki';'Roll Attitude Kp';'Pitch Attitude Kp';'Yaw Angle Kp';'Vertical Velocity Kp';'Vertical Position Kp';'Horizontal Velocity X Kp';'Horizontal Velocity X Kd';'Horizontal Velocity Y Kp';'Horizontal Position North Kp';'Horizontal Position East Kp'};
canonicalStage = {'Angular Rate Roll-Pitch';'Angular Rate Roll-Pitch';'Angular Rate Roll-Pitch';'Angular Rate Roll-Pitch';'Angular Rate Yaw';'Angular Rate Yaw';'Roll-Pitch Attitude';'Roll-Pitch Attitude';'Yaw Angle';'Vertical Velocity';'Vertical Position';'Horizontal Velocity';'Horizontal Velocity';'Horizontal Velocity';'Horizontal Position';'Horizontal Position'};
numberOfCanonicalGains = numel(canonicalPaths);
if ~isfield(AUTOPILOT_OUT,'info') || ~isstruct(AUTOPILOT_OUT.info)
error('QuadrotorFramework:ControllerGainTableMissingInfo','AUTOPILOT.info is required.');
end
if ~isfield(AUTOPILOT_OUT.info,'controllerGainSchema')
error('QuadrotorFramework:ControllerGainTableMissingSchema','AUTOPILOT.info.controllerGainSchema is required.');
end
schema = string(AUTOPILOT_OUT.info.controllerGainSchema);
if schema ~= "3.0"
error('QuadrotorFramework:ControllerGainTableSchema','Controller tuning requires controller gain schema 3.0.');
end
if ~isfield(AUTOPILOT_OUT.info,'activeController')
error('QuadrotorFramework:ControllerGainTableMissingActiveController','AUTOPILOT.info.activeController is required.');
end
controllerSet = upper(string(AUTOPILOT_OUT.info.activeController));
if ~ismember(controllerSet,["C1","C2"])
error('QuadrotorFramework:ControllerGainTableActiveController','AUTOPILOT.info.activeController must be C1 or C2.');
end
if ~isfield(AUTOPILOT_OUT,'controllerSets') || ~isstruct(AUTOPILOT_OUT.controllerSets)
error('QuadrotorFramework:ControllerGainTableMissingControllerSets','AUTOPILOT.controllerSets is required.');
end
controllerField = char(controllerSet);
if ~isfield(AUTOPILOT_OUT.controllerSets,controllerField) || ~isstruct(AUTOPILOT_OUT.controllerSets.(controllerField))
error('QuadrotorFramework:ControllerGainTableMissingControllerSet','AUTOPILOT.controllerSets.%s is required.',controllerField);
end
for canonicalGainIndex = 1:numberOfCanonicalGains
bankField = canonicalBankFields{canonicalGainIndex};
if ~isfield(AUTOPILOT_OUT.controllerSets.(controllerField),bankField)
error('QuadrotorFramework:ControllerGainTableMissingBankField','AUTOPILOT.controllerSets.%s.%s is required.',controllerField,bankField);
end
activeValue = localGetNestedField(AUTOPILOT_OUT,canonicalPaths{canonicalGainIndex});
bankValue = AUTOPILOT_OUT.controllerSets.(controllerField).(bankField);
if ~isscalar(activeValue) || ~isnumeric(activeValue) || ~isfinite(activeValue) || activeValue <= 0
error('QuadrotorFramework:ControllerGainTableInvalidActiveGain','Active gain "%s" must be a finite positive numeric scalar.',canonicalPaths{canonicalGainIndex});
end
if ~isscalar(bankValue) || ~isnumeric(bankValue) || ~isfinite(bankValue) || bankValue <= 0
error('QuadrotorFramework:ControllerGainTableInvalidBankGain','Controller-bank gain "%s.%s" must be a finite positive numeric scalar.',controllerField,bankField);
end
tolerance = max(1e-12,1e-10*max([1 abs(activeValue) abs(bankValue)]));
if abs(activeValue-bankValue) > tolerance
error('QuadrotorFramework:ControllerGainTableUnsynchronized','Active gain "%s" and controllerSets.%s.%s are not synchronized.',canonicalPaths{canonicalGainIndex},controllerField,bankField);
end
end
if nargin < 2 || isempty(parameterPaths)
parameterPaths = canonicalPaths;
else
if isstring(parameterPaths)
parameterPaths = cellstr(parameterPaths(:));
elseif ischar(parameterPaths)
parameterPaths = {parameterPaths};
end
if ~iscell(parameterPaths)
error('QuadrotorFramework:ControllerGainTablePaths','parameterPaths must be a char, string array, or cell array.');
end
parameterPaths = parameterPaths(:);
end
numberOfRequestedGains = numel(parameterPaths);
if numberOfRequestedGains < 1
error('QuadrotorFramework:ControllerGainTableEmptyPaths','At least one controller gain path is required.');
end
canonicalIndex = zeros(numberOfRequestedGains,1);
for parameterIndex = 1:numberOfRequestedGains
currentPath = char(parameterPaths{parameterIndex});
matchIndex = find(strcmp(canonicalPaths,currentPath),1,'first');
if isempty(matchIndex)
error('QuadrotorFramework:ControllerGainTableUnknownPath','Controller gain path "%s" is not part of the automatic tuning contract.',currentPath);
end
canonicalIndex(parameterIndex) = matchIndex;
end
if numel(unique(canonicalIndex)) ~= numberOfRequestedGains
error('QuadrotorFramework:ControllerGainTableDuplicatePath','Requested controller gain paths must be unique.');
end
oldValues = zeros(numberOfRequestedGains,1);
for parameterIndex = 1:numberOfRequestedGains
index = canonicalIndex(parameterIndex);
currentPath = canonicalPaths{index};
bankField = canonicalBankFields{index};
activeValue = localGetNestedField(AUTOPILOT_OUT,currentPath);
bankValue = AUTOPILOT_OUT.controllerSets.(controllerField).(bankField);
tolerance = max(1e-12,1e-10*max([1 abs(activeValue) abs(bankValue)]));
if abs(activeValue-bankValue) > tolerance
error('QuadrotorFramework:ControllerGainTableUnsynchronizedRequested','Requested gain "%s" is not synchronized with controllerSets.%s.%s.',currentPath,controllerField,bankField);
end
oldValues(parameterIndex) = activeValue;
end
wasModified = false(numberOfRequestedGains,1);
if nargin >= 3 && ~isempty(newValues)
newValues = double(newValues(:));
if numel(newValues) ~= numberOfRequestedGains
error('QuadrotorFramework:ControllerGainTableValueCount','Number of new gain values must match the number of requested parameter paths.');
end
if any(~isfinite(newValues))
error('QuadrotorFramework:ControllerGainTableFiniteValues','All controller gain values must be finite.');
end
if any(newValues <= 0)
error('QuadrotorFramework:ControllerGainTablePositiveValues','Automatic controller tuning only accepts strictly positive gain values.');
end
for parameterIndex = 1:numberOfRequestedGains
index = canonicalIndex(parameterIndex);
currentPath = canonicalPaths{index};
bankField = canonicalBankFields{index};
AUTOPILOT_OUT = localSetNestedField(AUTOPILOT_OUT,currentPath,newValues(parameterIndex));
AUTOPILOT_OUT.controllerSets.(controllerField).(bankField) = newValues(parameterIndex);
wasModified(parameterIndex) = abs(newValues(parameterIndex)-oldValues(parameterIndex)) > max(1e-14,eps(max(abs(oldValues(parameterIndex)),1)));
end
else
newValues = oldValues;
end
AUTOPILOT_OUT = localSynchronizeCompatibilityAliases(AUTOPILOT_OUT);
if isfield(AUTOPILOT_OUT.controllerSets.(controllerField),'source')
AUTOPILOT_OUT.info.controllerGainSource = AUTOPILOT_OUT.controllerSets.(controllerField).source;
end
if isfield(AUTOPILOT_OUT.controllerSets.(controllerField),'tuningCampaign')
AUTOPILOT_OUT.info.controllerTuningCampaign = AUTOPILOT_OUT.controllerSets.(controllerField).tuningCampaign;
end
effectiveValues = zeros(numberOfRequestedGains,1);
for parameterIndex = 1:numberOfRequestedGains
index = canonicalIndex(parameterIndex);
currentPath = canonicalPaths{index};
bankField = canonicalBankFields{index};
activeValue = localGetNestedField(AUTOPILOT_OUT,currentPath);
bankValue = AUTOPILOT_OUT.controllerSets.(controllerField).(bankField);
tolerance = max(1e-12,1e-10*max([1 abs(activeValue) abs(bankValue)]));
if abs(activeValue-bankValue) > tolerance
error('QuadrotorFramework:ControllerGainTableReadbackMismatch','Effective gain "%s" does not match controllerSets.%s.%s.',currentPath,controllerField,bankField);
end
effectiveValues(parameterIndex) = activeValue;
end
ParameterPath = strings(numberOfRequestedGains,1);
Label = strings(numberOfRequestedGains,1);
Stage = strings(numberOfRequestedGains,1);
for parameterIndex = 1:numberOfRequestedGains
index = canonicalIndex(parameterIndex);
ParameterPath(parameterIndex) = string(canonicalPaths{index});
Label(parameterIndex) = string(canonicalLabels{index});
Stage(parameterIndex) = string(canonicalStage{index});
end
BaselineValue = oldValues;
EffectiveValue = effectiveValues;
Multiplier = EffectiveValue ./ BaselineValue;
Log10Multiplier = log10(Multiplier);
Modified = wasModified;
GAIN_TABLE = table(ParameterPath,Label,Stage,BaselineValue,EffectiveValue,Multiplier,Log10Multiplier,Modified);
for canonicalGainIndex = 1:numberOfCanonicalGains
currentPath = canonicalPaths{canonicalGainIndex};
bankField = canonicalBankFields{canonicalGainIndex};
activeValue = localGetNestedField(AUTOPILOT_OUT,currentPath);
bankValue = AUTOPILOT_OUT.controllerSets.(controllerField).(bankField);
if ~isscalar(activeValue) || ~isnumeric(activeValue) || ~isfinite(activeValue) || activeValue <= 0
error('QuadrotorFramework:ControllerGainTableFinalActiveValidation','Invalid effective controller gain "%s".',currentPath);
end
if ~isscalar(bankValue) || ~isnumeric(bankValue) || ~isfinite(bankValue) || bankValue <= 0
error('QuadrotorFramework:ControllerGainTableFinalBankValidation','Invalid controller-bank gain "%s.%s".',controllerField,bankField);
end
tolerance = max(1e-12,1e-10*max([1 abs(activeValue) abs(bankValue)]));
if abs(activeValue-bankValue) > tolerance
error('QuadrotorFramework:ControllerGainTableFinalSynchronization','Final active gain "%s" does not match controllerSets.%s.%s.',currentPath,controllerField,bankField);
end
end
end
function AUTOPILOT = localSynchronizeCompatibilityAliases(AUTOPILOT)
if isfield(AUTOPILOT,'horizontal') && isfield(AUTOPILOT.horizontal,'position') && isfield(AUTOPILOT.horizontal.position,'north')
north = AUTOPILOT.horizontal.position.north;
if isfield(north,'Kp')
AUTOPILOT.horizontal.position.Kp = north.Kp;
end
if isfield(north,'Ki')
AUTOPILOT.horizontal.position.Ki = north.Ki;
end
if isfield(north,'Kd')
AUTOPILOT.horizontal.position.Kd = north.Kd;
end
if isfield(north,'N')
AUTOPILOT.horizontal.position.N = north.N;
end
end
if isfield(AUTOPILOT,'horizontal') && isfield(AUTOPILOT.horizontal,'velocity') && isfield(AUTOPILOT.horizontal.velocity,'x')
xVelocity = AUTOPILOT.horizontal.velocity.x;
if isfield(xVelocity,'Kp')
AUTOPILOT.horizontal.velocity.Kp = xVelocity.Kp;
end
if isfield(xVelocity,'Ki')
AUTOPILOT.horizontal.velocity.Ki = xVelocity.Ki;
end
if isfield(xVelocity,'Kd')
AUTOPILOT.horizontal.velocity.Kd = xVelocity.Kd;
end
if isfield(xVelocity,'N')
AUTOPILOT.horizontal.velocity.N = xVelocity.N;
end
end
if isfield(AUTOPILOT,'attitude') && isfield(AUTOPILOT.attitude,'roll')
if ~isfield(AUTOPILOT.attitude,'rollPitch') || ~isstruct(AUTOPILOT.attitude.rollPitch)
AUTOPILOT.attitude.rollPitch = struct();
end
rollAttitude = AUTOPILOT.attitude.roll;
if isfield(rollAttitude,'Kp')
AUTOPILOT.attitude.rollPitch.Kp = rollAttitude.Kp;
end
if isfield(rollAttitude,'Ki')
AUTOPILOT.attitude.rollPitch.Ki = rollAttitude.Ki;
end
if isfield(rollAttitude,'Kd')
AUTOPILOT.attitude.rollPitch.Kd = rollAttitude.Kd;
end
if isfield(rollAttitude,'N')
AUTOPILOT.attitude.rollPitch.N = rollAttitude.N;
end
end
if isfield(AUTOPILOT,'angularRate') && isfield(AUTOPILOT.angularRate,'roll')
if ~isfield(AUTOPILOT.angularRate,'rollPitch') || ~isstruct(AUTOPILOT.angularRate.rollPitch)
AUTOPILOT.angularRate.rollPitch = struct();
end
rollRate = AUTOPILOT.angularRate.roll;
if isfield(rollRate,'Kp')
AUTOPILOT.angularRate.rollPitch.Kp = rollRate.Kp;
end
if isfield(rollRate,'Ki')
AUTOPILOT.angularRate.rollPitch.Ki = rollRate.Ki;
end
if isfield(rollRate,'Kd')
AUTOPILOT.angularRate.rollPitch.Kd = rollRate.Kd;
end
if isfield(rollRate,'N')
AUTOPILOT.angularRate.rollPitch.N = rollRate.N;
end
end
if isfield(AUTOPILOT,'vertical') && isfield(AUTOPILOT.vertical,'altitude')
AUTOPILOT.vertical.position = AUTOPILOT.vertical.altitude;
end
if ~isfield(AUTOPILOT,'rate') || ~isstruct(AUTOPILOT.rate)
AUTOPILOT.rate = struct();
end
if isfield(AUTOPILOT,'angularRate')
if isfield(AUTOPILOT.angularRate,'rollPitch')
AUTOPILOT.rate.rollPitch = AUTOPILOT.angularRate.rollPitch;
end
if isfield(AUTOPILOT.angularRate,'yaw')
AUTOPILOT.rate.yaw = AUTOPILOT.angularRate.yaw;
end
end
end
function value = localGetNestedField(structure,fieldPath)
parts = strsplit(char(fieldPath),'.');
value = structure;
for partIndex = 1:numel(parts)
currentField = parts{partIndex};
if ~isstruct(value) || ~isfield(value,currentField)
error('QuadrotorFramework:ControllerGainTableMissingField','AUTOPILOT does not contain field path "%s".',fieldPath);
end
value = value.(currentField);
end
end
function structure = localSetNestedField(structure,fieldPath,newValue)
parts = strsplit(char(fieldPath),'.');
structure = localSetNestedRecursive(structure,parts,newValue);
end
function structure = localSetNestedRecursive(structure,parts,newValue)
currentField = parts{1};
if ~isfield(structure,currentField)
error('QuadrotorFramework:ControllerGainTableMissingSetField','Cannot set missing AUTOPILOT field "%s".',currentField);
end
if numel(parts) == 1
structure.(currentField) = newValue;
return;
end
if ~isstruct(structure.(currentField))
error('QuadrotorFramework:ControllerGainTableInvalidNestedField','AUTOPILOT field "%s" is not a structure.',currentField);
end
structure.(currentField) = localSetNestedRecursive(structure.(currentField),parts(2:end),newValue);
end
