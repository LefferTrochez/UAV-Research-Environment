# UAV Research Environment: A Parameter-Consistent Multi-Fidelity Framework for Quadrotor Control Evaluation

<p align="center">
  <a href="https://github.com/LefferTrochez/UAV-Research-Environment/releases/tag/v1.0-icra2027"><img src="https://img.shields.io/badge/version-v1.0--icra2027-blue" alt="Version" valign="middle"></a>
  <a href="https://www.mathworks.com/products/matlab.html"><img src="https://img.shields.io/badge/MATLAB-R2025a-orange" alt="MATLAB" valign="middle"></a>
  <a href="https://www.mathworks.com/products/simulink.html"><img src="https://img.shields.io/badge/Simulink-Based-orange" alt="Simulink" valign="middle"></a>
  <a href="https://www.mathworks.com/products/simscape.html"><img src="https://img.shields.io/badge/Simscape-Physical_Modeling-blue" alt="Simscape" valign="middle"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-Apache--2.0-red" alt="License" valign="middle"></a>
</p>

---

## Table of Contents

1. [Introduction](#introduction)
2. [Framework Overview](#framework-overview)
3. [Multi-Fidelity Plant Models](#multi-fidelity-plant-models)
4. [Benchmark Configuration](#benchmark-configuration)
5. [Repository Structure](#repository-structure)
6. [Getting Started](#getting-started)
7. [Requirements](#requirements)
8. [How to Use](#how-to-use)
9. [Generated Data and Repository Artifacts](#generated-data-and-repository-artifacts)
10. [Study Summary and Main Findings](#study-summary-and-main-findings)
11. [Technical Notes](#technical-notes)
12. [Technologies Used](#technologies-used)
13. [License](#license)
14. [References](#references)

---

## Introduction

This repository presents a MATLAB/Simulink-based research environment for the systematic evaluation of quadrotor control systems across multiple plant-model fidelity levels.

The main motivation is that controller performance is often evaluated using simulation models with substantially different levels of physical complexity. However, differences between simulation environments can be caused not only by model fidelity, but also by changes in vehicle parameters, controller implementation, sensors, estimators, trajectories, environmental conditions, solver settings, or evaluation metrics.

This framework was therefore designed around a parameter-consistent benchmarking methodology in which the plant model is changed while the remaining experimental architecture is kept as consistent as possible.

The framework includes three plant-model fidelity levels:

- **L1 — Analytical ODE model**
- **L2 — Simulink block-based model**
- **L3 — Simscape physical model**

The same overall vehicle definition, controller architecture, navigation estimator, reference missions, environmental conditions, and evaluation methodology are used across the three levels.

The resulting environment provides a structured workflow for studying the tradeoff between simulation fidelity, closed-loop evaluation behavior, and computational cost.

---

## Framework Overview

The core of the repository is the Simulink model:

```text
UAV_Research_Environment.slx
```

The framework organizes the complete quadrotor simulation and evaluation workflow around several common subsystems:

- Plant model
- Flight-control system
- State estimator
- Sensor models
- Mission and trajectory generation
- Operator protocol
- Environmental conditions
- Flight-management logic
- Ground-contact and landing logic
- Data logging
- Performance analysis
- Visualization

The three plant implementations are designed to represent the same reference quadrotor while progressively increasing the physical detail of the model.

The benchmark therefore follows the general principle:

```text
Same vehicle
+ Same controller
+ Same estimator
+ Same sensors
+ Same mission
+ Same disturbance condition
+ Same metrics
--------------------------------
Different plant-model fidelity
```

This structure allows model fidelity to be studied as the primary experimental variable.

---

## Multi-Fidelity Plant Models

### L1 — Analytical ODE Model

The L1 model is the lowest-complexity plant representation.

It implements the quadrotor rigid-body equations of motion directly using an analytical state-space formulation and explicit force and moment calculations.

Main characteristics include:

- Translational rigid-body dynamics
- Rotational rigid-body dynamics
- Motor/rotor force allocation
- Gravity
- Aerodynamic effects included through the analytical model
- Ground-contact handling
- Relatively low computational cost

The corresponding parameter definition is contained in:

```text
UAV_analytical.m
```

L1 is intended primarily for fast controller development, tuning, repeated simulation campaigns, and computationally intensive evaluation.

### L2 — Simulink Block-Based Model

The L2 plant introduces a more structured block-based representation using MATLAB/Simulink and aerospace-oriented modeling components.

It maintains the same high-level vehicle and controller interfaces while representing the vehicle dynamics using a different modeling abstraction.

The corresponding parameter definition is contained in:

```text
UAV_block.m
```

L2 provides an intermediate fidelity level between the analytical formulation and the physical Simscape implementation.

### L3 — Simscape Physical Model

The L3 plant is the highest-fidelity model included in the current framework.

It combines physical modeling components including:

- Simscape Multibody
- CAD-derived airframe geometry
- Physical mass and inertia properties
- Individual rotor locations
- Propeller models
- Motor and drive dynamics
- Electrical battery representation
- Aerodynamic forces and moments
- Physical ground interaction
- Landing-gear contact geometry

The corresponding parameter definition is contained in:

```text
UAV_simscape.m
```

The required CAD resources are stored in:

```text
CAD/
```

including:

```text
Airframe.step
Propeller_CCW.step
Propeller_CW.step
```

The L3 model provides substantially richer physical representation but also introduces a significantly higher computational burden.


---

## Benchmark Configuration

The current benchmark campaign uses:

```text
Controllers:             2
Reference missions:      2
Plant models:            3
Disturbance conditions:  2
Total experiments:      24
```

The experimental matrix therefore evaluates every controller under the same mission and disturbance conditions for all three plant-model fidelity levels.

The two controller configurations represent:

```text
C1 — Controller tuned using the L1 plant
C2 — Final tuned controller configuration
```

Each controller is evaluated across:

```text
L1
L2
L3
```

under both nominal and disturbed conditions.

The analysis includes several complementary groups of metrics.

### Flight Performance

Examples include:

- Position tracking error
- Velocity tracking error
- Attitude tracking error
- Angular-rate tracking error
- Path-tracking error
- Waypoint error
- Mission completion

### State Estimation

The estimator evaluation includes:

- Position estimation error
- Velocity estimation error
- Attitude estimation error
- Angular-rate estimation error
- Acceleration estimation error
- Axis-level metrics
- Mission-level metrics

### Control and Actuation

The framework records quantities related to:

- Motor commands
- Control effort
- Motor-speed behavior
- Actuation variability
- Saturation
- Axis-level control activity

### Landing

Landing evaluation includes metrics associated with:

- Touchdown
- Contact velocity
- Vehicle angular motion
- Ground interaction
- Mission termination

### Computational Performance

The benchmark also measures simulation cost in order to evaluate the practical tradeoff between physical fidelity and computational demand.

---

## Repository Structure

The repository is organized as follows:

```text
.
├── CAD/
│   ├── Airframe.step
│   ├── Propeller_CCW.step
│   └── Propeller_CW.step
│
├── ICRA2027 results/
│   ├── Controller tuning results/
│   ├── EKF tuning results/
│   ├── ICRA2027_Final_Experiments/
│   └── Real_Flight_TLOG/
│
├── results/
│   ├── log_T1_2026-09-07_17-47-20/
│   └── log_T2_2026-09-07_17-50-33/
│
├── UAV_Research_Environment.slx
├── initialize_project.m
│
├── Environment.m
├── UAV_analytical.m
├── UAV_block.m
├── UAV_simscape.m
├── UAV_autopilot.m
├── UAV_sensors.m
├── UAV_state_estimator.m
├── UAV_trajectories.m
├── UAV_operator_protocols.m
│
├── uav_remote_gui.m
│
├── plot_controller_results.m
├── plot_estimator_results.m
├── plot_mission_results.m
├── plot_touchdown_diagnostics.m
├── plot_trajectory_3d.m
│
├── LICENSE
└── README.md
```

### Main Simulink Model

```text
UAV_Research_Environment.slx
```

contains the integrated simulation environment.

### Initialization

```text
initialize_project.m
```

loads and configures the parameter definitions required by the framework.

### Vehicle Models

```text
UAV_analytical.m
UAV_block.m
UAV_simscape.m
```

define the main parameters associated with the three plant fidelity levels.

### Flight-Control System

```text
UAV_autopilot.m
```

contains the controller and autopilot configuration used by the framework.

### Sensors and State Estimation

```text
UAV_sensors.m
UAV_state_estimator.m
```

define the simulated sensor configuration and state-estimation architecture.

### Mission Definition

```text
UAV_trajectories.m
UAV_operator_protocols.m
```

define the reference missions and automatic operator protocol.

### Environment

```text
Environment.m
```

contains the environmental configuration used by the simulation.

### Visualization and Analysis

The repository includes dedicated analysis functions for:

```text
plot_controller_results.m
plot_estimator_results.m
plot_mission_results.m
plot_touchdown_diagnostics.m
plot_trajectory_3d.m
```

A graphical user interface is also provided through:

```text
uav_remote_gui.m
```

---

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/LefferTrochez/UAV-Research-Environment.git
```

Then enter the repository:

```bash
cd UAV-Research-Environment
```

### 2. Open MATLAB

Start MATLAB and set the repository root as the current working directory.

For example:

```matlab
cd('C:\GitHub\UAV-Research-Environment')
```

A short local path is recommended when possible.

### 3. Initialize the Environment

Run:

```matlab
clear
clc
initialize_project
```

The initialization script loads the required vehicle, controller, environment, sensor, estimator, trajectory, and simulation configuration.

### 4. Open the Main Model

Open:

```matlab
open_system('UAV_Research_Environment')
```

or open the file directly from MATLAB:

```text
UAV_Research_Environment.slx
```


---

## Requirements

The current implementation was developed and tested using MATLAB R2025a.

### Core Software

- MATLAB R2025a
- Simulink

### Required MATLAB Products

The complete framework uses functionality from the following MATLAB products:

- MATLAB
- Simulink
- Simscape
- Simscape Multibody
- Aerospace Toolbox
- Aerospace Blockset
- UAV Toolbox
- Navigation Toolbox
- Control System Toolbox
- Optimization Toolbox
- Global Optimization Toolbox

Some functionality is associated with specific parts of the workflow.

For example:

- **Simscape / Simscape Multibody** are required for the L3 physical model.
- **Navigation Toolbox** is used by the navigation/state-estimation workflow.
- **Global Optimization Toolbox** is used by the controller and estimator tuning workflows involving `surrogateopt`.
- **Aerospace-related products** support portions of the vehicle, environment, and block-based modeling architecture.

### Hardware Requirements

No specialized hardware is required to execute the simulation framework.

However, computational requirements differ substantially between fidelity levels.

In particular:

- L1 is suitable for rapid and repeated simulations.
- L2 introduces additional model complexity.
- L3 can require substantially more computation because of the physical Simscape and Multibody formulation.

A modern multi-core CPU and sufficient system memory are therefore recommended for L3 simulations and large benchmark campaigns.

### Operating System

The current repository has primarily been developed and tested on:

```text
Windows 11
```

The MATLAB source code is designed to avoid user-specific absolute project paths wherever possible.

---

## How to Use

The main workflow is:

```text
Initialize project
        ↓
Select plant model
        ↓
Select controller
        ↓
Select mission
        ↓
Configure environment
        ↓
Run simulation
        ↓
Export metrics and figures
```

### Initialize the Framework

Run:

```matlab
initialize_project
```

before executing the model.

### Select the Plant Fidelity

The framework provides three plant configurations:

```text
L1 — Analytical
L2 — Block-based
L3 — Physical
```

The selected plant is integrated through the common simulation architecture so that the controller and remaining benchmark components can be maintained consistently.

### Select the Mission

Mission definitions are contained in:

```text
UAV_trajectories.m
```

The current library contains several reference flight profiles ranging from structured waypoint tracking to more dynamically demanding motion.

### Run the Simulation

After initialization, open:

```text
UAV_Research_Environment.slx
```

update the model if required with:

```text
Ctrl + D
```

and press:

```text
Run
```

### Analyze the Simulation

After a simulation, the repository provides dedicated functions for generating figures and quantitative metrics.

These include:

```matlab
plot_controller_results
plot_estimator_results
plot_mission_results
plot_touchdown_diagnostics
plot_trajectory_3d
```

The resulting data can be exported in formats including:

```text
MAT
CSV
PNG
XLSX
```

depending on the analysis stage.

---

## Generated Data and Repository Artifacts

The repository includes data associated with the development and evaluation of the framework.

### Controller Tuning

```text
ICRA2027 results/
└── Controller tuning results/
```

contains the configuration, optimization checkpoints, optimized gains, stage-level information, and validation artifacts associated with controller tuning.

The controller optimization was performed progressively across the control hierarchy, including:

- Angular-rate control
- Attitude control
- Vertical velocity
- Vertical position
- Horizontal velocity
- Horizontal position

### State-Estimator Tuning

```text
ICRA2027 results/
└── EKF tuning results/
```

contains the configuration, optimization trials, selected parameters, checkpoints, and validation information associated with estimator tuning.

### Final Benchmark Data

```text
ICRA2027 results/
└── ICRA2027_Final_Experiments/
```

contains the aggregated data used to summarize the final simulation campaign.

This includes:

```text
ICRA2027_Final_Paper_Tables.xlsx
Paper_Tables_DIST.mat
Table01_All_Performance_Errors_DIST.csv
Table02_Actuation_Landing_Cost_DIST.csv
Supplement_Estimator_Axis_Errors_DIST.csv
Supplement_Waypoint_Errors_DIST.csv
```

These files provide both aggregated and axis-level benchmark information.

### Representative Simulation Runs

The:

```text
results/
```

folder contains representative simulation outputs including:

- Saved experiment data
- State-comparison figures
- Estimation-error figures
- Three-dimensional trajectory plots
- Motor-speed plots
- Control-axis plots
- Attitude and angular-rate tracking
- Mission-performance figures
- Touchdown diagnostics
- CSV metric tables

### Real-Flight Data

A real-flight dataset is also included in:

```text
ICRA2027 results/
└── Real_Flight_TLOG/
```

The folder contains a telemetry log together with representative processed figures.

The real-flight data is included as an additional reference for examining the behavior of the physical platform and for supporting future simulation-to-flight studies.


---

## Study Summary and Main Findings

This repository was developed to investigate whether increasing plant-model fidelity materially changes the conclusions obtained when evaluating the same quadrotor controller under otherwise comparable experimental conditions.

To address this question, three plant models with different levels of physical complexity were implemented within the same MATLAB/Simulink environment.

The study used common:

- Vehicle parameters
- Controller structure
- Estimator architecture
- Sensor configuration
- Flight missions
- Disturbance conditions
- Evaluation metrics

A complete experiment matrix was then constructed using:

```text
2 controllers
×
2 missions
×
3 plant models
×
2 disturbance conditions
=
24 closed-loop experiments
```

Controller and estimator tuning were performed separately, and a common evaluation pipeline was used to generate performance, estimation, actuation, landing, and computational-cost metrics.

The resulting experiments show that model fidelity should not automatically be interpreted as model usefulness.

Increasing physical detail introduces additional dynamic behavior and can provide information that is unavailable in lower-order models. However, this additional detail also increases simulation cost, and the benefit depends on the evaluation task being performed.

The main practical conclusion of the framework is therefore:

> **The appropriate simulation fidelity is task-dependent. Higher fidelity is not automatically the best choice for every controller-evaluation problem.**

Lower-fidelity models can remain highly valuable for controller development, tuning, repeated experiments, and large simulation campaigns when they preserve the dominant closed-loop behavior relevant to the task.

Higher-fidelity models become more useful when the evaluation requires physical effects that are not represented by simpler models, such as detailed actuator dynamics, electrical behavior, multibody effects, or physical ground interaction.

The proposed environment is therefore intended not to identify a universally superior model, but to provide a controlled methodology for determining when additional fidelity provides sufficient evaluation value to justify its additional computational cost.

---

## Technical Notes

### Coordinate Frames

The framework uses:

```text
Inertial frame: NED
Body frame:     FRD
```

where:

```text
NED = North-East-Down
FRD = Forward-Right-Down
```

Altitude visualizations may convert the NED Down coordinate to positive altitude for presentation.

### Common Plant Interface

The three plant models are designed to maintain a common high-level interface so that plant fidelity can be changed without redesigning the rest of the control architecture.

This is a central design requirement of the benchmark.

### State Estimation

The navigation architecture uses an inertial navigation estimator based on multisensor fusion.

The estimator receives information derived from sensors including:

- Accelerometer
- Gyroscope
- Magnetometer
- GNSS/GPS
- Barometric information

The same estimator architecture is maintained across the plant-model comparisons whenever possible.

### Controller Architecture

The autopilot follows a cascaded control structure containing loops associated with:

- Angular rate
- Attitude
- Vertical velocity
- Vertical position
- Horizontal velocity
- Horizontal position

This controller architecture is common across the plant models.

### Ground Interaction

Ground-contact behavior is represented across the framework, with the L3 implementation additionally using physical contact geometry derived from the vehicle model.

This allows landing and touchdown behavior to be included in the benchmark rather than limiting the analysis to free-flight trajectory tracking.

### Computational Cost

The three models have substantially different computational requirements.

This is intentional.

Computational cost is treated as an evaluation quantity rather than only as an implementation inconvenience, since simulation speed directly affects:

- Controller tuning
- Parameter sweeps
- Monte Carlo experiments
- Optimization
- Large benchmark campaigns
- Real-time feasibility

---

## Technologies Used

The framework is primarily based on:

- MATLAB
- Simulink
- Simscape
- Simscape Multibody
- Aerospace Toolbox
- Aerospace Blockset
- UAV Toolbox
- Navigation Toolbox
- Control System Toolbox
- Global Optimization Toolbox

---

## License

This project is licensed under the Apache License 2.0.

See:

```text
LICENSE
```

for the complete license terms.

---

## References

The framework makes use of MATLAB and several MathWorks modeling and simulation technologies.

Useful official resources include:

1. MathWorks. *MATLAB Documentation*.  
   https://www.mathworks.com/help/matlab/

2. MathWorks. *Simulink Documentation*.  
   https://www.mathworks.com/help/simulink/

3. MathWorks. *Simscape Documentation*.  
   https://www.mathworks.com/help/simscape/

4. MathWorks. *Simscape Multibody Documentation*.  
   https://www.mathworks.com/help/sm/

5. MathWorks. *Aerospace Blockset Documentation*.  
   https://www.mathworks.com/help/aeroblks/

6. MathWorks. *UAV Toolbox Documentation*.  
   https://www.mathworks.com/help/uav/

7. MathWorks. *Navigation Toolbox Documentation*.  
   https://www.mathworks.com/help/nav/

---

> **Anonymous review version**
>
> Citation information, author contact information, persistent archival identifiers, and MATLAB File Exchange links are intentionally omitted from this release and may be added after completion of the peer-review process.
