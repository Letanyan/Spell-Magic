class_name Ghostly
extends Enemy

var none_pattern: AttackPatterns
var random_pattern: AttackPatterns
var sequence_pattern: AttackPatterns

var idle_path: PathStyle
var attack_path: PathStyle

var ice1 := GlobalData.magic_book.copy_spell("linear")
var ice2 := GlobalData.magic_book.copy_spell("linear")
var ice3 := GlobalData.magic_book.copy_spell("linear")
var ice_arc1 := GlobalData.magic_book.copy_spell("arc")
var ice_arc2 := GlobalData.magic_book.copy_spell("arc")
var ice_arc3 := GlobalData.magic_book.copy_spell("arc")
var ice_scatter1 := GlobalData.magic_book.copy_spell("scatter-shot")
var ice_scatter2 := GlobalData.magic_book.copy_spell("scatter-shot")
var ice_scatter3 := GlobalData.magic_book.copy_spell("scatter-shot")
var ice_back1 := GlobalData.magic_book.copy_spell("line")
var ice_back2 := GlobalData.magic_book.copy_spell("line")
var ice_back3 := GlobalData.magic_book.copy_spell("line")
var electric1 := GlobalData.magic_book.copy_spell("linear")
var electric2 := GlobalData.magic_book.copy_spell("linear")
var electric3 := GlobalData.magic_book.copy_spell("linear")
var electric_arc1 := GlobalData.magic_book.copy_spell("arc")
var electric_arc2 := GlobalData.magic_book.copy_spell("arc")
var electric_arc3 := GlobalData.magic_book.copy_spell("arc")
var electric_scatter1 := GlobalData.magic_book.copy_spell("scatter-shot")
var electric_scatter2 := GlobalData.magic_book.copy_spell("scatter-shot")
var electric_scatter3 := GlobalData.magic_book.copy_spell("scatter-shot")
var electric_back1 := GlobalData.magic_book.copy_spell("line")
var electric_back2 := GlobalData.magic_book.copy_spell("line")
var electric_back3 := GlobalData.magic_book.copy_spell("line")
	
func setup(seedling: int, biome: World.Biome) -> void:
	vitals = Vitals.enemy(hp(3), mana(8), mana_regen(20), percep(4,6), atk(12), def(5), {Artifact.Element.ELECTRIC: res(5, 1), Artifact.Element.ICE: res(5, 1)})
	class_level = 17
	
	var sphere_path := Pathway.new().move_to(Vector3(0, 10, 0)).random_points_in_sphere(4, 0, 10, 7)
	idle_path = PathStyle.new(seedling, position).follow_path(sphere_path).align_y_to_air()
	
	const idle_r := 20.0
	const idle_h := 10.0
		
	var a: Vector3 = Rand.point_in_circle(idle_r, idle_h)
	var stretch := fit(5, 20)
	var rotate_path := Pathway.new() \
		.move_to(a) \
		.arc_to(a.rotated(Vector3.UP, PI / 2) + Vector3(0, -stretch, 0), true, runs(8), Easing.linear) \
		.arc_to(a.rotated(Vector3.UP, PI) + Vector3(0, 0, 0), true, runs(8), Easing.linear) \
		.arc_to(a.rotated(Vector3.UP, PI / 2 * 3) + Vector3(0, stretch, 0), true, runs(8), Easing.linear) \
		.arc_to(a  + Vector3(0, 0, 0), true, runs(8), Easing.linear) \
		.arc_to(a.rotated(Vector3.UP, PI / 2) + Vector3(0, -stretch, 0), true, runs(8), Easing.linear) \
		.arc_to(a.rotated(Vector3.UP, PI) + Vector3(0, 0, 0), true, runs(8), Easing.linear) \
		.arc_to(a.rotated(Vector3.UP, PI / 2 * 3) + Vector3(0, -stretch, 0), true, runs(8), Easing.linear) \
		.arc_to(a, true, runs(8), Easing.linear)
	
	attack_path = PathStyle.new(seedling).follow_path(rotate_path).align_y_to_ground_air_and_dirt().origin_is_player().look_at_player()
	
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	ice1.configure({"s": atks(3,15), "d": "2"}, Spell.Element.ICE, 10.0, power(10), radius(2), 1, 50, 50, 10)
	ice2.configure({"s": atks(3,12), "d": "2"}, Spell.Element.ICE, 8.0, power(12), radius(2), 1, 50, 50, 20)
	ice3.configure({"s": atks(3,10), "d": "2"}, Spell.Element.ICE, 6.0, power(8), radius(2), 1, 50, 50, 30)
	ice_arc1.configure({"R": "pi", "s": atks(3,15)}, Spell.Element.ICE, 10.0, power(8), radius(3), fiti(1, 8), 75, 25, 20)
	ice_arc2.configure({"R": "pi/2", "s": atks(3,12)}, Spell.Element.ICE, 8.0, power(10), radius(3), fiti(1, 6), 75, 50, 30)
	ice_arc3.configure({"R": "pi/4", "s": atks(3,10)}, Spell.Element.ICE, 6.0, power(12), radius(3), fiti(1, 4), 75, 75, 40)
	ice_scatter1.configure({"harc": "pi", "varc": "pi", "s": atks(3,15)}, Spell.Element.ICE, 10.0, power(11), radius(3), fiti(4, 16), 75, 25, 30)
	ice_scatter2.configure({"harc": "pi/2", "varc": "pi/2", "s": atks(3,12)}, Spell.Element.ICE, 8.0, power(14), radius(3), fiti(5, 15), 75, 50, 40)
	ice_scatter3.configure({"harc": "pi/4", "varc": "pi/4", "s": atks(3,10)}, Spell.Element.ICE, 6.0, power(17), radius(3), fiti(6, 18), 75, 75, 50)
	ice_back1.configure({"sx":"C*u*3", "sy":"C*v*3", "sz":"C*w*3", "ex":"-C*u*3", "ey":"-C*v*3", "ez":"-C*w*3"}, Spell.Element.ICE, fit(8, 3), power(14), radius(5), 1, 50, 100, 30)
	ice_back2.configure({"sx":"C*u*4", "sy":"C*v*4", "sz":"C*w*4", "ex":"-C*u*4", "ey":"-C*v*4", "ez":"-C*w*4"}, Spell.Element.ICE, fit(7, 2.5), power(12), radius(5), 1, 50, 100, 50)
	ice_back3.configure({"sx":"C*u*5", "sy":"C*v*5", "sz":"C*w*5", "ex":"-C*u*5", "ey":"-C*v*5", "ez":"-C*w*5"}, Spell.Element.ICE, fit(6, 2), power(10), radius(5), 1, 50, 100, 70)
	electric1.configure({"s": atks(3,15), "d": "2"}, Spell.Element.ELECTRIC, 10.0, power(10), radius(2), 1, 50, 50, 10)
	electric2.configure({"s": atks(3,12), "d": "2"}, Spell.Element.ELECTRIC, 8.0, power(12), radius(2), 1, 50, 50, 20)
	electric3.configure({"s": atks(3,10), "d": "2"}, Spell.Element.ELECTRIC, 6.0, power(8), radius(2), 1, 50, 50, 30)
	electric_arc1.configure({"R": "pi", "s": atks(3,15)}, Spell.Element.ELECTRIC, 10.0, power(8), radius(3), fiti(1, 8), 75, 25, 20)
	electric_arc2.configure({"R": "pi/2", "s": atks(3,12)}, Spell.Element.ELECTRIC, 8.0, power(10), radius(3), fiti(1, 6), 75, 50, 30)
	electric_arc3.configure({"R": "pi/4", "s": atks(3,10)}, Spell.Element.ELECTRIC, 6.0, power(12), radius(3), fiti(1, 4), 75, 75, 40)
	electric_scatter1.configure({"harc": "pi", "varc": "pi", "s": atks(3,15)}, Spell.Element.ELECTRIC, 10.0, power(11), radius(3), fiti(4, 16), 75, 25, 30)
	electric_scatter2.configure({"harc": "pi/2", "varc": "pi/2", "s": atks(3,12)}, Spell.Element.ELECTRIC, 8.0, power(14), radius(3), fiti(5, 15), 75, 50, 40)
	electric_scatter3.configure({"harc": "pi/4", "varc": "pi/4", "s": atks(3,10)}, Spell.Element.ELECTRIC, 6.0, power(17), radius(3), fiti(6, 18), 75, 75, 50)
	electric_back1.configure({"sx":"C*u*3", "sy":"C*v*3", "sz":"C*w*3", "ex":"-C*u*3", "ey":"-C*v*3", "ez":"-C*w*3"}, Spell.Element.ELECTRIC, fit(8, 3), power(14), radius(5), 1, 50, 100, 30)
	electric_back2.configure({"sx":"C*u*4", "sy":"C*v*4", "sz":"C*w*4", "ex":"-C*u*4", "ey":"-C*v*4", "ez":"-C*w*4"}, Spell.Element.ELECTRIC, fit(7, 2.5), power(12), radius(5), 1, 50, 100, 50)
	electric_back3.configure({"sx":"C*u*5", "sy":"C*v*5", "sz":"C*w*5", "ex":"-C*u*5", "ey":"-C*v*5", "ez":"-C*w*5"}, Spell.Element.ELECTRIC, fit(6, 2), power(10), radius(5), 1, 50, 100, 70)
	
	
	spell_drop_probs = {
		ice1: spell_drop(1),
		ice2: spell_drop(2),
		ice3: spell_drop(3),
		ice_arc1: spell_drop(4),
		ice_arc2: spell_drop(5),
		ice_arc3: spell_drop(6),
		ice_scatter1: spell_drop(7),
		ice_scatter2: spell_drop(8),
		ice_scatter3: spell_drop(9),
		ice_back1: spell_drop(2),
		ice_back2: spell_drop(3),
		ice_back3: spell_drop(4),
		electric1: spell_drop(1),
		electric2: spell_drop(2),
		electric3: spell_drop(3),
		electric_arc1: spell_drop(4),
		electric_arc2: spell_drop(5),
		electric_arc3: spell_drop(6),
		electric_scatter1: spell_drop(7),
		electric_scatter2: spell_drop(8),
		electric_scatter3: spell_drop(9),
		electric_back1: spell_drop(2),
		electric_back2: spell_drop(3),
		electric_back3: spell_drop(4),
	}
	
	random_pattern = AttackPatterns.new(
		[
			ice1,
			ice2,
			ice3,
			electric1,
			electric2,
			electric3,
			ice_back1,
			ice_back2,
			ice_back3,
			electric_back1,
			electric_back2,
			electric_back3,
		],
		AttackPatterns.choose_from_distribution(fit(5,2), [10, 3, 2, 10, 3, 2, 5, 1, 1, 5, 1, 1], -1)
	)
	
	sequence_pattern = AttackPatterns.new(
		[
			ice_scatter1,
			electric_arc1,
			ice_scatter2,
			electric_arc2,
			ice_scatter3,
			electric_arc3,
			
			electric_scatter1,
			ice_arc1,
			electric_scatter2,
			ice_arc2,
			electric_scatter3,
			ice_arc3,
		],
		AttackPatterns.choose_in_sequence(fitas(0.5, [ 1, 1, 3, 1, 5, 1,  1, 1, 3, 1, 5, 1,  ]), -1)
	)
	
	artifact_drop_probs = {
		"N": {
			"effect": { Artifact.Effect.RESISTANCE_FLAT: 10, Artifact.Effect.RESISTANCE_PERCENTAGE: 10 },
			"element": { Artifact.Element.ICE: 5, Artifact.Element.SPELL_RADIUS: 10, Artifact.Element.ANY: 1,  },
			"pattern": { Artifact.Pattern.CIRCLE: 2 },
			"tier": artier(12),
		},
		"E": {
			"is_effect": 0.75,
			"event": { Artifact.Event.DEAL: 2 },
			"effect": { Artifact.Effect.RESISTANCE_FLAT: 10, Artifact.Effect.RESISTANCE_PERCENTAGE: 10 },
			"ef_element": { Artifact.Element.ICE: 5, Artifact.Element.DURATION: 10, Artifact.Element.ANY: 1,  },
			"ev_element": { Artifact.Element.ICE: 10, Artifact.Element.ELECTRIC: 5, },
			"pattern": { Artifact.Pattern.CIRCLE: 2 },
			"tier": artier(12),
		},
		"S": {
			"effect": { Artifact.Effect.RESISTANCE_FLAT: 10, Artifact.Effect.RESISTANCE_PERCENTAGE: 10 },
			"element": { Artifact.Element.ICE: 5, Artifact.Element.COUNT: 10, Artifact.Element.ANY: 1,  },
			"pattern": { Artifact.Pattern.CIRCLE: 2 },
			"tier": artier(12),
		},
		"W": {
			"is_effect": 0.75,
			"event": { Artifact.Event.DEAL: 2 },
			"effect": { Artifact.Effect.RESISTANCE_FLAT: 10, Artifact.Effect.RESISTANCE_PERCENTAGE: 10 },
			"ef_element": { Artifact.Element.ICE: 5, Artifact.Element.POWER: 10, Artifact.Element.ANY: 1,  },
			"ev_element": { Artifact.Element.ICE: 10, Artifact.Element.ELECTRIC: 5, },
			"pattern": { Artifact.Pattern.CIRCLE: 2 },
			"tier": artier(12),
		},
	}
	
	animation_map["attack"] = "Headbutt"
	kind = World.Enemy.GHOSTLY
	super.setup(seedling, biome)


func update_behaviour() -> void:
	super.update_behaviour()
	if is_idle:
		set_path_and_attack(idle_path, none_pattern)
	elif vitals.health.percentage() >= 0.1:
		set_path_and_attack(attack_path, random_pattern)
	else:
		set_path_and_attack(attack_path, sequence_pattern)

	
