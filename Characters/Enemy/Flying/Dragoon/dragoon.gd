class_name Dragoon
extends Enemy

var none_pattern: AttackPatterns
var random_pattern: AttackPatterns
var sequence_pattern: AttackPatterns

var idle_path: PathStyle
var attack_path: PathStyle

var fire2 := GlobalData.magic_book.copy_spell("linear")
var fire1 := GlobalData.magic_book.copy_spell("linear")
var fire3 := GlobalData.magic_book.copy_spell("linear")
var fire_down1 := GlobalData.magic_book.copy_spell("top-down")
var fire_down2 := GlobalData.magic_book.copy_spell("top-down")
var fire_down3 := GlobalData.magic_book.copy_spell("top-down")
var fire_mine1 := GlobalData.magic_book.copy_spell("bomb-sphere-scatter")
var fire_mine2 := GlobalData.magic_book.copy_spell("bomb")
var fire_mine3 := GlobalData.magic_book.copy_spell("bomb-linear")
	
func setup(seedling: int) -> void:
	vitals = Vitals.enemy(hp(17), mana(19), mana_regen(20), 30, atk(17), def(17), {Artifact.Element.FIRE: res(12, 7)})
	
	var sphere_path := PathStyle.Pathway.new().move_to(Vector3(0, 10, 0)).random_points_in_sphere(4, 0, 10, 7)
	idle_path = PathStyle.new(0, position).follow_path(sphere_path).align_y_to_air()
	
	const x_size = 10
	const y_size = 10
	const z_size = 10
	var cube_path := PathStyle.Pathway.new() \
		.move_to(Vector3(0, 0, 0)) \
		.line_to(Globals.rand_v3_abs(x_size, y_size, z_size), 3, PathStyle.Easing.in_out_sine) \
		.line_to(Globals.rand_v3_abs(x_size, y_size, z_size), 2, PathStyle.Easing.in_out_sine) \
		.line_to(Globals.rand_v3_abs(x_size, y_size, z_size), 1, PathStyle.Easing.in_out_sine) \
		.line_to(Globals.rand_v3_abs(x_size, y_size, z_size), 2, PathStyle.Easing.in_out_sine) \
		.line_to(Vector3(0, 0, 0), 3, PathStyle.Easing.in_out_sine)
	
	attack_path = PathStyle.new(randi()).follow_path(cube_path).align_y_to_air().look_at_player() \
		.set_player_body_rotation_as_vision_angle(0, 10, 3, 6)
	
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	fire1.configure({"s": "lerp(fl, 2, 10)", "d": "2"}, Spell.Element.FIRE, 10.0, power(12), radius(3), 1, 50, 50, 65)
	fire2.configure({"s": "lerp(fl, 2, 10)", "d": "2"}, Spell.Element.FIRE, 8.0, power(14), radius(3), 1, 50, 50, 70)
	fire3.configure({"s": "lerp(fl, 4, 15)", "d": "2"}, Spell.Element.FIRE, 6.0, power(19), radius(3), 1, 50, 50, 75)
	fire_down1.configure({"H": "10"}, Spell.Element.FIRE, 10.0, power(10), radius(4), 1, 75, 25, 65)
	fire_down2.configure({"H": "20"}, Spell.Element.FIRE, 8.0, power(12), radius(4), 1, 75, 50, 70)
	fire_down3.configure({"H": "30"}, Spell.Element.FIRE, 6.0, power(14), radius(4), 1, 75, 75, 75)
	fire_mine1.configure({"d": "1", "Rmin": "4", "Rmax": "8", "S":"1", "s":"0"}, Spell.Element.FIRE, 5.0, power(7), radius(7), fiti(4, 15), 33, 66, 25)
	fire_mine2.configure({"d":"1", "S":"1", "s":"0.5"}, Spell.Element.FIRE, 7.0, power(11), radius(9), fiti(2, 8), 75, 120, 50)
	fire_mine3.configure({"d": "1", "R": "10", "S":"1.5-fl", "s":"lerp(fl, 2, 0.1)"}, Spell.Element.FIRE, 5.0, power(17), radius(5), fiti(5, 10), 70, 180, 60)
	
	random_pattern = AttackPatterns.new(
		[
			fire1,
			fire2,
			fire3,
			fire_down1,
			fire_down2,
			fire_down3,
		],
		AttackPatterns.choose_from_distribution(3.0, [14, 10, 8, 6, 4, 2], -1)
	)
	
	sequence_pattern = AttackPatterns.new(
		[
			fire_mine1,
			fire_down1,
			fire_mine2,
			fire_down2,
			fire_mine3,	
			fire_down3,
		],
		AttackPatterns.choose_in_sequence([ 2, 5, 2, 5, 2, 5 ], -1)
	)
	
	animation_map["attack"] = "Headbutt"
	kind = World.Enemy.DRAGOON

func attack_state() -> AttackPatterns:
	if is_idle:
		return none_pattern
	elif vitals.health.percentage() >= 0.1:
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
	var spell := fire1.duplicate().bake(new_name)
	return spell
