extends Node3D
## Start with -- --collision-debug. F8 toggles the overlay only in that opt-in run.
var game: Node
var enabled := false
var allowed := false
var shapes: Array[CollisionShape3D] = []
var displays: Array[MeshInstance3D] = []

func _ready() -> void:
	allowed = OS.is_debug_build() and "--collision-debug" in OS.get_cmdline_user_args()
	if not allowed:
		set_process(false)
		set_process_unhandled_input(false)
		return
	for node in game.world.find_children("*", "CollisionShape3D", true, false):
		if node.shape is BoxShape3D:
			shapes.append(node)
			var display := MeshInstance3D.new()
			var mesh := BoxMesh.new()
			mesh.size = node.shape.size
			display.mesh = mesh
			var material := StandardMaterial3D.new()
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			material.albedo_color = Color(0.2, 1, 0.8, 0.18) if node.get_parent() is Area3D else Color(1, 0.4, 0.15, 0.16)
			material.no_depth_test = true
			display.material_override = material
			display.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(display)
			displays.append(display)
	enabled = true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F8:
		enabled = not enabled

func _process(_delta: float) -> void:
	var nearby: Array[String] = []
	for i in range(shapes.size()):
		var shape := shapes[i]
		var body := shape.get_parent() as CollisionObject3D
		displays[i].global_transform = shape.global_transform
		displays[i].visible = enabled and body.collision_layer != 0 and shape.global_position.distance_to(game.player.global_position) < 12
		if displays[i].visible and body is StaticBody3D and shape.global_position.distance_to(game.player.global_position) < 2:
			nearby.append(str(body.get_parent().name))
	var blocking: Array[String] = []
	for i in range(game.player.get_slide_collision_count()):
		var hit: KinematicCollision3D = game.player.get_slide_collision(i)
		if absf(hit.get_normal().y) < 0.8:
			blocking.append(str(hit.get_collider().get_parent().name))
	game.ui.debug_text.visible = enabled
	game.ui.debug_text.text = "COLLISION DEBUG [F8]\nOrange: solid / Teal: interaction area\nBlocking: %s\nNearby: %s" % [", ".join(blocking) if not blocking.is_empty() else "none", ", ".join(nearby)]
