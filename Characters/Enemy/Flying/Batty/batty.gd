class_name Batty
extends Enemy

var none_pattern: AttackPatterns
var random_pattern: AttackPatterns
var sequence_pattern: AttackPatterns

var idle_path: PathStyle
var attack_path: PathStyle
	
func setup(seedling: int) -> void:
	vitals = Vitals.enemy(hp(10), mana(15), mana_regen(20), 40, atk(12), def(3), {Artifact.Element.ELECTRIC: res(7, 1)})
	vitals.perception.max_value = 50
	
	idle_path = PathStyle.new(0, position + Vector3(0, 10, 0)).random_points_in_sphere(4, 0, 10, 7).align_y_to_air()
	
	const idle_r := 20.0
	const idle_h := 10.0
		
	var a: Vector3 = Globals.rand_point_in_sphere(idle_r)
	var b: Vector3 = Globals.rand_point_in_sphere(idle_r)
	var c: Vector3 = Globals.rand_point_in_sphere(idle_r)
	var d: Vector3 = Globals.rand_point_in_sphere(idle_r)
	
	var rotate_path := PathStyle.Pathway.new() \
		.move_to(a) \
		.quad_to(b, Globals.project_point_onto_sphere(a.lerp(b, 0.5), idle_r), 3) \
		.quad_to(c, Globals.project_point_onto_sphere(b.lerp(c, 0.5), idle_r), 3) \
		.quad_to(d, Globals.project_point_onto_sphere(c.lerp(d, 0.5), idle_r), 3) \
		.quad_to(a, Globals.project_point_onto_sphere(d.lerp(a, 0.5), idle_r), 3)
	
	attack_path = PathStyle.new(randi()).follow_path(rotate_path).align_y_to_air().set_use_player_as_origin().look_at_player()
	
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	var elec1 := GlobalData.magic_book.copy_spell("linear", {"s": "5", "d": "2"}, Spell.Element.ELECTRIC, fit(5,10), power(13), radius(5), 1, 50, 50, 10)
	var elec2 := GlobalData.magic_book.copy_spell("linear", {"s": "5", "d": "2"}, Spell.Element.ELECTRIC, fit(6,12), power(16), radius(6), 1, 50, 50, 20)
	var elec3 := GlobalData.magic_book.copy_spell("linear", {"s": "10", "d": "2"}, Spell.Element.ELECTRIC, fit(7,14), power(11), radius(7), 1, 50, 50, 30)
	
	var elec_arc1 := GlobalData.magic_book.copy_spell("arc", {"R": "pi", "s": "5"}, Spell.Element.ELECTRIC, fit(6,12), power(8), radius(6), fiti(1, 8), 75, 25, 20)
	var elec_arc2 := GlobalData.magic_book.copy_spell("arc", {"R": "pi/2", "s": "5"}, Spell.Element.ELECTRIC, fit(5,10), power(10), radius(7), fiti(1, 6), 75, 50, 30)
	var elec_arc3 := GlobalData.magic_book.copy_spell("arc", {"R": "pi/4", "s": "10"}, Spell.Element.ELECTRIC, fit(4,8), power(12), radius(8), fiti(1, 4), 75, 75, 40)
	
	var elec_swipe1 := GlobalData.magic_book.copy_spell("swipe", {"Rx":fits(PI/8,PI/2), "Ry":"0", "Dn":fits(8,1), "dz":fits(2,4), "d":"Br*2+C-dz*N/2"}, Spell.Element.ELECTRIC, fit(8,2), power(12), radius(5), fiti(1,10), 25, 100, 10)
	var elec_swipe2 := GlobalData.magic_book.copy_spell("swipe", {"Rx":fits(PI/8,PI/2), "Ry":"0", "Dn":fits(8,1), "dz":fits(2,4), "d":"Br*2+C-dz*N/2"}, Spell.Element.ELECTRIC, fit(12,4), power(12), radius(5), fiti(1,10), 50, 150, 20)
	var elec_swipe3 := GlobalData.magic_book.copy_spell("swipe", {"Rx":fits(PI/8,PI/2), "Ry":"0", "Dn":fits(8,1), "dz":fits(2,4), "d":"Br*2+C-dz*N/2"}, Spell.Element.ELECTRIC, fit(16,6), power(12), radius(5), fiti(1,10), 75, 200, 30)
	
	random_pattern = AttackPatterns.new(
		[
			elec1,
			elec2,
			elec3,
			elec_swipe1,
			elec_swipe2,
			elec_swipe3,
		],
		AttackPatterns.choose_from_distribution(5.0, [20, 15, 10, 3, 2, 1], -1)
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
		AttackPatterns.choose_in_sequence([ 1, 2, 3, 1, 2, 3, 1, 2, 3 ], -1)
	)
	
	animation_map["attack"] = "Headbutt"
	kind = World.Enemy.BATTY

func attack_state() -> AttackPatterns:
	if is_idle:
		return none_pattern
	elif vitals.health.percentage() >= 0.3:
		return random_pattern
	else:
		return sequence_pattern


func update_behaviour() -> void:
	super.update_behaviour()
	if is_idle:
		current_path = idle_path
	else:
		current_path = attack_path

func drop_artifact() -> Artifact:
	var t := Artifact.Option.make_random()
	var l := Artifact.Option.make_random()
	var b := Artifact.Option.make_random()
	var r := Artifact.Option.make_random()
	return Artifact.new(player.name_generator.irish_names.generate(5, 3), t, l, b, r)
	
func drop_spell() -> Spell:
	var new_name := player.name_generator.latin_names.generate(6, 2)
	var spell := GlobalData.magic_book.copy_spell("arc", {"s": "5"}, Spell.Element.ELECTRIC, 1, 5, 0.2, 4, 50, 50, NAN).bake(new_name)
	return spell
