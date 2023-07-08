class_name Undead
extends Enemy

var none_pattern: AttackPatterns
var random_pattern: AttackPatterns
var sequence_pattern: AttackPatterns

var idle_path: PathStyle
var attack_path: PathStyle

func _ready():
	super._ready()
	
	animation_map["idle"] = "undead_idle"
	animation_map["walk"] = "undead_walk"
	
	velocity_movement = VelocityMovement.new()
	
	vitals = Vitals.new(Vitals.Stat.new(100, 0, 100), Vitals.Stat.new(50, 0, 5, 1))
	vitals.perception.value = 10
	
	hormones = Hormones.new(-1.0, 1.0, -1.0, 1.0)
	
	idle_path = PathStyle.new(randf()).random_points_in_circle(10, 10).speed(2).set_origin(position)
	attack_path = PathStyle.new(randf()).towards_player(0, 1).speed(2).use_physics()
	current_path = idle_path
	
	knowledge = Knowledge.new({EntityInfo.Kind.PLAYER: true, EntityInfo.Kind.UNDEAD: true}, false)
	
	none_pattern = AttackPatterns.none()
	
	random_pattern = AttackPatterns.new(
		[
			Spell.new(false, "u * t * 5", "v * t * 5 + 4", "w * t * 5", "1", 0.1, 5, Spell.Element.WATER, 1),
			Spell.new(false, "u * t * 5", "v * t * 5 + 4", "w * t * 5", "1", 0.1, 5, Spell.Element.WATER, 1),
			Spell.new(false, "u * t * 5", "v * t * 5 + 4", "w * t * 5", "1", 0.1, 5, Spell.Element.WATER, 1),
		],
		[ 5, 3, 2 ],
		false,
		0.25
	)
	
	sequence_pattern = AttackPatterns.new(
		[
			Spell.new(false, "u * t * 5", "v * t * 5 + 4", "w * t * 5", "1", 0.1, 5, Spell.Element.FIRE, 1),
			Spell.new(false, "u * t * 5", "v * t * 5 + 4", "w * t * 5", "1", 0.1, 5, Spell.Element.WATER, 1),
			Spell.new(false, "u * t * 5", "v * t * 5 + 4", "w * t * 5", "1", 0.1, 5, Spell.Element.ROCK, 1),
		],
		[ 2, 5, 3 ],
		true
	)

func attack_state() -> AttackPatterns:
	if current_path == idle_path:
		health_bar.visible = false
		return none_pattern
	elif vitals.health.value >= 50:
		health_bar.visible = true
		return sequence_pattern
	else:
		health_bar.visible = true
		return random_pattern

func entity_info() -> EntityInfo:
	return EntityInfo.new(EntityInfo.Kind.UNDEAD, position)

func update_entity_info(info: EntityInfo) -> bool:
	info.position = position
	return true


func update_behaviour():
	if current_path == idle_path and sqrt(player.position.distance_squared_to(position)) < vitals.perception.value:
		current_path = attack_path
	elif current_path == attack_path and sqrt(player.position.distance_squared_to(position)) > vitals.perception.value * 2:
		current_path = idle_path

func death_box() -> Vector3:
	return Vector3(0.7, 1.9, 0.3)
