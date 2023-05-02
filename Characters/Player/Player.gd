class_name Player
extends CharacterBody3D

@onready var cam_pivot: Marker3D = $CamPivot
@onready var cam_arm: SpringArm3D = $CamPivot/Arm
@onready var cam: Camera3D = $CamPivot/Arm/Lens

@export var speed: float = 24
@export var fall_acceleration: float = 75
@export var friction: float = 25
@export var jump_impulse: float = 20
@export var bounce_impulse: float = 16

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

signal player_moved

var target_velocity = Vector3.ZERO
var impulse = Vector3.ZERO

var particles: Array = []

var vitals: Vitals

func _ready():
	# These values need to be adjusted for the actor's speed
	# and the navigation layout.
	navigation_agent.path_desired_distance = 0.5
	navigation_agent.target_desired_distance = 0.5
	
	vitals = Vitals.new(100, 50)

func _input(event):
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and event is InputEventMouseMotion:
		cam_pivot.rotate_y(-event.relative.x / 180 * PI)
		cam_arm.rotate_x(-event.relative.y / 180 * PI / 3)
		cam_arm.rotation.x = clamp(cam_arm.rotation.x, -PI / 2, PI / 2)
		
func set_movement_target(movement_target: Vector3):
	navigation_agent.set_target_position(movement_target)

func interval_check(interval: int, epsilon: int):
	var t = Time.get_ticks_msec() % interval
	return t < epsilon

func _physics_process(delta):
	if not navigation_agent.is_navigation_finished():
		var current_agent_position: Vector3 = global_transform.origin
		var next_path_position: Vector3 = navigation_agent.get_next_path_position()

		var new_velocity: Vector3 = next_path_position - current_agent_position
		new_velocity = new_velocity.normalized()
		new_velocity = new_velocity * speed

		set_velocity(new_velocity)
		move_and_slide()

	if interval_check(500, 20):
		vitals.update_vitals()
		get_node("WetArea").scale = Vector3(vitals.wetness_scale(), vitals.wetness_scale(), vitals.wetness_scale())

	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction = direction.rotated(Vector3.UP, cam_pivot.rotation.y)
		
	if true or is_on_floor():
		target_velocity.x = direction.x * speed * (1 - vitals.freeze)
		target_velocity.z = direction.z * speed * (1 - vitals.freeze)
	
	if not is_on_floor():
		target_velocity.y = target_velocity.y - (fall_acceleration * delta)
	else:
		target_velocity.y = 0
	if Input.is_action_just_pressed("L3"):
		target_velocity.y = jump_impulse
		
	target_velocity.y = clampf(target_velocity.y, -100, 100)
	target_velocity.x = clampf(target_velocity.x, -100, 100)
	target_velocity.z = clampf(target_velocity.z, -100, 100)
	
	if absf(impulse.length()) > 1:
		var nor = impulse.normalized()
		var fri = friction * delta 
		impulse = Vector3(
			impulse.x - nor.x * fri,
			impulse.y - nor.y * fri,
			impulse.z - nor.z * fri,
		)
	else:
		impulse.x = 0
		impulse.y = 0
		impulse.z = 0
	
	velocity = target_velocity + impulse
	if direction != Vector3.ZERO:
		var pivot: Node3D = $Pivot
		pivot.rotation.y = lerp_angle(pivot.rotation.y, atan2(-velocity.x, -velocity.z), 0.15)
		var collision: Node3D = $Collision
		collision.rotation.y = pivot.rotation.y
		var wet_area: Node3D = $WetArea
		wet_area.rotation.y = pivot.rotation.y
		# $AnimationPlayer.speed_scale = 4
	else:
		pass
		# $AnimationPlayer.speed_scale = 1
		
	move_and_slide()
	if velocity:
		player_moved.emit(delta)
#		print(position)
				
	var t = Time.get_unix_time_from_system()
	var should_remove = []
	for i in range(particles.size()):
		var p: SpellBody = particles[i]
		p.update_spell(t, spell_variables(false))
		if p.has_expired(t):
			should_remove.append(i)
			p.stop_emitting()
			
	should_remove.reverse()
	for i in should_remove:
		particles.remove_at(i)
				
func spell_variables(fixed: bool) -> Dictionary:
	var result = Dictionary()
	var prefix = "" if fixed else "t"
	result[prefix + "x"] = position.x
	result[prefix + "y"] = position.y
	result[prefix + "z"] = position.z
	
	var cdir = ((global_position + Vector3(0, 1.2, 0)) - cam.global_position).normalized()
	
	result[prefix + "u"] = cdir.x
	result[prefix + "v"] = cdir.y
	result[prefix + "w"] = cdir.z
	
	if fixed:
		result["abs_pos"] = position
		var c = Vector3(0, 0, -1).rotated(Vector3.UP, $Pivot.rotation.y)
		result["cx"] = c.x
		result["cy"] = c.y
		result["cz"] = c.z
	else:
		result["rel_pos"] = position
		var c = Vector3(0, 0, -1).rotated(Vector3.UP, $Pivot.rotation.y)
		result["tcx"] = c.x
		result["tcy"] = c.y
		result["tcz"] = c.z
		
	return result
	

func cast_spell(insert: Callable, spell: Spell):
	var vars = spell_variables(true)
	var ps = spell.get_particles(spell_variables(true))
	for p in ps:
		particles.append(p)
		var temps_vars = vars.duplicate()
		temps_vars["n"] = p.n
		var delay = spell.calculate_delay(temps_vars)
		get_tree().create_timer(delay).connect("timeout", start_particle(p, insert))
		

func start_particle(p: SpellBody, insert: Callable):
	return func():
		p.time_start = Time.get_unix_time_from_system()
		if not p.spell.is_bomb:
			p.fixed_vars["abs_pos"] = position
			var cdir = ((global_position + Vector3(0, 1.2, 0)) - cam.global_position).normalized()
			p.fixed_vars["u"] = cdir.x
			p.fixed_vars["v"] = cdir.y
			p.fixed_vars["w"] = cdir.z
		insert.call(p)


func _on_wet_area_body_entered(body):
	print(body)
