class_name Dragoon
extends Enemy

var none_pattern: AttackPatterns
var random_pattern: AttackPatterns
var sequence_pattern: AttackPatterns

var idle_path: PathStyle
var attack_path: PathStyle
	
func setup(seedling: int) -> void:
	vitals = Vitals.enemy(hp(17), mana(19), mana_regen(20), 30, atk(17), def(17), {Artifact.Element.FIRE: res(12, 7)})
	
	idle_path = PathStyle.new(0, position + Vector3(0, 10, 0)).random_points_in_sphere(4, 0, 10, 7).align_y_to_air()
	
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
	
	var fire1 := GlobalData.magic_book.copy_spell("linear", {"s": "lerp(fl, 2, 10)", "d": "2"}, Spell.Element.FIRE, 10.0, power(12), radius(3), 1, 50, 50, 65)
	var fire2 := GlobalData.magic_book.copy_spell("linear", {"s": "lerp(fl, 2, 10)", "d": "2"}, Spell.Element.FIRE, 8.0, power(14), radius(3), 1, 50, 50, 70)
	var fire3 := GlobalData.magic_book.copy_spell("linear", {"s": "lerp(fl, 4, 15)", "d": "2"}, Spell.Element.FIRE, 6.0, power(19), radius(3), 1, 50, 50, 75)
	
	var fire_down1 := GlobalData.magic_book.copy_spell("top-down", {"H": "10"}, Spell.Element.FIRE, 10.0, power(10), radius(4), 1, 75, 25, 65)
	var fire_down2 := GlobalData.magic_book.copy_spell("top-down", {"H": "20"}, Spell.Element.FIRE, 8.0, power(12), radius(4), 1, 75, 50, 70)
	var fire_down3 := GlobalData.magic_book.copy_spell("top-down", {"H": "30"}, Spell.Element.FIRE, 6.0, power(14), radius(4), 1, 75, 75, 75)
	
	random_pattern = AttackPatterns.new(
		[
			fire1,
			fire2,
			fire3,
			fire_down1,
			fire_down2,
			fire_down3,
		],
		AttackPatterns.choose_from_distribution(5.0, [20, 15, 10, 3, 2, 1], -1)
	)
	
	sequence_pattern = AttackPatterns.new(
		[
			fire_down1,
			fire_down2,
			fire_down3,
			fire_down3,
			fire_down2,
			fire_down1,
		],
		AttackPatterns.choose_in_sequence([ 1, 2, 3, 1, 2, 3 ], -1)
	)
	
	animation_map["attack"] = "Headbutt"
	kind = World.Enemy.BAT

func attack_state() -> AttackPatterns:
	if is_idle:
		return none_pattern
	elif vitals.health.percentage() >= 0.1:
		return random_pattern
	else:
		return sequence_pattern

func entity_info() -> EntityInfo:
	return EntityInfo.new(EntityInfo.Kind.BAT, position)

func update_entity_info(info: EntityInfo) -> bool:
	info.position = position
	return true

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
