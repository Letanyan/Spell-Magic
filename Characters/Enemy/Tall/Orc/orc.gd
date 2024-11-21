class_name Orc
extends Enemy

var none_pattern: AttackPatterns
var random_pattern: AttackPatterns
var sequence_pattern: AttackPatterns

var idle_path: PathStyle
var attack_path: PathStyle

var rock_attack_small := GlobalData.magic_book.copy_spell("linear")
var rock_attack_medium := GlobalData.magic_book.copy_spell("linear")
var rock_attack_large := GlobalData.magic_book.copy_spell("linear")
	
func setup(seedling: int, biome: World.Biome) -> void:
	vitals = Vitals.enemy(hp(8), mana(1), mana_regen(1), percep(1,2), atk(7), def(3), {Artifact.Element.ROCK: res(1, 0)})
	
	var circle_path := Pathway.new().random_points_in_disc(2, 0, 20, 0, 10)
	idle_path = PathStyle.new(seedling, position).follow_path(circle_path).align_y_to_ground()
	attack_path = PathStyle.new(0, position).towards_player(fit(2,4), 1, 2).look_at_player_xz().align_y_to_ground()
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	rock_attack_small.configure({"d": "Br", "s": atks(1,2)}, Spell.Element.ROCK, fit(2,3), power(5), radius(2), 1, 0, 0, 0)
	rock_attack_medium.configure({"d": "Br*2", "s": atks(1,3)}, Spell.Element.ROCK, fit(2,4), power(6), radius(2), 1, 0, 0, 0)
	rock_attack_large.configure({"d": "Br*2.5", "s": atks(1,4)}, Spell.Element.ROCK, fit(2,5), power(7), radius(2), 1, 0, 0, 0)
	
	random_pattern = AttackPatterns.new(
		[
			rock_attack_small,
			rock_attack_medium,
			rock_attack_large,
		],
		AttackPatterns.choose_from_distribution(fit(5,3), [ 10, 3, 1 ], -1)
	)
	
	sequence_pattern = AttackPatterns.new(
		[
			rock_attack_small,
			rock_attack_medium,
			rock_attack_small,
			rock_attack_large,
			rock_attack_small,
		],
		AttackPatterns.choose_in_sequence(fitas(0.75, [ 2, 5, 2, 4, 2 ]), -1)
	)
	
	animation_map["attack"] = "Weapon"
	kind = World.Enemy.ORC
	super.setup(seedling, biome)

func attack_state() -> AttackPatterns:
	if is_idle:
		return none_pattern
	elif vitals.health.percentage() >= 0.5:
		return random_pattern
	else:
		return sequence_pattern


func update_behaviour() -> void:
	super.update_behaviour()
	if is_idle:
		current_path = idle_path
	elif vitals.health.percentage() >= 0.5:
		current_path = attack_path
	else:
		current_path = attack_path

func drop_artifact() -> Artifact:
	var t := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	var r := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	var b := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	var l := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	var new_name := player.name_generator.dutch_names.generate(7, 2)
	return Artifact.new(new_name, t, r, b, l)

func drop_health() -> float:
	return health_drop(1)
