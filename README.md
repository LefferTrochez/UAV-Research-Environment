# UAV Research Environment: A Parameter-Consistent Multi-Fidelity Framework for Quadrotor Control Evaluation

<p align="center">
  <img src="https://img.shields.io/badge/version-v1.0--icra2027-blue" alt="Version" valign="middle">
  <a href="https://www.mathworks.com/products/matlab.html"><img src="https://img.shields.io/badge/MATLAB-R2025a-orange" alt="MATLAB" valign="middle"></a>
  <a href="https://www.mathworks.com/products/simulink.html"><img src="https://img.shields.io/badge/Simulink-Based-orange" alt="Simulink" valign="middle"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-Apache--2.0-red" alt="License" valign="middle"></a>
</p>

---

## Introduction

This repository provides a MATLAB/Simulink environment for evaluating quadrotor controllers across three plant-model fidelity levels while keeping the main experimental conditions as consistent as possible.

The framework compares:

- **L1 — Analytical ODE model**
- **L2 — Simulink block-based model**
- **L3 — Simscape physical model**

The same reference vehicle, controller architecture, estimator, sensors, missions, disturbance conditions, and evaluation methodology are maintained across the plant models whenever possible.

The objective is to study how model fidelity affects closed-loop evaluation results and computational cost.

---

## Framework Overview

The main model is:

```text
UAV_Research_Environment.slx
```

The framework integrates:

- Multi-fidelity plant models
- Cascaded quadrotor control
- Sensor models
- State estimation
- Mission and trajectory generation
- Environmental disturbances
- Landing and ground-contact logic
- Performance logging and visualization

The three plant models share a common high-level architecture so that plant fidelity can be changed without redesigning the complete control and evaluation workflow.

---

## Demonstration Videos



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

Clone this repository using Git.

---

## Selecting a Trajectory

The trajectory library is defined in:

```text
UAV_trajectories.m
```

Select the desired trajectory by setting `TRAJECTORY_ID` before running the project initialization:

```matlab
TRAJECTORY_ID = uint8(1);
initialize_project
```

The available trajectory IDs are defined directly in `UAV_trajectories.m`.

After initialization, open the main model:

```matlab
open_system('UAV_Research_Environment')
```

Update the model with `Ctrl + D` if required, then press **Run**.

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

This framework was developed to investigate whether increasing plant-model fidelity changes controller-evaluation conclusions when the rest of the benchmark is kept as consistent as possible.

Three progressively more detailed plant models were implemented and evaluated within the same MATLAB/Simulink environment using a common control, estimation, sensing, mission, and analysis architecture.

The main conclusion is:

> **The appropriate simulation fidelity is task-dependent. Higher fidelity is not automatically the best choice for every controller-evaluation problem.**

Lower-fidelity models are useful for fast controller development, tuning, repeated testing, and large simulation campaigns. Higher-fidelity models become more valuable when the evaluation depends on physical effects that are not represented by simpler models, such as actuator dynamics, electrical behavior, multibody effects, or detailed ground interaction.

The purpose of the framework is therefore not to identify one universally superior model, but to support systematic evaluation of when additional physical fidelity provides enough value to justify its additional computational cost.

---

## 3D Model Reference

The 3D quadrotor model used for the **Simscape** representation was adapted from the **UNI-350CL** model provided by the UniQuad project:

https://hkust-aerial-robotics.github.io/UniQuad/

---

## License

This project is licensed under the Apache License 2.0. See the [LICENSE](LICENSE) file for details.

---

## Preliminary Release Notice

This repository is an initial functional research release and should be considered a working research snapshot rather than a final software distribution.

Although the framework has been tested for the study presented with this release, this first version may still contain implementation errors, compatibility issues, incomplete documentation, numerical inconsistencies, or other unintended behavior.

The repository is provided primarily to document and reproduce the current research workflow. Future versions may include corrections, refinements, additional validation, and improvements to usability and documentation.
