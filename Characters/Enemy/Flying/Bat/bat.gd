class_name Bat
extends Enemy

var none_pattern: AttackPatterns
var random_pattern: AttackPatterns
var sequence_pattern: AttackPatterns

var idle_path: PathStyle
var attack_path: PathStyle

var elec1 := GlobalData.magic_book.copy_spell("linear")
var elec2 := GlobalData.magic_book.copy_spell("linear")
var elec3 := GlobalData.magic_book.copy_spell("linear")
var elec_arc1 := GlobalData.magic_book.copy_spell("arc")
var elec_arc2 := GlobalData.magic_book.copy_spell("arc")
var elec_arc3 := GlobalData.magic_book.copy_spell("arc")
	
func setup(seedling: int, biome: World.Biome) -> void:
	vitals = Vitals.enemy(hp(5), mana(8), mana_regen(20), percep(2,5), atk(8), def(5), {Artifact.Element.ELECTRIC: res(5, 1)})
	
	var sphere_path := Pathway.new().move_to(Vector3(0, 10, 0)).random_points_in_sphere(4, 0, 10, 7)
	idle_path = PathStyle.new(seedling, position).follow_path(sphere_path).align_y_to_air()
	
	const idle_r := 20.0
	const idle_h := 10.0
		
	var a: Vector3 = Rand.point_in_circle(idle_r, idle_h)
	var b: Vector3 = Rand.point_in_circle(idle_r, idle_h)
	var c: Vector3 = Rand.point_in_circle(idle_r, idle_h)
	var d: Vector3 = Rand.point_in_circle(idle_r, idle_h)
	
	var rotate_path := Pathway.new() \
		.move_to(a) \
		.arc_to(b, true, runs(4), Easing.in_out_cubic) \
		.arc_to(c, true, runs(3), Easing.in_out_cubic) \
		.arc_to(d, true, runs(4), Easing.in_out_cubic) \
		.arc_to(a, true, runs(3), Easing.in_out_cubic)
	
	attack_path = PathStyle.new(seedling).follow_path(rotate_path).align_y_to_air().origin_is_player().look_at_player()
	
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	elec1.configure({"s": atks(2,8), "d": "2"}, Spell.Element.ELECTRIC, 10.0, power(10), radius(2), 1, 50, 50, 0)
	elec2.configure({"s": atks(3,9), "d": "2"}, Spell.Element.ELECTRIC, 8.0, power(12), radius(2), 1, 50, 50, 0)
	elec3.configure({"s": atks(4,10), "d": "2"}, Spell.Element.ELECTRIC, 6.0, power(8), radius(2), 1, 50, 50, 0)
	
	elec_arc1.configure({"R": "pi", "s": atks(2,8)}, Spell.Element.ELECTRIC, 10.0, power(8), radius(3), fiti(1, 8), 75, 25, 0)
	elec_arc2.configure({"R": "pi/2", "s": atks(3,9)}, Spell.Element.ELECTRIC, 8.0, power(10), radius(3), fiti(1, 6), 75, 50, 0)
	elec_arc3.configure({"R": "pi/4", "s": atks(4,10)}, Spell.Element.ELECTRIC, 6.0, power(12), radius(3), fiti(1, 4), 75, 75, 0)
	
	spell_drop_probs = {
		elec1: spell_drop(2),
		elec2: spell_drop(3),
		elec3: spell_drop(4),
		elec_arc1: spell_drop(10),
		elec_arc2: spell_drop(11),
		elec_arc3: spell_drop(12),
	}
	
	random_pattern = AttackPatterns.new(
		[
			elec1,
			elec2,
			elec3,
		],
		AttackPatterns.choose_from_distribution(fit(5.0, 2.0), [10, 3, 2], -1)
	)
	
	sequence_pattern = AttackPatterns.new(
		[
			elec1,
			elec_arc1,
			elec2,
			elec_arc2,
			elec3,
			elec_arc3,
		],
		AttackPatterns.choose_in_sequence(fitas(0.5, [ 1, 1, 3, 1, 5, 1 ]), -1)
	)
	
	artifact_drop_probs = {
		"all": {
			"is_effect": 0.5,
			"event": { Artifact.Event.DEAL: 5, Artifact.Event.RECEIVE: 5 },
			"effect": { Artifact.Effect.BOOST_PERCENTAGE: 2, Artifact.Effect.BOOST_FLAT: 10 },
			"ev_element": { Artifact.Element.ELECTRIC: 10, },
			"ef_element": { Artifact.Element.ELECTRIC: 10, Artifact.Element.MANA: 5, Artifact.Element.MANA_BUMP: 5, },
			"pattern": { Artifact.Pattern.CIRCLE: 4 },
			"tier": artier(5),
		},
	}
	
	animation_map["attack"] = "Headbutt"
	kind = World.Enemy.BAT
	super.setup(seedling, biome)


func update_behaviour() -> void:
	super.update_behaviour()
	if is_idle:
		set_path_and_attack(idle_path, none_pattern)
	elif vitals.health.percentage() >= 0.1:
		set_path_and_attack(attack_path, random_pattern)
	else:
		set_path_and_attack(attack_path, sequence_pattern)
