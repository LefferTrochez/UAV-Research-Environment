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

<p align="center">
  <img src="framework_overview.png" alt="Framework overview" width="900">
</p>



---

## Demonstration Videos

**Live 3D simulation:** Demonstration of the quadrotor simulation with real-time 3D trajectory visualization and live flight-state monitoring.




https://github.com/user-attachments/assets/d4cd0f30-7b3f-41c5-a28b-6278058ded06



**Simscape Multibody visualization:** Demonstration of the L3 physical model running in Simscape Multibody using Mechanics Explorer.

https://github.com/user-attachments/assets/017d02ad-7967-41f0-a2cc-a38247139f43

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


### Selecting a Trajectory

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

## Reproducibility and Technical Configuration

This section documents the configuration used for the experiments reported in the paper. Source files remain the authoritative implementation reference.

### Experimental Campaign

| Item | Configuration |
|---|---|
| Primary campaign | L1(C1), L2(C1), L3(C2) × T1/T2 × D0/D1 |
| Primary runs | 12 |
| Sensitivity runs | L3(C1) on T1-D1 and T2-D1 |
| Simulation horizon | 130 s |
| Control/estimation rate | 200 Hz |
| GPS rate | 10 Hz |
| Magnetometer fusion rate | 20 Hz |
| Barometer rate | 20 Hz |

C1 is used for L1 and L2, while C2 is used for L3. In the two supplementary sensitivity runs, C1 is transferred to L3 unchanged.

### Controller Gains

#### C1 — L1 and L2

Tuning source: `Controller_Tuning_2026-09-04_20-48-43`.

| Loop | Type | Gains |
|---|---|---|
| North position | P | `Kp = 0.630229618` |
| East position | P | `Kp = 0.922964404` |
| Body-X velocity | PD | `Kp = 2.278801060`, `Kd = 0.012960081`, `N = 1.890174530` |
| Body-Y velocity | P | `Kp = 0.957100556` |
| Vertical position | P | `Kp = 0.292511837` |
| Vertical velocity | P | `Kp = 179.235177724` |
| Yaw angle | P | `Kp = 9.737299688` |
| Roll attitude | P | `Kp = 16.244086526` |
| Pitch attitude | P | `Kp = 15.979489668` |
| Roll rate | PI | `Kp = 192.002243651`, `Ki = 36.716674044` |
| Pitch rate | PI | `Kp = 116.955688321`, `Ki = 324.349522335` |
| Yaw rate | PI | `Kp = 513.270796124`, `Ki = 48.966894919` |

#### C2 — L3

Tuning source: `Controller_Tuning_2026-09-06_23-55-42`.

| Loop | Type | Gains |
|---|---|---|
| North position | P | `Kp = 0.6302` |
| East position | P | `Kp = 0.9230` |
| Body-X velocity | PD | `Kp = 2.4273`, `Kd = 0.0044`, `N = 1.8902` |
| Body-Y velocity | P | `Kp = 6.0389` |
| Vertical position | P | `Kp = 1.8456` |
| Vertical velocity | P | `Kp = 253.1800` |
| Yaw angle | P | `Kp = 9.7373` |
| Roll attitude | P | `Kp = 6.4669` |
| Pitch attitude | P | `Kp = 6.3615` |
| Roll rate | PI | `Kp = 19.2000`, `Ki = 26.4700` |
| Pitch rate | PI | `Kp = 11.6960`, `Ki = 201.5600` |
| Yaw rate | PI | `Kp = 458.1200`, `Ki = 30.9870` |

Campaign gains are defined in `ICRA_experiment_config.m`. Common controller architecture and limits are defined in `UAV_autopilot.m`.

### Controller Assignment

| Experiment | Controller |
|---|---|
| L1–T1–D0/D1 | C1 |
| L1–T2–D0/D1 | C1 |
| L2–T1–D0/D1 | C1 |
| L2–T2–D0/D1 | C1 |
| L3–T1–D0/D1 | C2 |
| L3–T2–D0/D1 | C2 |
| Sensitivity L3–T1–D1 | C1 transferred unchanged |
| Sensitivity L3–T2–D1 | C1 transferred unchanged |

### Common Controller Limits

| Parameter | Value |
|---|---|
| Control frequency | 200 Hz |
| Controller sample time | 0.005 s |
| Horizontal velocity | ±1.0 m/s |
| Vertical velocity | ±0.6 m/s |
| Horizontal acceleration | ±3.0 m/s² |
| Maximum tilt | ±20° |
| Yaw-rate reference | ±60°/s = ±1.0472 rad/s |
| Roll/pitch rate reference | ±60°/s = ±1.0472 rad/s |
| Roll/pitch rate-controller output | ±20 rad/s |
| Yaw rate-controller output | ±100 rad/s |
| Vertical velocity-controller output | ±300 rad/s |
| Rate PI integrators | ±0.2 |
| Horizontal velocity integrator | ±0.2 |
| Vertical integrator | ±0.1 |
| Generic derivative coefficient | `N = 100` |
| Motor minimum command | 0 rad/s |
| Common motor maximum | `Inf` |
| Armed idle | 10% of hover rotor speed |

### Estimator Configuration

The estimator is an `insfilterMARG` Extended Kalman Filter (EKF) in the NED reference frame. It fuses accelerometer, gyroscope, magnetometer, GPS position, GPS velocity, and barometer measurements. The implementation is defined in `UAV_state_estimator.m`.

Final tuning source: `TUNED_300EVAL_2026_09_04`.

| Parameter | Value |
|---|---|
| `gyroNoiseScale` | `0.008535` |
| `gyroBiasNoiseScale` | `0.001197` |
| `accelNoiseScale` | `0.001169` |
| `accelBiasNoiseScale` | `0.002066` |
| `magBiasNoiseScale` | `0.360029` |
| `geomagneticVectorNoiseScale` | `0.008315` |
| `gpsPositionRScale_NE` | `3.046810` |
| `gpsVelocityRScale_NE` | `31.164150` |
| `gpsVelocityRScale_D` | `2.624673` |
| `magRScale` | `6.746872` |
| `baroRScale` | `4.764613` |
| `quaternionP0Scale` | `0.001018` |
| `positionP0Scale_NE` | `0.023288` |
| `positionP0Scale_D` | `17.644082` |
| `velocityP0Scale_NE` | `0.010597` |
| `velocityP0Scale_D` | `10.351926` |
| `gyroBiasP0Scale` | `0.003397` |
| `accelBiasP0Scale` | `0.086015` |
| `geomagneticP0Scale` | `0.001736` |
| `magBiasP0Scale` | `0.004873` |
| `robustPositionP0Scale_NE` | `0.139149` |
| `robustPositionP0Scale_D` | `0.240655` |
| `robustVelocityP0Scale_NE` | `0.001493` |
| `robustVelocityP0Scale_D` | `0.124664` |

### Estimator Rates and Initialization

| Parameter | Value |
|---|---|
| IMU prediction | 200 Hz |
| GPS fusion | 10 Hz |
| Magnetometer fusion | 20 Hz |
| Barometer fusion | 20 Hz |
| GPS samples for initialization | 20 |
| GPS initialization duration | 2.0 s |
| Barometer samples | 20 |
| Barometer initialization duration | 1.0 s |
| Estimator warm-up | 0.5 s |
| NavValid confirmation | 0.5 s |
| Expected NavValid | 2.5 s |
| Position STD maximum N/E/D | `[3, 3, 2] m` |
| Velocity STD maximum N/E/D | `[0.5, 0.5, 0.5] m/s` |
| GPS innovation gate | 5σ |
| Magnetometer innovation gate | 5σ |
| Barometer innovation gate | 5σ |
| Sensor timeout | 0.5 s |
| Invalid confirmation | 0.2 s |

No additional low-pass filter is included as part of the benchmark; filtering is provided primarily by the EKF and its covariance configuration.

### Sensor Configuration

Sensor models are defined in `UAV_sensors.m`.

#### IMU

| Parameter | Value |
|---|---|
| Sampling rate | 200 Hz |
| Accelerometer constant bias | `[0,0,0] m/s²` |
| Accelerometer velocity random walk | `[0.004,0.004,0.004] m/s²/√Hz` |
| Accelerometer bias instability | `[0.020,0.020,0.020] m/s²` |
| Accelerometer acceleration random walk | 0 |
| Accelerometer range | ±16 g |
| Accelerometer resolution | 0.001 m/s² |
| Gyroscope constant bias | `[0,0,0] rad/s` |
| Gyroscope angle random walk | `[0.02,0.02,0.02] deg/s/√Hz` |
| Gyroscope bias instability | `[0.05,0.05,0.05] deg/s` |
| Gyroscope rate random walk | 0 |
| Gyroscope range | ±2000 deg/s |
| Gyroscope resolution | 0.01 deg/s |
| IMU random seed | 67 |

#### Magnetometer

| Parameter | Value |
|---|---|
| Magnetic model | `WMM2025` |
| Decimal year | 2026.0 |
| White-noise PSD | `[0.05,0.05,0.05] µT/√Hz` |
| Bias instability | `[0.10,0.10,0.10] µT` |
| Constant bias | 0 |
| Random walk | 0 |
| Range | 1000 µT |
| Resolution | 0.15 µT |
| EKF fusion rate | 20 Hz |

#### GPS

| Parameter | Value |
|---|---|
| Rate | 10 Hz |
| Horizontal position accuracy | 1.6 m |
| Vertical position accuracy | 3.0 m |
| Velocity accuracy | 0.1 m/s |
| Decay factor | 0 |
| Random seed | 68 |

#### Barometer

| Parameter | Value |
|---|---|
| Rate | 20 Hz |
| Constant bias | 0 Pa |
| Noise density | 1 Pa/√Hz |
| Bias instability | 1 Pa |
| Decay factor | 0.99 |
| Random seed | 69 |

### Vehicle and Plant Parameters

| File | Configuration |
|---|---|
| `UAV_analytical.m` | L1 rigid-body and rotor reference parameters |
| `UAV_block.m` | L2 mapping of the same vehicle |
| `UAV_simscape.m` | L3 physical/electrical model |
| `Environment.m` | Gravity, atmosphere, ground, and disturbances |

#### Common Physical Vehicle

| Parameter | Value |
|---|---|
| Airframe mass | 1.408410 kg |
| Propeller mass | 0.006887 kg each |
| Number of propellers | 4 |
| Total airframe + propeller mass | 1.435958 kg |
| Propeller diameter | 0.2032 m = 8 in |
| Mean horizontal CG-to-rotor arm | 0.182296 m |
| `kT` | 0.10 |
| `kP` | 0.05 |
| `Ixx` | 0.00861159 kg·m² |
| `Iyy` | 0.00938242 kg·m² |
| `Izz` | 0.01076369 kg·m² |

The implementation preserves the complete inertia tensor, including the small off-diagonal terms, in the authoritative model files.

#### L1 Rotor Parameters

| Parameter | Value |
|---|---|
| `cT` | `5.29019e-6 N/(rad/s)²` |
| `cQ` | `8.55431e-8 N·m/(rad/s)²` |
| Rotor actuator time constant | 0 s |
| Actuator model | Ideal rotor speed |

L2 uses the corresponding block convention in `UAV_block.m`.

#### L3 Physical Actuator Parameters

| Parameter | Value |
|---|---|
| Wheelbase parameter | 0.350 m |
| Motor count | 4 |
| Motor `Kv` | 1300 rpm/V |
| Motor max current | 45.1 A |
| Motor max power | 1059 W |
| Motor `Kt` | 0.0073456 N·m/A |
| Motor max torque | 0.331287 N·m |
| Speed-controller torque saturation | 0.25 N·m |
| Torque-control time constant | 0.02 s |
| Rotor inertia | `8.0e-7 kg·m²` |
| Speed PI `Kp` | 0.00035 |
| Speed PI `Ki` | 0.005 |
| Drive efficiency | 90% |

#### L3 Battery Model

| Parameter | Value |
|---|---|
| Capacity | 3.3 Ah |
| Nominal voltage | 22.2 V |
| Fully charged voltage | 25.2 V |
| Internal resistance | 0.020 Ω |
| Initial SOC | 1.0 |

### Trajectory Configuration

T1 and T2 are defined in `UAV_trajectories.m`. Both use `passThroughIntermediate = false`.

#### T1 — ICRA Benchmark

`TRAJECTORY_ID = 1`

```matlab
waypoints = [
    0   0    0;
    0   0   -3;
    5   0   -3;
    5   0   -1.5;
    5  -5   -1.5;
    0   0   -1.5;
    0   0    0
];

yaw = [
     0;
     0;
     0;
     0;
    -pi/2;
     3*pi/4;
     0
];
```

#### T2 — High-Dynamics Mission

`TRAJECTORY_ID = 2`

```matlab
waypoints = [
     0   0    0;
     0   0   -3;
     4   4   -2;
    -4   4   -3.5;
     4  -4   -2;
     0   0   -1.5;
     0   0    0
];

yaw = [
     0;
     0;
     pi/4;
     pi/2;
    -pi/4;
     0;
     0
];
```

### Disturbance Configuration

D0 (`NOM`) uses:

```matlab
DIST_ENABLE = false;
```

D1 (`DIST`) uses:

```matlab
DIST_ENABLE = true;
```

The fixed disturbance realization is defined in `Environment.m`.

| Parameter | Value |
|---|---|
| Gust start | 20.0 s |
| Gust lengths X/Y/Z | `[25,25,15] m` |
| Gust amplitudes X/Y/Z | `[0.8,0.8,0.5] m/s` |
| Wind shear speed | 1.5 m/s at 6 m |
| Wind shear direction | 0° |
| Turbulence reference speed | 1.5 m/s at 6 m |
| Turbulence direction | 0° |
| Turbulence scale length | 533.4 m |
| Turbulence sample time | 0.1 s |
| Turbulence seeds | `[23341,23342,23343,23344]` |

### Mission and Solver Configuration

| Setting | Value |
|---|---|
| ARM | 3 s |
| RUN | 5 s |
| DISARM | 120 s |
| STOP | 130 s |
| Simulation horizon | 0–130 s |
| Operator mode | Automatic |
| Solver | `ode23t` |
| Solver type | Variable-step |
| Maximum step | `2e-3 s` |
| Minimum step | auto |
| Relative tolerance | `1e-4` |
| Absolute tolerance | `1e-3` |
| Simscape physical-network RelTol | `1e-3` |
| Simscape physical-network AbsTol | `1e-6` |
| Simscape minimum step | `1e-9` |
| Simscape local solver | OFF |

### Software and Hardware Configuration

| Setting | Value |
|---|---|
| MATLAB | 25.1.0.2973910 (R2025a) Update 1 |
| Simulink | R2025a |
| Operating system | Windows 11 Enterprise, Version 10.0, Build 26200 |
| Computer | Dell Precision 3680 |
| Processor | Intel Core i9-14900 |
| Memory | 32 GB RAM |
| Model | `UAV_Research_Environment.slx` |
| Simulation mode | Normal |
| Fast Restart for computational-cost measurements | OFF |
| Simulation pacing for computational-cost measurements | OFF |

### Reproducing the Campaign

The intended campaign interface is:

```matlab
CFG = ICRA_experiment_config;
CAMPAIGN = run_icra_campaign;
```

For an individual run:

```matlab
CFG = ICRA_experiment_config;
RUN = run_icra_experiment(CFG,runNumber);
```

The campaign mapping is **C1 → L1/L2** and **C2 → L3**. C1 is transferred unchanged to L3 only for the two supplementary T1-D1 and T2-D1 sensitivity runs.


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

This repository is an initial functional research release and should be considered a working research snapshot rather than a final software distribution. The repository is provided primarily to document and reproduce the current research workflow. Future versions may include corrections, refinements, additional validation, and improvements to usability and documentation.
