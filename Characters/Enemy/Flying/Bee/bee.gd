class_name Bee
extends Enemy

var none_pattern: AttackPatterns
var random_pattern: AttackPatterns
var sequence_pattern: AttackPatterns

var idle_path: PathStyle
var attack_path: PathStyle

var elec1 := GlobalData.magic_book.copy_spell("linear")
var elec2 := GlobalData.magic_book.copy_spell("linear")
var elec3 := GlobalData.magic_book.copy_spell("linear")
var fire_mine1 := GlobalData.magic_book.copy_spell("bomb-sphere-scatter")
var fire_mine2 := GlobalData.magic_book.copy_spell("bomb")
var fire_mine3 := GlobalData.magic_book.copy_spell("bomb-linear")
	
func setup(seedling: int, biome: World.Biome) -> void:
	vitals = Vitals.enemy(hp(13), mana(10), mana_regen(15), percep(1,5), atk(10), def(9), {Artifact.Element.ELECTRIC: res(8, 2), Artifact.Element.FIRE: res(8, 2)})
	
	var sphere_path := Pathway.new().move_to(Vector3(0, 10, 0)).random_points_in_sphere(4, 0, 10, 7)
	idle_path = PathStyle.new(0, position).follow_path(sphere_path).align_y_to_air()
	
	const idle_r := 20.0
		
	var a: Vector3 = Rand.point_in_sphere(idle_r)
	var b: Vector3 = Rand.point_in_sphere(idle_r)
	var c: Vector3 = Rand.point_in_sphere(idle_r)
	var d: Vector3 = Rand.point_in_sphere(idle_r)
	
	var rotate_path := Pathway.new() \
		.move_to(a) \
		.quad_to(b, Globals.project_point_onto_sphere(a.lerp(b, 0.5), idle_r), runs(6)) \
		.quad_to(c, Globals.project_point_onto_sphere(b.lerp(c, 0.5), idle_r), runs(6)) \
		.quad_to(d, Globals.project_point_onto_sphere(c.lerp(d, 0.5), idle_r), runs(6)) \
		.quad_to(a, Globals.project_point_onto_sphere(d.lerp(a, 0.5), idle_r), runs(6))
	
	attack_path = PathStyle.new(randi()).follow_path(rotate_path).align_y_to_air().set_use_player_as_origin().look_at_player()
	
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	elec1.configure({"s": atks(4,12), "d": "2"}, Spell.Element.ELECTRIC, fit(5,10), power(13), radius(5), 1, 50, 50, 10)
	elec2.configure({"s": atks(4,14), "d": "2"}, Spell.Element.ELECTRIC, fit(6,12), power(16), radius(6), 1, 50, 50, 20)
	elec3.configure({"s": atks(5,14), "d": "2"}, Spell.Element.ELECTRIC, fit(7,14), power(11), radius(7), 1, 50, 50, 30)
	fire_mine1.configure({"d": "1", "Rmin": "4", "Rmax": "8", "S":"1", "s":"0"}, Spell.Element.FIRE, fit(5,15), power(5), radius(5), fiti(4, 15), 33, 66, 25)
	fire_mine2.configure({"d":"1", "S":"1", "s":"0.5"}, Spell.Element.FIRE, fit(7,21), power(9), radius(7), fiti(2, 8), 75, 120, 50)
	fire_mine3.configure({"d": "1", "R": "10", "S":"1.5-fl", "s":"lerp(fl, 2, 0.1)"}, Spell.Element.FIRE, fit(5,10), power(15), radius(3), fiti(5, 10), 70, 180, 60)
	
	random_pattern = AttackPatterns.new(
		[
			elec1,
			elec2,
			elec3,
			fire_mine1,
			fire_mine2,
			fire_mine3,
		],
		AttackPatterns.choose_from_distribution(fit(5,1), [20, 15, 10, 3, 2, 1], -1)
	)
	
	sequence_pattern = AttackPatterns.new(
		[
			fire_mine1,
			elec1,
			fire_mine2,
			elec2,
			fire_mine3,
			elec3,
		],
		AttackPatterns.choose_in_sequence(fitas(0.3, [ 5, 2, 5, 2, 5, 2 ]), -1)
	)
	
	animation_map["attack"] = "Headbutt"
	kind = World.Enemy.BEE
	super.setup(seedling, biome)

func attack_state() -> AttackPatterns:
	if is_idle:
		return none_pattern
	elif vitals.health.percentage() >= 0.5:
		return sequence_pattern
	else:
		return random_pattern


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
	var spell := elec1.duplicate().bake(new_name)
	return spell
