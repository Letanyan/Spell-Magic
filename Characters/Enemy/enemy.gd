class_name Enemy
extends CharacterBody3D

var movement_target_position: Vector3 = Vector3.ZERO

@onready var animator: AnimationPlayer = $AnimationPlayer

var velocity_movement: VelocityMovement

var spell_caster = SpellCaster.new(SpellCaster.Entity.ENEMY)

var player: Player
var behaviour: Behaviour
var vitals: Vitals
var knowledge: Knowledge
var current_path: PathStyle

var animation_map: Dictionary

var behavior_tick: int = 0
var spell_tick: int = 0

func _ready():
	animation_map = {}
	current_path = PathStyle.new(randf()).circle(position, 15).speed(2)
	
func add_impulse(impulse: Vector3):
	velocity_movement.impulse += impulse
	
func add_shake(amount: float):
	player.add_shake(amount)
	
func increment_ticks():
	behavior_tick += 1
	spell_tick += 1
	
func play_animation(animation: String, blend: float):
	var anim = animation_map.get(animation, "")
	if anim != "":
		animator.play(anim, blend) 

func attack_state() -> AttackPatterns:
	return AttackPatterns.new([], [], false)

func _physics_process(delta):
	increment_ticks()

	var movement = velocity_movement.update(delta, vitals, current_path.movement_speed, self)
	if velocity_movement.impulse != Vector3.ZERO:
		velocity = movement["velocity"]
		move_and_slide()
	else:
		match current_path.mover:
			PathStyle.Mover.PHYSICS:
				velocity = movement["velocity"]
				move_and_slide()
			PathStyle.Mover.ABSOLUTE:
				position += movement["absolute"]
			PathStyle.Mover.ABSOLUTE_XZ:
				var v: Vector3 = movement["absolute"]
				var t: Vector3 = movement["target"]
				var g := Navigator.get_world_height(get_world_3d().direct_space_state, position.x, position.z)
				if position.y < g:
					position.y = g
					t.y = 0
				position += Vector3(v.x, v.y + t.y, v.z)
		if current_path.lookat == PathStyle.LookAt.PLAYER:
			look_at(player.position)

	if behavior_tick == 30:
		update_behaviour()
		var next_pos := current_path.next_position(self, player)
		velocity_movement.target_position = Navigator.find_target(get_node("."), next_pos)
		behavior_tick = 0

	if spell_tick == 30:
		var spell := attack_state().choose_spell(vitals, behaviour)
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
	spell_caster.cast_spell(self, vitals, insert, next_spell)

func entity_info() -> EntityInfo:
	return EntityInfo.new(EntityInfo.Kind.ENEMY, position)

func update_entity_info(info: EntityInfo):
	info.position = position

func update_behaviour():
	pass

func handle_damage():
	pass
