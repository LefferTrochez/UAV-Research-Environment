# UAV Research Environment: A Parameter-Consistent Multi-Fidelity Framework for Quadrotor Control Evaluation

<p align="center">
  <a href="https://github.com/LefferTrochez/UAV-Research-Environment/releases/tag/v1.0-icra2027"><img src="https://img.shields.io/badge/version-v1.0--icra2027-blue" alt="Version" valign="middle"></a>
  <a href="https://www.mathworks.com/products/matlab.html"><img src="https://img.shields.io/badge/MATLAB-R2025a-orange" alt="MATLAB" valign="middle"></a>
  <a href="https://www.mathworks.com/products/simulink.html"><img src="https://img.shields.io/badge/Simulink-Based-orange" alt="Simulink" valign="middle"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-Apache--2.0-red" alt="License" valign="middle"></a>
</p>

---

## Introduction

This repository provides a MATLAB/Simulink environment for evaluating quadrotor controllers across three plant-model fidelity levels while keeping the main experimental conditions consistent.

The framework compares:

- **L1 — Analytical ODE model**
- **L2 — Simulink block-based model**
- **L3 — Simscape physical model**

The same reference vehicle, controller architecture, estimator, sensors, missions, disturbance conditions, and evaluation methodology are used across the three plant models.

The objective is to study how model fidelity affects closed-loop evaluation results and computational cost.

---

## Framework Overview

The main model is:

```text
UAV_Research_Environment.slx
```

The framework integrates:

- Multi-fidelity plant models
- Cascaded quadrotor controller
- Sensor models
- State estimation
- Mission and trajectory generation
- Environmental disturbances
- Landing and ground-contact logic
- Performance logging and visualization

The benchmark campaign used:

```text
2 controllers
× 2 missions
× 3 plant models
× 2 disturbance conditions
= 24 experiments
```

The comparison includes flight tracking, estimation, actuation, landing, and computational-cost metrics.

---

## Requirements

The framework was developed and tested using **MATLAB R2025a** on Windows 11.

### Required MATLAB Products

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

`Simscape` and `Simscape Multibody` are required for the L3 physical model, while `Global Optimization Toolbox` is used by the controller and estimator tuning workflows.

---

## Getting Started

Clone the repository:

```bash
git clone https://github.com/LefferTrochez/UAV-Research-Environment.git
cd UAV-Research-Environment
```

Open MATLAB in the repository root and run:

```matlab
clear
clc
initialize_project
```

Then open the main Simulink model:

```matlab
open_system('UAV_Research_Environment')
```

or open `UAV_Research_Environment.slx` directly.

---

## Selecting a Trajectory

The trajectory library is defined in:

```text
UAV_trajectories.m
```

Select the desired mission by setting `TRAJECTORY_ID` before running `initialize_project`:

```matlab
TRAJECTORY_ID = uint8(1);
initialize_project
```

Available IDs are:

```text
1 — ICRA Benchmark
2 — High-Dynamics Mission
3 — Circular Validation
```

For example:

```matlab
TRAJECTORY_ID = uint8(2);
initialize_project
```

selects the High-Dynamics Mission.

After initialization, open the Simulink model, update it with `Ctrl + D` if required, and press **Run**.

---

## Repository Structure

```text
.
├── CAD/
│   ├── Airframe.step
│   ├── Propeller_CCW.step
│   └── Propeller_CW.step
│
├── ICRA2027 results/
├── results/
│
├── UAV_Research_Environment.slx
├── initialize_project.m
├── Environment.m
├── UAV_analytical.m
├── UAV_block.m
├── UAV_simscape.m
├── UAV_autopilot.m
├── UAV_sensors.m
├── UAV_state_estimator.m
├── UAV_trajectories.m
├── UAV_operator_protocols.m
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

---

## Study Summary and Main Finding

The framework was built to determine whether increasing plant-model fidelity changes controller-evaluation conclusions when the rest of the benchmark is kept as consistent as possible.

Three progressively more detailed plant models were evaluated using the same control and estimation architecture under common mission and disturbance conditions.

The main conclusion is:

> **The appropriate simulation fidelity is task-dependent. Higher fidelity is not automatically the best choice for every controller-evaluation problem.**

Lower-fidelity models are useful for fast controller development, tuning, repeated testing, and large simulation campaigns. Higher-fidelity models become more valuable when the evaluation depends on physical effects such as actuator dynamics, electrical behavior, multibody effects, or detailed ground interaction.

The purpose of the framework is therefore not to identify one universally superior model, but to quantify when additional physical fidelity provides enough evaluation value to justify its additional computational cost.

---

## 3D Model Reference

The 3D quadrotor model used for the Simulink representation was adapted from the **UniQuad** project:

https://hkust-aerial-robotics.github.io/UniQuad/

---

## License

This project is licensed under the Apache License 2.0. See the [LICENSE](LICENSE) file for details.
