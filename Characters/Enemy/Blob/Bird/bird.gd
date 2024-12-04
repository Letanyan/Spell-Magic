class_name Bird
extends Enemy

var none_pattern: AttackPatterns
var attack_pattern1: AttackPatterns
var attack_pattern2: AttackPatterns
var attack_pattern3: AttackPatterns

var idle_path: PathStyle
var attack_path: PathStyle

var air_small_fast := GlobalData.magic_book.copy_spell("linear")
var air_med_fast := GlobalData.magic_book.copy_spell("linear")
var air_large_fast := GlobalData.magic_book.copy_spell("linear")
var air_small_med := GlobalData.magic_book.copy_spell("linear")
var air_med_med := GlobalData.magic_book.copy_spell("linear")
var air_large_med := GlobalData.magic_book.copy_spell("linear")
var air_small_slow := GlobalData.magic_book.copy_spell("linear")
var air_med_slow := GlobalData.magic_book.copy_spell("linear")
var air_large_slow := GlobalData.magic_book.copy_spell("linear")
	
func setup(seedling: int, biome: World.Biome) -> void:
	vitals = Vitals.enemy(hp(13), mana(12), mana_regen(6), percep(3,7), atk(10), def(4), {Artifact.Element.AIR: res(5, 2)})
	
	var idle_pathway := Pathway.new() \
		.move_to(Vector3(0, 0, 0)) \
		.line_to(Vector3(0, 20, 0), runs(16), Easing.out_quart) \
		.line_to(Vector3(0, 0, 0), runs(14), Easing.out_quart)
	idle_path = PathStyle.new(seedling, position).follow_path(idle_pathway).align_y_to_ground_and_air()
	
	var attack_pathway := Pathway.new() \
		.move_to(Vector3(10, 0, 0)) \
		.line_to(Vector3(10 + 1, 0 * fit(10,20), 0), runs(10), Easing.out_quart) \
		.wait(10) \
		.line_to(Vector3(10, 0, 0), runs(15), Easing.out_quart) \
		.wait(4)
	attack_path = PathStyle.new().follow_path(attack_pathway)\
		.align_y_to_ground_and_air()\
		.origin_is_player()\
		.player_vision_is_camera(0, 10.0, 10.0, 20.0)\
		.look_at_player_xz()
	
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	air_small_fast.configure({"s":atks(5,15), "d":"Br*2+r"}, Spell.Element.AIR, 5, power(4), radius(2), 1, 25, 100, 50)
	air_med_fast.configure({"s":atks(5,15), "d":"Br*2+r"}, Spell.Element.AIR, 5, power(4), radius(3), 1, 25, 100, 50)
	air_large_fast.configure({"s":atks(5,15), "d":"Br*2+r"}, Spell.Element.AIR, 5, power(4), radius(4), 1, 25, 100, 50)
	air_small_med.configure({"s":atks(3,10), "d":"Br*2+r"}, Spell.Element.AIR, 5, power(7), radius(2), 1, 25, 100, 50)
	air_med_med.configure({"s":atks(3,10), "d":"Br*2+r"}, Spell.Element.AIR, 5, power(7), radius(3), 1, 25, 100, 50)
	air_large_med.configure({"s":atks(3,10), "d":"Br*2+r"}, Spell.Element.AIR, 5, power(7), radius(4), 1, 25, 100, 50)
	air_small_slow.configure({"s":atks(1,5), "d":"Br*2+r"}, Spell.Element.FIRE, 5, power(10), radius(2), 1, 25, 100, 50)
	air_med_slow.configure({"s":atks(1,5), "d":"Br*2+r"}, Spell.Element.WATER, 5, power(10), radius(3), 1, 25, 100, 50)
	air_large_slow.configure({"s":atks(1,5), "d":"Br*2+r"}, Spell.Element.ELECTRIC, 5, power(10), radius(4), 1, 25, 100, 50)
	
	spell_drop_probs = {
		air_small_slow: spell_drop(1),
		air_med_slow: spell_drop(2),
		air_large_slow: spell_drop(3),		
		air_small_med: spell_drop(4),
		air_med_med: spell_drop(5),
		air_large_med: spell_drop(6),
		air_small_fast: spell_drop(7),
		air_med_fast: spell_drop(8),
		air_large_fast: spell_drop(9),
	}
	
	attack_pattern1 = AttackPatterns.new(
		[
			air_small_fast,
			air_small_med,
			air_small_slow,
		],
		AttackPatterns.choose_from_distribution(fit(10, 3), [ 5, 5, 7 ], -1)
	)
	
	attack_pattern2 = AttackPatterns.new(
		[
			air_small_fast,
			air_small_med,
			air_small_slow,
			air_med_fast,
			air_med_med,
			air_med_slow,
		],
		AttackPatterns.choose_from_distribution(fit(7, 2), [ 2, 2, 3, 5, 5, 7 ], -1)
	)
	
	#attack_pattern3 = AttackPatterns.new(
		#[
			#AttackPatterns.new(
				#[air_small_slow, air_small_fast],
				#AttackPatterns.choose_in_sequence(fitas(0.75, [ 2, 1 ]), 1)
			#),
			#AttackPatterns.new(
				#[air_med_slow, air_med_fast],
				#AttackPatterns.choose_in_sequence(fitas(0.5, [ 3, 3]), 1)
			#),
			#AttackPatterns.new(
				#[air_large_slow, air_large_fast],
				#AttackPatterns.choose_in_sequence(fitas(0.25, [ 5, 5 ]), 1)
			#),
		#],
		#AttackPatterns.choose_from_distribution(1, [ 2, 3, 5 ], -1)
	#)
	attack_pattern3 = AttackPatterns.new(
		[
			AttackPatterns.new(
				[air_small_slow, air_med_slow],
				AttackPatterns.choose_in_sequence(fitas(0.75, [ 2, 2 ]), 1)
			),
			AttackPatterns.new(
				[air_med_slow, air_small_slow],
				AttackPatterns.choose_in_sequence(fitas(0.5, [ 3, 3 ]), 1)
			),
			AttackPatterns.new(
				[air_large_slow, air_small_slow],
				AttackPatterns.choose_in_sequence(fitas(0.25, [ 5, 5 ]), 1)
			),
		],
		AttackPatterns.choose_from_distribution(1, [ 2, 2, 2 ], -1)
	)
	
	animation_map["attack"] = "Bite_Front"
	kind = World.Enemy.BIRD
	super.setup(seedling, biome)
	

func update_behaviour() -> void:
	super.update_behaviour()
	if is_idle:
		set_path_and_attack(idle_path, none_pattern)
	elif vitals.health.percentage() > 0.5:
		set_path_and_attack(attack_path, attack_pattern3)
	elif vitals.health.percentage() > 0.25:
		set_path_and_attack(attack_path, attack_pattern2)
	else:
		set_path_and_attack(attack_path, attack_pattern3)


func drop_artifact() -> Artifact:
	var t := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	var r := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	var b := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	var l := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	var new_name := player.name_generator.cumbria_names.generate(8, 2)
	return Artifact.new(new_name, t, r, b, l)
