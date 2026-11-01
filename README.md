# NIGHT SHIFT 3.0

A self-contained, first-person horror game for Godot 4.7.2. Five shifts at Northstar, a remote forest gas station. Built with procedural low-poly meshes, shaders, synthesized audio, live security cameras and a bundled Northstar print atlas; no asset downloads or addons are required.

## October 23 remaster

This continues the existing campaign in the same project. Version-one saves, customer identities, monster clues, jobs, transaction rules, CCTV detection and the five-night ending remain supported.

- Three display modes: windowed, borderless fullscreen and exclusive fullscreen. Five window resolutions persist with settings; Alt+Enter works even when menu controls have focus.
- A clearer visitor card with a patience bar, container-based settings, unclipped warning text, and a cinematic menu that leaves the rainy station visible.
- Printed snack bags, bottle labels, coffee advertising and a missing-person poster; finer tiled floors, wet asphalt, less emissive retail props, irregular instanced conifers and occasional distant traffic.
- An employee restroom in the eastern office corner, a working rear storage exit with a shallow ramp, cleaning equipment, handover notes and a wall clock synchronized with the shift.
- Articulated knees/elbows, varied human builds and facial features, rare Watcher neck corrections, a more human-shaped apparition and shadows moving between shelves. Attack close-ups have refined eye sockets, facial anatomy, irregular teeth and curling fingers.
- Five tension levels, brief environmental silence and rare repeated customer dialogue, with cooldowns and permanent monster clues preserved.
- Visible held products/crates and scanner feedback. First-person props are excluded from CCTV. Customer paths now go around the raised pump islands; closing doors check the player's capsule across their swing.

The bundled artwork is in `assets/art/northstar_print_atlas.png`; its generation prompt and provenance are in `assets/art/PROVENANCE.md`. See `DEVELOPMENT_PROGRESS.md` for the exact changes, evidence and remaining human QA.

## Play

Open `project.godot` in Godot and press **F5**. Choose **BEGIN SHIFT**, read the handover, then **CLOCK IN**. Continue resumes the latest unlocked night at its beginning. Beginning a new game replaces the campaign checkpoint.

| Control | Action |
|---|---|
| WASD / mouse | Move / look |
| Shift | Sprint, using stamina |
| Ctrl | Crouch |
| Space | Jump (standing only) |
| E | Use the object under the crosshair |
| F | Toggle flashlight |
| Tab | Assignment sheet |
| Escape | Pause / leave an interaction screen |
| Alt+Enter / F11 | Toggle the selected fullscreen mode |
| Left / Right arrows | Switch CCTV channel while viewing cameras |

## Working a shift

Visitors walk in and wait across the counter. Their request and exact words appear in the HUD. Inspect their face and proportions. Starting on night 2, check the **STORE** camera in the rear security office. A customer missing from a clear live feed is an imitation.

For a human, collect the requested product, scan it on the black scanner next to the register, then use the register or green counter button to accept. Refuse an imitation with the register or red button. You do not need a product to refuse service. Accepting a monster is fatal even without a scanned item.

- **Coffee:** front-left coffee machine. $5 per sale.
- **Chips:** the two snack aisles. $4 per sale.
- **Water:** refrigerated drinks along the back wall. $3 per sale.
- **Cleaning:** look down at each of three dark spills, press E, and stay in place for two seconds.
- **Restocking:** collect a crate from rear storage, then use the RESTOCK marker at the snack aisle.
- **CCTV, telephone, flashlight charger:** rear-left security office.
- **Breaker:** right wall of rear-right storage room.
- **Restroom:** through security, in the office's rear-right corner. The rear service exit is beyond the crates in storage.
- **Notes:** inspect the office notices or missing-person poster with E; Escape puts the note down. Reading pauses the shift.

Refusing a human costs $8; an unanswered order costs $10. Three complaints end the shift, so indiscriminate refusal is not a winning strategy. Correct monster refusals keep you safe. Finish the visitor roster and chores and restore power before dawn. The clock waits at 05:59 if required work remains. Each completed shift pays an additional wage.

## Five-night campaign

1. **Induction:** five visitors; clear red-eye tells and an introductory human.
2. **Blind Spots:** six visitors; imitations absent from the live security feed.
3. **The Caller:** seven visitors; dangerous telephone invitations, distorted anatomy and impossible dialogue.
4. **After Hours:** eight visitors; outages, a storage-room voice and a repair trip in darkness.
5. **Last Light:** nine visitors; all tells, the final imitation, and a scripted dawn ending.

Patience decreases across nights. Middle roster positions shuffle on later nights. The final visitor and introductory encounter remain intentional. Random events add flickering, window taps, moving silhouettes, apparitions, doors and interference between the scheduled threats.

Warnings precede dangerous choices. Never invite a caller inside. Stay out of storage while the false voice is knocking; a message announces when it is safe. Static or a powerless monitor is not evidence of a missing customer—wait for a clear picture.

## Saves and settings

Campaign checkpoints and preferences are written to `user://night_shift.json`, using a verified temporary file and rename. The previous valid checkpoint is retained as `night_shift.json.bak`. A damaged or missing primary file automatically falls back to that backup, or a valid interrupted temporary save. Version-one campaign saves remain supported. On Windows the directory is normally `%APPDATA%/Godot/app_userdata/NIGHT SHIFT/`. Saves contain unlocked/completed nights, checkpoint money and settings. Retry restores the beginning-of-night cash balance. Mid-shift positions and visitors are intentionally not saved.

Settings provide volume, sensitivity, field of view (65–100 degrees), windowed/borderless/exclusive display mode, window resolution, head bob, reduced effects and graphics quality. The available window sizes are 1280 × 720, 1366 × 768, 1600 × 900, 1920 × 1080 and 2560 × 1440. Fullscreen uses the monitor's native size; a window size selected during fullscreen applies on return. Oversized windows fit the desktop. Low graphics reduces rain from 700 to 220 particles, stops animated window rain, and uses a 512 × 288 CCTV feed at 15 FPS instead of 768 × 432 at 24 FPS. Reduced effects suppresses lightning, grain and attack distortion and softens flicker and rig movement. Sudden sounds and horror imagery remain.

The 2.0 overhaul adds weathered surfaces, rain glass, richer station detail, warm/cold lighting contrast, emergency lighting, four animated monster identities and distinct attacks. The horror director responds to tension, spaces events apart, and adds spatial whispers, footsteps, thunder, false reflections and camera faults. CCTV explicitly labels connecting and unreliable feeds. Solid walls now prevent looking at a hidden apparition from dismissing it.

Version 3.0 fixes nonphysical floor interactions blocking movement, uses an anchored HUD with container-managed visitor/objective cards, and adds reliable native fullscreen switching with window restoration. Objectives collapse when a visitor arrives; Tab reopens them. Smaller human eyes, fitted clothing, hands, hair, smoother walking, crimped snack packages, fixture detail and subtler surface noise refine the same low-poly style. Repeated static geometry is instanced; original collision and interaction bodies remain in place.

Fullscreen fills the current monitor without stretching the 3D view. Native windows were tested at 1280 × 720, 1366 × 768, 1600 × 900, 1920 × 1080, 2560 × 1440 and 1280 × 960. Multi-monitor migration, unusual DPI configurations and the Godot editor's embedded game mode still warrant manual testing.

For collision debugging, start a debug build with `-- --collision-debug`, then use F8 to toggle translucent shape overlays and nearby/blocking object names. Orange denotes physical bodies; teal denotes non-blocking interaction areas. This mode requires explicit opt-in and is unavailable in release builds.

## Project organization

- `scenes/night_shift.tscn`: main scene and game state coordinator.
- `scenes/station.tscn`, `scripts/world.gd`: station, grounds, lights, props, doors and weather.
- `scenes/player.tscn`, `scripts/player.gd`: physical first-person controller and interaction ray.
- `scenes/customer.tscn`, `scripts/customer.gd`: generated appearances, clues, walking and patience.
- `scripts/security.gd`: one shared-world SubViewport, four camera positions, visibility masks.
- `scripts/horror_director.gd`: paced and scheduled supernatural events.
- `scripts/interface.gd`: menus, HUD, calls, CCTV and outcome screens.
- `scripts/audio.gd`: generated PCM rain, chimes, steps, whispers, rings and impacts, including positional cues.
- `scripts/atmosphere.gd`, `shaders/`: environmental detail, weather materials and screen effects.
- `scripts/encounter.gd`: four camera-relative animated attack variations.
- `scripts/static_batch.gd`: instancing for repeated static primitives, with dynamic/job objects excluded.
- `scripts/collision_debug.gd`: optional collision visualization and blocker identification.
- `scripts/station_extension.gd`, `forest.gd`: service rooms, rear access, traffic and shared conifer meshes.
- `assets/art/`: bundled print artwork and its provenance.

Geometry is generated when the scenes run. The editor scene tree is intentionally small; use Godot's **Remote** scene tree during play to inspect generated objects.

## Verification

Run from the project directory, substituting the path to your Godot executable:

```text
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/gameplay_test.gd -- --night-shift-test
godot --headless --path . --script res://tests/overhaul_test.gd -- --night-shift-test
godot --headless --path . --script res://tests/polish_test.gd -- --night-shift-test
godot --headless --path . --script res://tests/remaster_test.gd -- --night-shift-test
godot --path . --script res://tests/display_test.gd -- --night-shift-test
godot --path . --script res://tests/visual_test.gd -- --night-shift-test
godot --path . --disable-vsync --script res://tests/performance_test.gd -- --night-shift-test
```

Tests require `--night-shift-test` and use separate test saves; they do not overwrite the player's campaign. From PowerShell, `./tests/validate.ps1 -Rendered` runs import, gameplay, overhaul, physical traversal, screenshots, performance and native-window checks using the installed sibling engine. The display test also starts a separate headless engine to verify persisted fullscreen settings. `artifacts/` contains real engine screenshots and validation logs and is excluded from Godot's asset import scan. See `DEVELOPMENT_PROGRESS.md` for current 3.0 results; older sections retain the development history.

If Windows blocks local PowerShell scripts, use `powershell -NoProfile -ExecutionPolicy Bypass -File tests/validate.ps1 -Rendered`. This changes policy for that process only. The validator isolates its editor preferences and `user://` test data under `artifacts/qa_userdata`.

## Human playtesting

- Play all five nights continuously, including the phone/storage warnings, retry, Continue and final dawn.
- Change all display modes from menus and during a shift; try Alt+Enter, Alt+Tab, another monitor and Windows DPI scaling.
- Walk/crouch through each aisle and every doorway; stop in an entrance and try closing it. Return through the rear ramp without jumping.
- Compare each monster with a clear STORE camera feed, scan all three products, and finish cleaning/restocking.
- Review subtitles with tasks expanded, inspect the notes, and check 720p/1080p/1440p readability.
- Judge headphone levels, reduced effects and motion comfort. Test performance on a modest PC; recorded RTX 5060 samples are not a minimum specification.

The game retains a procedural stylized art direction. It does not include recorded voice acting or imported skeletal characters. Asphalt sheen is an authored shader effect rather than screen-space reflection. Automated campaign/display tests and screenshots supplement a human playthrough; no standalone Windows export is included.
