class_name VelocityMovement

@export var speed: float = 24
@export var fall_acceleration: float = 25
@export var friction: float = 0.9
@export var jump_impulse: float = 20
@export var bounce_impulse: float = 16
@export var water_bouyancy: float = 75

var target_position: Vector3:
	set(value):
		target_position = value
		has_navigation_target = true
var target_path: PackedVector3Array:
	set(value):
		target_path = value
		has_navigation_target = true
var closest_position_at_last_update := Vector3.ZERO
var position_is_same_as_last_update_count := 30
var has_navigation_target: bool
var current_biome: World.Biome = World.Biome.WATER

var vital_tick: float = 0.0

var velocity := Vector3.ZERO
var target_velocity := Vector3.ZERO
var impulse := Vector3.ZERO

var animation_scale: float

func _init(_speed: float = 24, _fall_acceleration: float = 150, _friction: float = 0.9, _jump_impulse: float = 20, _bounce_impulse: float = 16) -> void:
	update_movement_speed(speed, 1, 60.0)
	fall_acceleration = _fall_acceleration
	friction = _friction
	jump_impulse = _jump_impulse
	bounce_impulse = _bounce_impulse
	has_navigation_target = false
	
# returns the distance traveled by taking two steps. Which is what an animation walk cycle would use before looping.
static func stride_length_meters(height: float) -> float:
	return height * 0.0105156 * 2
	
func update_movement_speed(target: float, height: float, animation_frames: float) -> void:
	speed = target
	var result := (stride_length_meters(height) / animation_frames) * Engine.get_frames_per_second()
	animation_scale = result / target
	
func movement_speed_animation_scale() -> float:
	return animation_scale

#func player_movement_speed_animation_scale() -> float:
	#var s := (60.0 / 21.0) * 0.85
	#return speed / s

func increment_ticks(delta: float) -> void:
	vital_tick += delta

# returns 
# result["velocity"] = velocity
# result["absolute"] = navigation_velocity * delta
# result["target"] = target_velocity * delta
# result["impulse"] = impulse
# result["direction"] = direction
func update(delta: float, vitals: Vitals, movement_speed: float, body: CharacterBody, should_rotate_character: bool, sea_level: float) -> Dictionary:
	var result := {}
	increment_ticks(delta)
		
	#if not target_path.is_empty():
		#if target_path_duration < 0.0:
			#target_path_duration = 0.0
			#target_path.clear()
			#has_navigation_target = false
		#else:
			#target_path_duration -= delta
		
	if position_is_same_as_last_update_count < 0 or body.global_position.is_equal_approx(target_position):
		position_is_same_as_last_update_count = 30
		if target_path.is_empty():
			has_navigation_target = false
		else:
			target_position = target_path[0]
			target_path.remove_at(0)
	
	var navigation_velocity := Vector3.ZERO
	if has_navigation_target:
		#print(position_at_last_update, " == ", body.global_position, " => ", position_at_last_update.is_equal_approx(body.global_position))
		if target_position.distance_squared_to(body.global_position) >= target_position.distance_squared_to(closest_position_at_last_update):
			position_is_same_as_last_update_count -= 1
		else:
			closest_position_at_last_update = body.global_position
		var total_movement := target_position - body.global_position
		var length := total_movement.length()
		var direction := total_movement.normalized()
		var stun_value := 0.0 if vitals.stun.value > 0 else 1.0
		if (movement_speed * (1.0 - vitals.freeze.value) * stun_value * delta) > length:
			direction *= (length / delta) * (1.0 - vitals.freeze.value) * stun_value
		else:
			direction *= movement_speed * (1.0 - vitals.freeze.value) * stun_value
		navigation_velocity = direction
	else:
		var direction := Vector3.ZERO
		#var cam_pivot := body.get_node("CamPivot") as Node3D
		var input_dir := VelocityMovement.get_input_strength("move_left", "move_right", "move_forward", "move_back")
		var input_len := input_dir.length()
		var port := body.get_viewport()
		var pos := port.get_visible_rect().size / 2.0
		direction = port.get_camera_3d().project_ray_normal(pos)
		direction = direction.rotated(Vector3.UP, Vector3.FORWARD.signed_angle_to(Vector3(input_dir.x, 0, input_dir.y), Vector3.UP))
		if input_dir.length() < 1.0:
			direction *= input_dir.length()
		#direction = (body.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		#direction = direction.rotated(Vector3.UP, cam_pivot.rotation.y)
		result["direction"] = direction
		var stun_value := 0.005 if vitals.stun.value > 0 else 1.0
		navigation_velocity.x = direction.x * movement_speed * (1.0 - vitals.freeze.value) * input_len * stun_value
		navigation_velocity.z = direction.z * movement_speed * (1.0 - vitals.freeze.value) * input_len * stun_value
		if vitals.stun.value > 0.0:
			(body as Player).add_shake(vitals.stun.value)

	if vital_tick >= 1.0:
		var h := vitals.update_vitals(body)
		for dmg: Dictionary in h: ## [][String(dmg, el)](float, Spell.Element)
			Vitals.apply_damage(body.get_parent() as Node3D, body, dmg["dmg"] as float, dmg["el"] as Spell.Element, true, false, [])
		var wet_area := body.get_node("WetArea") as Area3D
		if wet_area != null:
			wet_area.scale = Vector3(vitals.wetness_scale() as float, vitals.wetness_scale() as float, vitals.wetness_scale() as float)
		vital_tick = 0.0
		if body.position.y < sea_level:
			var underwater := clampf(sea_level - body.position.y, 0.0, 10.0) / 10.0
			vitals.wetness.apply(underwater)
			vitals.health.apply(clampf(body.position.y - sea_level, -100.0, 0.0) / 100.0 * 5.0)
	
	target_velocity.x *= friction
	target_velocity.z *= friction
	if (body is Enemy and (body as Enemy).pushed_with_impulse) or (body is Player):
		var g := Navigator.get_world_height(body.get_world_3d().direct_space_state, body.position.x, body.position.z)
		if not body.is_on_floor: 
			if g < body.feet_position():
				target_velocity.y = target_velocity.y - fall_acceleration * delta
			elif g > body.feet_position():
				target_velocity.y = target_velocity.y + fall_acceleration * delta
		else:
			target_velocity.y = 0
		
	if body.feet_position() < -1000.0 or is_nan(body.position.y):
		body.set_feet_position(Navigator.get_world_height(body.get_world_3d().direct_space_state, body.position.x, body.position.z))
	elif body is Player:
		var wb := water_bouyancy
		var fa := fall_acceleration
		var fl := 0.0
		if current_biome == World.Biome.HFIL:
			wb = wb * -1.0
			fa = fa * 0.25
			fl = wb * delta
			
		if sea_level - 1.5 < body.feet_position() and body.feet_position() < sea_level - 1.45:
			target_velocity.y = fl
		elif body.feet_position() < sea_level - 1.5:
			if target_velocity.y < 0:
				target_velocity.y = target_velocity.y * 0.9
			target_velocity.y = target_velocity.y + wb * delta
		elif not body.is_on_floor and Navigator.get_world_height(body.get_world_3d().direct_space_state, body.position.x, body.position.z) < body.feet_position():
			target_velocity.y = target_velocity.y - fa * delta
		else:
			target_velocity.y = 0
		
	target_velocity.x = clampf(target_velocity.x, -50.0, 50.0)
	target_velocity.y = clampf(target_velocity.y, -50.0, 50.0)
	target_velocity.z = clampf(target_velocity.z, -50.0, 50.0)
	
	if impulse.length() > 1.0:
		impulse -= impulse * 0.1
	else:
		impulse = Vector3.ZERO
	
	target_velocity += impulse
	
	velocity = target_velocity + navigation_velocity
	result["velocity"] = velocity
	result["absolute"] = navigation_velocity * delta
	result["target"] = target_velocity * delta
	result["impulse"] = impulse
	result["here"] = target_position
	
	if should_rotate_character and navigation_velocity != Vector3.ZERO and not body.has_node("CamPivot"):
		var goal_angle := atan2(-navigation_velocity.x, -navigation_velocity.z)
		if is_zero_approx(navigation_velocity.x) and is_zero_approx(navigation_velocity.z):
			#body.rotation.y = lerp_angle(body.rotation.y, sin(navigation_velocity.y) * 2 * PI, 0.05)
			pass # dont rotate if character is moving up/down
		else:
			body.rotation.y = lerp_angle(body.rotation.y, goal_angle, 0.3)
		
	return result

func rotate_character(body: Player, direction: Vector3, is_underwater: bool) -> void:
	if direction != Vector3.ZERO:
		var cam_pivot := body.get_node("CamPivot") as Marker3D
		var pivot := body.get_node("Pivot") as Node3D
		if is_underwater or body.enemies_in_range.is_empty():
			pivot.rotation.y = lerp_angle(pivot.rotation.y, atan2(-direction.x, -direction.z), 0.3)
		else:
			pivot.rotation.y = lerp_angle(pivot.rotation.y, cam_pivot.rotation.y, 0.3)
		

static func get_input_strength(negative_x: String, positive_x: String, negative_y: String, positive_y: String, deadzone: float = 0.05) -> Vector2:
	var left := Input.get_action_raw_strength(negative_x)
	var right := Input.get_action_raw_strength(positive_x)
	var forward := Input.get_action_raw_strength(negative_y)
	var back := Input.get_action_raw_strength(positive_y)
	
	if left < deadzone:
		left = 0
	if right < deadzone:
		right = 0
	if forward < deadzone:
		forward = 0
	if back < deadzone:
		back = 0
	
	return Vector2(right - left, back - forward)
	
