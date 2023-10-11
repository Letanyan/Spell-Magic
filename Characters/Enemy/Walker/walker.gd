class_name Walker
extends Enemy

var none_pattern: AttackPatterns
var default_pattern: AttackPatterns
var sequence_pattern: AttackPatterns

var idle_path: PathStyle
var attack_path: PathStyle

func _ready():
	super._ready()
	
	velocity_movement = VelocityMovement.new()
	
	vitals = Vitals.new(Vitals.Stat.new(100, 0, 100), Vitals.Stat.new(50, 0, 5, 1))
	vitals.perception.value = 25
	
	idle_path = PathStyle.new(randf()).random_points_in_circle(10, 10).speed(2).set_origin(position)
	attack_path = PathStyle.new(randf()).towards_player(1.0, 2.0).speed(3).use_physics().set_use_player_as_origin().look_at_player()
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	default_pattern = AttackPatterns.new(
		[
			Spell.new(false, "u*(3 + 3*t)", "v*(3 + 3*t) + 2", "w*(3 + 3*t)", "1 + 2*fl", level * level * 2, 5, Spell.Element.ICE, 1),
			Spell.new(false, "u*(3 + 200*fl*t)", "v*(3 + 200*fl*t) + 0.5*-1*t*t + 2", "w*(3 + 200*fl*t)", "1 + r0 * fl * 10", 5 * level ** 3, 5, Spell.Element.ROCK, 1),
			Spell.new(false, "u*(3 + t*fl*100)", "v*(3 + t*fl*100) + 2", "w*(3 + t*fl*100)", "1 + fl*5", level * 0.5, 5, Spell.Element.WATER, 1),
		],
		[ 3, 7, 2 ],
		false,
		0.25
	)
	
	sequence_pattern = AttackPatterns.new(
		[
			Spell.new(false, "u * t * 5 + u*3", "v * t * 5 + v*6", "w * t * 5 + w*3", "1", 25, 5, Spell.Element.ELECTRIC, 1),
			Spell.new(false, "u * t * 5 + u*3", "v * t * 5 + v*6", "w * t * 5 + w*3", "1", 50, 5, Spell.Element.ELECTRIC, 1),
			Spell.new(false, "u * t * 5 + u*3", "v * t * 5 + v*6", "w * t * 5 + w*3", "1", 75, 5, Spell.Element.ELECTRIC, 1),
		],
		[ 2, 5, 3 ],
		true
	)
	
	animation_map["attack"] = "Weapon"

func attack_state() -> AttackPatterns:
	if current_path == idle_path:
		health_bar.visible = false
		return none_pattern
	elif vitals.health.value >= 50:
		health_bar.visible = true
		return default_pattern
	else:
		health_bar.visible = true
		return default_pattern

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
