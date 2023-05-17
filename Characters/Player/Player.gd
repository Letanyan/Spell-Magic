class_name Player
extends CharacterBody3D

@onready var cam_pivot: Marker3D = $CamPivot
@onready var cam_arm: SpringArm3D = $CamPivot/Arm
@onready var cam: Camera3D = $CamPivot/Arm/Lens

@onready var animator: AnimationPlayer = $Pivot/AnimationPlayer 

var velocity_movement = VelocityMovement.player()
var spell_caster = SpellCaster.new(SpellCaster.Entity.PLAYER)

signal player_moved

var vitals: Vitals

func _ready():
	vitals = Vitals.new(100, 50)

func _input(event):
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and event is InputEventMouseMotion:
		cam_pivot.rotate_y(-event.relative.x / 180 * PI)
		cam_arm.rotate_x(-event.relative.y / 180 * PI / 3)
		cam_arm.rotation.x = clamp(cam_arm.rotation.x, -PI / 2, PI / 2)

func apply_impulse(impulse: Vector3):
	velocity_movement.impulse += impulse

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
				
	spell_caster.deferred_update(self, delta)

func cast_spell(insert: Callable, next_spell: Spell):
	spell_caster.cast_spell(self, vitals, insert, next_spell)

func _on_wet_area_body_entered(body):
	print(body)
