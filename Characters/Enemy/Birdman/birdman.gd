class_name Birdman
extends Enemy

var none_pattern: AttackPatterns
var attack_pattern1: AttackPatterns
var attack_pattern2: AttackPatterns
var attack_pattern3: AttackPatterns

var idle_path: PathStyle
var attack_path: PathStyle


func _ready() -> void:
	super._ready()
	
	velocity_movement = VelocityMovement.new()
	
	vitals = Vitals.new(Vitals.Stat.new(100, 0, 100), Vitals.Stat.new(50, 0, 5, 1))
	vitals.perception.value = 35
	vitals.attack.value = randf_range(level * 2, (level + 10) * 2)
	vitals.defence.value = randf_range(level, level + 5)
	
	var idle_pathway: PathStyle.Pathway = PathStyle.Pathway.new() \
		.move_to(Vector3(0, -4, 0)) \
		.line_to(Vector3(0, 20, 0), 5, PathStyle.Easing.out_quart) \
		.line_to(Vector3(0, -4, 0), 2, PathStyle.Easing.out_quart)
	idle_path = PathStyle.new(randf()).follow_path(idle_pathway).speed(2).align_y_to_ground_and_air().set_origin(position).use_absolute()
	
	var attack_pathway := PathStyle.Pathway.new()
	attack_pathway.append(
		[
			PathStyle.Segment.linear(Vector3(0, -4, 0), Vector3(0, 20, 0)),
			PathStyle.Segment.linear(Vector3(0, 20, 0), Vector3(0, -4, 0)),
		],
		[5, 2],
		[PathStyle.Easing.out_quart, PathStyle.Easing.out_quart]
	)
	attack_path = PathStyle.new(randf()).follow_path(attack_pathway)\
	.align_y_to_ground_and_air()\
	.set_use_player_as_origin()\
	.set_player_body_vision_as_origin(0, 0, 10.0 + randf_range(10.0, 20.0) + (level / 10.0) )\
	.look_at_player()\
	.speed(clampf(level / 100.0 * 25, 2, 25))
	
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	var water_spell := GlobalData.magic_book.copy_spell("linear", {}, true)
	water_spell.element = Spell.Element.WATER
	
	var water_fast := water_spell.duplicate({"s":str((level + 10.0) / 110.0 * 50.0), "d":"Br*2+r"})
	water_fast.power = clamp(randf_range(level, level * 2), 0, UpgradeSettings.LIMIT_P)
	var water_small_fast := water_fast.duplicate()
	water_small_fast.radius = 1
	var water_med_fast := water_fast.duplicate()
	water_med_fast.radius = 2
	var water_large_fast := water_fast.duplicate()
	water_large_fast.radius = 5
	
	var water_med := water_spell.duplicate({"s":str((level + 25.0) / 125.0 * 25.0), "d":"Br*2+r"})
	water_med.power = clamp(randf_range(level, level * 4), 0, UpgradeSettings.LIMIT_P)
	var water_small_med := water_med.duplicate()
	water_small_med.radius = 1
	var water_med_med := water_med.duplicate()
	water_med_med.radius = 2
	var water_large_med := water_med.duplicate()
	water_large_med.radius = 5
	
	var water_slow := water_spell.duplicate({"s":str((level + 50.0) / 150.0 * 15.0), "d":"Br*2+r"})
	water_slow.power = clamp(randf_range(level, level * 8), 0, UpgradeSettings.LIMIT_P)
	var water_small_slow := water_slow.duplicate()
	water_small_slow.radius = 1
	var water_med_slow := water_slow.duplicate()
	water_med_slow.radius = 2
	var water_large_slow := water_slow.duplicate()
	water_large_slow.radius = 5
	
	
	
	attack_pattern1 = AttackPatterns.new(
		[
			water_small_fast,
			water_small_med,
			water_small_slow,
		],
		[ 5, 5, 7 ],
		0.25
	)
	
	attack_pattern2 = AttackPatterns.new(
		[
			water_small_fast,
			water_small_med,
			water_small_slow,
			water_med_fast,
			water_med_med,
			water_med_slow,
		],
		[ 2, 2, 3, 5, 5, 7 ],
		0.33
	)
	
	attack_pattern3 = AttackPatterns.new(
		[
			AttackPatterns.new(
				[water_small_slow, water_small_fast],
				[2, 1]
			),
			AttackPatterns.new(
				[water_med_slow, water_med_fast],
				[3, 3]
			),
			AttackPatterns.new(
				[water_large_slow, water_large_fast],
				[5, 5]
			),
		],
		[ 2, 3, 5 ],
		0.5
	)
	
	animation_map["attack"] = "Weapon"
	
func _physics_process(delta: float) -> void:
	super._physics_process(delta)

func attack_state() -> AttackPatterns:
	health_bar.visible = not current_path == idle_path
	if current_path == idle_path:
		return none_pattern
	elif vitals.health.value >= 50:
		return attack_pattern1
	elif vitals.health.value >= 25:
		return attack_pattern2
	else:
		return attack_pattern3

func entity_info() -> EntityInfo:
	return EntityInfo.new(EntityInfo.Kind.UNDEAD, position)

func update_entity_info(info: EntityInfo) -> bool:
	info.position = position
	return true


func update_behaviour() -> void:
	if current_path == idle_path and sqrt(player.position.distance_squared_to(position)) < vitals.perception.value:
		current_path = attack_path		
	elif current_path == attack_path and sqrt(player.position.distance_squared_to(position)) > vitals.perception.value:
		current_path = idle_path
			

func death_box() -> Vector3:
	return Vector3(0.7, 1.9, 0.3)

func drop_artifact() -> Artifact:
	var t := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(10, 30))
	var r := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(10, 30))
	var b := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(10, 30))
	var l := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(10, 30))
	return Artifact.new(Time.get_datetime_string_from_system(), t, r, b, l)

func drop_spell() -> Spell:
	var water_para := GlobalData.magic_book.copy_spell("parabola", {"height":"4", "speed":"4"})
	water_para.element = Spell.Element.AIR
	water_para.name = "WaterP"
	return water_para
