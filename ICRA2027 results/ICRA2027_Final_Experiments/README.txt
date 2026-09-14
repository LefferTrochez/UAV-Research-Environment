ICRA 2027 FINAL EXPERIMENT CODES
================================

This folder contains the seven final campaign/post-processing files supplied for the ICRA 2027 multi-fidelity UAV experiment.

Key revisions in this package:
- Model renamed to UAV_Research_Environment.slx / UAV_Research_Environment.
- Configuration schema advanced to 1.2 so legacy 1.1 results are automatically treated as stale.
- C1 gains synchronized with the frozen UAV_autopilot values.
- C2 synchronized with the final L3-validated gain set (C1 inherited gains plus final roll/pitch attitude/rate changes).
- Campaign preflight no longer requires the obsolete 2026-09-06 C2 source string.
- Code snapshot now includes the model and main project parameter/model files.
- Finalizer inherits CFG.SchemaVersion instead of hard-coding 1.1.
- REAL T2 comparison policy is centralized in CFG: trim 13.0 s from the leading unavailable portion, re-zero time, and do not stretch/compress telemetry.
- Paper tables recompute REAL T2 comparison metrics on the trimmed window.
- Paper figures remove artificial time scaling, L3 roll scaling, trajectory reflection/warping and vertical display offsets.

Official campaign command:
    CAMPAIGN = run_icra_campaign;

After campaign completion:
    make_paper_tables
    make_paper_figures

Note: run_icra_campaign automatically disables pacing for official computational-cost measurements.
