extends SceneTree
var game: Node3D
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + message)
	else:
		print("PASS: ", message)

func settle() -> void:
	for i in range(8):
		await process_frame
	await create_timer(0.1).timeout

func capture(title: String) -> void:
	await settle()
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png("res://artifacts/3.0_" + title + ".png")
	check(error == OK, "Rendered capture " + title)

func bounds(control: Control, title: String) -> void:
	var rect := control.get_global_rect()
	var screen := Rect2(Vector2.ZERO, game.ui.root.size)
	check(screen.grow(1).encloses(rect), title + " stays within logical viewport " + str(screen.size))

func run() -> void:
	if "--night-shift-test" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless":
		quit(1)
		return
	game = load("res://scenes/night_shift.tscn").instantiate()
	root.add_child(game)
	game.save_path = "user://night_shift.display.test.json"
	game.new_game()
	game.clock_in()
	game.set_process(false)
	game.director.set_process(false)
	game.player.enabled = false
	game.night = 5
	game.spawn_customer("mimic")
	game.active_customer.state = "waiting"
	game.active_customer.position = Vector3(5, 0, 4)
	game.active_customer.set_process(false)
	game.player.position = Vector3(5, 0.04, 0.5)
	game.player.rotation = Vector3(0, PI, 0)
	game.ui.tasks_open = true
	game.held_product = "coffee"
	game.carrying_crate = true
	game.ui.toast("The security office phone is ringing. Remember: never invite a caller inside.", 500)
	var debug := game.get_node("CollisionDebug")
	if debug.allowed:
		await capture("collision_debug")
		check(debug.displays.size() > 0 and game.ui.debug_text.visible, "Opt-in collision visualization runs")
		debug.enabled = false
	print("DISPLAY monitor size: ", DisplayServer.screen_get_size(root.current_screen))
	for resolution in [Vector2i(1280, 720), Vector2i(1366, 768), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(1280, 960)]:
		game.set_mode("playing")
		game.player.enabled = false
		root.mode = Window.MODE_WINDOWED
		root.size = resolution
		await settle()
		var title := "%dx%d" % [resolution.x, resolution.y]
		check(root.size == resolution, "Native window accepts " + title)
		check(game.ui.hud.is_visible_in_tree() and game.ui.order_backdrop.is_visible_in_tree(), title + " HUD and visitor card are rendered")
		for control in [game.ui.hud.get_node("ShiftRecord"), game.ui.right_column, game.ui.vital_card, game.ui.subtitle_card, game.ui.prompt, game.ui.controls_hint]:
			bounds(control, title + " " + str(control.name))
		check(not game.ui.order_backdrop.get_global_rect().intersects(game.ui.task_card.get_global_rect()), title + " visitor and objectives do not overlap")
		check(not game.ui.right_column.get_global_rect().intersects(game.ui.subtitle_card.get_global_rect()), title + " visitor column stays clear of subtitles")
		check(game.ui.right_column.get_global_rect().position.x > game.ui.root.size.x * 0.65, title + " visitor card leaves the central face visible")
		await capture(title + "_visitor")
		game.ui.tasks_open = true
		await settle()
		check(not game.ui.order_backdrop.get_global_rect().intersects(game.ui.task_card.get_global_rect()), title + " expanded assignments stay clear of visitor")
		bounds(game.ui.right_column, title + " expanded assignment column")
		if resolution == Vector2i(1280, 720):
			await capture(title + "_expanded_tasks")
		game.ui.tasks_open = false
		game.set_mode("menu")
		game.ui.main_menu()
		await settle()
		for control in game.ui.modal.find_child("MenuActions", true, false).get_children():
			if control is Control:
				bounds(control, title + " main menu control")
		await capture(title + "_menu")
		game.ui.settings_menu("menu")
		await settle()
		var settings_box: Control = game.ui.modal.get_child(1)
		for control in settings_box.find_children("*", "Control", true, false):
			if control.is_visible_in_tree() and (control is Label or control is Range or control is BaseButton):
				check(settings_box.get_global_rect().grow(1).encloses(control.get_global_rect()), title + " settings control fits: " + str(control.name))
		await capture(title + "_settings")
		game.ui.briefing()
		await capture(title + "_briefing")
		game.set_mode("playing")
		game.ui.clear_modal()
		game.player.enabled = false
	# Exercise the actual settings callbacks, including native exclusive mode.
	game.set_mode("pause")
	game.ui.settings_menu("pause")
	for i in range(game.WINDOW_RESOLUTIONS.size()):
		game.ui.resolution_selector.item_selected.emit(i)
		await settle()
		check(root.size == game.WINDOW_RESOLUTIONS[i], "Resolution selector applies " + str(game.WINDOW_RESOLUTIONS[i]))
	game.ui.display_selector.item_selected.emit(2)
	await settle()
	check(root.mode == Window.MODE_EXCLUSIVE_FULLSCREEN, "Exclusive fullscreen is active in the native renderer")
	check(root.size == DisplayServer.screen_get_size(root.current_screen), "Exclusive fullscreen fills the monitor")
	game.ui.display_selector.item_selected.emit(1)
	await settle()
	check(root.mode == Window.MODE_FULLSCREEN, "Exclusive mode switches directly to borderless")
	game.ui.resolution_selector.item_selected.emit(2)
	game.ui.display_selector.item_selected.emit(0)
	await settle()
	check(root.mode == Window.MODE_WINDOWED and root.size == Vector2i(1600, 900), "Window resolution selected during fullscreen is restored")
	game.ui.display_selector.grab_focus()
	var focused_event := InputEventKey.new()
	focused_event.keycode = KEY_ENTER
	focused_event.alt_pressed = true
	focused_event.pressed = true
	Input.parse_input_event(focused_event)
	await settle()
	check(root.mode == Window.MODE_FULLSCREEN, "Alt+Enter works while a settings control has keyboard focus")
	focused_event.pressed = false
	Input.parse_input_event(focused_event)
	game.set_display_mode(0)
	await settle()
	game.ui.clear_modal()
	# Native borderless fullscreen and return, including capture and save persistence.
	game.set_window_resolution(Vector2i(1280, 720))
	await settle()
	game.set_mode("playing")
	var mouse_before := Input.mouse_mode
	game.settings.fullscreen = true
	game.apply_window_mode()
	await settle()
	check(root.mode == Window.MODE_FULLSCREEN, "Native borderless fullscreen mode is active")
	check(root.size == DisplayServer.screen_get_size(root.current_screen), "Fullscreen fills the current monitor")
	check(Input.mouse_mode == mouse_before, "Fullscreen preserves captured mouse")
	game.apply_settings()
	check(root.mode == Window.MODE_FULLSCREEN, "Unrelated settings do not reset fullscreen")
	game.save_progress()
	var probe_output: Array = []
	var probe_code := OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", "res://tests/window_persistence_probe.gd", "--", "--night-shift-test"], probe_output)
	check(probe_code == 0, "A separate engine process reloads the fullscreen preference")
	game.settings.fullscreen = false
	game.load_progress(true)
	check(game.settings.fullscreen == true, "Fullscreen preference survives save/load")
	await capture("fullscreen")
	var event := InputEventKey.new()
	event.keycode = KEY_ENTER
	event.alt_pressed = true
	event.pressed = true
	game._unhandled_input(event)
	await settle()
	check(root.mode == Window.MODE_WINDOWED and not game.settings.fullscreen, "Alt+Enter returns to windowed mode")
	check(root.size == Vector2i(1280, 720), "Leaving fullscreen restores window size")
	check(Input.mouse_mode == mouse_before, "Window restoration preserves captured mouse")
	game.player.enabled = false
	# F11 is a second supported shortcut; it must not update the player's position.
	var old_position: Vector3 = game.player.position
	event.keycode = KEY_F11
	event.alt_pressed = false
	game._unhandled_input(event)
	await settle()
	check(root.mode == Window.MODE_FULLSCREEN and game.player.position == old_position, "F11 toggles fullscreen without moving the player")
	game.settings.fullscreen = false
	game.apply_window_mode()
	await settle()
	for entry in ["pause", "register", "phone", "gameover", "victory"]:
		game.set_mode(entry)
		match entry:
			"pause": game.ui.pause_menu()
			"register": game.ui.register_menu()
			"phone": game.ui.phone_screen()
			"gameover": game.ui.result_screen(false)
			"victory": game.ui.result_screen(true, true)
		await capture(entry)
	game.set_mode("playing")
	game.security.open()
	game.security.select(2)
	await create_timer(0.5).timeout
	await capture("cctv")
	var frame: Control = game.ui.modal.get_node("CameraFrame")
	for control in frame.find_children("*", "Button", true, false):
		check(frame.get_global_rect().encloses(control.get_global_rect()), "CCTV button stays within its panel")
	game.close_overlay()
	# Long environmental text must scroll above its dismissal button.
	game.interact("note:handover")
	await settle()
	var reader: ScrollContainer = game.ui.modal.find_child("NoteReader", true, false)
	var note_panel: Control = reader.get_parent()
	check(note_panel.get_global_rect().encloses(reader.get_global_rect()), "Note reader stays within its modal")
	check(reader.get_global_rect().end.y < note_panel.get_children().back().get_global_rect().position.y, "Long note cannot overlap its dismissal button")
	reader.scroll_vertical = 10000
	await settle()
	check(reader.scroll_vertical > 0, "Long handover remains accessible by scrolling")
	await capture("handover_scrolled")
	game.close_overlay()
	for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
		if FileAccess.file_exists(game.save_path + suffix):
			DirAccess.remove_absolute(game.save_path + suffix)
	print("DISPLAY TESTS PASSED: ", checks - failures, " / ", checks)
	game.queue_free()
	await process_frame
	await create_timer(0.3).timeout
	quit(0 if failures == 0 else 1)
