class_name Bougeon
extends Enemy

var none_pattern: AttackPatterns
var attack_pattern1: AttackPatterns
var attack_pattern2: AttackPatterns
var attack_pattern3: AttackPatterns

var idle_path: PathStyle
var attack_path: PathStyle

var air_small_fast := GlobalData.magic_book.copy_spell("linear")
var air_med_med := GlobalData.magic_book.copy_spell("linear")
var air_large_slow := GlobalData.magic_book.copy_spell("linear")
var air_ring := GlobalData.magic_book.copy_spell("plane-slice")
var air_flurry := GlobalData.magic_book.copy_spell("plane-linear")
	
func setup(seedling: int, biome: World.Biome) -> void:
	vitals = Vitals.enemy(hp(13), mana(12), mana_regen(6), percep(3,7), atk(10), def(4), {Artifact.Element.AIR: res(5, 2)})
	class_level = 12
	
	var idle_pathway := Pathway.new().random_points_in_disc(runs(12), 3, 8, 0, 5, Easing.in_out_quad)
	idle_path = PathStyle.new(seedling, position).follow_path(idle_pathway).align_y_to_ground_and_air()
	
	var attack_pathway := Pathway.new()
	var starting_point := Rand.point_in_disc(fit(3, 6), fit(4, 10), 0)
	attack_pathway.move_to(starting_point)
	var last_point := starting_point
	for i in fiti(3, 4):
		var np := Rand.point_in_disc(fit(3, 6), fit(4, 10), 0)
		var mid := last_point.lerp(np, 0.5)
		mid.y = fit(0, 10)
		attack_pathway.line_to(mid, runs(13), Easing.rising)
		attack_pathway.line_to(np, runs(13), Easing.falling)
		last_point = np
	var mid := last_point.lerp(starting_point, 0.5)
	mid.y = fit(0, 10)
	attack_pathway.line_to(mid, runs(13), Easing.rising)
	attack_pathway.line_to(starting_point, runs(13), Easing.falling)
	
	attack_path = PathStyle.new().follow_path(attack_pathway)\
		.align_y_to_ground_and_air()\
		.origin_is_player()\
		.player_vision_is_camera(0, 0.0, 1.0, 2.0)\
		.look_at_player()\
		.initial_position_can_update_on_ground()
	
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	air_small_fast.configure({"s":atks(5,15), "d":"Br*2+r"}, Spell.Element.AIR, 5, power(4), radius(2), 1, 25, 100, ea(8))
	air_med_med.configure({"s":atks(3,10), "d":"Br*2+r"}, Spell.Element.AIR, 5, power(7), radius(3), 1, 25, 100, ea(10))
	air_large_slow.configure({"s":atks(1,5), "d":"Br*2+r"}, Spell.Element.AIR, 5, power(10), radius(4), 1, 25, 100, ea(15))
	air_flurry.configure({"s":atks(5,17), "d":"Br*2", "R":fits(1,5)+"*rn0+rn1", "off":"uvw", "dir":"uvw", "a":"rn0*2*pi"}, Spell.Element.AIR, fit(3,6), power(12), radius(7), fiti(2, 10), 40, 60, ea(12), null, "n*"+fits(3, 0.3))
	air_ring.configure({"s": atks(2,6), "d":"Br*2+"+fits(2,8), "R":fits(2,8), "off": "uvw", "dir":"uvw", "a":"(n/N*2*pi)+t"}, Spell.Element.AIR, fit(5,10), power(15), radius(5), fiti(4, 12), 30, 90, ea(14))
	
	spell_drop_probs = {
		air_small_fast: spell_drop(3),
		air_med_med: spell_drop(2),
		air_large_slow: spell_drop(1),
		air_flurry: spell_drop(8),
		air_ring: spell_drop(10),
	}
	
	attack_pattern1 = AttackPatterns.new(
		[
			air_small_fast,
			air_med_med,
			air_large_slow,
		],
		AttackPatterns.choose_from_distribution(fit(10, 3), [ 5, 5, 7 ], -1)
	)
	
	attack_pattern2 = AttackPatterns.new(
		[
			air_small_fast,
			air_med_med,
			air_large_slow,
			air_flurry,
			air_ring,
		],
		AttackPatterns.choose_from_distribution(fit(7, 2), [ 5, 5, 7, 2, 1 ], -1)
	)
	
	attack_pattern3 = AttackPatterns.new(
		[
			AttackPatterns.new(
				[air_flurry, air_large_slow, air_large_slow, air_flurry],
				AttackPatterns.choose_in_sequence(fitas(0.75, [ 2, 1, 0.5, 2 ]), 1)
			),
			AttackPatterns.new(
				[air_ring, air_med_med, air_med_med, air_ring, air_ring],
				AttackPatterns.choose_in_sequence(fitas(0.5, [ 3, 3, 2, 2, 1 ]), 1)
			),
			AttackPatterns.new(
				[air_flurry, air_small_fast, air_small_fast, air_small_fast, air_small_fast, air_small_fast],
				AttackPatterns.choose_in_sequence(fitas(0.25, [ 5, 5, 4, 3, 2, 1 ]), 1)
			),
		],
		AttackPatterns.choose_from_distribution(1, [ 2, 3, 5 ], -1)
	)
	
	artifact_drop_probs = {
		"NE": {
			"is_effect": 0.75,
			"event": { Artifact.Event.RECEIVE: 2, Artifact.Event.DEAL: 10 },
			"effect": { Artifact.Effect.RESISTANCE_PERCENTAGE: 10, Artifact.Effect.RESISTANCE_FLAT: 10 },
			"ev_element": { Artifact.Element.AIR: 10 },
			"ef_element": { Artifact.Element.AIR: 10, Artifact.Element.HEALTH_BUMP: 5 },
			"pattern": { Artifact.Pattern.SQUARE: 10, Artifact.Pattern.CIRCLE: 2 },
			"tier": artier(8),
		},
		"WS": {
			"is_effect": 0.5,
			"event": { Artifact.Event.RECEIVE: 10, Artifact.Event.DEAL: 2 },
			"effect": { Artifact.Effect.RESISTANCE_PERCENTAGE: 10, Artifact.Effect.RESISTANCE_FLAT: 10 },
			"ev_element": { Artifact.Element.AIR: 10, },
			"ef_element": { Artifact.Element.AIR: 10, Artifact.Element.HEALTH_BUMP: 5 },
			"pattern": { Artifact.Pattern.SQUARE: 2, Artifact.Pattern.CIRCLE: 10 },
			"tier": artier(8),
		}
	}
	
	animation_map["attack"] = "Bite_Front"
	kind = World.Enemy.BOUGEON
	super.setup(seedling, biome)
	

func update_behaviour() -> void:
	super.update_behaviour()
	if is_idle:
		set_path_and_attack(idle_path, none_pattern)
	elif vitals.health.percentage() > 0.5:
		set_path_and_attack(attack_path, attack_pattern1)
	elif vitals.health.percentage() > 0.25:
		set_path_and_attack(attack_path, attack_pattern1)
	else:
		set_path_and_attack(attack_path, attack_pattern3)
