class_name OrcDead
extends Enemy

var none_pattern: AttackPatterns
var random_pattern: AttackPatterns
var sequence_pattern: AttackPatterns

var idle_path: PathStyle
var attack_path: PathStyle

var electric_attack_small := GlobalData.magic_book.copy_spell("plane-slice")
var electric_attack_medium := GlobalData.magic_book.copy_spell("plane-slice")
var electric_attack_large := GlobalData.magic_book.copy_spell("plane-slice")
var electric_attack_lines := GlobalData.magic_book.copy_spell("bomb-linear")
	
func setup(seedling: int, biome: World.Biome) -> void:
	vitals = Vitals.enemy(hp(18), mana(16), mana_regen(10), percep(4,6), atk(14), def(13), {Artifact.Element.ELECTRIC: res(3, 1)})
	
	var circle_path := Pathway.new().random_points_in_disc(2, 0, 20, 0, 10)
	idle_path = PathStyle.new(seedling, position).follow_path(circle_path).align_y_to_ground()
	attack_path = PathStyle.new(0, position).towards_player(fit(5,10), 6, 12).look_at_player_xz().align_y_to_ground()
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	electric_attack_small.configure({
		"d": "C", "s": "0", "R": fits(6, 2)+"+rn0*"+fits(5, 8),
		"off": "uvw", "dir": "uvw", "a": "n/N*pi*2",
	}, Spell.Element.ELECTRIC, fit(7,14), power(5), radius(2), fiti(8,16), 5, 100, ea(10), null, fits(4,2)+"+n*"+fits(1.5, 0.25))
	electric_attack_medium.configure({
		"d": "C", "s": "0", "R": fits(8, 4)+"+rn0*"+fits(6, 12),
		"off": "uvw", "dir": "uvw", "a": "n/N*pi*2",
	}, Spell.Element.ELECTRIC, fit(5,10), power(6), radius(4), fiti(7,14), 3, 200, ea(13), null, fits(4,2)+"+n*"+fits(1.5, 0.25))
	electric_attack_large.configure({
		"d": "C", "s": "0", "R": fits(10, 5)+"+rn0*"+fits(9, 18),
		"off": "uvw", "dir": "uvw", "a": "n/N*pi*2",
	}, Spell.Element.ELECTRIC, fit(3,6), power(7), radius(6), fiti(6,12), 1, 300, ea(16), null, fits(4,2)+"+n*"+fits(1.5, 0.25))
	electric_attack_lines.configure({
		"d": "1", "a": "0", "R": "0.5", "S": fits(5,1), "s":fits(2, 0.5),
		"LC": "2", "LR": "pi*0.5"
	}, Spell.Element.ELECTRIC, fit(2, 10), power(5), radius(3), fiti(4,10), 10, 50, ea(10))
	
	random_pattern = AttackPatterns.new(
		[
			electric_attack_lines,
			electric_attack_small,
			electric_attack_medium,
			electric_attack_large,
		],
		AttackPatterns.choose_from_distribution(atkd(8), [ 10, 3, 1 ], -1)
	)
	
	sequence_pattern = AttackPatterns.new(
		[
			electric_attack_lines,
			electric_attack_small,
			electric_attack_medium,
			electric_attack_large,
		],
		AttackPatterns.choose_from_distribution(atkd(14), [2, 5, 4, 3], -1)
	)
	
	animation_map["attack"] = "Weapon"
	kind = World.Enemy.ORC_DEAD
	super.setup(seedling, biome)


func update_behaviour() -> void:
	super.update_behaviour()
	if is_idle:
		set_path_and_attack(idle_path, none_pattern)
	elif vitals.health.percentage() >= 0.5:
		set_path_and_attack(attack_path, random_pattern)
	else:
		set_path_and_attack(attack_path, sequence_pattern)

func drop_artifact() -> Artifact:
	var t := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	var r := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	var b := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	var l := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	var new_name := player.name_generator.dutch_names.generate(7, 2)
	return Artifact.new(new_name, t, r, b, l)

func drop_health() -> float:
	return health_drop(1)
