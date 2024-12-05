class_name Birdman
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

var air_mine := GlobalData.magic_book.copy_spell("bomb-disc-scatter")
	
func setup(seedling: int, biome: World.Biome) -> void:
	vitals = Vitals.enemy(hp(17), mana(16), mana_regen(10), percep(4,6), atk(17), def(8), {Artifact.Element.AIR: res(5, 2)})
	
	var idle_pathway := Pathway.new() \
		.move_to(Vector3(0, -4, 0)) \
		.line_to(Vector3(0, 20, 0), runs(16), Easing.out_quart) \
		.line_to(Vector3(0, -4, 0), runs(18), Easing.out_quart)
	idle_path = PathStyle.new(seedling, position).follow_path(idle_pathway).align_y_to_ground_and_air()
	
	var attack_pathway := Pathway.new() \
		.move_to(Vector3(10, 0, 0)) \
		.line_to(Vector3(10, fit(15,450), 0), runs(20), Easing.out_quart) \
		.wait(fit(10,60)) \
		.line_to(Vector3(10, 0, 0), runs(12), Easing.out_quart) \
		.wait(fit(4,8))
	attack_path = PathStyle.new().follow_path(attack_pathway)\
		.align_y_to_ground_and_air()\
		.player_vision_is_body_rotation(0, 0, 10.0)\
		.look_at_player_xz()
	
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	air_mine.configure({"d":"1", "Rmin":"4", "Rmax":"8", "arc":"2*pi", "S":"0", "s":"0"}, Spell.Element.AIR, fit(5,15), power(5), radius(3), fiti(5,25), 5, 300, fit(25, 75))
	air_mine.y = air_mine.y + " + t*0.0001"
	air_mine.y_expr = Expr.new(air_mine.y)
	
	air_small_fast.configure({"s":atks(5,15), "d":"Br*2+r"}, Spell.Element.AIR, 5, power(14), radius(1), 1, 25, 100, 50)
	air_med_fast.configure({"s":atks(5,15), "d":"Br*2+r"}, Spell.Element.AIR, 5, power(14), radius(2), 1, 25, 100, 50)
	air_large_fast.configure({"s":atks(5,15), "d":"Br*2+r"}, Spell.Element.AIR, 5, power(14), radius(5), 1, 25, 100, 50)
	air_small_med.configure({"s":atks(3,10), "d":"Br*2+r"}, Spell.Element.AIR, 5, power(17), radius(1), 1, 25, 100, 50)
	air_med_med.configure({"s":atks(3,10), "d":"Br*2+r"}, Spell.Element.AIR, 5, power(17), radius(2), 1, 25, 100, 50)
	air_large_med.configure({"s":atks(3,10), "d":"Br*2+r"}, Spell.Element.AIR, 5, power(17), radius(5), 1, 25, 100, 50)
	air_small_slow.configure({"s":atks(1,5), "d":"Br*2+r"}, Spell.Element.AIR, 5, power(20), radius(1), 1, 25, 100, 50)
	air_med_slow.configure({"s":atks(1,5), "d":"Br*2+r"}, Spell.Element.AIR, 5, power(20), radius(2), 1, 25, 100, 50)
	air_large_slow.configure({"s":atks(1,5), "d":"Br*2+r"}, Spell.Element.AIR, 5, power(20), radius(5), 1, 25, 100, 50)
	
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
		AttackPatterns.choose_from_distribution(fit(10, 2), [ 5, 5, 7 ], -1)
	)
	
	attack_pattern2 = AttackPatterns.new(
		[
			air_small_fast,
			air_small_med,
			air_small_slow,
			air_med_fast,
			air_med_med,
			air_med_slow,
			air_mine,
		],
		AttackPatterns.choose_from_distribution(fit(7, 2), [ 8, 8, 12, 20, 20, 28, 1 ], -1)
	)
	
	attack_pattern3 = AttackPatterns.new(
		[
			AttackPatterns.new(
				[air_small_slow, air_small_fast, air_mine],
				AttackPatterns.choose_in_sequence(fitas(0.75, [ 2, 1, 1 ]), 1)
			),
			AttackPatterns.new(
				[air_med_slow, air_med_fast, air_mine],
				AttackPatterns.choose_in_sequence(fitas(0.5, [ 3, 3, 1 ]), 1)
			),
			AttackPatterns.new(
				[air_large_slow, air_large_fast, air_mine],
				AttackPatterns.choose_in_sequence(fitas(0.25, [ 5, 5, 1 ]), 1)
			),
		],
		AttackPatterns.choose_from_distribution(1, [ 2, 3, 5 ], -1)
	)
	
	artifact_drop_probs = {
		"NS": {
			"effect": { Artifact.Effect.BOOST_PERCENTAGE: 2, Artifact.Effect.BOOST_FLAT: 10 },
			"element": { Artifact.Element.AIR: 10, Artifact.Element.RUNNING_SPEED: 2 },
			"pattern": { Artifact.Pattern.TRIANGLE: 10, Artifact.Pattern.CIRCLE: 2 },
			"tier": artier(14),
		},
		"WE": {
			"effect": { Artifact.Effect.BOOST_PERCENTAGE: 10, Artifact.Effect.BOOST_FLAT: 2 },
			"element": { Artifact.Element.AIR: 10 },
			"pattern": { Artifact.Pattern.TRIANGLE: 2, Artifact.Pattern.CIRCLE: 10 },
			"tier": artier(14),
		}
	}
	
	animation_map["attack"] = "Weapon"
	kind = World.Enemy.BIRDMAN
	super.setup(seedling, biome)


func update_behaviour() -> void:
	super.update_behaviour()
	if is_idle:
		set_path_and_attack(idle_path, none_pattern)
	elif vitals.health.percentage() > 0.5:
		set_path_and_attack(attack_path, attack_pattern1)
	elif vitals.health.percentage() > 0.25:
		set_path_and_attack(attack_path, attack_pattern2)
	else:
		set_path_and_attack(attack_path, attack_pattern3)
