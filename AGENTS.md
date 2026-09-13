# AGENTS.md — Coin Maker Game Development Rules

## Project Goal

This is a Godot game project.

The game is being developed iteratively from a playable vertical slice toward a larger game.

Prioritize:

1. Playability
2. Correct game systems
3. Stable save/load
4. Combat feel
5. Content
6. Visual polish

Do not spend excessive compute or context on visual polish while core gameplay is incomplete.

---

# Token / Usage Efficiency

Minimize Codex usage while maintaining implementation quality.

## Context

* Do not scan or reread the entire repository unless necessary.
* Inspect only files relevant to the current task.
* Reuse information already learned during the current session.
* Do not repeatedly inspect unchanged files.
* Do not reread generated assets unless visual verification is necessary.
* Prefer targeted search over broad repository exploration.
* Avoid large directory listings unless required.
* Do not analyze generated/import/cache directories unless directly relevant.

For Godot, normally ignore generated/cache content such as `.godot/` unless debugging an import/cache-specific problem.

## Scope

Work only on the requested feature.

Do not automatically:

* refactor unrelated code
* rebalance unrelated systems
* redesign existing UI
* regenerate working assets
* rewrite working systems
* clean up unrelated files

If an unrelated improvement is discovered, mention it in the final report instead of implementing it.

---

# Task Size

Prefer small, complete iterations.

A normal iteration should focus on one area, for example:

* one gameplay mechanic
* one combat feature
* one UI screen
* one map section
* one save/load feature
* one bug or closely related group of bugs
* one asset pass

Do not expand a small request into a full-game improvement pass.

If the requested work is large, implement the most useful playable portion first.

---

# Testing / Verification

Use the cheapest verification method that gives reasonable confidence.

Preferred order:

1. Static/code inspection
2. Targeted script or unit test
3. Targeted Godot scene execution
4. Full game execution
5. Visual/render inspection

Do not repeatedly launch or render the entire game after every small edit.

Batch related edits first, then verify once.

Run additional verification only when:

* the previous verification failed
* the change affects another system
* visual behavior cannot be verified otherwise

When a targeted test is sufficient, do not run a full-game test.

---

# Image and Asset Generation

Image generation is expensive and should be deliberate.

Do not generate images automatically merely because a placeholder exists.

During gameplay/system development:

* use existing assets first
* reuse existing assets when reasonable
* use placeholders when appropriate

Generate a new asset only when:

* the user explicitly requests it, OR
* the current feature cannot be meaningfully evaluated without it

Before generating an image, check whether a suitable existing asset already exists.

Do not regenerate an acceptable asset merely to make minor visual improvements.

When generating assets:

* generate only the assets required for the current task
* avoid multiple speculative variants unless requested
* save successful assets and reuse them
* do not repeatedly inspect the same unchanged image

Separate gameplay implementation from large visual-polish passes whenever possible.

---

# Combat Design

Maintain the intended melee/ranged distinction.

## Melee

Melee should generally provide:

* higher close-range damage
* broad slash coverage where appropriate
* multi-target potential
* temporary damage reduction during committed attacks where designed
* short stagger against normal enemies

Bosses must not be permanently stagger-locked.

Boss attack patterns should provide readable openings where melee characters can safely engage.

## Ranged

Ranged combat should primarily benefit from:

* distance
* positioning
* safer sustained damage

Do not erase the melee/ranged distinction by making ranged strictly superior at equivalent progression.

Balance values should preferably live in data/configuration rather than being scattered through gameplay code.

---

# Save / Progression Safety

Changes to progression systems must preserve save compatibility whenever practical.

Before modifying save structures:

* inspect the existing save schema
* prefer additive changes
* provide defaults for missing older fields

Do not erase existing player progress during ordinary development/testing unless explicitly required.

Persistent systems include, where applicable:

* equipment
* gems
* currency
* rewards
* progression
* base upgrades
* boss completion

---

# Resume After Interruption

The task may be interrupted because of Codex usage limits, application closure, or other external interruption.

Always make work resumable.

During implementation:

* save meaningful changes to files as work progresses
* avoid keeping important state only in reasoning/context
* keep the working tree in an understandable state whenever possible

When starting or resuming work:

1. Check the current working tree/status first.
2. Inspect existing modifications before changing anything.
3. Assume existing modifications may be valid work from the previous interrupted session.
4. Do NOT discard, revert, overwrite, or recreate existing work unless it is clearly broken.
5. Determine the last completed implementation step from the files and current changes.
6. Continue from that point.
7. Do not restart the entire task merely because the previous conversation context is unavailable.
8. Read only the files necessary to recover the immediate state.
9. Run the smallest useful verification before continuing if the previous session appears to have stopped during verification.

If the previous run stopped because of a usage limit:

* preserve all completed work
* resume from the interruption point when Codex becomes available again
* do not repeat completed asset generation
* do not repeat successful tests without a reason
* do not perform a full repository re-analysis
* continue with the next unfinished step

---

# Work Checkpoint

For multi-step tasks, maintain a small checkpoint file:

`dev/WORK_STATUS.md`

Keep it concise.

It should contain only:

* Current objective
* Completed
* Remaining
* Last verification result
* Important changed files
* Generated assets that should NOT be regenerated
* Known issue/blocker

Update this file after meaningful milestones and before ending a long task.

Do not turn WORK_STATUS.md into a development diary.

On a resumed session, read `dev/WORK_STATUS.md` before performing broad repository exploration.

If its information conflicts with the actual code or git state, trust the code/git state and update the checkpoint.

---

# Stop Conditions

Stop the current iteration when:

* the requested feature works
* targeted verification passes
* remaining work is unrelated polish

Do not continue spending usage merely because additional improvements are possible.

At completion, report concisely:

* what was implemented
* what was tested
* what remains
* any known issues

Do not automatically start unrelated improvements.

---

# Current Project Context

The project currently includes or is actively implementing:

* departure/opening sequence
* camp/base flow
* multi-zone coastal exploration
* melee combat
* ranged/lightning combat
* equipment
* support gems
* loot/progression
* save/load
* gacha/reward flow
* satyr enemy
* cyclops/boss encounter

Recent generated character assets include:

* `assets/characters/satyr.png`
* `assets/characters/cyclops.png`

Do not regenerate these assets unless they are missing, broken, or the user explicitly requests replacement.

The current priority is to finish and verify the playable gameplay loop before spending substantial usage on additional visual polish.
