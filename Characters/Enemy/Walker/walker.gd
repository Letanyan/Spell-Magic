class_name Walker
extends Enemy

var none_pattern: AttackPatterns
var default_pattern: AttackPatterns
var sequence_pattern: AttackPatterns
var defence_pattern: AttackPatterns

var idle_path: PathStyle
var attack_path: PathStyle

var ice_wall_timer: int = 0

func _ready():
	super._ready()
	
	velocity_movement = VelocityMovement.new()
	
	vitals = Vitals.new(Vitals.Stat.new(100, 0, 100), Vitals.Stat.new(50, 0, 5, 1))
	vitals.perception.value = 25
	
	idle_path = PathStyle.new().speed(2).random_points_in_circle(10, 10).set_origin(position)
	attack_path = PathStyle.new().set_use_player_as_origin().set_player_body_vision_as_origin(0, 10).speed(2).use_physics().look_at_player()
	attack_path.min_radius = 0
	attack_path.max_radius = 1
	current_path = idle_path
	
	var water_small := GlobalData.magic_book.copy_spell("linear", {"d": "Br", "s": "8"})
	water_small.element = Spell.Element.WATER
	water_small.radius = 0.2
	var water_medium := GlobalData.magic_book.copy_spell("linear", {"d": "Br*2", "s": "4", "h": "Br/2+0.4"})
	water_medium.element = Spell.Element.WATER
	water_medium.radius = 0.8
	var water_large := GlobalData.magic_book.copy_spell("linear", {"d": "Br*3", "s": "2", "h": "Br/2+0.6"})
	water_large.element = Spell.Element.WATER
	water_large.radius = 1.2
	
	var ice_small := GlobalData.magic_book.copy_spell("linear", {"d": "Br", "s": "8", "h": "Br/2+0.4"})
	ice_small.element = Spell.Element.ICE
	ice_small.radius = 0.8
	var ice_medium := GlobalData.magic_book.copy_spell("linear", {"d": "Br*2", "s": "4", "h": "Br/2+0.8"})
	ice_medium.element = Spell.Element.ICE
	ice_medium.radius = 1.6
	var ice_large := GlobalData.magic_book.copy_spell("linear", {"d": "Br*3", "s": "2", "h": "Br/2+1.6"})
	ice_large.element = Spell.Element.ICE
	ice_large.radius = 3.2
	
	var ice_wall := GlobalData.magic_book.copy_spell("wall", {})
	ice_wall.element = Spell.Element.ICE
	ice_wall.radius = 3 * 2
	ice_wall.follow = true
	ice_wall.duration = 10.0
	
	
	none_pattern = AttackPatterns.none()
	
	default_pattern = AttackPatterns.new(
		[
			water_small,
			water_medium,
			water_large,
			ice_small,
			ice_medium,
			ice_large,
		],
		[ 10, 4, 2, 10, 4, 2 ],
		0.5,
		[
#			AttackMovement.new(),
#			AttackMovement.new(
#				PathStyle.new(randf()).random_points_in_circle(10, 1).speed(10).set_use_player_as_origin(),
#				PathStyle.new(randf()).random_points_in_circle(10, 1).speed(10).set_use_player_as_origin(),
#				PathStyle.new(randf()).random_points_in_circle(10, 1).speed(10).set_use_player_as_origin(),
#			)
		]
	)
	
	sequence_pattern = AttackPatterns.new(
		[
			water_small,
			ice_small,
			water_small,
			ice_small,
			water_large,
			ice_large,
			water_large,
			ice_large,
			water_medium,
			ice_medium,
			water_medium,
			ice_medium,
		],
		[ 2, 2, 2, 2, 6, 6, 6, 6, 4, 4, 4, 4 ],
	)
	
	defence_pattern = AttackPatterns.new(
		[ice_wall],
		[0],
	)
	
	animation_map["attack"] = "Weapon"

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if current_path != idle_path:
		ice_wall_timer += 1

func __default_pattern() -> AttackPatterns:
	default_pattern.spells = [
		GlobalData.magic_book.copy_spell("Rain"),
		GlobalData.magic_book.copy_spell("parabola", {"height":"4", "speed":"4"})
	]
	return default_pattern

func attack_state() -> AttackPatterns:
	health_bar.visible = not current_path == idle_path
	if current_path == idle_path:
		return none_pattern
	else:
		if ice_wall_timer == 0 or ice_wall_timer > 60 * 10:
			ice_wall_timer = 1
			return defence_pattern
		elif vitals.health.value >= 50:
			return default_pattern
		else:
			return sequence_pattern

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
