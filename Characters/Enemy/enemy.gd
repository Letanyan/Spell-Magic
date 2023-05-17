class_name Enemy
extends CharacterBody3D

var movement_target_position: Vector3 = Vector3.ZERO

@onready var animator: AnimationPlayer = $AnimationPlayer

var velocity_movement: VelocityMovement

var spell_caster = SpellCaster.new(SpellCaster.Entity.ENEMY)

var player: Player
var blender: NoiseBlender
var behaviour: Behaviour
var vitals: Vitals
var patterns: AttackPatterns

var animation_map: Dictionary

var behavior_tick: int = 0
var spell_tick: int = 0

func _ready():
	animation_map = {}
	
func apply_impulse(impulse: Vector3):
	velocity_movement.impulse += impulse
	
func increment_ticks():
	behavior_tick += 1
	spell_tick += 1
	
	
func play_animation(animation: String, blend: float):
	var anim = animation_map.get(animation, "")
	if anim != "":
		animator.play(anim, blend) 

func _physics_process(delta):
	increment_ticks()
	
	var movement = velocity_movement.update(delta, vitals, behaviour.movement_speed(), self)
	velocity = movement["velocity"]
	move_and_slide()

		
	if behavior_tick == 20:
		behaviour.update_state(self, player)
		var next_pos = behaviour.next_position(self, player)
		velocity_movement.target_position = Navigator.find_path(get_node("."), next_pos)
		behavior_tick = 0
	
	if spell_tick == 60:
		var spell = patterns.choose_spell(0.5 if behaviour.is_aggresive() else 0.0)
		if spell != null:
			cast_spell(func(p): if p != null: call_deferred("add_sibling", p), spell)
		spell_tick = 0
		
	spell_caster.update(self, delta)
	
	if velocity != Vector3.ZERO:
		if is_on_floor():
			if velocity.length() > 1:
				play_animation("walk", 1)
			else:
				play_animation("run", 1)
	else:
		if is_on_floor():
			play_animation("idle", 1)

	if not is_on_floor_only():
		play_animation("run", 1)

func cast_spell(insert: Callable, next_spell: Spell):
	spell_caster.cast_spell(self, insert, next_spell)
