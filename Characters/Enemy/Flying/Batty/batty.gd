class_name Batty
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
var elec_swipe1 := GlobalData.magic_book.copy_spell("swipe")
var elec_swipe2 := GlobalData.magic_book.copy_spell("swipe")
var elec_swipe3 := GlobalData.magic_book.copy_spell("swipe")
	
func setup(seedling: int, biome: World.Biome) -> void:
	vitals = Vitals.enemy(hp(8), mana(15), mana_regen(20), percep(4,6), atk(12), def(3), {Artifact.Element.ELECTRIC: res(7, 1)})
	
	var sphere_path := Pathway.new().move_to(Vector3(0, 10, 0)).random_points_in_sphere(4, 0, 10, 7)
	idle_path = PathStyle.new(seedling, position).follow_path(sphere_path).align_y_to_air()
	
	const idle_r := 20.0
		
	var a: Vector3 = Rand.point_in_sphere(idle_r)
	var b: Vector3 = Rand.point_in_sphere(idle_r)
	var c: Vector3 = Rand.point_in_sphere(idle_r)
	var d: Vector3 = Rand.point_in_sphere(idle_r)
	
	var rotate_path := Pathway.new() \
		.move_to(a) \
		.quad_to(b, Globals.project_point_onto_sphere(a.lerp(b, 0.5), idle_r), runs(15), Easing.in_sine) \
		.quad_to(c, Globals.project_point_onto_sphere(b.lerp(c, 0.5), idle_r), runs(15), Easing.in_sine) \
		.quad_to(d, Globals.project_point_onto_sphere(c.lerp(d, 0.5), idle_r), runs(15), Easing.in_sine) \
		.quad_to(a, Globals.project_point_onto_sphere(d.lerp(a, 0.5), idle_r), runs(15), Easing.in_sine)
	
	attack_path = PathStyle.new(seedling).follow_path(rotate_path).align_y_to_air().origin_is_player().look_at_player()
	
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	elec1.configure({"s": atks(2,10), "d": "2"}, Spell.Element.ELECTRIC, fit(5,10), power(13), radius(5), 1, 50, 50, 10)
	elec2.configure({"s": atks(3,12), "d": "2"}, Spell.Element.ELECTRIC, fit(6,12), power(16), radius(6), 1, 50, 50, 20)
	elec3.configure({"s": atks(4,14), "d": "2"}, Spell.Element.ELECTRIC, fit(7,14), power(11), radius(7), 1, 50, 50, 30)
	elec_arc1.configure({"R": "pi", "s": atks(2,10)}, Spell.Element.ELECTRIC, fit(6,12), power(8), radius(6), fiti(1, 8), 75, 25, 20)
	elec_arc2.configure({"R": "pi/2", "s": atks(3,12)}, Spell.Element.ELECTRIC, fit(5,10), power(10), radius(7), fiti(1, 6), 75, 50, 30)
	elec_arc3.configure({"R": "pi/4", "s": atks(4,14)}, Spell.Element.ELECTRIC, fit(4,8), power(12), radius(8), fiti(1, 4), 75, 75, 40)
	elec_swipe1.configure({"Rx":fits(PI/8,PI/2), "Ry":"0", "Dn":fits(8,1), "dz":fits(2,4), "d":"Br*2+C-dz*N/2"}, Spell.Element.ELECTRIC, fit(8,2), power(12), radius(5), fiti(1,10), 25, 100, 10)
	elec_swipe2.configure({"Rx":fits(PI/8,PI/2), "Ry":"0", "Dn":fits(8,1), "dz":fits(2,4), "d":"Br*2+C-dz*N/2"}, Spell.Element.ELECTRIC, fit(12,4), power(12), radius(5), fiti(1,10), 50, 150, 20)
	elec_swipe3.configure({"Rx":fits(PI/8,PI/2), "Ry":"0", "Dn":fits(8,1), "dz":fits(2,4), "d":"Br*2+C-dz*N/2"}, Spell.Element.ELECTRIC, fit(16,6), power(12), radius(5), fiti(1,10), 75, 200, 30)
	
	spell_drop_probs = {
		elec1: spell_drop(1),
		elec2: spell_drop(2),
		elec3: spell_drop(3),
		elec_arc1: spell_drop(6),
		elec_arc2: spell_drop(7),
		elec_arc3: spell_drop(8),
		elec_swipe1: spell_drop(10),
		elec_swipe2: spell_drop(11),
		elec_swipe3: spell_drop(12),
	}
	
	random_pattern = AttackPatterns.new(
		[
			elec1,
			elec2,
			elec3,
			elec_swipe1,
			elec_swipe2,
			elec_swipe3,
		],
		AttackPatterns.choose_from_distribution(fit(5,3), [20, 15, 10, 3, 2, 1], -1)
	)
	
	sequence_pattern = AttackPatterns.new(
		[
			elec1,
			elec_arc1,
			elec_swipe1,
			elec2,
			elec_arc2,
			elec_swipe2,
			elec3,
			elec_arc3,
			elec_swipe3,
		],
		AttackPatterns.choose_in_sequence(fitas(0.5, [ 1, 2, 3, 1, 2, 3, 1, 2, 3 ]), -1)
	)
	
	artifact_drop_probs = {
		"all": {
			"is_effect": 0.5,
			"event": { Artifact.Event.DEAL: 5, Artifact.Event.RECEIVE: 5 },
			"effect": { Artifact.Effect.BOOST_PERCENTAGE: 10, Artifact.Effect.BOOST_FLAT: 2 },
			"ev_element": { Artifact.Element.ELECTRIC: 10, },
			"ef_element": { Artifact.Element.ELECTRIC: 10, Artifact.Element.MANA: 10, Artifact.Element.MANA_BUMP: 10, },
			"pattern": { Artifact.Pattern.CIRCLE: 4 },
			"tier": artier(10),
		},
	}
	
	animation_map["attack"] = "Headbutt"
	kind = World.Enemy.BATTY
	super.setup(seedling, biome)


func update_behaviour() -> void:
	super.update_behaviour()
	if is_idle:
		set_path_and_attack(idle_path, none_pattern)
	elif vitals.health.percentage() >= 0.3:
		set_path_and_attack(attack_path, random_pattern)
	else:
		set_path_and_attack(attack_path, sequence_pattern)
