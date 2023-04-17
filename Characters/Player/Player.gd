class_name Player
extends CharacterBody3D

@onready var cam_pivot = $CamPivot
@onready var cam_arm = $CamPivot/Arm
@onready var cam = $CamPivot/Arm/Lens

@export var speed = 14
@export var fall_acceleration = 75
@export var friction = 25
@export var jump_impulse = 14
@export var bounce_impulse = 16

var target_velocity = Vector3.ZERO
var impulse = Vector3.ZERO

var spells: Array = []
var particles: Array = []

func _input(event):
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and event is InputEventMouseMotion:
		cam_pivot.rotate_y(-event.relative.x / 180 * PI)
		cam_arm.rotate_x(-event.relative.y / 180 * PI / 3)
		cam_arm.rotation.x = clamp(cam_arm.rotation.x, -PI / 2, PI / 2)

func _physics_process(delta):
	var input_dir = Input.get_vector("left", "right", "forward", "back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction = direction.rotated(Vector3.UP, cam_pivot.rotation.y)
		
	target_velocity.x = direction.x * speed
	target_velocity.z = direction.z * speed
	
	if not is_on_floor():
		target_velocity.y = target_velocity.y - (fall_acceleration * delta)
		# $AnimationPlayer.stop()
	elif Input.is_action_just_pressed("jump"):
		target_velocity.y = jump_impulse
	else:
		pass
		# $AnimationPlayer.play()
	
	if absf(impulse.length()) > 1:
		var len = impulse.length()
		var nor = impulse.normalized()
		var fri = friction * delta 
		impulse = Vector3(
			impulse.x - nor.x * fri,
			impulse.y - nor.y * fri,
			impulse.z - nor.z * fri,
		)
#		impulse.x = impulse.x + (friction * delta * -signf(impulse.x))
#		impulse.y = impulse.y + (friction * delta * -signf(impulse.y))
#		impulse.z = impulse.z + (friction * delta * -signf(impulse.z))
	else:
		impulse.x = 0
		impulse.y = 0
		impulse.z = 0
	
#	print(impulse)
	velocity = target_velocity + impulse
	if direction != Vector3.ZERO:
		$Pivot.rotation.y = lerp_angle($Pivot.rotation.y, atan2(-velocity.x, -velocity.z), 0.15)
		# $AnimationPlayer.speed_scale = 4
	else:
		pass
		# $AnimationPlayer.speed_scale = 1
		
	move_and_slide()
	
	for index in range(get_slide_collision_count()):
		var collision = get_slide_collision(index)
		if direction != Vector3.ZERO:
			target_velocity.y = floor(collision.get_normal().y * speed)
		if collision.get_collider() == null:
			continue
		if collision.get_collider().is_in_group("mob"):
			var mob = collision.get_collider()
			if Vector3.UP.dot(collision.get_normal()) > 0.1:
				mob.squash()
				target_velocity.y = bounce_impulse
				
	var t = Time.get_ticks_msec()
	var should_remove = []
	for i in range(spells.size()):
		var p: SpellBody = particles[i]
		spells[i].update_spell(t, spell_variables(false), p)
		if spells[i].has_expired(t):
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
	
	return result
	

func cast_spell(spell: Spell) -> SpellBody:
	spells.append(spell)
	var p = spell.get_particle()
	p.spell = spell
	particles.append(p)
	return p
