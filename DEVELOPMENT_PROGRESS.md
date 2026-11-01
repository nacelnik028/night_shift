# NIGHT SHIFT 3.0 development progress

Updated: 2026-10-23. The October 23 checkpoint immediately below is current. Subsequent October 22 sections retain development history; their earlier limitations and measurements are historical. `DEVELOPMENT.md` describes the original version.

## October 23 — verified remaster checkpoint

### Foundation and preservation

- Inspected this exact existing project through Godot MCP and the filesystem. The installed engine is Godot 4.7.2, Compatibility renderer. Contrary to the prompt's version label, the files already contained a substantial 3.0 pass; existing implementations were inspected before extending them.
- Read README, progress notes, all scene structure, controller, world/collision generation, UI, customers, director, audio, rendering, save code and test harnesses. No Git repository or applicable AGENTS.md was present. No other project was modified and no subagents were used.
- Created and reopened `artifacts/checkpoints/night_shift_baseline_20261023_175410.zip` before source edits: 79,966 bytes, SHA256 `3A6C0206A2A4B4D3DB24F38644D50802E3A7511A2105BC034BCDB9253B69AA5E`. Source, scenes, shaders, tests and documentation are included; generated caches/artifacts are excluded.
- Fresh baseline: 157 campaign, 65 overhaul, 52 physical traversal and 125 actual native-display checks passed. Initial runs exposed host certificate/editor-preference access restrictions; final validation is clean. The validator now keeps its editor preferences and test saves under `artifacts/qa_userdata`.
- The user's original campaign file was copied, without changing it, to `artifacts/checkpoints/campaign_snapshot_20261023.json` (SHA256 `70B18DA52E38DF11C0EED04221439D6963EAB104ECC42BFF1560918644C2AC74`). All automated writes use isolated test paths.
- Godot MCP added the actual `ServiceWing` node to `scenes/station.tscn`. Version/project discovery and project-launch tools were also used. As before, the launch tool did not retain an active process handle for its later debug query; sustained verification uses the console executable and real rendered harnesses.

### Display, collision and UI fixes

- Added explicit windowed, borderless and exclusive fullscreen selection, plus the five requested window resolutions and save persistence. Legacy fullscreen booleans still load as borderless. Resolution pairs are validated; desktop fitting and prior maximized-window restoration remain.
- Moved display shortcut handling ahead of focused GUI controls. Native tests inject Alt+Enter while the display selector has focus, verify all modes/resolutions, monitor filling, window restoration, mouse capture and separate-process persistence.
- Retained the original non-blocking task areas, 0.28m player capsule, standing clearance, safe margin, floor snapping and opt-in collision debugger. Doors now test their closing sweep against the player's actual capsule instead of closing through an occupied doorway. Opening doors remains immediate and usable when approached closely.
- Added an actual rear-wall opening and matching door, visible shallow ramp and outdoor pad. Physics traversal verifies both directions without jumping. Required walls and obstacle collisions remain.
- A new route audit found an existing issue: the straight customer arrival/departure segments crossed the raised pump islands. Additional waypoints now route around them. Every arrival/departure segment is sampled with a capsule against the real world; all are clear.
- Settings use two container-managed columns. Visitor identity/dialogue/order have separate labels and a patience bar. Objectives still collapse for visitors. Warning cards grow upward; long environmental notes scroll inside a bounded reader above their dismissal button.
- Rebuilt the main menu as a compact left-side composition over the rainy station. Play, Continue, Settings and Quit retain their behavior.

### Art, environment and interaction polish

- Generated and integrated `assets/art/northstar_print_atlas.png` with the built-in image generation tool using the imagegen skill. It supplies four coordinated prints: coffee advertising, Road Bites packaging, a fictional missing-person notice and Cold Spring water labels. Prompt/provenance: `assets/art/PROVENANCE.md`. The PNG is bundled locally and does not require a service at runtime.
- Replaced the large checker-floor overlays with shader-defined grout, tile variation and grime. Added a wet-asphalt shader with subdued specular puddles, rain ripples and an authored canopy sheen. This is an economical shader approximation, not SSR.
- Reduced emissive amber/green on merchandise and buttons. Added framed aisle placards, printed bags and bottle fronts; retained existing detailed counter, register, scanner, coffee machine, refrigeration, ceiling fixtures, vents, cables and pump hoses.
- Added a separate staff restroom in unused office space, toilet/sink/soap/fixture, rear service exit, storage rack rails, housekeeping equipment, an extinguisher silhouette and readable handover/notice interactions. New decorative pieces do not add invisible movement blockers.
- The wall clock now follows shift minutes and dawn. Occasional distant traffic has wheels, windows, lamps and a bounded travel/cooldown cycle. Rain emission points avoid the pump canopy as well as the store.
- Replaced repeated cone crowns with six shared irregular conifer meshes and instanced varied transforms. Existing forest placement seed and clear station/road space remain.
- Added cached first-person coffee/chips/water/crate models. They have no collision and use a visual layer excluded from CCTV. Successful scanning briefly changes the actual scanner strip, and restocking now visibly fills gaps in the snack display.

### Characters, horror and campaign

- Retained the four original monster IDs, permanent detection clues, CCTV visibility rule, roster identities and decision consequences. Existing four attack variations, reduced-effects handling, sound synthesis and five-night finale remain functional.
- Articulated knees and elbows improve walking and waiting. Added shoe details, clothing seams/pockets, independent human build/height variation, varied face/nose widths and smaller human head proportions.
- Watchers remain unblinking with rare bounded neck corrections. Mimic/Broken One proportions, expressions, head tracking and fair dialogue remain. Outdoor/shelf silhouettes now have humanoid limbs and face the observer.
- The final close-up review also remastered the attack rig: smaller recessed eyes, brow/cheek forms, a darker scalp, an elliptical mouth cavity, shorter irregular teeth and articulated curling fingers replace the old oversized sockets, square mouth and rigid finger rods. Four attack identities and the reduced-effects option remain.
- Added five numeric tension levels, temporary environmental silence, a moving shelf shadow and an occasional imitation repeating a previous human's line. Dialogue echoes retain the explicit Mimic clue. Availability checks avoid wasting camera/vanish events in unsuitable contexts; normal global/per-event cooldowns and scheduled phone/storage warnings remain.
- Readable office and missing-person notes connect the predecessor, recordings and dawn ending. Reading freezes the shift consistently with the existing modal interactions. No campaign/save schema reset or replacement game loop.

### Final automated and rendered verification

Full command: `powershell -NoProfile -ExecutionPolicy Bypass -File tests/validate.ps1 -Rendered`.

| Suite | Result |
|---|---:|
| Godot editor/import | Clean |
| Campaign/gameplay | 157 passed |
| Existing overhaul | 65 / 65 |
| Physical collision/traversal | 90 / 90 |
| New remaster regressions | 59 / 59 |
| Actual Windows display/layout | 307 / 307 |
| Total assertions | **678 passed** |
| Rendered scenario captures | 33 |
| Native-display/debug captures | 34 |

- Final logs: `artifacts/3.0_import.log`, `3.0_gameplay.log`, `3.0_overhaul.log`, `3.0_polish.log`, `3.0_remaster.log`, `3.0_visual.log`, `3.0_performance.log`, `3.0_display.log`. No parser/runtime/shader errors, missing-resource errors or warnings in that final run. `3.0_main_scene_smoke.log` additionally records a clean native launch of the configured main scene with automatic exit.
- Campaign tests cover all five nights, transactions, tasks, monster clues, phone/storage choices, camera operation, save/load, retry, game over and victory. New checks cover service doors/ramp, occupied door closure, customer paths, notes, held props/CCTV exclusion, scanner/restock feedback, clock, traffic, silence, dialogue echo, rigs and legacy/new display preferences. The attack review caught a mesh-scale overwrite during mouth animation; all four rigs now sample their full animation range in a bounds regression.
- Native checks use the Windows renderer on a 3840 × 2160 monitor at 1280 × 720, 1366 × 768, 1600 × 900, 1920 × 1080, 2560 × 1440 and an additional 1280 × 960. These are actual windows, not headless display assertions.
- Inspected real screenshots of the menu, 720p/1440p HUD and settings, retail shelves, customers/monsters, restroom, service exit, held products, traffic, shelf shadow, long-note scrolling, CCTV, attacks and ending. The note inspection caught a signature/button overlap; the bounded scroll reader fixes it and has native regression coverage.

### Performance evidence

- Same project/camera/1280 × 720 store sample: baseline **1,699 draw calls / 1,811 nodes**; final **898 draw calls / 1,755 nodes**. The source-normalization batches share unit boxes, cylinders and print quads across sizes, retain 12m spatial cells and exclude doors, clocks, jobs, traffic, scanner feedback and restocked products.
- Final short uncapped RTX 5060 samples: **728.2 FPS store**, **709.1 FPS CCTV**, **768.8 FPS Low CCTV**. Raw logs record the engine/GPU. CCTV now warms for 40 frames before timing; baseline and final CCTV FPS therefore must not be interpreted as a controlled speedup. The draw-call reduction is measured; no minimum-spec FPS is claimed.

### Modified/new file inventory

Modified: `scenes/station.tscn`; `scripts/atmosphere.gd`, `audio.gd`, `customer.gd`, `encounter.gd`, `game.gd`, `horror_director.gd`, `interface.gd`, `palette.gd`, `player.gd`, `static_batch.gd`, `world.gd`; `shaders/surface.gdshader`; `tests/display_test.gd`, `performance_test.gd`, `validate.ps1`, `visual_test.gd`; `README.md`, `DEVELOPMENT_PROGRESS.md`.

New: `scripts/station_extension.gd`, `scripts/forest.gd`, `shaders/wet_asphalt.gdshader`, `tests/remaster_test.gd`, `assets/art/northstar_print_atlas.png`, `assets/art/PROVENANCE.md`, plus their generated Godot UID/import sidecars. Logs, screenshots and checkpoint archives are under the import-excluded `artifacts/` directory. `project.godot` and the user's original save were not changed by this continuation.

### Remaining human QA and next action

All automated checks currently pass. Next action is an uninterrupted human playthrough from Night 1 through dawn, using the README checklist. Still unverified: subjective headphone balance/comfort, multi-monitor/DPI/Alt-Tab and embedded-editor fullscreen behavior, arbitrary movement corners, and low-end hardware performance. The art remains procedural stylized low-poly with generated print artwork; no recorded voices, skeletal animation assets or standalone Windows export were added. The restroom, rear exit and functional clock listed as gaps in the older sections are now implemented.

Launch: open this existing `project.godot` in Godot 4.7.2, press F5, choose BEGIN SHIFT or CONTINUE, then CLOCK IN. The final verified source archive is `artifacts/checkpoints/night_shift_3.0_verified_20261023_final.zip`; the earlier verified archive is retained alongside it.

## October 22 history — earlier 3.0 implementation

### Inspection and preservation

- Used the actual Godot MCP project-information, project-launch and debug-output tools; installed engine remains Godot 4.7.2, Compatibility renderer.
- Reinspected the existing scene/script hierarchy, procedural collision generator, controller, display configuration, HUD/menu code, saves, documentation and tests. Baseline import, 157 campaign checks and 65 overhaul checks passed.
- Continued in this same project. Original IDs, five-night rosters, transaction rules, tasks, saves, camera masks and horror progression remain.
- Earlier pre-fix checkpoint: `../night_shift_ui_collision_20261022_183359.zip`.
- 3.0 checkpoint before further work: `../night_shift_before_3.0_20261022_183941.zip`, 63,491 bytes, SHA256 `19E4BB4B5D43147CC656D12EFEBCE307E3997C648564C54535E68BD180588756`. Includes sources, scenes, shaders, tests, configuration and documentation; generated cache and screenshot artifacts excluded.

### Root causes and fixes

- **Invisible floor blockers:** `NightPalette.box()` created StaticBody3D for every action even when `solid=false`. Hidden cleaning targets and the low restock marker therefore blocked feet. They now use Area3D on physics layer bit 4, mask 0; player physics sees layer 1 only, while the interaction ray sees both. Completed cleaning areas leave the ray layer until the next shift.
- **UI overlap:** HUD labels and panels had independent 1280 × 720 pixel positions, including a moved task label and fixed visitor backdrop. Anchored cards/VBox containers now manage compact top-left records, top-right objectives/visitor/inventory, lower-left vitals, centered prompts, subtitles and hints. Visitor arrival collapses objectives; Tab can expand them without overlap. Major modals center on the logical viewport; CCTV uses a container-managed video/control layout.
- **Window instability:** every preference change reapplied native window mode, with no preservation of window size/position. Fullscreen is now changed only when needed, uses native borderless fullscreen, preserves/restores the previous window geometry and keeps mouse capture. Alt+Enter and F11 toggle it; the settings checkbox stays synchronized. Canvas-items scaling explicitly expands the logical canvas while maintaining aspect, rather than stretching the 3D image.
- **Movement reliability:** retained the 0.28m capsule radius and safe standing clearance; set safe margin to 0.002m and floor snap to 0.18m. Head bob/steps now use actual movement instead of input against a wall. Door collisions remain attached to the same rotating visual pivots.
- **Interaction reliability:** fresh raycasts include non-blocking areas and still stop at solid scenery. Completed spill targets stop intercepting the ray. Physical proxy meshes are labelled; only intentional shelf/door/map/batched proxies retain hidden physical geometry.
- **Debug mode:** `-- --collision-debug` in a debug build enables orange physical/teal interaction overlays and blocking/nearby object names. F8 toggles it. Default and release runs omit it.

### Visual, animation, audio and performance polish

- Human eyes reduced to more natural proportions; added hair variation, shoulder shaping, collars, buttons, cuffs, hands/thumbs and shoe soles. Retained red eyes, elongated arms, camera absence and all existing clues.
- Walking limb motion is smoothed around the existing procedural rig. No customer route or AI state machine was replaced.
- Added crimped package tops, shared snack materials, fluorescent end caps, outlets and visual-only kick-plate scuffs. Reduced excessive surface noise and film grain while retaining wetness, grime, fog and readable clues.
- Attack playback is capped at -13 dB instead of the prior -8 dB default; volume/mute and reduced-effects controls remain. Audio code is validated; subjective headphone balancing is still manual.
- Static MultiMesh batches combine matching primitives/materials while excluding doors, tubes changed by power, spills and supernatural figures. Original collision/interaction nodes remain at the same transforms. Optional `--no-static-batching` supports comparison.
- Measured same-machine sample: the final artwork without batching reported **6,575 draw calls**, compared with **1,793** with batching. Short uncapped FPS samples varied substantially across runs; consult the logs rather than treating any single value as a minimum specification.

### Modified files

`project.godot`; `scripts/game.gd`, `interface.gd`, `palette.gd`, `player.gd`, `world.gd`, `customer.gd`, `atmosphere.gd`, `audio.gd`; `shaders/surface.gdshader`; new `scripts/collision_debug.gd` and `static_batch.gd`; new `tests/polish_test.gd`, `display_test.gd`, `window_persistence_probe.gd`; `tests/validate.ps1`; README and this file. No replacement project or external asset dependency.

### Current QA and continuation

- **Final run: import clean; 157 campaign + 65 overhaul + 52 collision/traversal + 125 native-display checks passed (399 total).** No parser/runtime/shader warnings or errors were reported by the final validation logs.
- Rendered harnesses produced **23 scenario captures plus 33 native-display/debug captures**. Reviewed the actual 720p and 1440p HUD, expanded tasks, 1080p briefing, 4:3 layout, settings, human/monster faces, CCTV, collision overlay and encounter images.
- Latest 1280 × 720 uncapped sample on the RTX 5060: **424.0 FPS store**, **373.0 FPS CCTV**, **475.9 FPS Low CCTV**, 1,793 store draw calls. Earlier batched samples ranged roughly 207–427 FPS for the store, so these short measurements are local observations, not an FPS guarantee.
- MCP launch returned success but its subsequent debug query had no active process handle. Sustained tests and captures used the installed console executable. A normal interactive game launch was also started via the installed Windows executable after validation; see `artifacts/3.0_launch.log`.

- Current logs are `artifacts/3.0_import.log`, `3.0_gameplay.log`, `3.0_overhaul.log`, `3.0_polish.log`, `3.0_visual.log`, `3.0_performance.log`, `3.0_display.log`.
- Native display tests use the actual Windows renderer on this **3840 × 2160** monitor. They exercise 1280 × 720, 1366 × 768, 1600 × 900, 1920 × 1080, 2560 × 1440 and an additional 1280 × 960 window. Fullscreen fills the native monitor, preserves mouse capture, restores window size and persists into a separate engine process.
- Screenshot review found the old CCTV buttons extending below their frame; the new container layout addresses that. Review also caught a test setup that left HUD hidden after menu capture; the harness now checks real visibility at every resolution.
- Physical regression paths cross all three spills, the restock marker, both aisles, refrigerator approach, both sides of the counter, pump/parking routes and all three doorways in both directions. Closed doors must block and open doors must permit passage.
- Existing overhaul checks continue to exercise jump/landing, standing clearance, all encounter rigs, camera signal states, save corruption/recovery and legacy settings. Existing campaign checks exercise all five nights, tasks, transactions, monster detection and ending.
- Manual QA remains: uninterrupted five-night human playthrough, subjective audio/comfort evaluation, multi-monitor/DPI/Alt-Tab behavior and editor-embedded game fullscreen behavior. No standalone Windows export was made. Art remains procedural stylized low-poly; no recorded voices or skeletal animation assets.
- Original scope gaps remain: separate restroom and usable rear exit are absent; the wall clock is decorative while the HUD clock is authoritative. No reproducible unintended blocker remains on the tested paths; arbitrary corner interactions still benefit from human playtesting.

## Scope and preservation

Improve the existing game in place. Preserve the five-night roster, transaction rules, tasks, camera detection, phone/storage warnings, progression and version-1 saves. Do not create another project. No external assets required. No subagents used.

## Phase 0 — inspected and baseline validated

Backup: `../night_shift_before_2.0_20261022_135224.zip` (50 entries, 11,483,651 bytes). SHA256: `9D18B419D0ADAB74D5BCCF7FF1D49085745BB680285A5600378D29020419DD2B`. Reopened successfully. Initial ZIP attempt failed to load a .NET assembly; the second attempt succeeded before any source edits.

- Read all nine gameplay scripts, all four scenes, all three test scripts, configuration, README, development notes and existing validation logs. Catalogued screenshot artifacts and UID files. `.godot` is generated cache.
- Main scene: `scenes/night_shift.tscn` -> `scripts/game.gd`. Geometry is generated by `world.gd`; controller `player.gd`; characters `customer.gd`; UI `interface.gd`; horror `horror_director.gd`; shared-world camera `security.gd`; PCM audio `audio.gd`; geometry helpers `palette.gd`.
- Godot MCP discovered and used for version and project information: **4.7.2.stable.official.ed1daf0bf**, Compatibility renderer. Console executable: `../../Godot_v4.7.2-stable_win64_console.exe`.
- Executed baseline editor/import validation successfully and gameplay suite: **157 checks passed**.
- No Git repository or applicable AGENTS.md found. A sibling ZIP backup is created before source changes; see backup record below. Generated cache excluded; original source and artifacts included.
- Existing working systems: transactions and rejection penalties, four monster IDs, waypoints, doors, ray interactions, five-night campaign, chores, saves/settings, live CCTV, paced/scheduled hazards and basic scare.

## Overhaul batches — implemented and validated

1. Surface/window shaders, environmental detail and weather/lighting controls: complete.
2. Watcher (`red_eyes`), Mimic (`mimic`), Shadow (`absent`), Broken One (`final`) animation and clue improvements: complete; original IDs and roster rules retained.
3. Tension/cooldowns, ambient events, spatial audio, distinct attacks and explicit camera signal states: complete.
4. Settings integration, player reliability, save recovery, regression tests and rendered review: complete in this continuation.
5. Current documentation and validation artifacts: updated. Next recommended work is a continuous human campaign playthrough and subjective sound balancing.

## Modified-file inventory

- `DEVELOPMENT_PROGRESS.md` (new): ongoing development handoff requested by user.
- Phase 1: `scenes/station.tscn` (MCP added AtmosphereDetails), `scripts/world.gd`, new `scripts/atmosphere.gd`, `shaders/surface.gdshader`, `shaders/rain_glass.gdshader`.
- Phase 2/3 implementation: `scripts/customer.gd`, `scripts/palette.gd`, `scripts/game.gd`, `scripts/horror_director.gd`.
- Encounter/audio/camera batch: `scripts/audio.gd`, `scripts/encounter.gd`, `scripts/security.gd`, `scripts/interface.gd`, `shaders/cctv.gdshader`, `shaders/encounter_screen.gdshader`.
- Continuation: `scripts/game.gd`, `scripts/player.gd`, `scripts/interface.gd`, `scripts/horror_director.gd`; new `tests/overhaul_test.gd`; updated existing gameplay/visual/performance scripts and `tests/validate.ps1`; README and this checkpoint.

## Phase 1 — environment batch complete

- Added world-space grain, grime and wetness shaders; animated rain glass; ceiling panels/vents; counter slats/printer/keypad; chiller doors/caps/vents; electrical details; signs; pump hoses; drains; dumpster; road sign and bare forest branches.
- Warm front-shop lights contrast with cooler rear fluorescent fixtures and moonlight. Added emergency lamp and lightning infrastructure; graphics preset hooks await UI integration.
- Existing interaction geometry and customer routes preserved. Door tween now accepts a slow-event duration.
- Executed Godot editor/import validation and existing gameplay suite after this batch: **157 checks passed**. Rendered review is pending.

## Phase 2/3 — monster and animation batch complete

- Preserved monster IDs/rosters and assigned Watcher, Mimic, Shadow, Broken One identities. Added low-poly skull/jaw/ears, sockets, asymmetry, teeth, blinking humans, head tracking, breathing, copied posture, gliding Shadow and Broken One joint motion.
- Added rare per-customer cues, human appearance/dialogue/rejection variation and variable arrival gaps.
- Next: validate this batch, then implement tension/audio/camera/scare changes. Update unfinished list at final QA.

Phase 2/3 validation: editor/import succeeded; **157 gameplay checks passed** after monster/animation changes. Original camera masks, all rosters and customer paths still pass.

## Phase 4–7 — tension, audio, encounters and CCTV integration

- Added adaptive tension bands, global/per-event cooldowns, repeat suppression, bounded event history, observation-sensitive window/forest figures, false mirror image, distant footsteps, behind-player whispers, thunder and rare monitor face. Scheduled dangerous choices retain original warnings. Undecided customers never disappear.
- Added PCM wind/hum/drone loops, breath/door/cash/thunder/joint sounds, indoor rain attenuation and bounded one-shot voices; no file dependencies.
- New `scripts/encounter.gd` supplies four camera-relative lunge/face/jaw/arm variations, dedicated lighting, smooth fade; `shaders/encounter_screen.gdshader` supplies mild chromatic distortion. Reduced effects suppress distortion and lightning.
- `scripts/security.gd` now throttles live frames, adds switching/dropout timers and explicit unreliable-signal labels; `shaders/cctv.gdshader` provides interference/monitor face.
- First import caught a type inference error in tension target; explicit float annotation added. Full validation pending for this batch.
- MCP launch reported success but a later debug query found no active process. Do not count that as a verified live run. Use console-rendered visual harness for reliable capture/logging.
- Next: run import/gameplay; integrate graphics/UI settings and save/player fixes; add focused tests and render review.

## Continuation completed — 2026-10-22

- Inspected all source scripts, scenes, shaders, tests, configuration, documentation and artifact inventory. Confirmed the actual project through Godot MCP. No replacement project was created.
- Source backup before continuation edits: `../night_shift_resume_20261022_180648.zip` (56,364 bytes; scripts, scenes, shaders, tests, configuration and documentation).
- Backup SHA256: `69E37AD213180EDDBC7BE27583974B7C2FDA173C798B7B65197A382D01AA874E`.
- Fresh baseline import and 157 gameplay checks passed before modifications. Existing 2.0 encounter, audio and CCTV code was present and functional; earlier pending notes above are historical.
- Added live Low graphics and FOV controls, consistent settings layout and numerical FOV display. Zero volume now mutes. Reduced effects immediately clears active lightning and hides grain; distortion is suppressed.
- Added Space jump, a physics clearance check before standing from crouch, and complete controller reset on retry. Repeated input setup no longer duplicates bindings.
- Saves validate JSON/schema, retain the prior valid checkpoint, recover from backup or interrupted temporary files, reject incorrect setting types, and report recovery/failure. Version-one format is retained.
- Added line-of-sight checks for observation-sensitive figures. Solid walls obstruct observation; front glass allows it.
- Added a dark HUD order panel. Rendered review found briefing text escaping the modal because wrapping was enabled after Godot calculated its minimum width. Wrapping is now configured before text creation, with regression checks for all five briefings.
- Test scripts now refuse to run without the isolated-save flag and clean their test backup files. The validator records native stderr before reporting failures.

## Current verification

- Godot **4.7.2.stable.official.ed1daf0bf**, Windows, Compatibility renderer.
- **157 gameplay checks + 65 overhaul checks passed** in fresh engine processes. Includes the original complete campaign, real movement/collision/raycast checks, four encounter rigs, camera reliability states, tension pacing, save corruption/recovery, legacy settings and all briefing bounds.
- Editor/import completed with no parser errors. Rendered harness captured **23 screenshots** with no reported shader/runtime errors. Reviewed settings, station, Watcher/Mimic, live/absent/static CCTV, exterior, attack/reduced-effects, briefing and ending images.
- GPU performance results are in `artifacts/2.0_performance.log`. These are short, uncapped 180-frame local samples at 1280 × 720 on an RTX 5060, not a minimum-spec guarantee.
- Final sample: **224.7 FPS store**, **206.3 FPS standard CCTV**, **228.9 FPS Low CCTV**; store sample reported 5,626 draw calls and 1,615 nodes.
- Godot MCP was used for project/version inspection and an actual project launch; its debug output reported the NVIDIA renderer and no errors. Its process handle was no longer active at the later stop call, so sustained validation used the console engine and rendered harness.
- Current logs: `artifacts/2.0_import.log`, `2.0_gameplay.log`, `2.0_overhaul.log`, `2.0_visual.log`, `2.0_performance.log`.

## Remaining limitations / human QA

- No known failing automated check remains. Full continuous human playthrough and subjective audio balancing are still required.
- Art and audio are procedural. The four attacks share a constructed rig with different motion/anatomy treatments; no recorded voice acting.
- The mirror event is an authored false figure, not a real reflected viewport. CCTV is a real live viewport.
- The original campaign deliberately uses the caller-invitation hazard, not a three-ring answering rule; no campaign rule was replaced during this overhaul.
- Original environment scope still lacks a separate restroom and usable rear exit. The wall clock is decorative; the HUD clock is authoritative. These were outside the unfinished 2.0 continuation batches and remain future work.
- High mesh/draw-call counts warrant testing on lower-end hardware. No standalone Windows export was generated.

## Reproduction commands (PowerShell, project directory)

```powershell
& '../../Godot_v4.7.2-stable_win64_console.exe' --headless --path . --editor --import --quit
& '../../Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/gameplay_test.gd -- --night-shift-test
& '../../Godot_v4.7.2-stable_win64_console.exe' --path . --script res://tests/visual_test.gd -- --night-shift-test
& '../../Godot_v4.7.2-stable_win64_console.exe' --path . --disable-vsync --script res://tests/performance_test.gd -- --night-shift-test
```

Tests must use `--night-shift-test` to isolate saves from the player's campaign. Never infer a passed test from an old log.
