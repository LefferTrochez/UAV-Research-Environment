# Controller Tuning — UAV Research Environment

Automatic sequential tuning of the cascaded controller used by
`UAV_Research_Environment`.

The tuner follows the controller hierarchy from the innermost loops to the
outermost loops and freezes the accepted gains before moving to the next stage.

## 1. Controller sets

The framework uses two controller gain sets:

```text
L1 Analytical     -> C1
L2 Simulink       -> C1
L3 Simscape       -> C2
```

`UAV_autopilot.m` selects the corresponding controller set automatically from
the active plant model.

C1 is jointly tuned using L1 and L2.

C2 is tuned separately using L3.

The controller architecture is identical in all cases. Only the gain set changes.

## 2. Tuning experiment

The current C1 tuning campaign uses:

```text
Controller set:        C1
Plant models:          L1 + L2
Plant weighting:       0.5 L1 + 0.5 L2
Trajectory:            2
Controller feedback:   EST
Metric state source:   TRUE
Disturbances:          OFF
Operator mode:         AUTOMATIC
Execution:             SERIAL SAFE
Gain schema:           3.0
```

The controller therefore operates from estimated states exactly as in the final
closed-loop architecture, while objective metrics are computed from the true
simulated states.

## 3. Tuning sequence

The automatic sequence is:

```text
1. Angular Rate — Roll/Pitch
        ↓
2. Angular Rate — Yaw
        ↓
3. Roll/Pitch Attitude
        ↓
4. Yaw Angle
        ↓
5. Vertical Velocity
        ↓
6. Vertical Position
        ↓
7. Horizontal Velocity
        ↓
8. Horizontal Position
        ↓
Final Validation
```

Each accepted stage is frozen before the optimizer proceeds to the next outer
loop.

## 4. Tunable gains

The tuning architecture contains 16 active gains:

```text
Angular Rate Roll:
    Kp
    Ki

Angular Rate Pitch:
    Kp
    Ki

Angular Rate Yaw:
    Kp
    Ki

Roll Attitude:
    Kp

Pitch Attitude:
    Kp

Yaw Angle:
    Kp

Vertical Velocity:
    Kp

Vertical Position:
    Kp

Horizontal Velocity X:
    Kp
    Kd

Horizontal Velocity Y:
    Kp

Horizontal Position North:
    Kp

Horizontal Position East:
    Kp
```

The controller gain hierarchy and the corresponding controller bank are kept
synchronized during optimization.

## 5. Controller banks

The gain banks are stored in:

```matlab
AUTOPILOT.controllerSets.C1
AUTOPILOT.controllerSets.C2
```

The active controller is reported through:

```matlab
AUTOPILOT.info.activeController
```

The mapping is:

```text
UAV_MODEL = 1 -> C1
UAV_MODEL = 2 -> C1
UAV_MODEL = 3 -> C2
```

C1 and C2 must not overwrite each other.

## 6. Main files

```text
controller_tuning_config.m
controller_tuning_gain_table.m
evaluate_controller_candidate.m
evaluate_controller_candidates_parallel.m
tune_controller_stage.m
tune_controller.m
tune_controller_from_scratch.m
apply_controller_tuning_result.m
```

`controller_tuning_config.m`
defines the experiment, optimization stages, parameter bounds, objective
weights, penalties, validation requirements, and output files.

`controller_tuning_gain_table.m`
provides the authoritative mapping between the 16 active gains and the selected
controller bank.

`evaluate_controller_candidate.m`
evaluates one gain candidate over the configured plant models.

For C1 it evaluates both:

```text
L1
L2
```

and combines their objective values using the configured plant weights.

`evaluate_controller_candidates_parallel.m`
evaluates optimizer candidate batches using the serial-safe execution contract.

`tune_controller_stage.m`
optimizes one controller stage and freezes the accepted gains.

`tune_controller.m`
runs the complete eight-stage tuning campaign and final validation.

`tune_controller_from_scratch.m`
starts a completely new tuning campaign using the current baseline controller.

`apply_controller_tuning_result.m`
applies a validated tuning result to the corresponding controller bank while
preserving the other bank.

## 7. Running C1 tuning

Initialize the project with C1 active:

```matlab
clear
UAV_MODEL = 1;
initialize_project
```

Then run:

```matlab
CONTROLLER_TUNING_RESULT = tune_controller;
```

The tuning routine automatically evaluates each candidate on both L1 and L2.

Do not manually switch plant models during optimization.

## 8. Starting a new C1 campaign

To explicitly start a new campaign:

```matlab
CONTROLLER_TUNING_RESULT = tune_controller_from_scratch;
```

The tuning system does not resume an older campaign unless that capability is
explicitly implemented.

## 9. Applying the final C1 result

After all eight stages and final validation pass:

```matlab
[AUTOPILOT_TUNED,GAIN_TABLE] = ...
    apply_controller_tuning_result( ...
        CONTROLLER_TUNING_RESULT);
```

The application routine verifies:

```text
Schema = 3.0
Controller set = C1
Plants = L1 + L2
Trajectory = 2
Feedback = EST
Metric state = TRUE
8 / 8 tuning stages completed
Final validation = PASS
16 active gains present
```

Only `controllerSets.C1` is updated.

`controllerSets.C2` is preserved.

## 10. C2 tuning

C2 follows the same controller architecture but is tuned specifically for L3:

```text
Controller set:        C2
Plant model:           L3
Trajectory:            2
Controller feedback:   EST
Metric state source:   TRUE
```

The C2 campaign must preserve the final C1 bank.

The C2-specific tuning configuration is generated separately after the C1
campaign is finalized.

## 11. Feedback and evaluation states

The controller is tuned using:

```text
EST
```

as its feedback source.

This includes the estimator dynamics, sensor noise, update rates, and estimation
errors seen by the deployed controller.

The optimization objective is evaluated using:

```text
TRUE
```

states.

This separates controller information from performance measurement:

```text
Controller input -> EST
Performance truth -> TRUE
```

## 12. Tuning trajectory

Trajectory 2 is used as the optimization trajectory.

The same trajectory is used across candidate evaluations so that changes in the
objective are attributable to controller gains rather than mission changes.

Additional trajectories are reserved for final cross-trajectory validation.

## 13. Multi-plant C1 objective

C1 is optimized jointly over L1 and L2.

For each gain candidate:

```text
Candidate gains
      ↓
Evaluate L1
      ↓
J_L1

Candidate gains
      ↓
Evaluate L2
      ↓
J_L2
```

The final candidate objective is:

```text
J_C1 = 0.5 J_L1 + 0.5 J_L2
```

unless different plant weights are explicitly configured.

This prevents C1 from becoming specialized to only one of the two low-cost
plant representations.

## 14. Optimization principles

The tuner uses the following rules:

```text
Tune inside-out
Freeze accepted inner-loop gains
Use identical experiment conditions between candidates
Use EST feedback
Evaluate performance against TRUE states
Reject invalid or unstable simulations
Penalize actuator saturation
Penalize mission failure
Preserve controller-bank isolation
Perform final full-mission validation
```

A stage is not accepted simply because the optimizer returns a lower scalar
cost. Stage acceptance must also satisfy the configured validation and
improvement requirements.

## 15. Reproducibility

The tuning configuration records:

```text
Controller set
Plant models
Plant weights
Trajectory ID
Feedback source
Metric state source
Gain schema
Optimization stages
Gain bounds
Objective weights
Penalty parameters
Simulation duration
Validation thresholds
Random-search settings
Optimizer settings
Output paths
```

The final tuning result stores the configuration and the complete tuned
`AUTOPILOT` structure so that the controller can be reconstructed and audited.

## 16. Output files

The C1 campaign uses dedicated output files such as:

```text
Controller_Tuning_C1_Result.mat
Controller_Tuning_C1_Stages.mat
Controller_Tuning_C1_Gains.csv
Controller_Tuning_C1_Validation.mat
Controller_Tuning_C1_Checkpoint.mat
```

Results are stored separately from the C2 campaign to prevent accidental
overwriting.

## 17. Final validation

After optimization, the final controller must complete a full validation run
under the configured experiment.

The final result is accepted only when:

```text
All 8 stages completed
All 16 gains valid
Controller bank synchronized
Mission completed
Controller feedback = EST
Metrics evaluated from TRUE
Plant configuration correct
Final validation passed
```

For C1, validation includes both L1 and L2.

For C2, validation uses L3.

## 18. Final experiment architecture

The intended controller comparison is:

```text
Trajectory 2 + EST feedback

L1 + C1
L2 + C1
L3 + C2
```

Additional trajectories are then used for independent validation of the tuned
controllers.

This preserves the same controller structure and experiment interfaces while
allowing the higher-fidelity L3 plant to use a dedicated gain set when required.