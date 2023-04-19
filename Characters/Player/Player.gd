class_name Player
extends CharacterBody3D

@onready var cam_pivot: Marker3D = $CamPivot
@onready var cam_arm: SpringArm3D = $CamPivot/Arm
@onready var cam: Camera3D = $CamPivot/Arm/Lens

@export var speed = 14
@export var fall_acceleration = 75
@export var friction = 25
@export var jump_impulse = 20
@export var bounce_impulse = 16

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

signal player_moved

var target_velocity = Vector3.ZERO
var impulse = Vector3.ZERO

var spells: Array = []
var particles: Array = []

func _ready():
	# These values need to be adjusted for the actor's speed
	# and the navigation layout.
	navigation_agent.path_desired_distance = 0.5
	navigation_agent.target_desired_distance = 0.5

func _input(event):
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and event is InputEventMouseMotion:
		cam_pivot.rotate_y(-event.relative.x / 180 * PI)
		cam_arm.rotate_x(-event.relative.y / 180 * PI / 3)
		cam_arm.rotation.x = clamp(cam_arm.rotation.x, -PI / 2, PI / 2)
		
func set_movement_target(movement_target: Vector3):
	navigation_agent.set_target_position(movement_target)

func _physics_process(delta):
	if not navigation_agent.is_navigation_finished():
		var current_agent_position: Vector3 = global_transform.origin
		var next_path_position: Vector3 = navigation_agent.get_next_path_position()

		var new_velocity: Vector3 = next_path_position - current_agent_position
		new_velocity = new_velocity.normalized()
		new_velocity = new_velocity * speed

		set_velocity(new_velocity)
		move_and_slide()
		print(navigation_agent.distance_to_target())

	var input_dir = Input.get_vector("left", "right", "forward", "back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction = direction.rotated(Vector3.UP, cam_pivot.rotation.y)
		
	if is_on_floor():
		target_velocity.x = direction.x * speed
		target_velocity.z = direction.z * speed
	
	if not is_on_floor():
		target_velocity.y = target_velocity.y - (fall_acceleration * delta)
	else:
		target_velocity.y = 0
	if Input.is_action_just_pressed("jump"):
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
		# $AnimationPlayer.speed_scale = 4
	else:
		pass
		# $AnimationPlayer.speed_scale = 1
		
	move_and_slide()
	if velocity:
		player_moved.emit(delta)
				
	var t = Time.get_ticks_msec()
	var should_remove = []
	for i in range(spells.size()):
		var p: SpellBody = particles[i]
		var spell: Spell = spells[i]
		spell.update_spell(t, spell_variables(false), p)
		if spell.has_expired(t):
			should_remove.append(i)
			p.stop_emitting()
			
	should_remove.reverse()
	for i in should_remove:
		spells.remove_at(i)
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
	else:
		result["rel_pos"] = position
	
	return result
	

func cast_spell(spell: Spell) -> SpellBody:
	spells.append(spell)
	var p = spell.get_particle()
	p.spell = spell
	particles.append(p)
	return p
