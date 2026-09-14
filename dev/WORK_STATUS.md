# Work Status
## Objective
Finalize v0.2.21 attack latency mitigation without reducing visual quality.
## Completed
v0.2.20 published and all five assets verified. v21 shares slash Shader/ArrayMesh while retaining per-effect uniforms, warms slash/sword wave/elements behind loading screen, disables accumulated input. No automatic macOS quality reduction. Model/light/shadow/resolution unchanged.
## Verification
Immediate click damage/pose and shared resources/independent uniforms pass; Windows loading/render and packaged startup pass. macOS runtime unavailable: user reports33-60FPS and attack-only1-2sec latency; fix is not confirmed on Mac. All platforms packaged.
## Remaining
Commit/push/publish/verify v0.2.21. Do not run mac21.cjs (unapplied old proposal lowers quality). latency21.cjs is already applied; do not rerun.