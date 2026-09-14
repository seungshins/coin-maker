# Work Status
## Objective
Finalize v0.2.20 crowd performance, encounter variants, progression and summon fixes.
## Completed
Cached collision geometry/bounds; merge static enemy mesh siblings while preserving joints; shared actor materials and screen culling; translucent entry loading with model preparation; shade/ember priest and Empusa boss variant. Gacha capacity 3 + level/10 capped12 with one-time saved-capacity migration. Summon HP1.25x player/baseDR25%, stronger guard, projectile DR fix, live might/ward/wind buffs. Minimap fits whole geometry and boss arena with cached transform.
## Verification
Walkable 10000 calls 441ms ->120ms; satyr visible meshes117->29. QHD RTX5070Ti 60 active enemies median8.83ms, p95 12.325ms (short synthetic test, not sustained all-skill FPS). Targeted tests pass. All existing and new tests passed after updating intended guardHP expectation. Windows release startup exit0; macOS/Linux packaged but runtime untested. Full-screen loading and cross minimap visually verified. Render screenshots in .runtime/v20-*.
## Remaining
Commit/push and publish/verify v0.2.20 release. Do NOT rerun work mutation scripts. Existing image assets unchanged.
