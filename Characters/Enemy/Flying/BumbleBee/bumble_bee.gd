class_name BumbleBee
extends Enemy

var none_pattern: AttackPatterns
var random_pattern: AttackPatterns
var sequence_pattern: AttackPatterns

var idle_path: PathStyle
var attack_path: PathStyle
	
func setup(seedling: int) -> void:
	vitals = Vitals.enemy(hp(15), mana(15), mana_regen(20), 20, atk(15), def(14), {Artifact.Element.ELECTRIC: res(8, 4), Artifact.Element.FIRE: res(8, 4)})
	vitals.perception.max_value = 50
	
	idle_path = PathStyle.new(0, position + Vector3(0, 10, 0)).random_points_in_sphere(4, 0, 10, 7).align_y_to_air()
	
	const idle_r := 15.0
		
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
	
	var fire1 := GlobalData.magic_book.copy_spell("linear", {"s": "5", "d": "2"}, Spell.Element.FIRE, fit(5,10), power(15), radius(6), 1, 50, 150, 20)
	var fire2 := GlobalData.magic_book.copy_spell("linear", {"s": "5", "d": "2"}, Spell.Element.FIRE, fit(6,12), power(17), radius(7), 1, 50, 150, 30)
	var fire3 := GlobalData.magic_book.copy_spell("linear", {"s": "10", "d": "2"}, Spell.Element.FIRE, fit(7,14), power(13), radius(8), 1, 50, 150, 40)
	
	var elec_mine1 := GlobalData.magic_book.copy_spell("bomb-sphere-scatter", {"d": "1", "Rmin": "4", "Rmax": "8", "S":"1", "s":"0"}, Spell.Element.ELECTRIC, fit(5,10), power(10), radius(5), fiti(4, 15), 33, 66, 50)
	var elec_mine2 := GlobalData.magic_book.copy_spell("bomb", {"d":"1", "S":"1", "s":"0.5"}, Spell.Element.ELECTRIC, fit(7,14), power(14), radius(7), fiti(2, 8), 75, 120, 50)
	var elec_mine3 := GlobalData.magic_book.copy_spell("bomb-linear", {"d": "1", "R": "10", "S":"1.5-fl", "s":"lerp(fl, 2, 0.1)"}, Spell.Element.ELECTRIC, fit(5,10), power(15), radius(3), fiti(5, 10), 70, 180, 50)
	
	random_pattern = AttackPatterns.new(
		[
			fire1,
			fire2,
			fire3,
			elec_mine1,
			elec_mine2,
			elec_mine3,
		],
		AttackPatterns.choose_from_distribution(fit(5,3), [20, 15, 10, 3, 2, 1], -1)
	)
	
	sequence_pattern = AttackPatterns.new(
		[
			elec_mine1,
			fire1,
			elec_mine2,
			fire2,
			elec_mine3,
			fire3,
		],
		AttackPatterns.choose_in_sequence([ 4, 1, 4, 1, 4, 1 ], -1)
	)
	
	animation_map["attack"] = "Headbutt"
	kind = World.Enemy.BEE

func attack_state() -> AttackPatterns:
	if is_idle:
		return none_pattern
	elif vitals.health.percentage() >= 0.5:
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
