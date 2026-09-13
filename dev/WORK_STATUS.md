# Work Status
## Objective
Complete v0.2.18 user TODO: directions, gacha budgets, comparison, primary weapon, supports/upgrades, corridors, performance and effects.
## Completed implementation
Town facing Vector2 and movement facing; arrow aliases; 3 gacha/level (Lv100 final boss +1 capped3); primary weapon UI and cast restrictions, all weapons protected; quick tooltip comparison; FPS saved toggle; model template reuse/nearby staged creation; wide dense C/S roads; ten new supports with hit context; trigger selector, +10 capped skill upgrades; bowstring/casting poses; serrated wave/spin geometry and spin radius190 damage24.
## Verification
23 existing tests and new v18 integration passed. UI/front-back rendered; cache creation measured13ms cold/2ms shared. Final bowstring/Lv100/trigger2slot checks included in targeted pass. Model remains procedural, not PNG-level realism.
## Remaining
Final package build/smoke, commit/push and release18. Version is now0.2.18. Do not rerun todo18a/b/c/tests18 mutation scripts. Preserve assets/saves.
