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
var has_navigation_target: bool

var vital_tick: float = 0.0

var velocity := Vector3.ZERO
var target_velocity := Vector3.ZERO
var impulse := Vector3.ZERO

func _init(_speed: float = 24, _fall_acceleration: float = 75, _friction: float = 75, _jump_impulse: float = 20, _bounce_impulse: float = 16):
	speed = _speed
	fall_acceleration = _fall_acceleration
	friction = _friction
	jump_impulse = _jump_impulse
	bounce_impulse = _bounce_impulse
	has_navigation_target = false
	
static func player() -> VelocityMovement:
	var desired_speed = 12.0
	var s = (60.0 / 21.0) * 0.85
	return VelocityMovement.new(s * desired_speed, 150, 150)

func increment_ticks(delta: float):
	vital_tick += delta

func update(delta: float, vitals: Vitals, movement_speed: float, body: CharacterBody3D) -> Dictionary:
	var result := {}
	increment_ticks(delta)
	
	if body.position == target_position:
		has_navigation_target = false
	
	var navigation_velocity := Vector3.ZERO
	if has_navigation_target:
		var new_velocity := target_position - body.global_position
		var length := new_velocity.length()
		new_velocity = new_velocity.normalized()
		if length < 1.0:
			new_velocity *= length
		var stun_value := 0.0 if vitals.stun.value > 0 else 1.0
		new_velocity = new_velocity * movement_speed * (1.0 - vitals.freeze.value) * stun_value

		navigation_velocity = new_velocity

	if vital_tick >= 1.0:
		var h := vitals.update_vitals(body)
		for dmg in h:
			Vitals.apply_damage(body.get_parent(), body, dmg["dmg"], dmg["el"], true, false, [])
		var wet_area := body.get_node("WetArea")
		if wet_area != null:
			wet_area.scale = Vector3(vitals.wetness_scale(), vitals.wetness_scale(), vitals.wetness_scale())
		vital_tick = 0.0
		if body.position.y < Globals.sea_level():
			var underwater = clamp(Globals.sea_level() - body.position.y, 0.0, 10.0) / 10.0
			vitals.wetness.apply(underwater)

	
	var direction := Vector3.ZERO
	if body.has_node("CamPivot"):
		var cam_pivot := body.get_node("CamPivot")
		var input_dir := VelocityMovement.get_input_strength("move_left", "move_right", "move_forward", "move_back")
		var input_len := input_dir.length()
		direction = (body.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		direction = direction.rotated(Vector3.UP, cam_pivot.rotation.y)
		result["direction"] = direction
		if true or body.is_on_floor():
			var stun_value := 0.0 if vitals.stun.value > 0 else 1.0
			target_velocity.x = direction.x * speed * (1 - vitals.freeze.value) * input_len * stun_value
			target_velocity.z = direction.z * speed * (1 - vitals.freeze.value) * input_len * stun_value
	else:
		target_velocity.x = 0
		target_velocity.z = 0
		
	if body.position.y < 0 or is_nan(body.position.y):
		body.position.y = Navigator.get_world_height(body.get_world_3d().direct_space_state, body.position.x, body.position.z)
		body.position.x = 0
		body.position.z = 0
	elif body.position.y < Globals.sea_level():
		if target_velocity.y < 0:
			target_velocity.y = target_velocity.y * 0.9
		target_velocity.y = target_velocity.y + water_bouyancy * delta		
	elif not body.is_on_floor() and Navigator.get_world_height(body.get_world_3d().direct_space_state, body.position.x, body.position.z) < body.position.y:
		target_velocity.y = target_velocity.y - fall_acceleration * delta
	else:
		target_velocity.y = 0
		
	target_velocity.x = clampf(target_velocity.x, -50, 50)
	target_velocity.y = clampf(target_velocity.y, -50, 50)
	target_velocity.z = clampf(target_velocity.z, -50, 50)
	
	if absf(impulse.length()) > 1:
		impulse -= impulse.normalized() * friction * delta 
	else:
		impulse = Vector3.ZERO
	
	target_velocity += impulse
	
	velocity = target_velocity + navigation_velocity
	result["velocity"] = velocity
	result["absolute"] = navigation_velocity * delta
	result["target"] = target_velocity * delta
	result["impulse"] = impulse
	
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

func rotate_character(body: Player, direction: Vector3):
	if direction != Vector3.ZERO:
		var pivot: Node3D = body.get_node("Pivot")
		pivot.rotation.y = lerp_angle(pivot.rotation.y, atan2(-direction.x, -direction.z), 0.3)
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
	
