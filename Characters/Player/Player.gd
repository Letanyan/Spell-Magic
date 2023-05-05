class_name Player
extends CharacterBody3D

@onready var cam_pivot: Marker3D = $CamPivot
@onready var cam_arm: SpringArm3D = $CamPivot/Arm
@onready var cam: Camera3D = $CamPivot/Arm/Lens

@onready var animator: AnimationPlayer = $Pivot/AnimationPlayer 

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

var velocity_movement = VeloctyMovement.new()

signal player_moved


var particles: Array = []

var vitals: Vitals

func _ready():
	# These values need to be adjusted for the actor's speed
	# and the navigation layout.
	navigation_agent.path_desired_distance = 0.5
	navigation_agent.target_desired_distance = 0.5
	velocity_movement.navigation_agent = navigation_agent
	
	vitals = Vitals.new(100, 50)

func _input(event):
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and event is InputEventMouseMotion:
		cam_pivot.rotate_y(-event.relative.x / 180 * PI)
		cam_arm.rotate_x(-event.relative.y / 180 * PI / 3)
		cam_arm.rotation.x = clamp(cam_arm.rotation.x, -PI / 2, PI / 2)
		
func set_movement_target(movement_target: Vector3):
	navigation_agent.set_target_position(movement_target)

func apply_impulse(impulse: Vector3):
	velocity_movement.impulse += impulse

func interval_check(interval: int, epsilon: int):
	var t = Time.get_ticks_msec() % interval
	return t < epsilon

func _physics_process(delta):
	var movement = velocity_movement.update(delta, vitals, 14, self)
	velocity = movement["velocity"]
	move_and_slide()
	var direction = movement["direction"]
	if direction != Vector3.ZERO:
		if is_on_floor():
			if direction.length() > 1:
				animator.play("Man_Walk", 1)
			else:
				animator.play("Man_Run", 1)
	else:
		if is_on_floor():
			animator.play("Man_Idle", 1)
		
	if not is_on_floor_only():
		animator.play("Man_Run", 1)
		
	if velocity:
		player_moved.emit(delta)
				
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

	var cdir = ((global_position + cam_pivot.position) - cam.global_position).normalized()
	
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
	
func all_spell_variables():
	var result = spell_variables(true)
	result.merge(spell_variables(false))
	return result

func cast_spell(insert: Callable, spell: Spell):
	var vars = all_spell_variables()
	var ps = spell.get_particles(vars)
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
			p.fixed_vars.merge(spell_variables(true), true)
		insert.call(p)


func _on_wet_area_body_entered(body):
	print(body)
