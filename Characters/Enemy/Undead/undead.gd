class_name Undead
extends Enemy

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
	
	idle_path = PathStyle.new(blender, get_rid().get_id()).circle(position, 15).speed(2)
	attack_path = PathStyle.new(blender, get_rid().get_id()).follow_player(0, 1).speed(2)
	current_path = idle_path
	
	knowledge = Knowledge.new({EntityInfo.Kind.PLAYER: true, EntityInfo.Kind.UNDEAD: true}, false)
	
	random_pattern = AttackPatterns.new(
		[
			Spell.new(false, "u * t * 5", "v * t * 5 + 4", "w * t * 5", "1", 0.1, 5000, Spell.Element.WATER, 1),
			Spell.new(false, "u * t * 5", "v * t * 5 + 4", "w * t * 5", "1", 0.1, 5000, Spell.Element.WATER, 1),
			Spell.new(false, "u * t * 5", "v * t * 5 + 4", "w * t * 5", "1", 0.1, 5000, Spell.Element.WATER, 1),
		],
		[ 5, 3, 2 ],
		false
	)
	
	sequence_pattern = AttackPatterns.new(
		[
			Spell.new(false, "u * t * 5", "v * t * 5 + 4", "w * t * 5", "1", 0.1, 5000, Spell.Element.FIRE, 1),
			Spell.new(false, "u * t * 5", "v * t * 5 + 4", "w * t * 5", "1", 0.1, 5000, Spell.Element.WATER, 1),
			Spell.new(false, "u * t * 5", "v * t * 5 + 4", "w * t * 5", "1", 0.1, 5000, Spell.Element.ROCK, 1),
		],
		[ 2, 5, 3 ],
		true
	)

func attack_state() -> AttackPatterns:
	if vitals.health.value >= 50:
		return sequence_pattern
	else:
		return random_pattern

func entity_info() -> EntityInfo:
	return EntityInfo.new(EntityInfo.Kind.UNDEAD, position)

func update_entity_info(info: EntityInfo):
	info.position = position


func update_behaviour():
	if current_path == idle_path and sqrt(player.position.distance_squared_to(position)) < 30.0:
		print("aggro: ", sqrt(player.position.distance_squared_to(position)))
		vitals.aggression.value = 0.5
		current_path = attack_path
	elif current_path == attack_path and sqrt(player.position.distance_squared_to(position)) > 90.0:
		print("passive: ", sqrt(player.position.distance_squared_to(position)))
		vitals.aggression.value = 0.0
		current_path = idle_path
