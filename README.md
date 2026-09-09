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
