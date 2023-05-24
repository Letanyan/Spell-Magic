class_name Player
extends CharacterBody3D

@onready var cam_pivot: Marker3D = $CamPivot
@onready var cam_arm: SpringArm3D = $CamPivot/Arm
@onready var cam: Camera3D = $CamPivot/Arm/Lens

@onready var animator: AnimationPlayer = $Pivot/AnimationPlayer 
@onready var cam_animator: AnimationPlayer = $AnimationPlayer

var velocity_movement = VelocityMovement.player()
var spell_caster = SpellCaster.new(SpellCaster.Entity.PLAYER)

var camera_target_velocity: float = 0
var shake_intensity: float = 0.0
const camera_shake_noise = preload("res://Characters/Player/camera_shake_noise.tres")

signal player_moved

var vitals: Vitals

func _ready():
	vitals = Vitals.new(Vitals.Stat.new(100, 0, 100), Vitals.Stat.new(50, 0, 50, 1))
	velocity = Vector3.ZERO

func _input(event):
	pass
	
func pan_camera(movement: Vector2):
	var damping = 0.75
	cam_pivot.rotate_y(-movement.x * damping / 180 * PI)
	cam_arm.rotate_x(-movement.y * damping / 180 * PI / 3)
	cam_arm.rotation.x = clamp(cam_arm.rotation.x, -PI / 2, PI / 2)

func add_impulse(impulse: Vector3):
	velocity_movement.impulse += impulse
	
func add_shake(amount: float):
	shake_intensity += amount

func _physics_process(delta):
	var movement = velocity_movement.update(delta, vitals, 14, self)
	velocity = movement["velocity"]
	move_and_slide()
	var direction = movement["direction"]
	if direction != Vector3.ZERO:
		if is_on_floor():
			if velocity.length() < 1:
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
		
	var rate = 0.05 if velocity.length() == 0 else 0.01
	camera_target_velocity = lerp(camera_target_velocity, clamp(velocity.length(), 0.0, 3.0), rate)
	cam_arm.spring_length = 1 + camera_target_velocity
	
	if shake_intensity > 0.0:
		var intensity = clamp(shake_intensity, 0, 1) ** 2
		if is_zero_approx(intensity):
			shake_intensity = 0.0
		else:
			shake_intensity = clamp(lerp(shake_intensity, 0.0, 0.05), 0.0, 1.0)
		var t = fmod(Time.get_unix_time_from_system(), 1000000)
		var dx = camera_shake_noise.get_noise_3d(t, 0, 0)
		var dy = camera_shake_noise.get_noise_3d(0, t, 0)
		var dz = camera_shake_noise.get_noise_3d(0, 0, t)
		cam.rotation.x = (dx * intensity) * (2 * PI / 8)
		cam.rotation.y = (dy * intensity) * (2 * PI / 8)
		cam.rotation.z = (dz * intensity) * (2 * PI / 8)
				
	spell_caster.deferred_update(self, delta)

func cast_spell(insert: Callable, next_spell: Spell):
	spell_caster.cast_spell(self, vitals, insert, next_spell)

func _on_wet_area_body_entered(body):
	print(body)
	
func entity_info() -> EntityInfo:
	return EntityInfo.new(EntityInfo.Kind.PLAYER, position)

func update_entity_info(info: EntityInfo):
	info.position = position
