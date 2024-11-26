class_name BumbleBee
extends Enemy

var none_pattern: AttackPatterns
var random_pattern: AttackPatterns
var sequence_pattern: AttackPatterns

var idle_path: PathStyle
var attack_path: PathStyle

var fire1 := GlobalData.magic_book.copy_spell("linear")
var fire2 := GlobalData.magic_book.copy_spell("linear")
var fire3 := GlobalData.magic_book.copy_spell("linear")
var elec_mine1 := GlobalData.magic_book.copy_spell("bomb-sphere-scatter")
var elec_mine2 := GlobalData.magic_book.copy_spell("bomb")
var elec_mine3 := GlobalData.magic_book.copy_spell("bomb-linear")
	
func setup(seedling: int, biome: World.Biome) -> void:
	vitals = Vitals.enemy(hp(15), mana(15), mana_regen(20), percep(1,5), atk(15), def(14), {Artifact.Element.ELECTRIC: res(8, 4), Artifact.Element.FIRE: res(8, 4)})
	
	var sphere_path := Pathway.new().move_to(Vector3(0, 10, 0)).random_points_in_sphere(fit(2,7), 0, 10, 7)
	idle_path = PathStyle.new(0, position).follow_path(sphere_path).align_y_to_air()
	
	const idle_r := 15.0
		
	var a: Vector3 = Rand.point_in_sphere(idle_r)
	var b: Vector3 = Rand.point_in_sphere(idle_r)
	var c: Vector3 = Rand.point_in_sphere(idle_r)
	var d: Vector3 = Rand.point_in_sphere(idle_r)
	
	var rotate_path := Pathway.new() \
		.move_to(a) \
		.quad_to(b, Globals.project_point_onto_sphere(a.lerp(b, 0.5), idle_r), runs(5)) \
		.quad_to(c, Globals.project_point_onto_sphere(b.lerp(c, 0.5), idle_r), runs(5)) \
		.quad_to(d, Globals.project_point_onto_sphere(c.lerp(d, 0.5), idle_r), runs(5)) \
		.quad_to(a, Globals.project_point_onto_sphere(d.lerp(a, 0.5), idle_r), runs(5))
	
	attack_path = PathStyle.new(randi()).follow_path(rotate_path).align_y_to_air().origin_is_player().look_at_player()
	
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	fire1.configure({"s": atks(3,10), "d": "2"}, Spell.Element.FIRE, fit(5,10), power(15), radius(6), 1, 50, 150, 20)
	fire2.configure({"s": atks(4,12), "d": "2"}, Spell.Element.FIRE, fit(6,12), power(17), radius(7), 1, 50, 150, 30)
	fire3.configure({"s": atks(5,14), "d": "2"}, Spell.Element.FIRE, fit(7,14), power(13), radius(8), 1, 50, 150, 40)
	elec_mine1.configure({"d": "1", "Rmin": "4", "Rmax": "8", "S":"1", "s":"0"}, Spell.Element.ELECTRIC, fit(10,5), power(10), radius(5), fiti(4, 15), 33, 66, 50)
	elec_mine2.configure({"d":"1", "S":"1", "s":"0.5"}, Spell.Element.ELECTRIC, fit(14,7), power(14), radius(7), fiti(2, 8), 75, 120, 50)
	elec_mine3.configure({"d": "1", "R": "10", "S":"1.5-fl", "s":fits(2,0.1)}, Spell.Element.ELECTRIC, fit(10,5), power(15), radius(3), fiti(5, 10), 70, 180, 50)
	
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
		AttackPatterns.choose_in_sequence(fitas(0.5, [ 4, 1, 4, 1, 4, 1 ]), -1)
	)
	
	animation_map["attack"] = "Headbutt"
	kind = World.Enemy.BUMBLE_BEE
	super.setup(seedling, biome)


func update_behaviour() -> void:
	super.update_behaviour()
	if is_idle:
		set_path_and_attack(idle_path, none_pattern)
	elif vitals.health.percentage() >= 0.5:
		set_path_and_attack(attack_path, random_pattern)
	else:
		set_path_and_attack(attack_path, sequence_pattern)

func drop_artifact() -> Artifact:
	var t := Artifact.Option.make_random()
	var l := Artifact.Option.make_random()
	var b := Artifact.Option.make_random()
	var r := Artifact.Option.make_random()
	return Artifact.new(player.name_generator.irish_names.generate(5, 3), t, l, b, r)
	
func drop_spell() -> Spell:
	var new_name := player.name_generator.latin_names.generate(6, 2)
	var spell := fire1.duplicate().bake(new_name)
	return spell
