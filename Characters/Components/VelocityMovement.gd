class_name VelocityMovement

@export var speed: float = 24
@export var fall_acceleration: float = 25
@export var friction: float = 75
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

func _init(_speed: float = 24, _fall_acceleration: float = 75, _friction: float = 75, _jump_impulse: float = 20, _bounce_impulse: float = 16) -> void:
	speed = _speed
	fall_acceleration = _fall_acceleration
	friction = _friction
	jump_impulse = _jump_impulse
	bounce_impulse = _bounce_impulse
	has_navigation_target = false
	
static func player() -> VelocityMovement:
	# FIXME: apply this to enemies as well and update their animation speed accordingly
	var desired_speed := 12.0
	var s := (60.0 / 21.0) * 0.85
	return VelocityMovement.new(s * desired_speed, 150, 150)
	
func update_player_movement_speed(target: float) -> void:
	var s := (60.0 / 21.0) * 0.85
	speed = s * target

func player_movement_speed_animation_scale() -> float:
	var s := (60.0 / 21.0) * 0.85
	return speed / s

func increment_ticks(delta: float) -> void:
	vital_tick += delta

# returns 
# result["velocity"] = velocity
# result["absolute"] = navigation_velocity * delta
# result["target"] = target_velocity * delta
# result["impulse"] = impulse
# result["direction"] = direction
func update(delta: float, vitals: Vitals, movement_speed: float, body: CharacterBody) -> Dictionary:
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

	if vital_tick >= 1.0:
		var h := vitals.update_vitals(body)
		for dmg: Dictionary in h: # [][String(dmg, el)](float, Spell.Element)
			Vitals.apply_damage(body.get_parent() as Node3D, body, dmg["dmg"] as float, dmg["el"] as Spell.Element, true, false, [])
		var wet_area := body.get_node("WetArea") as Area3D
		if wet_area != null:
			wet_area.scale = Vector3(vitals.wetness_scale() as float, vitals.wetness_scale() as float, vitals.wetness_scale() as float)
		vital_tick = 0.0
		if body.position.y < Globals.sea_level():
			var underwater := clampf(Globals.sea_level() - body.position.y, 0.0, 10.0) / 10.0
			vitals.wetness.apply(underwater)
			vitals.health.apply(clampf(body.position.y - Globals.sea_level(), -100.0, 0.0) / 100.0 * 5.0)

	
	var direction := Vector3.ZERO
	if body.has_node("CamPivot"):
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
		target_velocity.x = direction.x * movement_speed * (1.0 - vitals.freeze.value) * input_len * stun_value
		target_velocity.z = direction.z * movement_speed * (1.0 - vitals.freeze.value) * input_len * stun_value
		(body as Player).add_shake(vitals.stun.value)
	else:
		target_velocity.x = 0.0
		target_velocity.z = 0.0
		if target_velocity.y > 0.0:
			target_velocity.y = 0.0
		
	if body.feet_position() < -1000.0 or is_nan(body.position.y):
		body.set_feet_position(Navigator.get_world_height(body.get_world_3d().direct_space_state, body.position.x, body.position.z))
	elif body is Player:
		if current_biome == World.Biome.HFIL:
			target_velocity.y -= 10.0
		elif Globals.sea_level() - 1.5 < body.feet_position() and body.feet_position() < Globals.sea_level() - 1.45:
			target_velocity.y = 0 
		elif body.feet_position() < Globals.sea_level() - 1.5:
			if target_velocity.y < 0:
				target_velocity.y = target_velocity.y * 0.9
			target_velocity.y = target_velocity.y + water_bouyancy * delta
		elif not body.is_on_floor() and Navigator.get_world_height(body.get_world_3d().direct_space_state, body.position.x, body.position.z) < body.feet_position():
			target_velocity.y = target_velocity.y - fall_acceleration * delta
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
	
	if body.has_node("CamPivot"):
		pass
#		if direction != Vector3.ZERO:
#			var pivot: Node3D = body.get_node("Pivot")
#			pivot.rotation.y = lerp_angle(pivot.rotation.y, atan2(-direction.x, -direction.z), 0.3)
#			var collision: Node3D = body.get_node("Collision")
#			collision.rotation.y = pivot.rotation.y
#			var wet_area: Node3D = body.get_node("WetArea")
#			wet_area.rotation.y = pivot.rotation.y
	else:
		if navigation_velocity != Vector3.ZERO:
			body.rotation.y = lerp_angle(body.rotation.y, atan2(-navigation_velocity.x, -navigation_velocity.z), 0.3)
		
	return result

func rotate_character(body: Player, direction: Vector3, is_underwater: bool) -> void:
	if direction != Vector3.ZERO:
		var cam_pivot := body.get_node("CamPivot") as Marker3D
		var pivot := body.get_node("Pivot") as Node3D
		if is_underwater:
			pivot.rotation.y = lerp_angle(pivot.rotation.y, atan2(-direction.x, -direction.z), 0.3)
		else:
			pivot.rotation.y = lerp_angle(pivot.rotation.y, cam_pivot.rotation.y, 0.3)
		var collision: Node3D = body.get_node("Collision")
		collision.rotation.y = pivot.rotation.y
		var wet_area: Node3D = body.get_node("WetArea")
		wet_area.rotation.y = pivot.rotation.y

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
	
