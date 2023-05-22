class_name VelocityMovement

@export var speed: float = 24
@export var fall_acceleration: float = 75
@export var friction: float = 75
@export var jump_impulse: float = 20
@export var bounce_impulse: float = 16

var target_position: Vector3:
	set(value):
		target_position = value
		has_navigation_target = true
var has_navigation_target: bool

var vital_tick: int = 0

var velocity = Vector3.ZERO
var target_velocity = Vector3.ZERO
var impulse = Vector3.ZERO

func _init(_speed: float = 24, _fall_acceleration: float = 75, _friction: float = 75, _jump_impulse: float = 20, _bounce_impulse: float = 16):
	speed = _speed
	fall_acceleration = _fall_acceleration
	friction = _friction
	jump_impulse = _jump_impulse
	bounce_impulse = _bounce_impulse
	has_navigation_target = false
	
static func player() -> VelocityMovement:
	return VelocityMovement.new(36, 150, 150)

func increment_ticks():
	vital_tick += 1

func update(delta: float, vitals: Vitals, movement_speed: float, body: CharacterBody3D) -> Dictionary:
	var result = {}
	
	if body.position == target_position:
		has_navigation_target = false
	
	var navigation_velocity = Vector3.ZERO
	if has_navigation_target:
		var current_agent_position: Vector3 = body.global_transform.origin
		var next_path_position: Vector3 = target_position

		var new_velocity: Vector3 = next_path_position - current_agent_position
		new_velocity = new_velocity.normalized()
		new_velocity = new_velocity * movement_speed * (1.0 - vitals.freeze.value)

		navigation_velocity = new_velocity

	if vital_tick == 60:
		vitals.update_vitals()
		var wet_area = body.get_node("WetArea")
		if wet_area != null:
			wet_area.scale = Vector3(vitals.wetness_scale(), vitals.wetness_scale(), vitals.wetness_scale())
		vital_tick = 0

	
	var direction = Vector3.ZERO
	if body.has_node("CamPivot"):
		var cam_pivot = body.get_node("CamPivot")
		var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		direction = (body.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		direction = direction.rotated(Vector3.UP, cam_pivot.rotation.y)
		result["direction"] = direction
		if true or body.is_on_floor():
			target_velocity.x = direction.x * speed * (1 - vitals.freeze.value)
			target_velocity.z = direction.z * speed * (1 - vitals.freeze.value)
	
	if not body.is_on_floor() and Navigator.get_world_height(body.get_world_3d().direct_space_state, body.position.x, body.position.z) < body.position.y:
		target_velocity.y = target_velocity.y - (fall_acceleration * delta)
	else:
		target_velocity.y = 0
		
	target_velocity.x = clampf(target_velocity.x, -100, 100)
	target_velocity.y = clampf(target_velocity.y, -100, 100)
	target_velocity.z = clampf(target_velocity.z, -100, 100)
	
	if absf(impulse.length()) > 1:
		impulse -= impulse.normalized() * friction * delta 
	else:
		impulse = Vector3.ZERO
	
	target_velocity += impulse
	
	velocity = target_velocity + navigation_velocity
	result["velocity"] = velocity
	result["absolute"] = navigation_velocity * delta
	result["target"] = target_velocity * delta
	
	if body.has_node("CamPivot"):
		if direction != Vector3.ZERO:
			var pivot: Node3D = body.get_node("Pivot")
	#		pivot.rotation.y = lerp_angle(pivot.rotation.y, atan2(-velocity.x, -velocity.z), 0.15)
			pivot.rotation.y = lerp_angle(pivot.rotation.y, atan2(-direction.x, -direction.z), 0.3)
			var collision: Node3D = body.get_node("Collision")
			collision.rotation.y = pivot.rotation.y
			var wet_area: Node3D = body.get_node("WetArea")
			wet_area.rotation.y = pivot.rotation.y
	else:
		if navigation_velocity != Vector3.ZERO:
			body.rotation.y = lerp_angle(body.rotation.y, atan2(-navigation_velocity.x, -navigation_velocity.z), 0.3)
		
		
		
	return result
