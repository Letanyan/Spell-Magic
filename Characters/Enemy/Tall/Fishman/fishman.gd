class_name Fishman
extends Enemy

var none_pattern: AttackPatterns
var default_pattern: AttackPatterns

var idle_path: PathStyle
var attack_direct_path: PathStyle
	
var water_para := GlobalData.magic_book.copy_spell("loop-shot")
var water_line := GlobalData.magic_book.copy_spell("linear")
var water_arc := GlobalData.magic_book.copy_spell("arc")
var water_shower := GlobalData.magic_book.copy_spell("line")
var water_shower_chain := GlobalData.magic_book.copy_spell("linear-flurry")
	
func setup(seedling: int, biome: World.Biome) -> void:
	vitals = Vitals.enemy(hp(18), mana(18), mana_regen(18), percep(1,4), atk(10), def(12), {Artifact.Element.WATER: res(8, 3)})
	
	var circle_path := Pathway.new().random_points_in_disc(fit(6,12), 0, 10, 0, 10)
	idle_path = PathStyle.new(seedling, position).follow_path(circle_path).align_y_to_ground()
	attack_direct_path = PathStyle.new(seedling, position).towards_player(fit(2,8), 4, 6).player_vision_is_body_rotation(0, 20, 2, 3).align_y_to_ground().look_at_player_xz()
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	water_para.configure({"H":"4", "s":atks(3,6), "CC": "C", "spread":"pi/2"}, Spell.Element.WATER, 5, power(12), radius(4), fiti(1, 7), 50, 100, 50)
	water_line.configure({"s":atks(2,8), "d":"2"}, Spell.Element.WATER, 5, power(8), radius(3), 1, 50, 100, 50)
	water_arc.configure({"s":atks(2,10), "d":"Br", "R":"pi/4"}, Spell.Element.WATER, 5, power(9), radius(3), fiti(3, 15), 50, 100, 50)
	water_shower.configure({"sx":"u*Br","sy":"v*Br","sz":"w*Br","ex":"u*C","ey":"C*v","ez":"C*w"}, Spell.Element.WATER, 5.0, power(5), radius(2), 1, 60.0, 80.0, 0.0, water_shower_chain)
	water_shower_chain.configure({"s":fits(2,6), "d": "C", "dx":"0", "dy":"-1", "dz":"0", "oy": "u*d*10", "r": fits(4,10)}, Spell.Element.WATER, 20.0, power(6), radius(2), fiti(5, 20), 30.0, 50.0, 60.0)
	
	default_pattern = AttackPatterns.new(
		[
			AttackPatterns.new(
				[
					water_para,
					water_line,
					water_arc
				],
				AttackPatterns.choose_from_distribution(fit(4,1), [ 4, 10, 1 ], 9)
			),
			AttackPatterns.new(
				[
					water_line,
					water_shower,
					water_arc
				],
				AttackPatterns.choose_in_sequence(fitas(0.25, [ 2, 4, 10 ]))
			)
		],
		AttackPatterns.choose_from_distribution(3.5, [ 10, 3 ], -1)
	)
	
	animation_map["attack"] = "Weapon"
	kind = World.Enemy.FISHMAN
	super.setup(seedling, biome)
	

func update_behaviour() -> void:
	super.update_behaviour()
	if is_idle:
		set_path_and_attack(idle_path, none_pattern)
	else:
		set_path_and_attack(attack_direct_path, default_pattern)

func drop_artifact() -> Artifact:
	#var t := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	#var r := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	#var b := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	#var l := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	
	var t := Artifact.Option.make_random(1.0, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.CRIT_RATE: 0.5, Artifact.Element.CRIT_DMG: 0.2}, Vector2i(2, 5))
	var r := Artifact.Option.make_random(1.0, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.CRIT_RATE: 0.5, Artifact.Element.CRIT_DMG: 0.2}, Vector2i(2, 5))
	var b := Artifact.Option.make_random(1.0, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.CRIT_RATE: 0.5, Artifact.Element.CRIT_DMG: 0.2}, Vector2i(2, 5))
	var l := Artifact.Option.make_random(1.0, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.CRIT_RATE: 0.5, Artifact.Element.CRIT_DMG: 0.2}, Vector2i(2, 5))
	
	return Artifact.new(player.name_generator.chinese_names.generate(8, 1), t, r, b, l)

func drop_coins() -> Array[int]:
	return [1, 5, 10, 5, 5, 10, 1, 1, 1, 1]
