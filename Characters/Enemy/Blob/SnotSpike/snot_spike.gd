class_name SnotSpike
extends Enemy

var none_pattern: AttackPatterns
var random_pattern: AttackPatterns
var sequence_pattern: AttackPatterns

var idle_path: PathStyle
var attack_path: PathStyle

var water_spout1 := GlobalData.magic_book.copy_spell("plane-slice")
var water_spout2 := GlobalData.magic_book.copy_spell("plane-slice")
var water_spout3 := GlobalData.magic_book.copy_spell("plane-slice")
var water_down1 := GlobalData.magic_book.copy_spell("plane-linear")
var water_down2 := GlobalData.magic_book.copy_spell("plane-linear")
var water_down3 := GlobalData.magic_book.copy_spell("plane-linear")
var water_spiral1 := GlobalData.magic_book.copy_spell("plane-slice")
var water_spiral2 := GlobalData.magic_book.copy_spell("plane-slice")
var water_spiral3 := GlobalData.magic_book.copy_spell("plane-slice")
	
func setup(seedling: int, biome: World.Biome) -> void:
	vitals = Vitals.enemy(hp(18), mana(5), mana_regen(10), percep(1,4), atk(15), def(10), {Artifact.Element.WATER: res(10, 0)})
	class_level = 15
	
	var circle_path := Pathway.new().random_points_in_disc(1, 0, 2, 0, 3)
	idle_path = PathStyle.new(seedling, position).follow_path(circle_path).align_y_to_ground()
	
	attack_path = PathStyle.new(seedling, position).towards_player(fit(2,10), 1, 2).align_y_to_ground().look_at_player()
	
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	water_spout1.configure({
		"d":"Br*2", "s":"0", "R":"1+t/T*"+fits(6,12), "off":Expr.vec0, "dir":Expr.vec_right, "a":Expr.arc_frac, "c": Expr.vec0
	}, Spell.Element.WATER, fit(4,8), power(10), radius(5), fiti(5, 20), 33, 99, ea(12))
	water_spout1.follow = true
	water_spout2.configure({
		"d":"Br*2", "s":"0", "R":"1+t/T*"+fits(6,12), "off":Expr.vec0, "dir":Expr.vec_right, "a":Expr.arc_frac, "c": Expr.vec_up
	}, Spell.Element.WATER, fit(4,8), power(12), radius(5), fiti(5, 20), 66, 66, ea(15))
	water_spout2.follow = true
	water_spout3.configure({
		"d":"Br*2", "s":"0", "R":"1+t/T*"+fits(6,12), "off":Expr.vec0, "dir":Expr.vec_right, "a":Expr.arc_frac, "c": "vec(0,2,0)"
	}, Spell.Element.WATER, fit(4,8), power(14), radius(5), fiti(5, 20), 99, 33, ea(18))
	water_spout3.follow = true
	
	water_down1.configure({
		"d": "8", "s":atks(6,12), "R":fits(8,14), "off":Expr.vec_up, "dir":Expr.vec_down, "a":"0", "c":Expr.vec0
	}, Spell.Element.WATER, fit(4,8), power(10), radius(6), fiti(3,15), 40, 80, ea(13))
	water_down1.follow = true
	water_down2.configure({
		"d": "8", "s":atks(7,13), "R":fits(6,12), "off":Expr.vec_up, "dir":Expr.vec_down, "a":"0", "c":Expr.vec0
	}, Spell.Element.WATER, fit(4,8), power(12), radius(5), fiti(3,12), 60, 100, ea(16))
	water_down2.follow = true
	water_down3.configure({
		"d": "8", "s":atks(8,14), "R":fits(4,10), "off":Expr.vec_up, "dir":Expr.vec_down, "a":"0", "c":Expr.vec0
	}, Spell.Element.WATER, fit(4,8), power(14), radius(4), fiti(3,9), 80, 120, ea(19))
	water_down3.follow = true
	
	water_spiral1.configure({
		"d": "Br*2", "s": "0", "R":fits(6,12), "off":Expr.vec0, "dir":Expr.vec_right, "a":"n/N*tau+t/T*tau*"+atks(6,12), "c": Expr.vec0 
	}, Spell.Element.WATER, fit(5, 10), power(12), radius(5), fiti(3,15), 33, 99, ea(14))
	water_spiral1.follow = true
	water_spiral2.configure({
		"d": "Br*2", "s": "0", "R":fits(6,12), "off":Expr.vec0, "dir":Expr.vec_right, "a":"n/N*tau+t/T*tau*"+atks(7,14), "c": Expr.vec0 
	}, Spell.Element.WATER, fit(5, 10), power(15), radius(4), fiti(3,15), 66, 122, ea(17))
	water_spiral2.follow = true
	water_spiral3.configure({
		"d": "Br*2", "s": "0", "R":fits(6,12), "off":Expr.vec0, "dir":Expr.vec_right, "a":"n/N*tau+t/T*tau*"+atks(8,16), "c": Expr.vec0 
	}, Spell.Element.WATER, fit(5, 10), power(17), radius(3), fiti(3,15), 99, 155, ea(20))
	water_spiral3.follow = true
	
	spell_drop_probs = {
		water_spout1: spell_drop(1),
		water_spout2: spell_drop(2),
		water_spout3: spell_drop(3),
		water_down1: spell_drop(5),
		water_down2: spell_drop(6),
		water_down3: spell_drop(7),
		water_spiral1: spell_drop(10),
		water_spiral2: spell_drop(11),
		water_spiral3: spell_drop(12),
	}
	
	
	random_pattern = AttackPatterns.new(
		[
			water_spout1,
			water_spout2,
			water_spout3,
			water_down1,
			water_down2,
			water_down3,
		],
		AttackPatterns.choose_from_distribution(fit(6,10), [ 12, 10, 8, 6, 4, 2 ], -1)
	)
	
	sequence_pattern = AttackPatterns.new(
		[
			water_spiral1,
			water_down1,
			water_spiral2,
			water_down2,
			water_spiral3,
			water_down3,
		],
		AttackPatterns.choose_in_sequence(fita([4, 5, 4, 5, 4, 5], [8, 10, 8, 10, 8, 10]), -1)
	)
	
	artifact_drop_probs = {
		"NE": {
			"is_effect": 0.4,
			"event": { Artifact.Event.DEAL: 2, Artifact.Event.RECEIVE: 5 },
			"effect": { Artifact.Effect.RESISTANCE_FLAT: 20, Artifact.Effect.RESISTANCE_PERCENTAGE: 5 },
			"ev_element": { Artifact.Element.WATER: 10 },
			"ef_element": { Artifact.Element.WATER: 10, Artifact.Element.MANA: 10, Artifact.Element.MANA_BUMP: 5, },
			"pattern": { Artifact.Pattern.SQUARE: 4, Artifact.Pattern.CIRCLE: 2 },
			"tier": artier(11),
		},
		"SW": {
			"is_effect": 0.6,
			"event": { Artifact.Event.RECEIVE: 2, Artifact.Event.DEAL: 5 },
			"effect": { Artifact.Effect.BOOST_PERCENTAGE: 20, Artifact.Effect.BOOST_FLAT: 5 },
			"ev_element": { Artifact.Element.WATER: 10 },
			"ef_element": { Artifact.Element.WATER: 10, Artifact.Element.ROCK: 10, Artifact.Element.DEFENCE: 10, Artifact.Element.COUNT: 10, Artifact.Element.CRIT_RATE: 10 },
			"pattern": { Artifact.Pattern.CIRCLE: 2, Artifact.Pattern.TRIANGLE: 4 },
			"tier": artier(12),
		}
	}
	
	animation_map["attack"] = "Bite_Front"
	kind = World.Enemy.SNOT_SPIKE
	super.setup(seedling, biome)


func update_behaviour() -> void:
	super.update_behaviour()
	if is_idle:
		set_path_and_attack(idle_path, none_pattern)
	elif vitals.health.percentage() > 0.5:
		set_path_and_attack(attack_path, sequence_pattern)
	else:
		set_path_and_attack(attack_path, random_pattern)
