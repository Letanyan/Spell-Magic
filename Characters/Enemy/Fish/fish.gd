class_name Fish
extends Enemy

var none_pattern: AttackPatterns
var basic_pattern: AttackPatterns
var flopping_pattern: AttackPatterns

var idle_path: PathStyle
var attack_direct_path: PathStyle
var attack_jump_path: PathStyle

var jump_timer: int = 0
	
func setup(seedling: int) -> void:
	vitals = Vitals.new(Vitals.Stat.new(100, 0, 100), Vitals.Stat.new(50, 0, 5, 1))
	vitals.perception.value = 20
	
	const idle_r := 10.0
	var a := Globals.rand_v3_abs(idle_r, 0, idle_r) + Vector3(0, bounds.y / 2, 0)
	var b := Globals.rand_v3_abs(idle_r, 0, idle_r) + Vector3(0, bounds.y / 2, 0)
	var c := Globals.rand_v3_abs(idle_r, 0, idle_r) + Vector3(0, bounds.y / 2, 0)
	var d := Globals.rand_v3_abs(idle_r, 0, idle_r) + Vector3(0, bounds.y / 2, 0)
	var e := Globals.rand_v3_abs(idle_r, 0, idle_r) + Vector3(0, bounds.y / 2, 0)
	var idle_pathway: PathStyle.Pathway = PathStyle.Pathway.new() \
		.move_to(Vector3(0, bounds.y / 2, 0)) \
		.line_to(a, 2, PathStyle.Easing.linear) \
		.quad_to(b, Globals.midpoint_tangent1(a, b) if randf() < 0.5 else Globals.midpoint_tangent2(a, b), 2, PathStyle.Easing.linear) \
		.quad_to(c, Globals.midpoint_tangent1(b, c) if randf() < 0.5 else Globals.midpoint_tangent2(b, c), 2, PathStyle.Easing.linear) \
		.quad_to(d, Globals.midpoint_tangent1(c, d) if randf() < 0.5 else Globals.midpoint_tangent2(c, d), 2, PathStyle.Easing.linear) \
		.quad_to(e, Globals.midpoint_tangent1(d, e) if randf() < 0.5 else Globals.midpoint_tangent2(d, e), 2, PathStyle.Easing.linear) \
		.quad_to(a, Globals.midpoint_tangent1(e, a) if randf() < 0.5 else Globals.midpoint_tangent2(e, a), 2, PathStyle.Easing.linear)
	
	idle_path = PathStyle.new().follow_path(idle_pathway).align_y_to_ground().set_origin(position).use_absolute()
	attack_direct_path = PathStyle.new().towards_player(2, 4, 6).use_physics()
	current_path = idle_path
	
	var jump_path: PathStyle.Pathway = PathStyle.Pathway.new() \
		.move_to(Vector3(0, 0, 10)) \
		.quad_to(Vector3(0, 0, -10), Vector3(0, 20, 0), 3, PathStyle.Easing.out_expo) \
		.quad_to(Vector3(0, 0, 10), Vector3(0, 20, 0), 3, PathStyle.Easing.out_expo)
		
	attack_jump_path = PathStyle.new().follow_path(jump_path).align_y_to_ground_and_air().set_player_body_vision_as_origin(0, 1)
	
	none_pattern = AttackPatterns.none()
	
	var water_para1 := GlobalData.magic_book.copy_spell("loop-shot", {"H":"5"})
	water_para1.element = Spell.Element.WATER
	water_para1.duration = invfl * 6 + 2
	var water_para2 := GlobalData.magic_book.copy_spell("loop-shot", {"H":"7.5"})
	water_para2.element = Spell.Element.WATER
	water_para2.duration = invfl * 4 + 2
	var water_para3 := GlobalData.magic_book.copy_spell("loop-shot", {"H":"10"})
	water_para3.element = Spell.Element.WATER
	water_para3.duration = invfl * 2 + 2
	var water_line1 := GlobalData.magic_book.copy_spell("linear", {"s":"fl*8+2", "d":"Br*2"})
	water_line1.element = Spell.Element.WATER
	water_line1.duration = 2.0 + fl * 6
	var water_line2 := GlobalData.magic_book.copy_spell("linear", {"s":"fl*12+3", "d":"Br*2"})
	water_line2.element = Spell.Element.WATER
	water_line2.duration = 4.0 + fl * 6
	var water_line3 := GlobalData.magic_book.copy_spell("linear", {"s":"fl*16+4", "d":"Br*2"})
	water_line3.element = Spell.Element.WATER
	water_line3.duration = 6.0 + fl * 6
	
	var water_shower1 := GlobalData.magic_book.copy_spell("linear", {"s":"fl*20", "d":"Br*2", "rv": "rv+pi/8"})
	water_shower1.element = Spell.Element.WATER
	water_shower1.duration = 5.0
	water_shower1.chain = GlobalData.magic_book.copy_spell("linear-flurry", {"s":"fl*8+2", "d": "C", "dx":"0", "dy":"-1", "dz":"0", "oy": "u*d*10", "r": "fl * 6 + 4"})
	water_shower1.chain.element = Spell.Element.WATER
	water_shower1.chain.count = clampi(int(fl * 10.0), 0, 10) + 5
	water_shower1.chain.duration = 20
	
	basic_pattern = AttackPatterns.new(
		[
			water_line1,
			water_line2,
			water_line3,
			water_para1,
			water_para2,
			water_para3,
		],
		AttackPatterns.choose_from_distribution(invfl * 10 + 0.5, [ 10, 6, 4, 5, 3, 1 ], -1)
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
				AttackPatterns.choose_from_distribution(invfl * 10 + 0.1, [7, 4, 1], 5)
			),
		],
		AttackPatterns.choose_in_sequence([ 1, 5 ], -1)
	)
	
	animation_map["attack"] = "Bite_Front"
	kind = World.Enemy.FISH
	
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if current_path == attack_direct_path:
		jump_timer += 1

func attack_state() -> AttackPatterns:
	health_bar.visible = not current_path == idle_path
	if current_path == idle_path:
		return none_pattern
	elif vitals.health.percentage() > 0.2:
		return basic_pattern
	else:
		return flopping_pattern

func entity_info() -> EntityInfo:
	return EntityInfo.new(EntityInfo.Kind.UNDEAD, position)

func update_entity_info(info: EntityInfo) -> bool:
	info.position = position
	return true


func update_behaviour() -> void:
	if current_path == idle_path and sqrt(player.position.distance_squared_to(position)) < vitals.perception.value:
		current_path = attack_direct_path
		player.watch_enemy(self)
	elif current_path == attack_direct_path and sqrt(player.position.distance_squared_to(position)) > vitals.perception.value * 2:
		current_path = idle_path
		player.ignore_enemy(self)
		
	
	#if current_path == idle_path and sqrt(player.position.distance_squared_to(position)) < vitals.perception.value:
		#sequence_pattern.reset()
		#default_pattern.reset()
		#current_path = attack_direct_path
	#elif current_path == attack_direct_path:
		#if sqrt(player.position.distance_squared_to(position)) > vitals.perception.value * 2:
			#current_path = idle_path
		#elif jump_timer > 60 * 5 and attack_direct_path.stored_loops > 0:
			##create_attack_jump_path()
			#attack_direct_path.stored_loops = 0
			#sequence_pattern.reset()
			#default_pattern.reset()
			#current_path = attack_jump_path
	#elif current_path == attack_jump_path and attack_jump_path.stored_loops > 0:
		#attack_jump_path.stored_loops = 0
		#jump_timer = 0
		#sequence_pattern.reset()
		#default_pattern.reset()
		#current_path = attack_direct_path
			

func create_attack_jump_path() -> void:
	var start := position - player.position
	var mid: Vector3 = lerp(position, player.position, 2.5) + Vector3(0, 25, 0) - player.position
	var end: Vector3 = lerp(position, player.position, 5.0) - player.position
	var attack_jump_pathway := PathStyle.Pathway.new() \
		.cubic_to(start, end, mid, 8, PathStyle.Easing.linear)
	DebugDraw3D.draw_sphere(start, 0.5, Color(1, 0, 0), 5)
	DebugDraw3D.draw_sphere(mid, 0.5, Color(0, 1, 0), 5)
	DebugDraw3D.draw_sphere(end, 0.5, Color(0, 0, 1), 5)
	attack_jump_path = PathStyle.new().follow_path(attack_jump_pathway).set_use_player_as_origin().align_y_to_origin().look_at_player()

func death_box() -> Vector3:
	return Vector3(0.7, 1.9, 0.3)

func drop_artifact() -> Artifact:
	var t := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	var r := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	var b := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	var l := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	return Artifact.new(Time.get_datetime_string_from_system(), t, r, b, l)
