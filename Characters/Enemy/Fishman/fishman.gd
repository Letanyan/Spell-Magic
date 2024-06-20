class_name Fishman
extends Enemy

var none_pattern: AttackPatterns
var default_pattern: AttackPatterns
var sequence_pattern: AttackPatterns

var idle_path: PathStyle
var attack_direct_path: PathStyle
	
func setup() -> void:
	vitals = Vitals.new(Vitals.Stat.new(100, 0, 100), Vitals.Stat.new(50, 0, 5, 1))
	vitals.perception.value = 20
	
	idle_path = PathStyle.new(randf()).random_points_in_circle(10, 10, 0, 10).align_y_to_ground().set_origin(position).use_absolute()
	attack_direct_path = PathStyle.new(randf(), position).towards_player(2, 4, 6).set_player_body_vision_as_origin(0, 20, 2, 3).align_y_to_ground().use_absolute().look_at_player_xz()
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	var water_para := GlobalData.magic_book.copy_spell("loop-shot", {"H":"4", "s":str(4+level*1.1), "CC": "C"})
	water_para.element = Spell.Element.WATER
	var water_line := GlobalData.magic_book.copy_spell("linear", {"s":str(5+level*1.1), "d":"2"})
	water_line.duration = 5
	water_line.element = Spell.Element.WATER
	
	default_pattern = AttackPatterns.new(
		[
			water_line,
			water_para,
		],
		AttackPatterns.choose_from_distribution(0.25, [ 7, 3 ], -1)
	)
	
	sequence_pattern = AttackPatterns.new(
		[
			Spell.new(false, "u * t * 5 + u * 2", "v * t * 5 + v * 2 + 2", "w * t * 5 + w * 2", 1, 50, 5, Spell.Element.FIRE, 1),
			Spell.new(false, "u * t * 5 + u * 2", "v * t * 5 + v * 2 + 2", "w * t * 5 + w * 2", 1, 50, 5, Spell.Element.WATER, 1),
			Spell.new(false, "u * t * 5 + u * 2", "v * t * 5 + v * 2 + 2", "w * t * 5 + w * 2", 1, 50, 5, Spell.Element.ROCK, 1),
		],
		AttackPatterns.choose_in_sequence([ 2, 5, 3 ], -1)
	)
	
	animation_map["attack"] = "Weapon"
	kind = World.Enemy.FISH

func attack_state() -> AttackPatterns:
	health_bar.visible = not current_path == idle_path
	if current_path == idle_path:
		return none_pattern
	elif vitals.health.value >= 50:
		return default_pattern
	else:
		return default_pattern

func entity_info() -> EntityInfo:
	return EntityInfo.new(EntityInfo.Kind.UNDEAD, position)

func update_entity_info(info: EntityInfo) -> bool:
	info.position = position
	return true

func update_behaviour() -> void:
	if current_path == idle_path and sqrt(player.position.distance_squared_to(position)) < vitals.perception.value:
		current_path = attack_direct_path
	elif current_path == attack_direct_path and sqrt(player.position.distance_squared_to(position)) > vitals.perception.value * 5:
		current_path = idle_path

func drop_artifact() -> Artifact:
	var t := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(10, 30))
	var r := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(10, 30))
	var b := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(10, 30))
	var l := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(10, 30))
	return Artifact.new(Time.get_datetime_string_from_system(), t, r, b, l)
