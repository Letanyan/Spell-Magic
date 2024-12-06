class_name SnotBlob
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
	vitals = Vitals.enemy(hp(15), mana(5), mana_regen(10), percep(1,3), atk(10), def(10), {Artifact.Element.FIRE: res(-10, 0), Artifact.Element.WATER: res(10, 0)})
	
	var circle_path := Pathway.new().random_points_in_disc(1, 0, 2, 0, 3)
	idle_path = PathStyle.new(seedling, position).follow_path(circle_path).align_y_to_ground()
	
	attack_path = PathStyle.new(seedling, position).towards_player(runs(4), 2, 3).align_y_to_ground().look_at_player_xz()
	
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	water_spout1.configure({
		"d":"Br*2", "s":"0", "R":"1+t/T*"+fits(3,9), "off":"vec(0,0,0)", "dir":"vec(1,0,0)", "a":"n/N*2*pi", "c": "vec(0,0,0)"
	}, Spell.Element.WATER, fit(8,16), power(10), radius(3), fiti(3, 15), 33, 99, ea(10))
	water_spout1.follow = true
	water_spout2.configure({
		"d":"Br*2", "s":"0", "R":"1+t/T*"+fits(3,9), "off":"vec(0,0,0)", "dir":"vec(1,0,0)", "a":"n/N*2*pi", "c": "vec(0,1,0)"
	}, Spell.Element.WATER, fit(8,16), power(12), radius(3), fiti(3, 15), 66, 66, ea(12), water_spout1)
	water_spout2.follow = true
	water_spout2.chain_cast_kind = Spell.ChainCastKind.START
	water_spout3.configure({
		"d":"Br*2", "s":"0", "R":"1+t/T*"+fits(3,9), "off":"vec(0,0,0)", "dir":"vec(1,0,0)", "a":"n/N*2*pi", "c": "vec(0,2,0)"
	}, Spell.Element.WATER, fit(8,16), power(14), radius(3), fiti(3, 15), 99, 33, ea(14), water_spout2)
	water_spout3.follow = true
	water_spout3.chain_cast_kind = Spell.ChainCastKind.START
	
	water_down1.configure({
		"d": "8", "s":atks(4,10), "R":fits(6,12), "off":"vec(0,1,0)", "dir":"vec(0,-1,0)", "a":"n/N*2*pi", "c":"vec(0,0,0)"
	}, Spell.Element.WATER, fit(4,8), power(10), radius(3), fiti(3,15), 40, 80, ea(11))
	water_down1.follow = true
	water_down2.configure({
		"d": "8", "s":atks(4,10), "R":fits(5,10), "off":"vec(0,1,0)", "dir":"vec(0,-1,0)", "a":"n/N*2*pi", "c":"vec(0,0,0)"
	}, Spell.Element.WATER, fit(4,8), power(12), radius(3), fiti(3,12), 60, 100, ea(13), water_down1)
	water_down2.follow = true
	water_down2.chain_cast_kind = Spell.ChainCastKind.END
	water_down3.configure({
		"d": "8", "s":atks(4,10), "R":fits(4,8), "off":"vec(0,1,0)", "dir":"vec(0,-1,0)", "a":"n/N*2*pi", "c":"vec(0,0,0)"
	}, Spell.Element.WATER, fit(4,8), power(14), radius(3), fiti(3,9), 80, 120, ea(15), water_down2)
	water_down3.follow = true
	water_down3.chain_cast_kind = Spell.ChainCastKind.END
	
	water_spiral1.configure({
		"d": "Br*2", "s": "0", "R":fits(6,12), "off":"vec(0,0,0)", "dir":"vec(1,0,0)", "a":"n/N*2*pi+t/T*2*pi*"+atks(4,10), "c": "vec(0,0,0)" 
	}, Spell.Element.WATER, fit(6, 12), power(12), radius(4), fiti(3,15), 33, 99, ea(12))
	water_spiral1.follow = true
	water_spiral2.configure({
		"d": "Br*2", "s": "0", "R":fits(8,14), "off":"vec(0,0,0)", "dir":"vec(1,0,0)", "a":"n/N*2*pi+t/T*2*pi*"+atks(4,10), "c": "vec(0,0,0)" 
	}, Spell.Element.WATER, fit(6, 12), power(12), radius(4), fiti(3,10), 66, 122, ea(14), water_spiral1)
	water_spiral2.follow = true
	water_spiral2.chain_cast_kind = Spell.ChainCastKind.START
	water_spiral3.configure({
		"d": "Br*2", "s": "0", "R":fits(10,16), "off":"vec(0,0,0)", "dir":"vec(1,0,0)", "a":"n/N*2*pi+t/T*2*pi*"+atks(4,10), "c": "vec(0,0,0)" 
	}, Spell.Element.WATER, fit(6, 12), power(12), radius(4), fiti(3,5), 99, 155, ea(16), water_spiral2)
	water_spiral3.follow = true
	water_spiral3.chain_cast_kind = Spell.ChainCastKind.START
	
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
		AttackPatterns.choose_from_distribution(fit(6,10), [ 12, 10, 8, 3, 2, 1 ], -1)
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
		AttackPatterns.choose_in_sequence(fita([6, 4, 6, 4, 6, 4], [10, 8, 10, 8, 10, 8]), -1)
	)
	
	artifact_drop_probs = {
		"NS": {
			"is_effect": 0.75,
			"event": { Artifact.Event.DEAL: 2 },
			"effect": { Artifact.Effect.RESISTANCE_FLAT: 10, Artifact.Effect.BOOST_PERCENTAGE: 5 },
			"ev_element": { Artifact.Element.WATER: 10 },
			"ef_element": { Artifact.Element.WATER: 10, Artifact.Element.MANA: 10, Artifact.Element.MANA_BUMP: 5, },
			"pattern": { Artifact.Pattern.TRIANGLE: 2 },
			"tier": artier(8),
		},
		"WE": {
			"is_effect": 0.25,
			"event": { Artifact.Event.RECEIVE: 2 },
			"effect": { Artifact.Effect.BOOST_PERCENTAGE: 10, Artifact.Effect.BOOST_FLAT: 15 },
			"ev_element": { Artifact.Element.WATER: 10 },
			"ef_element": { Artifact.Element.WATER: 10, Artifact.Element.ROCK: 10, Artifact.Element.DEFENCE: 10, Artifact.Element.COUNT: 2 },
			"pattern": { Artifact.Pattern.CIRCLE: 2, Artifact.Pattern.SQUARE: 4 },
			"tier": artier(9),
		}
	}
	
	animation_map["attack"] = "Bite_Front"
	kind = World.Enemy.SNOT_BLOB
	super.setup(seedling, biome)


func update_behaviour() -> void:
	super.update_behaviour()
	if is_idle:
		set_path_and_attack(idle_path, none_pattern)
	elif vitals.health.percentage() > 0.5:
		set_path_and_attack(attack_path, sequence_pattern)
	else:
		set_path_and_attack(attack_path, random_pattern)
