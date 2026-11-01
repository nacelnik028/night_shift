extends SceneTree
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if "--night-shift-test" not in OS.get_cmdline_user_args():
		quit(1)
		return
	var game: Node3D = load("res://scenes/night_shift.tscn").instantiate()
	root.add_child(game)
	game.save_path = "user://night_shift.display.test.json"
	game.load_progress(true)
	var success: bool = game.settings.fullscreen == true and game.has_save
	print("SEPARATE PROCESS FULLSCREEN PREFERENCE: ", success)
	game.queue_free()
	await process_frame
	await create_timer(0.3).timeout
	quit(0 if success else 1)
