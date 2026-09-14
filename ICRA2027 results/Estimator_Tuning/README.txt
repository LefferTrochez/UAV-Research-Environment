ESTIMATOR TUNING
================

Automatic simultaneous tuning of the 24 EKF covariance parameters
(Q, R, P0 and robust initialization P0) using surrogateopt + PARSIM.

The current configuration is a 30-evaluation smoke test intended to verify
the complete tuning pipeline before launching the definitive 300-evaluation
campaign.


=======================================================================
1. OPEN MATLAB IN THE PROJECT ROOT
=======================================================================

Open MATLAB in:

...\Quadrotor Framework\v1.0.0


=======================================================================
2. ADD THE TUNING FOLDER TO THE MATLAB PATH
=======================================================================

Run:

addpath(fullfile(pwd,'Estimator_Tuning'));
rehash;


=======================================================================
3. START FROM THE NOMINAL ESTIMATOR
=======================================================================

Before initializing the project, remove any tuning override left from a
previous experiment:

clear ESTIMATOR_TUNING_OVERRIDE
clear ESTIMATOR_TUNING_SILENT

Then initialize the project normally:

initialize_project


=======================================================================
4. VERIFY THE REQUIRED SIMULATION CONFIGURATION
=======================================================================

Before tuning, verify:

- UAV model: L1
- Disturbances: disabled
- Operator mode: automatic
- Controller feedback Manual Switch: TRUE
- Simulation is stopped
- Quadrotor_Framework contains no unsaved changes

IMPORTANT:

TRUE feedback is required only for the controller state-feedback path.

TRUE_STATES are NEVER supplied to INS_EKF.

The EKF continues to use only the simulated sensor measurements.

Estimator health / NavValid is still active during tuning. Therefore an
invalid covariance candidate can trigger a navigation failsafe even while
the controller uses TRUE state feedback.


=======================================================================
5. SAVE THE SIMULINK MODEL
=======================================================================

After setting the Manual Switch to TRUE, save the model:

save_system('Quadrotor_Framework')

or press:

Ctrl + S

PARSIM must not be started while the model contains unsaved changes.


=======================================================================
6. CLEAR THE ACTIVE TUNING FUNCTIONS
=======================================================================

Before running a new campaign:

clear estimator_tuning_config
clear tune_state_estimator
clear evaluate_estimator_candidate
clear evaluate_estimator_candidates_parallel
rehash


=======================================================================
7. OPTIONAL NOMINAL SMOKE TEST
=======================================================================

A single-seed nominal test can be performed before launching the optimizer:

CFG = estimator_tuning_config;

CFG_test = CFG;
CFG_test.training.seedOffsets = 0;

nominalVector = ESTIMATOR.tuning.nominalVector(:);
z0 = zeros(24,1);

[J0, BASELINE_TEST] = evaluate_estimator_candidate( ...
    z0, ...
    CFG_test, ...
    nominalVector, ...
    [], ...
    'serial');

BASELINE_TEST.success
BASELINE_TEST.meanMetrics
BASELINE_TEST.messages

Expected:

BASELINE_TEST.success = 1


=======================================================================
8. CURRENT 30-EVALUATION SMOKE TEST
=======================================================================

The current estimator_tuning_config.m uses:

MaxFunctionEvaluations = 30
MinSurrogatePoints      = 25
BatchSize               = 5
Training seeds          = [0 37 91]
Validation seeds        = [151 307 509]
Fast Restart            = false
Parallel execution      = true

One optimizer evaluation means:

1 EKF candidate x 3 training sensor-noise seeds

Therefore the 30-evaluation smoke test requires up to approximately:

30 candidates x 3 seeds = 90 training simulations

Additional nominal, preflight, final verification and validation
simulations occur outside this optimization budget.


=======================================================================
9. RUN THE TUNING
=======================================================================

Run:

TUNING_RESULT = tune_state_estimator;


=======================================================================
10. CANDIDATE ACCEPTANCE RULE
=======================================================================

A candidate seed is valid only if the mission satisfies the complete
mission-level acceptance sequence:

TAKEOFF
-> vehicle becomes airborne
-> CGS Complete is reached
-> no ABORTED / navigation-failsafe phase occurs
-> final Landed is confirmed

A failed mission is NOT scored as a successful estimator run.

If ANY training seed fails, the complete candidate receives the configured
failure penalty.

The generic COMPLETE Stateflow phase is recorded as a diagnostic, but CGS
Complete is the authoritative navigation-completion event.


=======================================================================
11. WHAT TO CHECK AFTER THE 30-EVALUATION TEST
=======================================================================

The final report prints:

- Function evaluations
- Valid mission candidates
- Failed candidates
- Valid candidate fraction
- Best training cost
- Validation baseline status
- Validation status
- Validation cost
- Validation improvement
- Total execution time

The purpose of this 30-evaluation campaign is NOT to obtain the final EKF.

Its purpose is to verify that:

- surrogateopt operates correctly
- PARSIM operates correctly
- all 24 parameters are applied correctly
- failed missions are rejected
- valid missions receive finite costs
- the optimizer can identify valid candidates
- independent validation executes correctly
- all results are saved correctly


=======================================================================
12. VALIDATION FAILURE
=======================================================================

If the best training candidate fails one or more independent validation
seeds, the tuning script does NOT discard the campaign.

The complete optimization and validation results are still saved for
diagnosis.

In that case:

ValidationPassed = false
ValidationImproved = false

The candidate must NOT be considered the final estimator.


=======================================================================
13. RESULTS
=======================================================================

Each tuning campaign creates a new folder inside:

Estimator_Tuning_Results/

Example:

Estimator_Tuning_Results/
    EKF_Tuning_YYYY-MM-DD_HH-MM-SS/

The folder contains:

- tuning configuration snapshot
- code snapshot
- nominal training baseline
- surrogateopt checkpoint
- optimizer trials
- best-parameter CSV
- independent validation result
- complete TUNING_RESULT structure


=======================================================================
14. DEFINITIVE 300-EVALUATION CAMPAIGN
=======================================================================

Only after the 30-evaluation smoke test operates correctly should the
definitive campaign be launched.

In estimator_tuning_config.m change:

CFG.optimizer.maxFunctionEvaluations = ...
    300;

CFG.optimizer.minSurrogatePoints = ...
    48;

Keep:

CFG.optimizer.batchSize = ...
    5;

CFG.optimizer.parallelUseFastRestart = ...
    false;

Then clear the tuning functions, verify TRUE feedback, save the model and
run again:

clear estimator_tuning_config
clear tune_state_estimator
clear evaluate_estimator_candidate
clear evaluate_estimator_candidates_parallel
rehash

TUNING_RESULT = tune_state_estimator;


=======================================================================
IMPORTANT
=======================================================================

- Do NOT modify UAV_sensors.m during estimator tuning.
- SENSOR physical properties are fixed.
- TRUE_STATES are never fed into INS_EKF.
- TRUE states are used only for estimator scoring and feedback verification.
- Controller feedback must remain TRUE throughout tuning.
- Navigation health / NavValid remains active.
- Failed or aborted missions are invalid estimator candidates.
- All configured training seeds must succeed.
- Validation seeds are independent from training seeds.
- The tuner optimizes all 24 EKF uncertainty parameters simultaneously.
- The production ESTIMATOR is never overwritten automatically.
- Do not manually apply the tuned parameters until the candidate has passed
  the required validation and subsequent EST-feedback closed-loop test.