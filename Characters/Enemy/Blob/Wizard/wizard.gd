class_name Wizard
extends Enemy

var none_pattern: AttackPatterns
var random_pattern1: AttackPatterns
var random_pattern2: AttackPatterns

var idle_path: PathStyle
var attack_path: PathStyle

var fire1 := GlobalData.magic_book.copy_spell("linear")
var water1 := GlobalData.magic_book.copy_spell("linear")
var elec1 := GlobalData.magic_book.copy_spell("linear")
var ice1 := GlobalData.magic_book.copy_spell("linear")

var fire_circle := GlobalData.magic_book.copy_spell("circle")
var fire_circle_line := GlobalData.magic_book.copy_spell("line")
var water_circle := GlobalData.magic_book.copy_spell("circle")
var water_circle_line := GlobalData.magic_book.copy_spell("line")
var elec_circle := GlobalData.magic_book.copy_spell("circle")
var elec_circle_line := GlobalData.magic_book.copy_spell("line")
var ice_circle := GlobalData.magic_book.copy_spell("circle")
var ice_circle_line := GlobalData.magic_book.copy_spell("line")
	
func setup(seedling: int, biome: World.Biome) -> void:
	vitals = Vitals.enemy(hp(5), mana(20), mana_regen(10), percep(1,4), atk(20), def(2), {Artifact.Element.FIRE: res(-10, 0), Artifact.Element.WATER: res(10, 0)})
	class_level = 19
	
	var circle_path := Pathway.new().random_points_in_disc(1, 0, 2, 0, 3)
	idle_path = PathStyle.new(seedling, position).follow_path(circle_path).align_y_to_ground()
	
	attack_path = PathStyle.new(seedling, position).towards_player(fit(1,10), 1, 2).align_y_to_ground().look_at_player()
	
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	fire1.configure({"s": atks(1,20), "d": "2"}, Spell.Element.FIRE, 10.0, power(18), radius(5), 1, 50, 150, 75)
	water1.configure({"s": atks(1,20), "d": "2"}, Spell.Element.WATER, 8.0, power(18), radius(5), 1, 50, 150, 75)
	elec1.configure({"s": atks(1,20), "d": "2"}, Spell.Element.ELECTRIC, 6.0, power(18), radius(5), 1, 50, 150, 75)
	ice1.configure({"s": atks(1,20), "d": "2"}, Spell.Element.ICE, 6.0, power(18), radius(5), 1, 50, 150, 75)
	
	fire_circle.configure({"cx":"C*u","cy":"C*v","cz":"C*w","ux":"0","uy":"1","uz":"0","rots":fits(2,10),"R":fits(3,10)}, Spell.Element.FIRE, fit(4,15), power(1), radius(2), 1, 5, 100, 0, fire_circle_line)
	fire_circle_line.configure({"sx":"0","sy":"0","sz":"0","ex":"C*u","ey":"C*v","ez":"C*w"}, Spell.Element.FIRE, fit(5,2), power(18), radius(7), fiti(3,15), 70, 150, 75)
	fire_circle_line.set_delay("n*"+fits(2,0.5))
	
	water_circle.configure({"cx":"C*u","cy":"C*v","cz":"C*w","ux":"0","uy":"1","uz":"0","rots":fits(2,10),"R":fits(3,10)}, Spell.Element.WATER, fit(4,15), power(1), radius(2), 1, 5, 100, 0, fire_circle_line)
	water_circle_line.configure({"sx":"0","sy":"0","sz":"0","ex":"C*u","ey":"C*v","ez":"C*w"}, Spell.Element.WATER, fit(5,2), power(18), radius(7), fiti(3,15), 70, 150, 75)
	water_circle_line.set_delay("n*"+fits(2,0.5))
	
	elec_circle.configure({"cx":"C*u","cy":"C*v","cz":"C*w","ux":"0","uy":"1","uz":"0","rots":fits(2,10),"R":fits(3,10)}, Spell.Element.ELECTRIC, fit(4,15), power(1), radius(2), 1, 5, 100, 0, fire_circle_line)
	elec_circle_line.configure({"sx":"0","sy":"0","sz":"0","ex":"C*u","ey":"C*v","ez":"C*w"}, Spell.Element.ELECTRIC, fit(5,2), power(18), radius(7), fiti(3,15), 70, 150, 75)
	elec_circle_line.set_delay("n*"+fits(2,0.5))
	
	ice_circle.configure({"cx":"C*u","cy":"C*v","cz":"C*w","ux":"0","uy":"1","uz":"0","rots":fits(2,10),"R":fits(3,10)}, Spell.Element.ICE, fit(4,15), power(1), radius(2), 1, 5, 100, 0, fire_circle_line)
	ice_circle_line.configure({"sx":"0","sy":"0","sz":"0","ex":"C*u","ey":"C*v","ez":"C*w"}, Spell.Element.ICE, fit(5,2), power(18), radius(7), fiti(3,15), 70, 150, 75)
	ice_circle_line.set_delay("n*"+fits(2,0.5))
	
	spell_drop_probs = {
		fire_circle: spell_drop(6),
		fire_circle_line: spell_drop(3),
		water_circle: spell_drop(6),
		water_circle_line: spell_drop(3),
		elec_circle: spell_drop(6),
		elec_circle_line: spell_drop(3),
		ice_circle: spell_drop(6),
		ice_circle_line: spell_drop(3),
		fire1: spell_drop(2),
		water1: spell_drop(2),
		elec1: spell_drop(2),
		ice1: spell_drop(2),
	}
	
	random_pattern1 = AttackPatterns.new(
		[
			fire1,
			water1,
			elec1,
			ice1,
		],
		AttackPatterns.choose_from_distribution(fit(5, 0.5), [ 5, 5, 5, 5 ], -1)
	)
	
	random_pattern2 = AttackPatterns.new(
		[
			AttackPatterns.new(
				[
					fire_circle,
					water_circle,
					elec_circle,
					ice_circle,
				],
				AttackPatterns.choose_from_distribution(fit(5, 0.5), [ 5, 5, 5, 5 ], 1)
			),
			AttackPatterns.new(
				[
					fire1,
					water1,
					elec1,
					ice1,
				],
				AttackPatterns.choose_from_distribution(fit(5, 0.5), [ 5, 5, 5, 5 ], 5)
			)
		],
		AttackPatterns.choose_in_sequence(fitas(0.1, [3, 25]))
	)
	
	artifact_drop_probs = {
		"all": {
			"is_effect": 0.5,
			"event": { Artifact.Event.DEAL: 5, Artifact.Event.RECEIVE: 5 },
			"effect": { Artifact.Effect.RESISTANCE_FLAT: 10, Artifact.Effect.RESISTANCE_PERCENTAGE: 20, Artifact.Effect.BOOST_PERCENTAGE: 20, Artifact.Effect.BOOST_FLAT: 10 },
			"ev_element": { Artifact.Element.WATER: 10, Artifact.Element.ICE: 10, Artifact.Element.FIRE: 10, Artifact.Element.ELECTRIC: 10 },
			"ef_element": { Artifact.Element.WATER: 10, Artifact.Element.ICE: 10, Artifact.Element.FIRE: 10, Artifact.Element.ELECTRIC: 10 },
			"pattern": { Artifact.Pattern.CIRCLE: 4 },
			"tier": artier(15),
		},
	}
	
	animation_map["attack"] = "Bite_Front"
	kind = World.Enemy.WIZARD
	super.setup(seedling, biome)


func update_behaviour() -> void:
	super.update_behaviour()
	if is_idle:
		set_path_and_attack(idle_path, none_pattern)
	elif vitals.health.percentage() > 0.7:
		set_path_and_attack(attack_path, random_pattern1)
	else:
		set_path_and_attack(attack_path, random_pattern2)
