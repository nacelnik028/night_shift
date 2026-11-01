extends CharacterBody3D

var camera: Camera3D
var torch: SpotLight3D
var ray: RayCast3D
var stamina := 100.0
var battery := 100.0
var enabled := false
var sensitivity := 0.0022
var bob := 0.0
var crouching := false
var torch_enabled := true
var game: Node
var footstep_timer := 0.0
var flashlight_model: MeshInstance3D
var body_collision: CollisionShape3D
var standing_shape: CapsuleShape3D
var base_fov := 76.0
var held_display: Node3D
var held_models: Dictionary = {}
var held_key := ""

func _ready() -> void:
	name = "Player"
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 0.18
	safe_margin = 0.002
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.28
	capsule.height = 1.75
	standing_shape = capsule.duplicate()
	var collision := CollisionShape3D.new()
	body_collision = collision
	collision.shape = capsule
	collision.position.y = 0.9
	add_child(collision)
	camera = Camera3D.new()
	camera.position.y = 1.62
	camera.fov = 76
	camera.near = 0.06
	add_child(camera)
	camera.current = true
	torch = SpotLight3D.new()
	torch.light_color = Color(0.82, 0.9, 1.0)
	torch.light_energy = 2.6
	torch.spot_range = 20.0
	torch.spot_angle = 31.0
	torch.spot_attenuation = 0.8
	torch.shadow_enabled = false
	torch.position = Vector3(0.18, -0.18, -0.15)
	camera.add_child(torch)
	ray = RayCast3D.new()
	ray.target_position = Vector3(0, 0, -3.4)
	ray.collision_mask = 1 | 4
	ray.collide_with_areas = true
	camera.add_child(ray)
	var housing := NightPalette.material(Color(0.055, 0.07, 0.08), 0.3)
	var model := NightPalette.cylinder(camera, Vector3(0.27, -0.27, -0.46), 0.055, 0.25, housing)
	model.rotation.x = PI / 2
	model.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	model.layers = 4
	flashlight_model = model
	build_held_items()

func build_held_items() -> void:
	held_display = Node3D.new()
	held_display.position = Vector3(-0.25, -0.33, -0.57)
	held_display.rotation = Vector3(0.12, 0.18, -0.08)
	camera.add_child(held_display)
	var paper := NightPalette.material(Color("d3c9aa"), 0.93)
	var dark := NightPalette.material(Color("1a2426"))
	for key in ["coffee", "chips", "water", "crate"]:
		var item := Node3D.new()
		item.name = "Held_" + key
		held_display.add_child(item)
		held_models[key] = item
		match key:
			"coffee":
				NightPalette.cylinder(item, Vector3.ZERO, 0.050, 0.17, paper, 0.065)
				NightPalette.cylinder(item, Vector3(0, 0.092, 0), 0.068, 0.02, dark)
				NightPalette.print_quad(item, Vector3(0, 0, 0.061), Vector2(0.07, 0.10), 0)
			"chips":
				NightPalette.box(item, Vector3.ZERO, Vector3(0.17, 0.22, 0.07), paper)
				NightPalette.print_quad(item, Vector3(0, 0, 0.036), Vector2(0.17, 0.21), 1)
				for y in [-0.112, 0.112]:
					NightPalette.box(item, Vector3(0, y, 0), Vector3(0.18, 0.014, 0.065), dark)
			"water":
				NightPalette.cylinder(item, Vector3.ZERO, 0.043, 0.21, NightPalette.material(Color("709b97"), 0.25), 0.035)
				NightPalette.cylinder(item, Vector3(0, 0.12, 0), 0.023, 0.035, paper)
				NightPalette.print_quad(item, Vector3(0, 0, 0.044), Vector2(0.065, 0.11), 3)
			"crate":
				NightPalette.box(item, Vector3.ZERO, Vector3(0.32, 0.23, 0.25), NightPalette.material(Color("806449")))
				NightPalette.box(item, Vector3(0, 0.117, 0), Vector3(0.05, 0.006, 0.25), paper)
				NightPalette.print_quad(item, Vector3(0, 0, 0.126), Vector2(0.18, 0.15), 1)
		item.visible = false
	for mesh in held_display.find_children("*", "GeometryInstance3D", true, false):
		mesh.layers = 4
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func sync_held_item() -> void:
	var key: String = "crate" if game.carrying_crate else game.held_product
	if key != held_key:
		held_key = key
		for item in held_models:
			held_models[item].visible = item == key
	held_display.visible = game.mode == "playing" and not key.is_empty()

func _unhandled_input(event: InputEvent) -> void:
	if not enabled:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotation.y -= event.relative.x * sensitivity
		camera.rotation.x = clampf(camera.rotation.x - event.relative.y * sensitivity, -1.35, 1.35)
	if event.is_action_pressed("flashlight"):
		torch_enabled = not torch_enabled
		game.sound.play_effect("click")
	if event.is_action_pressed("interact"):
		var target := interaction()
		if not target.is_empty():
			game.interact(target.action)

func interaction() -> Dictionary:
	ray.force_raycast_update()
	if ray.is_colliding():
		var collider := ray.get_collider()
		if collider is Node and collider.has_meta("action"):
			if collider.get_meta("action", "").begins_with("clean:") and not collider.get_parent().get_parent().visible:
				return {}
			return {"action": collider.get_meta("action"), "prompt": collider.get_meta("prompt", "Interact")}
	return {}

func _physics_process(delta: float) -> void:
	if not enabled:
		return
	crouching = Input.is_action_pressed("crouch") or (crouching and not can_stand())
	body_collision.shape.height = 1.1 if crouching else 1.75
	body_collision.position.y = 0.57 if crouching else 0.9
	var input_dir := Input.get_vector("left", "right", "forward", "back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var sprint := Input.is_action_pressed("sprint") and stamina > 3.0 and not crouching and direction.length() > 0.1
	var speed := 5.6 if sprint else (1.8 if crouching else 3.5)
	stamina = clampf(stamina + (-20.0 if sprint else 14.0) * delta, 0, 100)
	velocity.x = move_toward(velocity.x, direction.x * speed, delta * 15)
	velocity.z = move_toward(velocity.z, direction.z * speed, delta * 15)
	if not is_on_floor():
		velocity.y -= 18 * delta
	else:
		velocity.y = -0.1
		if Input.is_action_just_pressed("jump") and not crouching:
			velocity.y = 5.2
	move_and_slide()
	var moving := Vector2(get_real_velocity().x, get_real_velocity().z).length() > 0.2 and is_on_floor()
	if moving:
		bob += delta * (12 if sprint else 8)
		footstep_timer -= delta
		if footstep_timer <= 0:
			game.sound.play_effect("step", -19.0)
			footstep_timer = 0.32 if sprint else 0.53
	var bob_height := sin(bob) * 0.035 if moving and game.settings.get("head_bob", true) else 0.0
	camera.position.y = lerpf(camera.position.y, (1.02 if crouching else 1.62) + bob_height, minf(1, delta * 12))
	camera.fov = lerpf(camera.fov, base_fov + (4.0 if sprint else 0.0), minf(1, delta * 5))
	if torch_enabled and battery > 0:
		battery = maxf(0, battery - delta * 0.085)
	torch.visible = torch_enabled and battery > 0
	torch.light_energy = 2.6 * minf(1.0, battery / 15.0)
	position.x = clampf(position.x, -37, 37)
	position.z = clampf(position.z, -30, 35)

func can_stand() -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = standing_shape
	query.transform = global_transform
	query.transform.origin += Vector3(0, 0.9, 0)
	query.collision_mask = collision_mask
	query.exclude = [get_rid()]
	query.margin = 0.001
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()

func reset_controller() -> void:
	velocity = Vector3.ZERO
	crouching = false
	body_collision.shape.height = 1.75
	body_collision.position.y = 0.9
	camera.position = Vector3(0, 1.62, 0)
	camera.rotation = Vector3.ZERO
	camera.fov = base_fov
	bob = 0
	footstep_timer = 0
	stamina = 100
	battery = 100
	torch_enabled = true
