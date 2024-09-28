class_name Ghost
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
	
func setup(seedling: int) -> void:
	vitals = Vitals.enemy(hp(1), mana(8), mana_regen(20), percep(4,5), atk(10), def(5), {Artifact.Element.ELECTRIC: res(5, 1), Artifact.Element.ICE: res(7, 3)})
	vitals.perception.max_value = 40
	
	var sphere_path := PathStyle.Pathway.new().move_to(Vector3(0, 10, 0)).random_points_in_sphere(4, 0, 10, 7)
	idle_path = PathStyle.new(0, position).follow_path(sphere_path).align_y_to_air()
	
	const idle_r := 20.0
	const idle_h := 10.0
		
	var a: Vector3 = Globals.rand_point_in_circle(idle_r, idle_h)
	var rotate_path := PathStyle.Pathway.new() \
		.move_to(a) \
		.arc_to(a.rotated(Vector3.UP, PI / 2), true, 1, PathStyle.Easing.linear) \
		.arc_to(a.rotated(Vector3.UP, PI), true, 1, PathStyle.Easing.linear) \
		.arc_to(a.rotated(Vector3.UP, PI / 2 * 3), true, 1, PathStyle.Easing.linear) \
		.arc_to(a, true, 1, PathStyle.Easing.linear)
	
	attack_path = PathStyle.new(randi()).follow_path(rotate_path).align_y_to_air().set_use_player_as_origin().look_at_player()
	
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	ice1.configure({"s": atks(3,17), "d": "2"}, Spell.Element.ICE, 10.0, power(10), radius(2), 1, 50, 50, 10)
	ice2.configure({"s": atks(3,15), "d": "2"}, Spell.Element.ICE, 8.0, power(12), radius(2), 1, 50, 50, 20)
	ice3.configure({"s": atks(3,10), "d": "2"}, Spell.Element.ICE, 6.0, power(8), radius(2), 1, 50, 50, 30)
	ice_arc1.configure({"R": "pi", "s": atks(3,17)}, Spell.Element.ICE, 10.0, power(8), radius(3), fiti(1, 8), 75, 25, 20)
	ice_arc2.configure({"R": "pi/2", "s": atks(3,15)}, Spell.Element.ICE, 8.0, power(10), radius(3), fiti(1, 6), 75, 50, 30)
	ice_arc3.configure({"R": "pi/4", "s": atks(3,10)}, Spell.Element.ICE, 6.0, power(12), radius(3), fiti(1, 4), 75, 75, 40)
	ice_scatter1.configure({"harc": "pi", "varc": "pi", "s": atks(2,6)}, Spell.Element.ICE, 10.0, power(11), radius(3), fiti(4, 16), 75, 25, 30)
	ice_scatter2.configure({"harc": "pi/2", "varc": "pi/2", "s": atks(2,6)}, Spell.Element.ICE, 8.0, power(14), radius(3), fiti(5, 15), 75, 50, 40)
	ice_scatter3.configure({"harc": "pi/4", "varc": "pi/4", "s": atks(2,6)}, Spell.Element.ICE, 6.0, power(17), radius(3), fiti(6, 18), 75, 75, 50)
	
	random_pattern = AttackPatterns.new(
		[
			ice1,
			ice2,
			ice3,
		],
		AttackPatterns.choose_from_distribution(fit(5,2), [10, 3, 2], -1)
	)
	
	sequence_pattern = AttackPatterns.new(
		[
			ice_scatter1,
			ice_arc1,
			ice_scatter2,
			ice_arc2,
			ice_scatter3,
			ice_arc3,
		],
		AttackPatterns.choose_in_sequence(fitas(0.3, [ 1, 1, 3, 1, 5, 1 ]), -1)
	)
	
	animation_map["attack"] = "Headbutt"
	kind = World.Enemy.GHOST

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
	var spell := ice1.duplicate().bake(new_name)
	return spell
