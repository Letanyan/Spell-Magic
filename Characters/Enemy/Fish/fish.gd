class_name Fish
extends Enemy

var none_pattern: AttackPatterns
var default_pattern: AttackPatterns
var sequence_pattern: AttackPatterns

var idle_path: PathStyle
var attack_direct_path: PathStyle
var attack_jump_path: PathStyle

var jump_timer: int = 0
	
func setup() -> void:
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
	
	idle_path = PathStyle.new(randf()).follow_path(idle_pathway).align_y_to_ground().set_origin(position).use_absolute()
	attack_direct_path = PathStyle.new(randf()).towards_player(2, 4, 6).use_physics()
	current_path = idle_path
	
	var jump_path: PathStyle.Pathway = PathStyle.Pathway.new() \
		.move_to(Vector3(0, 0, 10)) \
		.quad_to(Vector3(0, 0, -10), Vector3(0, 20, 0), 3, PathStyle.Easing.out_expo) \
		.quad_to(Vector3(0, 0, 10), Vector3(0, 20, 0), 3, PathStyle.Easing.out_expo)
		
	attack_jump_path = PathStyle.new().follow_path(jump_path).align_y_to_ground_and_air().set_player_body_vision_as_origin(0, 1)
	
	none_pattern = AttackPatterns.none()
	
	var water_para := GlobalData.magic_book.copy_spell("loop-shot", {"H":"4", "s":"4"})
	water_para.element = Spell.Element.WATER
	var water_line := GlobalData.magic_book.copy_spell("linear", {"s":"15", "d":"1"})
	water_line.element = Spell.Element.WATER
	
	default_pattern = AttackPatterns.new(
		[
			water_line,
			water_para,
		],
		AttackPatterns.choose_from_distribution(0.25, [ 7, 3 ])
	)
	
	sequence_pattern = AttackPatterns.new(
		[
			Spell.new(false, "u * t * 5 + u * 2", "v * t * 5 + v * 2 + 2", "w * t * 5 + w * 2", 1, 50, 5, Spell.Element.FIRE, 1),
			Spell.new(false, "u * t * 5 + u * 2", "v * t * 5 + v * 2 + 2", "w * t * 5 + w * 2", 1, 50, 5, Spell.Element.WATER, 1),
			Spell.new(false, "u * t * 5 + u * 2", "v * t * 5 + v * 2 + 2", "w * t * 5 + w * 2", 1, 50, 5, Spell.Element.ROCK, 1),
		],
		AttackPatterns.choose_in_sequence([ 2, 5, 3 ])
	)
	
	animation_map["attack"] = "Bite_Front"
	kind = World.Enemy.FISH
	
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if current_path == attack_direct_path:
		jump_timer += 1

func __default_pattern() -> AttackPatterns:
	var water_para := GlobalData.magic_book.copy_spell("loop-shot", {"H":"4", "speed":"4"})
	water_para.element = Spell.Element.WATER
	var water_line := GlobalData.magic_book.copy_spell("linear", {"speed":"15", "offset":"1"})
	water_line.element = Spell.Element.WATER
	
	default_pattern.spells = [
		water_line,
		water_para,
	]
	return default_pattern

func attack_state() -> AttackPatterns:
	health_bar.visible = not current_path == idle_path
	if current_path == idle_path:
		return none_pattern
	elif vitals.health.value >= 50:
		return __default_pattern()
	else:
		return default_pattern

func entity_info() -> EntityInfo:
	return EntityInfo.new(EntityInfo.Kind.UNDEAD, position)

func update_entity_info(info: EntityInfo) -> bool:
	info.position = position
	return true


func update_behaviour() -> void:
	if current_path == idle_path and sqrt(player.position.distance_squared_to(position)) < vitals.perception.value:
		current_path = attack_jump_path
	elif current_path == attack_jump_path and sqrt(player.position.distance_squared_to(position)) > vitals.perception.value * 2:
		current_path = idle_path
		
	
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
	attack_jump_path = PathStyle.new(0.0).follow_path(attack_jump_pathway).set_use_player_as_origin().align_y_to_origin().look_at_player()

func death_box() -> Vector3:
	return Vector3(0.7, 1.9, 0.3)

func drop_artifact() -> Artifact:
	var t := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(10, 30))
	var r := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(10, 30))
	var b := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(10, 30))
	var l := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(10, 30))
	return Artifact.new(Time.get_datetime_string_from_system(), t, r, b, l)
