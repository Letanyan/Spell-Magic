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
	
	idle_path = PathStyle.new().random_points_in_circle(10, 10).speed(2).set_origin(position)
#	attack_path = PathStyle.new(randf()).towards_player(1.0, 2.0).speed(3).use_physics().set_use_player_as_origin().look_at_player()
	attack_path = PathStyle.new().set_use_player_as_origin().set_player_vision_as_origin(0, 10).speed(2).use_physics().look_at_player()
	attack_path.min_radius = 0
	attack_path.max_radius = 1
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	default_pattern = AttackPatterns.new(
		[
			GlobalData.magic_book.spell_with_name("Rain"),
			GlobalData.magic_book.spell_with_name("Sprite"),
		],
		[ 1, 40 ],
		false,
		0.0,
		[
			AttackMovement.new(),
			AttackMovement.new(
				PathStyle.new(randf()).random_points_in_circle(10, 1).speed(10).set_use_player_as_origin(),
				PathStyle.new(randf()).random_points_in_circle(10, 1).speed(10).set_use_player_as_origin(),
				PathStyle.new(randf()).random_points_in_circle(10, 1).speed(10).set_use_player_as_origin(),
			)
		]
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

func __default_pattern() -> AttackPatterns:
	default_pattern.spells = [
		GlobalData.magic_book.spell_with_name("Rain"),
		GlobalData.magic_book.spell_with_name("Sprite"),
	]
	return default_pattern

func attack_state() -> AttackPatterns:
	if current_path == idle_path:
		return none_pattern
	elif vitals.health.value >= 50:
		return __default_pattern()
	else:
		return default_pattern

func entity_info() -> EntityInfo:
	return EntityInfo.new(EntityInfo.Kind.UNDEAD, position)

func update_entity_info(info: EntityInfo) -> bool:
	info.position = position
	return true


func update_behaviour():
	if current_path == idle_path and sqrt(player.position.distance_squared_to(position)) < vitals.perception.value:
		player.watch_enemy(get_node("."))
		health_bar.visible = true
		current_path = attack_path
	elif current_path == attack_path and sqrt(player.position.distance_squared_to(position)) > vitals.perception.value * 2:
		player.ignore_enemy(get_node("."))
		health_bar.visible = false
		current_path = idle_path

func death_box() -> Vector3:
	return Vector3(0.7, 1.9, 0.3)
