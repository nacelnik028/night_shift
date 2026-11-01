extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if "--night-shift-test" not in OS.get_cmdline_user_args():
		push_error("Tests require --night-shift-test to isolate campaign saves.")
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	var game: Node3D = load("res://scenes/night_shift.tscn").instantiate()
	root.add_child(game)
	game.new_game()
	game.clock_in()
	game.player.enabled = false
	game.player.position = Vector3(0, 0.1, 5.5)
	game.player.rotation = Vector3.ZERO
	for i in range(40):
		await process_frame
	var start := Time.get_ticks_usec()
	for i in range(180):
		await process_frame
	var elapsed := (Time.get_ticks_usec() - start) / 1000000.0
	print("PERFORMANCE store: ", snappedf(180.0 / elapsed, 0.1), " FPS average / ", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), " draws / ", Performance.get_monitor(Performance.OBJECT_NODE_COUNT), " nodes")
	game.security.open()
	for i in range(40):
		await process_frame
	start = Time.get_ticks_usec()
	for i in range(180):
		await process_frame
	elapsed = (Time.get_ticks_usec() - start) / 1000000.0
	print("PERFORMANCE CCTV: ", snappedf(180.0 / elapsed, 0.1), " FPS average")
	game.settings.low_graphics = true
	game.apply_settings()
	for i in range(30):
		await process_frame
	start = Time.get_ticks_usec()
	for i in range(180):
		await process_frame
	elapsed = (Time.get_ticks_usec() - start) / 1000000.0
	print("PERFORMANCE low CCTV: ", snappedf(180.0 / elapsed, 0.1), " FPS average")
	for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
		if FileAccess.file_exists(game.save_path + suffix):
			DirAccess.remove_absolute(game.save_path + suffix)
	game.queue_free()
	await create_timer(0.25).timeout
	quit()
