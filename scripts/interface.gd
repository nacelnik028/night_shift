extends CanvasLayer

const INK := Color("091319")
const PAPER := Color("dce5d6")
const MINT := Color("8fe2c0")
const AMBER := Color("edb66e")
var game: Node
var root: Control
var hud: Control
var modal: Control
var header: Label
var status: Label
var prompt: Label
var subtitle: Label
var tasks: Label
var customer_text: Label
var carried_text: Label
var stamina_bar: ProgressBar
var battery_bar: ProgressBar
var message_timer := 0.0
var tasks_open := false
var camera_view: TextureRect
var camera_label: Label
var camera_hint: Label
var noise: ColorRect
var flash: ColorRect
var progress: ProgressBar
var scare_effect: ColorRect
var order_backdrop: PanelContainer
var task_card: PanelContainer
var right_column: VBoxContainer
var subtitle_card: PanelContainer
var vital_card: PanelContainer
var controls_hint: Label
var debug_text: Label
var display_selector: OptionButton
var resolution_selector: OptionButton
var patience_bar: ProgressBar
var visitor_dialogue: Label
var visitor_order: Label
var visitor_was_waiting := false

func _ready() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var theme := Theme.new()
	theme.default_font_size = 20
	theme.set_color("font_color", "Label", PAPER)
	theme.set_color("font_color", "Button", PAPER)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("18312f") if state in ["hover", "focus"] else Color("111f24")
		style.border_color = MINT if state in ["hover", "focus"] else Color("344640")
		style.set_border_width_all(1)
		style.content_margin_left = 20
		style.content_margin_right = 20
		style.content_margin_top = 12
		style.content_margin_bottom = 12
		theme.set_stylebox(state, "Button", style)
	root.theme = theme
	build_hud()
	noise = ColorRect.new()
	noise.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	noise.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; uniform float strength = 0.018; void fragment(){ vec2 uv=UV; float grain=fract(sin(dot(uv*TIME,vec2(12.9898,78.233)))*43758.5453); float vignette=smoothstep(0.25,0.78,distance(uv,vec2(0.5))); COLOR=vec4(vec3(grain*0.12),vignette*0.35+grain*strength); }"
	var shader_material := ShaderMaterial.new()
	shader_material.shader = shader
	noise.material = shader_material
	root.add_child(noise)
	modal = Control.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(modal)
	scare_effect = ColorRect.new()
	scare_effect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scare_effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var scare_material := ShaderMaterial.new()
	scare_material.shader = preload("res://shaders/encounter_screen.gdshader")
	scare_effect.material = scare_material
	scare_effect.visible = false
	root.add_child(scare_effect)
	flash = ColorRect.new()
	flash.color = Color(0.5, 0, 0, 0)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(flash)

func label(parent: Node, words: String, pos: Vector2, size: int = 20, color: Color = PAPER, width: float = 700, wrap: bool = false) -> Label:
	var node := Label.new()
	if wrap:
		node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.text = words
	node.position = pos
	node.size.x = width
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	parent.add_child(node)
	return node

func panel(parent: Node, pos: Vector2, dimensions: Vector2, alpha: float = 0.94) -> Panel:
	var node := Panel.new()
	node.position = pos
	node.size = dimensions
	var style := StyleBoxFlat.new()
	style.bg_color = Color(INK, alpha)
	style.border_color = Color("34463f")
	style.set_border_width_all(1)
	node.add_theme_stylebox_override("panel", style)
	parent.add_child(node)
	return node

func button(parent: Node, words: String, pos: Vector2, callback: Callable, width: float = 340) -> Button:
	var node := Button.new()
	node.text = words
	node.position = pos
	node.size = Vector2(width, 48)
	node.alignment = HORIZONTAL_ALIGNMENT_LEFT
	node.pressed.connect(func(): game.sound.play_effect("click"); callback.call())
	parent.add_child(node)
	return node

func build_hud() -> void:
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud)
	var record := hud_card(hud)
	record.name = "ShiftRecord"
	record.position = Vector2(24, 24)
	record.custom_minimum_size.x = 300
	var record_stack := stack_in(record)
	header = flow_label(record_stack, "NIGHT 01  /  12:00 AM", 21, PAPER)
	status = flow_label(record_stack, "", 13, MINT)
	right_column = VBoxContainer.new()
	right_column.name = "ObjectivesAndVisitor"
	hud.add_child(right_column)
	right_column.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	right_column.offset_left = -344
	right_column.offset_right = -24
	right_column.offset_top = 24
	right_column.add_theme_constant_override("separation", 10)
	right_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	task_card = hud_card(right_column)
	tasks = flow_label(stack_in(task_card), "", 15, MINT)
	order_backdrop = hud_card(right_column)
	var order_stack := stack_in(order_backdrop)
	flow_label(order_stack, "VISITOR AT THE COUNTER", 12, AMBER)
	customer_text = flow_label(order_stack, "", 14, PAPER)
	visitor_dialogue = flow_label(order_stack, "", 16, PAPER)
	visitor_order = flow_label(order_stack, "", 13, AMBER)
	patience_bar = meter(Vector2.ZERO, Vector2(280, 4), AMBER)
	patience_bar.reparent(order_stack)
	patience_bar.custom_minimum_size.y = 4
	flow_label(order_stack, "Inspect face · camera · words\nScan the order, then use the register.", 12, MINT)
	carried_text = flow_label(right_column, "", 13, AMBER)
	var crosshair := flow_label(hud, "·", 26, PAPER)
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.offset_left = -8
	crosshair.offset_top = -18
	crosshair.offset_right = 8
	crosshair.offset_bottom = 18
	crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt = flow_label(hud, "", 16, PAPER)
	prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	prompt.offset_left = -260
	prompt.offset_right = 260
	prompt.offset_top = 46
	prompt.offset_bottom = 76
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_card = hud_card(hud)
	subtitle_card.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	subtitle_card.offset_left = -294
	subtitle_card.offset_right = 294
	subtitle_card.offset_top = -140
	subtitle_card.offset_bottom = -60
	subtitle_card.grow_vertical = Control.GROW_DIRECTION_BEGIN
	subtitle = flow_label(stack_in(subtitle_card), "", 17, AMBER)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Let the container grow for long warnings instead of silently clipping text.
	subtitle.max_lines_visible = -1
	controls_hint = flow_label(hud, "[E] USE   [F] LIGHT   [TAB] TASKS   [ESC] PAUSE", 12, Color("8b9f99"))
	controls_hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	controls_hint.offset_left = -300
	controls_hint.offset_right = 300
	controls_hint.offset_top = -34
	controls_hint.offset_bottom = -14
	controls_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vital_card = hud_card(hud)
	vital_card.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	vital_card.offset_left = 24
	vital_card.offset_right = 224
	vital_card.offset_top = -117
	vital_card.offset_bottom = -24
	var vitals := stack_in(vital_card)
	flow_label(vitals, "STAMINA", 11, MINT)
	stamina_bar = meter(Vector2.ZERO, Vector2(168, 5), MINT)
	stamina_bar.reparent(vitals)
	stamina_bar.custom_minimum_size.y = 5
	flow_label(vitals, "FLASHLIGHT", 11, AMBER)
	battery_bar = meter(Vector2.ZERO, Vector2(168, 5), AMBER)
	battery_bar.reparent(vitals)
	battery_bar.custom_minimum_size.y = 5
	progress = meter(Vector2.ZERO, Vector2(280, 5), MINT)
	progress.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	progress.offset_left = -140
	progress.offset_right = 140
	progress.offset_top = 86
	progress.offset_bottom = 91
	progress.visible = false
	debug_text = flow_label(hud, "", 13, AMBER)
	debug_text.position = Vector2(24, 120)
	debug_text.size = Vector2(490, 250)
	debug_text.visible = false

func hud_card(parent: Node) -> PanelContainer:
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(INK, 0.88)
	style.border_color = Color("34463f")
	style.set_border_width_all(1)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", style)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(card)
	return card

func stack_in(parent: Node) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(box)
	return box

func flow_label(parent: Node, words: String, size_value: int, color: Color) -> Label:
	var text := Label.new()
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.text = words
	text.add_theme_font_size_override("font_size", size_value)
	text.add_theme_color_override("font_color", color)
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(text)
	return text

func meter(pos: Vector2, dimensions: Vector2, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.position = pos
	bar.size = dimensions
	bar.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("253331")
	bg.content_margin_top = 0
	bg.content_margin_bottom = 0
	var fg := StyleBoxFlat.new()
	fg.bg_color = color
	fg.content_margin_top = 0
	fg.content_margin_bottom = 0
	bar.add_theme_font_size_override("font_size", 1)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fg)
	hud.add_child(bar)
	bar.size = dimensions
	return bar

func clear_modal() -> void:
	for child in modal.get_children():
		modal.remove_child(child)
		child.queue_free()
	modal.visible = false

func base_modal(kicker: String, title: String, description: String) -> Panel:
	clear_modal()
	modal.visible = true
	var dim := ColorRect.new()
	dim.color = Color(0.005, 0.015, 0.02, 0.65)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(dim)
	var box := panel(modal, Vector2(70, 62), Vector2(1140, 596))
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.offset_left = -570
	box.offset_right = 570
	box.offset_top = -298
	box.offset_bottom = 298
	label(box, kicker, Vector2(36, 30), 14, MINT, 1000)
	label(box, title, Vector2(32, 63), 56, PAPER, 1050)
	var desc := label(box, description, Vector2(36, 147), 20, Color("a5b8ae"), 1050, true)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size.x = 1050
	desc.name = "Description"
	return box

func main_menu() -> void:
	hud.visible = false
	clear_modal()
	modal.visible = true
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; void fragment(){float a=mix(0.90,0.05,smoothstep(0.10,0.77,UV.x)); COLOR=vec4(0.009,0.019,0.023,a);}"
	material.shader = shader
	shade.material = material
	modal.add_child(shade)
	var box := VBoxContainer.new()
	box.name = "MenuActions"
	box.position = Vector2(70, 40)
	box.size = Vector2(420, 628)
	box.add_theme_constant_override("separation", 10)
	modal.add_child(box)
	flow_label(box, "NORTHSTAR / COUNTY ROAD 16 / EST. 1978", 13, MINT)
	flow_label(box, "NIGHT\nSHIFT", 74, PAPER)
	flow_label(box, "Five nights. One station.\nSomething out there has learned to knock.", 17, Color("b2c5ba"))
	var gap := Control.new()
	gap.custom_minimum_size.y = 8
	box.add_child(gap)
	button(box, "BEGIN SHIFT   →", Vector2.ZERO, game.new_game)
	var resume := button(box, "CONTINUE  /  NIGHT %02d" % game.unlocked_night, Vector2.ZERO, game.continue_game)
	resume.disabled = not game.has_save
	button(box, "SETTINGS", Vector2.ZERO, func(): settings_menu("menu"))
	button(box, "QUIT", Vector2.ZERO, func(): game.get_tree().quit())
	flow_label(box, "INSPECT THE VISITOR. SCAN THE ORDER.\nSERVE A HUMAN. REFUSE AN IMITATION.", 12, MINT)
	var note := label(modal, "HEADPHONES RECOMMENDED\nSudden sounds, flashing lights and horror imagery", Vector2.ZERO, 12, Color("a1b5ab"), 520, true)
	note.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	note.offset_left = -545
	note.offset_right = -32
	note.offset_top = -65
	note.offset_bottom = -24
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if not game.save_notice.is_empty():
		flow_label(box, game.save_notice, 13, AMBER)

func briefing() -> void:
	var data: Dictionary = game.night_data()
	var box := base_modal("EMPLOYEE HANDOVER  /  OCTOBER %02d" % (21 + game.night), "NIGHT %02d  /  %s" % [game.night, data.title], data.brief)
	label(box, "TONIGHT'S ASSIGNMENT", Vector2(36, 265), 16, MINT)
	label(box, game.task_text(), Vector2(36, 306), 20, PAPER, 650)
	label(box, "THE FOUR RULES\n\nRed eyes are never normal.\nA visitor must exist on camera.\nRead the words they choose.\nDo not open a door for a voice.\n\nThree complaints end your shift.", Vector2(735, 270), 18, AMBER, 360)
	button(box, "CLOCK IN   →", Vector2(36, 501), game.clock_in)

func pause_menu() -> void:
	var box := base_modal("SHIFT SUSPENDED", "TAKE A BREATH", "The clock and the visitors wait while this screen is open.")
	button(box, "RESUME", Vector2(36, 245), game.resume_game)
	button(box, "SETTINGS", Vector2(36, 310), func(): settings_menu("pause"))
	button(box, "MAIN MENU", Vector2(36, 375), game.return_menu)
	label(box, "FIELD GUIDE\n\nRed eyes: inspect the face.\nMissing reflection: use STORE camera.\nImitation: unnatural speech or anatomy.\n\nProducts: coffee by the front window,\nchips in the aisles, water at the fridges.\nBreaker and stock: rear storage room.\nPhone, charger and cameras: security office.", Vector2(480, 240), 19, PAPER, 600)

func settings_menu(origin: String) -> void:
	var box := base_modal("PERSONAL PREFERENCES", "SETTINGS", "Settings are saved automatically. Reduce effects if you prefer steadier lighting.")
	box.offset_top = -328
	box.offset_bottom = 328
	var columns := HBoxContainer.new()
	columns.name = "SettingsColumns"
	columns.position = Vector2(36, 224)
	columns.size = Vector2(1068, 330)
	columns.add_theme_constant_override("separation", 64)
	box.add_child(columns)
	var left := stack_in(columns)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.custom_minimum_size.x = 450
	var right := stack_in(columns)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var volume := setting_slider(left, "MASTER VOLUME", 0, 1, 0.01, game.settings.volume)
	volume.value_changed.connect(func(value): game.settings.volume = value; game.apply_settings(); game.save_progress())
	var sensitivity := setting_slider(left, "MOUSE SENSITIVITY", 0.0007, 0.005, 0.0001, game.settings.sensitivity)
	sensitivity.value_changed.connect(func(value): game.settings.sensitivity = value; game.apply_settings(); game.save_progress())
	var fov := setting_slider(left, "FIELD OF VIEW   /   %d°" % game.settings.fov, 65, 100, 1, game.settings.fov)
	var fov_label: Label = left.get_child(left.get_child_count() - 2)
	fov.value_changed.connect(func(value): game.settings.fov = value; fov_label.text = "FIELD OF VIEW   /   %d°" % value; game.apply_settings(); game.save_progress())
	for entry in [["head_bob", "Head bob"], ["reduced_flashes", "Reduce flashes / distortion"]]:
		var check := CheckButton.new()
		check.text = entry[1]
		check.custom_minimum_size.y = 40
		check.button_pressed = game.settings[entry[0]]
		left.add_child(check)
		var key: String = entry[0]
		check.toggled.connect(func(value): game.settings[key] = value; game.apply_settings(); game.save_progress())
	flow_label(right, "DISPLAY MODE  /  ALT+ENTER OR F11", 14, MINT)
	display_selector = OptionButton.new()
	display_selector.name = "DisplayMode"
	for title in ["Windowed", "Borderless fullscreen", "Exclusive fullscreen"]:
		display_selector.add_item(title)
	display_selector.select((2 if game.settings.exclusive_fullscreen else 1) if game.settings.fullscreen else 0)
	right.add_child(display_selector)
	display_selector.item_selected.connect(func(index): game.set_display_mode(index); game.save_progress())
	flow_label(right, "WINDOW RESOLUTION", 14, MINT)
	resolution_selector = OptionButton.new()
	resolution_selector.name = "WindowResolution"
	for resolution in game.WINDOW_RESOLUTIONS:
		resolution_selector.add_item("%d × %d" % [resolution.x, resolution.y])
		if resolution == Vector2i(game.settings.window_width, game.settings.window_height):
			resolution_selector.select(resolution_selector.item_count - 1)
	right.add_child(resolution_selector)
	resolution_selector.item_selected.connect(func(index): game.set_window_resolution(game.WINDOW_RESOLUTIONS[index]); game.save_progress())
	flow_label(right, "GRAPHICS QUALITY", 14, MINT)
	var quality := OptionButton.new()
	quality.add_item("Standard / full atmosphere")
	quality.add_item("Low / lighter weather and CCTV")
	quality.select(1 if game.settings.low_graphics else 0)
	right.add_child(quality)
	quality.item_selected.connect(func(index): game.settings.low_graphics = index == 1; game.apply_settings(); game.save_progress())
	flow_label(right, "Fullscreen uses the monitor's native size.\nWindow resolution applies when you return.\nOversized windows fit the available desktop.", 14, AMBER)
	button(box, "← BACK", Vector2(36, 578), func():
		if origin == "menu":
			main_menu()
		else:
			pause_menu()
	)

func setting_slider(parent: Node, title: String, minimum: float, maximum: float, increment: float, value: float) -> HSlider:
	flow_label(parent, title, 14, MINT)
	var slider := HSlider.new()
	slider.custom_minimum_size.y = 28
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = increment
	slider.value = value
	parent.add_child(slider)
	return slider

func register_menu() -> void:
	var box := base_modal("NORTHSTAR / POINT OF SALE", "CUSTOMER REVIEW", "Verify the face, the camera and the words before completing the sale.")
	var order := label(box, game.order_summary(), Vector2(36, 242), 20, PAPER, 620, true)
	order.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	order.size.x = 620
	label(box, "A sale requires the requested item to be scanned.\nYou can refuse service without scanning an item.", Vector2(36, 465), 16, AMBER, 650)
	button(box, "ACCEPT / COMPLETE SALE", Vector2(710, 270), func(): game.decide(true), 380)
	button(box, "REJECT / REFUSE SERVICE", Vector2(710, 340), func(): game.decide(false), 380)
	button(box, "← KEEP INSPECTING", Vector2(710, 460), game.close_overlay, 380)

func result_screen(won: bool, ending: bool = false) -> void:
	var title := "SHIFT COMPLETE" if won else "YOU LET IT IN"
	if not won and not game.death_is_scary:
		title = "SHIFT TERMINATED"
	var desc: String = "Dawn finds you still here. The next clerk never arrives." if won else game.death_reason
	if ending:
		title = "THE ROAD REMEMBERS"
		desc = "06:00 AM. The forest goes quiet. For the first time in five nights, the road leads somewhere else."
	var box := base_modal("NORTHSTAR / EMPLOYEE RECORD", title, desc)
	label(box, "NIGHTS SURVIVED   %d / 5\nCASH ON HAND     $%d\nCORRECT DECISIONS   %d\n\n%s" % [game.completed_nights.size(), game.money, game.correct_decisions, "You leave your badge on the counter.\nBehind you, the OPEN sign finally goes dark." if ending else "Progress saves at the beginning and end of every shift."], Vector2(36, 260), 22, PAPER, 1040)
	if not ending:
		button(box, "NEXT NIGHT   →" if won else "RETRY NIGHT   →", Vector2(36, 494), game.next_or_retry)
	button(box, "MAIN MENU", Vector2(440, 494), game.return_menu)

func toast(message: String, duration: float = 5.0) -> void:
	subtitle.text = message
	message_timer = duration

func camera_screen(texture: Texture2D) -> void:
	clear_modal()
	modal.visible = true
	var frame := hud_card(modal)
	frame.name = "CameraFrame"
	frame.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	frame.offset_left = -575
	frame.offset_right = 575
	frame.offset_top = -320
	frame.offset_bottom = 320
	var column := stack_in(frame)
	camera_label = flow_label(column, "", 19, MINT)
	camera_view = TextureRect.new()
	camera_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	camera_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	camera_view.texture = texture
	camera_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/cctv.gdshader")
	camera_view.material = material
	column.add_child(camera_view)
	camera_hint = flow_label(column, "CONNECTING / Wait for a clear live image.", 15, AMBER)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	column.add_child(row)
	button(row, "← PREVIOUS", Vector2.ZERO, func(): game.security.select(game.security.index - 1), 240).custom_minimum_size.x = 240
	button(row, "NEXT →", Vector2.ZERO, func(): game.security.select(game.security.index + 1), 240).custom_minimum_size.x = 240
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	button(row, "[ESC] DISCONNECT", Vector2.ZERO, game.close_overlay, 320).custom_minimum_size.x = 320

func phone_screen() -> void:
	var box := base_modal("INCOMING CALL  /  NUMBER WITHHELD", "A FAMILIAR VOICE", "The line crackles. It sounds exactly like you.")
	label(box, "\"It's cold out here. Tell me I can come inside.\nJust say it. I need to hear you say it.\"\n\nThe employee notice says:\nNEVER INVITE A CALLER INSIDE.", Vector2(36, 256), 25, AMBER, 1020)
	button(box, "HANG UP", Vector2(36, 485), func(): game.answer_phone(false))
	button(box, "INVITE THE CALLER INSIDE", Vector2(440, 485), func(): game.answer_phone(true), 610)

func note_screen(id: String) -> void:
	var notes := {
		"rules": ["EMPLOYEE NOTICE", "NORTHSTAR / SAFETY POLICY", "Inspect every visitor before accepting payment. Collect the requested product and scan it at the counter. Red eyes, impossible anatomy and unnatural speech are reasons to refuse service.\n\nFrom the second shift onward, compare the visitor with the STORE camera. A missing visitor only counts as evidence on a clear, powered live feed.\n\nNever invite a caller inside. Stay out of storage while a voice is knocking; wait for the all-clear. Three complaints end your shift."],
		"missing": ["MISSING", "COUNTY SHERIFF / ROAD 16", "Last seen on County Road 16, driving a red semi truck. The report mentions a stop at Northstar just after midnight.\n\nSomeone has underlined the date twice. A second handwriting on the back says: 'He came in again on Thursday. He didn't remember his own name.'\n\nThe notice has been pinned here long enough for the paper around it to fade."],
		"handover": ["THE PREVIOUS CLERK", "HANDOVER / 21 OCTOBER", "No deliveries after midnight. Leave the back light on. The spare supplies are in storage; the charger is beside the security monitor.\n\nIf the phone rings and you hear yourself, hang up. If someone knocks from inside storage, do not answer.\n\nI checked the tapes. The truck driver was there on Monday. On Tuesday there was only his voice.\n\nIf you make it to six, leave your badge. Don't wait for the next clerk.\n\n- D."]
	}
	var entry: Array = notes.get(id, notes.rules)
	var box := base_modal(entry[1], entry[0], "A note left for the next person on the night shift. Scroll to read; Escape puts it down.")
	var scroll := ScrollContainer.new()
	scroll.name = "NoteReader"
	scroll.position = Vector2(36, 232)
	scroll.size = Vector2(1068, 262)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var body := flow_label(scroll, entry[2], 19, PAPER)
	body.name = "NoteText"
	body.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	button(box, "[ESC] PUT DOWN", Vector2(36, 514), game.close_overlay)

func _process(delta: float) -> void:
	if not game or not game.player:
		return
	game.player.sync_held_item()
	if is_instance_valid(display_selector):
		display_selector.select((2 if game.settings.exclusive_fullscreen else 1) if game.settings.fullscreen else 0)
	scare_effect.visible = game.mode == "scare" and not game.settings.reduced_flashes
	if scare_effect.visible:
		scare_effect.material.set_shader_parameter("strength", (1.0 - smoothstep(1.5, 2.0, game.scare_timer)) * smoothstep(0.0, 0.5, game.scare_timer))
	if message_timer > 0 and game.mode == "playing":
		message_timer -= delta
		if message_timer <= 0:
			subtitle.text = ""
	if not hud.visible:
		return
	header.text = "NIGHT %02d  /  %s" % [game.night, game.clock_text()]
	status.text = "$ %03d  •  VISITORS %d/%d  •  ERR %d/3" % [game.money, game.customers_done, game.customer_total, game.complaints]
	stamina_bar.value = game.player.stamina
	battery_bar.value = game.player.battery
	var target: Dictionary = game.player.interaction() if game.mode == "playing" else {}
	prompt.text = "[E]  " + target.get("prompt", "") if not target.is_empty() else ""
	if game.work_timer > 0:
		prompt.text = "WORKING… stay nearby"
	progress.visible = game.work_timer > 0
	progress.value = (1.0 - game.work_timer / 2.0) * 100
	var waiting: bool = is_instance_valid(game.active_customer) and game.active_customer.state == "waiting"
	if waiting and not visitor_was_waiting:
		tasks_open = false
		order_backdrop.modulate.a = 0
	visitor_was_waiting = waiting
	tasks.text = "ASSIGNMENT  /  [TAB]\n" + game.task_text() if tasks_open else "[TAB]  ASSIGNMENT  /  %d OF %d VISITORS" % [game.customers_done, game.customer_total]
	customer_text.text = "%s  /  VISITOR %02d" % [game.active_customer.visitor_name.to_upper(), game.visitor_serial] if waiting else ""
	if waiting:
		visitor_dialogue.text = '"' + game.active_customer.dialogue + '"'
		visitor_order.text = "%s  /  %s\nPATIENCE  %ds" % [game.active_customer.product.to_upper(), "SCANNED ✓" if game.active_customer.scanned else "AWAITING SCAN", ceili(game.active_customer.patience)]
		patience_bar.value = clampf(game.active_customer.patience / (115.0 - game.night * 7) * 100, 0, 100)
	order_backdrop.visible = not customer_text.text.is_empty() and game.mode == "playing"
	order_backdrop.modulate.a = move_toward(order_backdrop.modulate.a, 1, delta * 7)
	right_column.visible = game.mode == "playing"
	subtitle_card.visible = not subtitle.text.is_empty() and game.mode in ["playing", "finale"]
	prompt.visible = game.mode == "playing"
	controls_hint.visible = game.mode == "playing"
	carried_text.text = ""
	if not game.held_product.is_empty():
		carried_text.text = "CARRYING  /  " + game.held_product.to_upper()
	if game.carrying_crate:
		carried_text.text += "\nCARRYING  /  RESTOCK CRATE"
	carried_text.visible = not carried_text.text.strip_edges().is_empty()
