class_name Mushroom
extends Enemy

var none_pattern: AttackPatterns
var basic_pattern: AttackPatterns

var idle_path: PathStyle

var water_para1 := GlobalData.magic_book.copy_spell("loop-shot")
var water_para2 := GlobalData.magic_book.copy_spell("loop-shot")
var water_para3 := GlobalData.magic_book.copy_spell("loop-shot")
var water_line1 := GlobalData.magic_book.copy_spell("linear")
var water_line2 := GlobalData.magic_book.copy_spell("linear")
var water_line3 := GlobalData.magic_book.copy_spell("linear")
var water_down1 := GlobalData.magic_book.copy_spell("top-down")
var water_down2 := GlobalData.magic_book.copy_spell("top-down")
var water_down3 := GlobalData.magic_book.copy_spell("top-down")
var water_shower1 := GlobalData.magic_book.copy_spell("linear")
var water_shower1_chain := GlobalData.magic_book.copy_spell("linear-flurry")

	
func setup(seedling: int, biome: World.Biome) -> void:
	vitals = Vitals.enemy(hp(10), mana(10), mana_regen(5), percep(1,4), atk(5), def(4), {Artifact.Element.WATER: res(10, 0)})
	
	idle_path = PathStyle.still_path().align_y_to_ground()
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	water_para1.configure({"H":"5"}, Spell.Element.WATER, fit(8, 2), power(15), radius(4), 1, 50, 100, 25)
	water_para2.configure({"H":"7.5"}, Spell.Element.WATER, fit(6, 2), power(14), radius(3), 1, 50, 100, 50)
	water_para3.configure({"H":"10"}, Spell.Element.WATER, fit(4, 2), power(13), radius(2), 1, 50, 100, 75)
	water_line1.configure({"s":atks(2,12), "d":"Br*2"}, Spell.Element.WATER, fit(2, 8), power(10), radius(3), 1, 10, 200, 50)
	water_line2.configure({"s":atks(3,14), "d":"Br*2"}, Spell.Element.WATER, fit(2, 8), power(10), radius(4), 1, 10, 200, 50)
	water_line3.configure({"s":atks(4,16), "d":"Br*2"}, Spell.Element.WATER, fit(2, 8), power(10), radius(5), 1, 10, 200, 50)
	water_down1.configure({"H": "10"}, Spell.Element.WATER, fit(10, 5), power(8), radius(5), 1, 75, 25, 55)
	water_down2.configure({"H": "20"}, Spell.Element.WATER, fit(8, 4), power(10), radius(4), 1, 75, 50, 65)
	water_down3.configure({"H": "30"}, Spell.Element.WATER, fit(6, 3), power(12), radius(3), 1, 75, 75, 75)
	water_shower1.configure({"s":fits(3,8), "d":"Br*2", "rv": "rv+pi/8"}, Spell.Element.WATER, 5.0, power(5), radius(2), 1, 60.0, 80.0, 0.0, water_shower1_chain)
	water_shower1_chain.configure({"s":fits(2,6), "d": "C", "dx":"0", "dy":"-1", "dz":"0", "oy": "u*d*10", "r": "fl * 6 + 4"}, Spell.Element.WATER, 20.0, power(6), radius(2), fiti(5, 20), 30.0, 50.0, 60.0)
	
	spell_drop_probs = {
		water_para1: spell_drop(4),
		water_para2: spell_drop(5),
		water_para3: spell_drop(6),
		water_line1: spell_drop(1),
		water_line2: spell_drop(2),
		water_line3: spell_drop(3),
		water_down1: spell_drop(6),
		water_down2: spell_drop(7),
		water_down3: spell_drop(8),
		water_shower1: spell_drop(12),
	}
	
	basic_pattern = AttackPatterns.new(
		[
			water_line1,
			water_line2,
			water_line3,
			water_para1,
			water_para2,
			water_para3,
			water_down1,
			water_down2,
			water_down3,
		],
		AttackPatterns.choose_from_distribution(fit(6,1.5), [ 20, 18, 16,  14, 12, 10,  8, 6, 4 ], -1)
	)
	
	artifact_drop_probs = {
		"N": {
			"is_effect": 0.5,
			"event": { Artifact.Event.RECEIVE: 2 },
			"effect": { Artifact.Effect.RESISTANCE_FLAT: 10, Artifact.Effect.BOOST_PERCENTAGE: 5 },
			"ev_element": { Artifact.Element.WATER: 10 },
			"ef_element": { Artifact.Element.WATER: 10, Artifact.Element.MANA: 10, Artifact.Element.MANA_BUMP: 5, },
			"pattern": { Artifact.Pattern.TRIANGLE: 2 },
			"tier": artier(12),
		},
		"WSE": {
			"is_effect": 0.8,
			"event": { Artifact.Event.DEAL: 2 },
			"effect": { Artifact.Effect.RESISTANCE_PERCENTAGE: 10, Artifact.Effect.BOOST_FLAT: 15 },
			"ev_element": { Artifact.Element.WATER: 10, Artifact.Element.ROCK: 10 },
			"ef_element": { Artifact.Element.WATER: 10, Artifact.Element.ROCK: 10, Artifact.Element.HEALTH: 10, Artifact.Element.HEALTH_BUMP: 10 },
			"pattern": { Artifact.Pattern.CIRCLE: 2, Artifact.Pattern.SQUARE: 4 },
			"tier": artier(14),
		}
	}
	
	animation_map["attack"] = "Bite_Front"
	kind = World.Enemy.MUSHROOM
	super.setup(seedling, biome)


func update_behaviour() -> void:
	super.update_behaviour()
	if is_idle:
		set_path_and_attack(idle_path, none_pattern)
	else:
		set_path_and_attack(idle_path, basic_pattern)
