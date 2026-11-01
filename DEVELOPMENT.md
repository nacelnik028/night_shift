# Development checkpoint — 2026-10-22

## Status

All six requested development stages are implemented. The project started in an empty directory. Godot MCP discovery, version inspection, scene creation, project launch and debug-output inspection were used alongside direct filesystem edits and the installed Godot console executable.

1. Procedural furnished station and surrounding forest/forecourt, first-person controller, menu, HUD, collision and interaction system. Initial engine import and launch checked; a GDScript inference error was fixed.
2. Multiple generated visitor appearances, entrance/counter/departure routes, three purchasable products, scanner, register, money, penalties and monster clues. Initial seven transaction checks passed.
3. HorrorDirector, paced ambient events, warnings, power failure, moving figures and an animated mesh jumpscare. Transaction suite rerun after integration.
4. Shared-world SubViewport security cameras, invisible-on-camera render layer, telephone choices, cleaning, supply crates, charging and breaker repair. Engine-compiled and covered by the expanded integration suite.
5. Five distinct briefings, growing shuffled rosters, reduced patience, completion gates, wages, unlocks, retry/continue, atomic checkpoint saves, preferences and the final dawn ending.
6. Rendered screenshot review, readable red eyes, improved STORE camera framing, populated shelves, glass entrance, prop detail, positional audio, HUD/register layout fixes, reduced flashes, optimized shadow usage and performance sampling.

## Validation record

- Godot **4.7.2.stable.official.ed1daf0bf**, Windows, Compatibility renderer.
- Automated gameplay suite: **157 checks passed**. Covers transactions, complaints, all five rosters, entry/departure paths, final sequence, task gates, saves/settings, phone hazards, storage hazards, camera masks, power, movement/door collision and ray access to all principal interactions.
- Actual rendered screenshot script captures 13 views: menu, store, customer, camera, exterior, scare, register, absent visitor feed, office, phone, briefing, dawn and victory.
- Screenshot review caught washed-out eye clues, an obstructed camera view, an overlapping register layout, shadow artifacts and an initially opaque entrance. These were corrected.
- Physics testing caught an outward-swinging office door pushing the player sideways. Doors now open into their rooms, and the open/closed traversal checks pass.
- A short 180-frame uncapped sample at the default 1280 × 720 on the connected NVIDIA RTX 5060 measured approximately **249 FPS in-store** and **189 FPS with CCTV**. This is a local sample, not a hardware-wide performance promise.
- The integration harness waits for the audio mixer to release streams before quitting; the final test run should have no exit-time audio leak warning.

## Scope and practical limits

This is a complete small campaign built around procedural low-poly art. Dialogue is written on screen with synthesized sound cues; there is no recorded voice acting. Visitors use tested fixed waypoint routes through this specific station instead of a general navigation mesh. Security video is a real view of the current world. The final sequence is scripted, followed by a victory screen.

Automated tests accelerate the scenario and sometimes place the player or visitors at known positions. Collision and interaction-ray checks run through Godot physics, and the separate visual script renders with the actual GPU. A continuous human playthrough of all five nights and subjective audio balancing were not performed. No standalone platform export was produced; F5 runs the complete project directly.

## Maintenance

The gameplay test is `tests/gameplay_test.gd`; visual and performance checks are beside it. All current game logic is implemented in real GDScript. There are no external art/audio dependencies or placeholder script calls. Future work can focus on authored character art, additional dialogue variety, accessibility refinement and human playtesting without replacing the working systems.
