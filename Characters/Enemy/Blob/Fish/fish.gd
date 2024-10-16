class_name Fish
extends Enemy

var none_pattern: AttackPatterns
var basic_pattern: AttackPatterns
var flopping_pattern: AttackPatterns

var idle_path: PathStyle
var attack_jump_over_path: PathStyle
var attack_jump_circle_path: PathStyle

var jump_timer: int = 0

var water_para1 := GlobalData.magic_book.copy_spell("loop-shot")
var water_para2 := GlobalData.magic_book.copy_spell("loop-shot")
var water_para3 := GlobalData.magic_book.copy_spell("loop-shot")
var water_line1 := GlobalData.magic_book.copy_spell("linear")
var water_line2 := GlobalData.magic_book.copy_spell("linear")
var water_line3 := GlobalData.magic_book.copy_spell("linear")
var water_shower1 := GlobalData.magic_book.copy_spell("linear")
var water_shower1_chain := GlobalData.magic_book.copy_spell("linear-flurry")
	
func setup(seedling: int, biome: World.Biome) -> void:
	vitals = Vitals.enemy(hp(15), mana(10), mana_regen(10), percep(1,4), atk(5), def(7), {Artifact.Element.WATER: res(10, 0)})
	
	const idle_r := 10.0
	var a := Globals.rand_v3_abs(idle_r, 0, idle_r) + Vector3(0, bounds.y / 2, 0)
	var b := Globals.rand_v3_abs(idle_r, 0, idle_r) + Vector3(0, bounds.y / 2, 0)
	var c := Globals.rand_v3_abs(idle_r, 0, idle_r) + Vector3(0, bounds.y / 2, 0)
	var d := Globals.rand_v3_abs(idle_r, 0, idle_r) + Vector3(0, bounds.y / 2, 0)
	var e := Globals.rand_v3_abs(idle_r, 0, idle_r) + Vector3(0, bounds.y / 2, 0)
	var idle_pathway := Pathway.new() \
		.move_to(Vector3(0, bounds.y / 2, 0)) \
		.line_to(a, 2, Easing.linear) \
		.quad_to(b, Globals.midpoint_tangent1(a, b) if randf() < 0.5 else Globals.midpoint_tangent2(a, b), 2, Easing.linear) \
		.quad_to(c, Globals.midpoint_tangent1(b, c) if randf() < 0.5 else Globals.midpoint_tangent2(b, c), 2, Easing.linear) \
		.quad_to(d, Globals.midpoint_tangent1(c, d) if randf() < 0.5 else Globals.midpoint_tangent2(c, d), 2, Easing.linear) \
		.quad_to(e, Globals.midpoint_tangent1(d, e) if randf() < 0.5 else Globals.midpoint_tangent2(d, e), 2, Easing.linear) \
		.quad_to(a, Globals.midpoint_tangent1(e, a) if randf() < 0.5 else Globals.midpoint_tangent2(e, a), 2, Easing.linear)
	
	idle_path = PathStyle.new().follow_path(idle_pathway).align_y_to_ground().set_origin(position).use_absolute()
	current_path = idle_path
	
	var jump_over_path := Pathway.new() \
		.move_to(Vector3(0, 0, 10)) \
		.quad_to(Vector3(0, 0, -10), Vector3(0, 20, 0), fit(6,2), Easing.out_expo) \
		.quad_to(Vector3(0, 0, 10), Vector3(0, 20, 0), fit(6,2), Easing.out_expo)
	attack_jump_over_path = PathStyle.new().follow_path(jump_over_path).align_y_to_ground_and_jump() \
		.set_player_body_rotation_as_vision_angle(0, 0).set_initial_position_can_update(PathStyle.InitialPositionCanUpdate.ON_GROUND) \
		.look_at_player_xz()
		
	var jump_point_1 := Vector3(0, 0, 10).rotated(Vector3.UP, PI * 2 * randf())
	var jump_point_2 := jump_point_1.rotated(Vector3.UP, PI * (randf_range(-1.0, -0.25) if randf() < 0.5 else randf_range(0.25, 1.0) ))
	var jump_point_3 := jump_point_2.rotated(Vector3.UP, PI * (randf_range(-1.0, -0.25) if randf() < 0.5 else randf_range(0.25, 1.0) ))
	var jump_point_4 := jump_point_3.rotated(Vector3.UP, PI * (randf_range(-1.0, -0.25) if randf() < 0.5 else randf_range(0.25, 1.0) ))
	var jump_point_5 := jump_point_4.rotated(Vector3.UP, PI * (randf_range(-1.0, -0.25) if randf() < 0.5 else randf_range(0.25, 1.0) ))
	var jump_circle_path := Pathway.new() \
		.move_to(jump_point_1) \
		.quad_to(jump_point_2, Globals.vec3_y(jump_point_1.lerp(jump_point_2, 0.5), 20), 3, Easing.out_expo) \
		.quad_to(jump_point_3, Globals.vec3_y(jump_point_2.lerp(jump_point_3, 0.5), 20), 3, Easing.out_expo) \
		.quad_to(jump_point_4, Globals.vec3_y(jump_point_3.lerp(jump_point_4, 0.5), 20), 3, Easing.out_expo) \
		.quad_to(jump_point_5, Globals.vec3_y(jump_point_4.lerp(jump_point_5, 0.5), 20), 3, Easing.out_expo) \
		.quad_to(jump_point_1, Globals.vec3_y(jump_point_5.lerp(jump_point_1, 0.5), 20), 3, Easing.out_expo)
	attack_jump_circle_path = PathStyle.new().follow_path(jump_circle_path).align_y_to_ground_and_air() \
		.set_player_body_rotation_as_vision_angle(0, 1).set_initial_position_can_update(PathStyle.InitialPositionCanUpdate.NEVER) \
		.look_at_player_xz()
	
	none_pattern = AttackPatterns.none()
	
	water_para1.configure({"H":"5"}, Spell.Element.WATER, fit(8, 2), power(15), radius(2), 1, 50, 100, 25)
	water_para2.configure({"H":"7.5"}, Spell.Element.WATER, fit(6, 2), power(14), radius(3), 1, 50, 100, 50)
	water_para3.configure({"H":"10"}, Spell.Element.WATER, fit(4, 2), power(13), radius(4), 1, 50, 100, 75)
	water_line1.configure({"s":atks(2,10), "d":"Br*2"}, Spell.Element.WATER, fit(2, 8), power(10), radius(3), 1, 10, 200, 50)
	water_line2.configure({"s":atks(3,12), "d":"Br*2"}, Spell.Element.WATER, fit(2, 8), power(10), radius(3), 1, 10, 200, 50)
	water_line3.configure({"s":atks(4,15), "d":"Br*2"}, Spell.Element.WATER, fit(2, 8), power(10), radius(3), 1, 10, 200, 50)
	# FIXME [1]: create linear spell that travels an exact distance
	water_shower1.configure({"s":atks(3,4), "d":"Br*2", "rv": "rv+pi/8"}, Spell.Element.WATER, 5.0, power(5), radius(2), 1, 60.0, 80.0, 0.0, water_shower1_chain)
	water_shower1_chain.configure({"s":fits(2,6), "d": "C", "dx":"0", "dy":"-1", "dz":"0", "oy": "u*d*10", "r": "fl * 6 + 4"}, Spell.Element.WATER, 20.0, power(6), radius(2), fiti(5, 20), 30.0, 50.0, 60.0)
	
	basic_pattern = AttackPatterns.new(
		[
			water_line1,
			water_line2,
			water_line3,
			water_para1,
			water_para2,
			water_para3,
		],
		AttackPatterns.choose_from_distribution(fit(6,2), [ 10, 6, 4, 5, 3, 1 ], -1)
	)
	
	flopping_pattern = AttackPatterns.new(
		[
			water_shower1,
			AttackPatterns.new(
				[
					water_para1,
					water_para2,
					water_para3,
				],
				AttackPatterns.choose_from_distribution(fit(3,1), [7, 4, 1], 5)
			),
		],
		AttackPatterns.choose_in_sequence([ 1, 5 ], -1)
	)
	
	animation_map["attack"] = "Bite_Front"
	kind = World.Enemy.FISH
	super.setup(seedling, biome)
	

func attack_state() -> AttackPatterns:
	if is_idle:
		return none_pattern
	elif vitals.health.percentage() > 0.2:
		return basic_pattern
	else:
		return flopping_pattern


func update_behaviour() -> void:
	super.update_behaviour()
	if is_idle:
		current_path = idle_path
	elif vitals.health.percentage() >= 0.25:
		current_path = attack_jump_circle_path
	else:
		current_path = attack_jump_over_path
			

func create_attack_jump_path() -> void:
	var start := position - player.position
	var mid: Vector3 = lerp(position, player.position, 2.5) + Vector3(0, 25, 0) - player.position
	var end: Vector3 = lerp(position, player.position, 5.0) - player.position
	var attack_jump_pathway := Pathway.new() \
		.cubic_to(start, end, mid, 8, Easing.linear)
	DebugDraw3D.draw_sphere(start, 0.5, Color(1, 0, 0), 5)
	DebugDraw3D.draw_sphere(mid, 0.5, Color(0, 1, 0), 5)
	DebugDraw3D.draw_sphere(end, 0.5, Color(0, 0, 1), 5)
	attack_jump_over_path = PathStyle.new().follow_path(attack_jump_pathway).set_use_player_as_origin().align_y_to_origin().look_at_player()


func drop_artifact() -> Artifact:
	var t := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	var r := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	var b := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	var l := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	var new_name := player.name_generator.capital_cities.generate(8, 2)
	return Artifact.new(new_name, t, r, b, l)
