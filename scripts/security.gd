extends Node

var game: Node
var viewport: SubViewport
var camera: Camera3D
var index := 2
var names := ["01 / PARKING LOT", "02 / ENTRANCE", "03 / STORE", "04 / STORAGE CORRIDOR"]
var switch_time := 0.0
var blackout_time := 0.0
var face_time := 0.0
var frame_time := 0.0

func _ready() -> void:
	viewport = SubViewport.new()
	viewport.size = Vector2i(768, 432)
	viewport.own_world_3d = false
	viewport.world_3d = game.get_viewport().world_3d
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(viewport)
	camera = Camera3D.new()
	camera.cull_mask = 1
	camera.fov = 85
	viewport.add_child(camera)
	camera.current = true
	select(2)

func select(value: int) -> void:
	index = wrapi(value, 0, 4)
	switch_time = 0.28
	frame_time = 0
	camera.position = game.world.camera_positions[index]
	camera.fov = 65 if index == 2 else 85
	camera.look_at(game.world.camera_targets[index])
	if is_instance_valid(game.ui.camera_label):
		game.ui.camera_label.text = "● REC    " + names[index] + "    /    " + game.clock_text()

func open() -> void:
	if not game.world.powered:
		game.ui.toast("CCTV has no power. Restore the breaker in storage.")
		return
	game.set_mode("cameras")
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	game.ui.camera_screen(viewport.get_texture())
	select(index)
	game.camera_checked = true

func close() -> void:
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	game.ui.camera_view = null
	game.ui.camera_label = null
	switch_time = 0
	blackout_time = 0
	face_time = 0

func _process(delta: float) -> void:
	if game.mode in ["playing", "cameras"]:
		blackout_time = maxf(0, blackout_time - delta)
		face_time = maxf(0, face_time - delta)
	if game.mode != "cameras":
		return
	switch_time = maxf(0, switch_time - delta)
	frame_time -= delta
	if frame_time <= 0:
		frame_time = 1.0 / (15.0 if game.settings.get("low_graphics", false) else 24.0)
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	if not game.world.powered:
		game.close_overlay()
		game.ui.toast("CAMERA LINK LOST. Restore power in storage.")
		return
	if is_instance_valid(game.ui.camera_view):
		game.ui.camera_view.material.set_shader_parameter("interference", game.director.interference > 0)
		game.ui.camera_view.material.set_shader_parameter("dropout", maxf(switch_time, blackout_time))
		game.ui.camera_view.material.set_shader_parameter("face", face_time)
		game.ui.camera_view.material.set_shader_parameter("reduced", game.settings.reduced_flashes)
	if is_instance_valid(game.ui.camera_label):
		game.ui.camera_label.text = "● REC    " + names[index] + "    /    " + game.clock_text() + "    " + signal_status()
		game.ui.camera_hint.text = "CLEAR LIVE FEED / Compare the visitor at the counter." if signal_clear() else "SIGNAL UNRELIABLE / Wait for a clear image before judging a missing visitor."

func signal_clear() -> bool:
	return game.world.powered and switch_time <= 0 and blackout_time <= 0 and face_time <= 0 and game.director.interference <= 0

func signal_status() -> String:
	if switch_time > 0: return "[CONNECTING]"
	return "[LIVE]" if signal_clear() else "[SIGNAL LOST]"

func apply_quality(low: bool) -> void:
	viewport.size = Vector2i(512, 288) if low else Vector2i(768, 432)
