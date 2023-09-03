class_name Bat
extends Enemy

var none_pattern: AttackPatterns
var random_pattern: AttackPatterns
var sequence_pattern: AttackPatterns

var idle_path: PathStyle
var attack_path: PathStyle

func _ready():
	super._ready()
	
	velocity_movement = VelocityMovement.new()
	
	vitals = Vitals.new(Vitals.Stat.new(100, 0, 100), Vitals.Stat.new(50, 0, 5, 1))
	vitals.perception.value = 25
	
	hormones = Hormones.new(0.7, 1.0, -0.75, 0)
	
	idle_path = PathStyle.new(randf()).circle_path(5, 10).set_origin(position).speed(7).use_absolute().align_y_to_origin()
	attack_path = PathStyle.new(randf()).circle_path(5 * randf() + 5, 5 * randf() + 2).set_use_player_as_origin().speed(2).use_absolute().align_y_to_origin().look_at_player()
	current_path = idle_path
	
	knowledge = Knowledge.new({EntityInfo.Kind.PLAYER: true, EntityInfo.Kind.BAT: true}, false)
	
	none_pattern = AttackPatterns.none()
	
	random_pattern = AttackPatterns.new(
		[
			Spell.new(false, "u * t * 10 + u * 2", "v * t * 10 + v * 2", "w * t * 10 + w * 2", "1", 0.1, 1000, Spell.Element.ELECTRIC, 1),
			Spell.new(false, "u * t * 5 + u * 2", "v * t * 5 + v * 2", "w * t * 5 + w * 2", "1", 0.1, 2000, Spell.Element.ELECTRIC, 1),
			Spell.new(false, "u * t * 15 + u * 2", "v * t * 15 + v * 2", "w * t * 15 + w * 2", "1", 0.1, 3000, Spell.Element.ELECTRIC, 1),
		],
		[ 3, 10, 2 ],
		false,
		0.15
	)
	
	sequence_pattern = AttackPatterns.new(
		[
			Spell.new(false, "u * t * 5", "v * t * 5 + 1", "w * t * 5", "1", 0.1, 5, Spell.Element.ELECTRIC, 1),
			Spell.new(false, "u * t * 5", "v * t * 5 + 1", "w * t * 5", "1", 0.1, 5, Spell.Element.FIRE, 1),
			Spell.new(false, "u * t * 5", "v * t * 5 + 1", "w * t * 5", "1", 0.1, 5, Spell.Element.ELECTRIC, 1),
		],
		[ 1, 2, 1 ],
		true
	)
	
	animation_map["run"] = "Fast_Flying"
	animation_map["idle"] = "Flying_Idle"
	animation_map["walk"] = "Flying_Idle"
	animation_map["attack"] = "Headbutt"
#	animation_is_nested = true

func attack_state() -> AttackPatterns:
	if current_path == idle_path:
		return none_pattern
	elif vitals.health.value >= 50:
		return random_pattern
	else:
		return sequence_pattern

func entity_info() -> EntityInfo:
	return EntityInfo.new(EntityInfo.Kind.BAT, position)

func update_entity_info(info: EntityInfo) -> bool:
	info.position = position
	return true


func update_behaviour():
	if current_path == idle_path and sqrt(player.position.distance_squared_to(position)) < vitals.perception.value:
		current_path = attack_path
	elif current_path == attack_path and sqrt(player.position.distance_squared_to(position)) > vitals.perception.value * 2:
		current_path = idle_path
