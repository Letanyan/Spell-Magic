class_name Fish
extends Enemy

var none_pattern: AttackPatterns
var default_pattern: AttackPatterns
var sequence_pattern: AttackPatterns

var idle_path: PathStyle
var attack_direct_path: PathStyle
var attack_jump_path: PathStyle

var jump_timer: int = 0

func _ready():
	super._ready()
	
	velocity_movement = VelocityMovement.new()
	
	vitals = Vitals.new(Vitals.Stat.new(100, 0, 100), Vitals.Stat.new(50, 0, 5, 1))
	vitals.perception.value = 20
	
	const idle_r := 10.0
	var randarc := func() -> PathStyle.Segment:
		var s : Vector3 = Globals.rand_v3_abs(idle_r, 0, idle_r)
		var e : Vector3 = Globals.rand_v3_abs(idle_r, 0, idle_r)
		var a := s.x
		var b := s.z
		var c := e.x
		var d := e.z
		
		var p := Vector3(0.5*(c+a) + sqrt(3.0)/2.0 * (d-b), 0, 0.5*(d+b) - sqrt(3.0)/2.0 * (c-a))
		var q := Vector3(0.5*(c+a) - sqrt(3.0)/2.0 * (d-b), 0, 0.5*(d+b) + sqrt(3.0)/2.0 * (c-a))
		var m: Vector3
		if randf() < 0.5:
			m = p
		else:
			m = q
			
		return PathStyle.Segment.quad(s, e, m)
	var idle_pathway := PathStyle.Pathway.new()
	idle_pathway.append([randarc.call(), randarc.call(), randarc.call(), randarc.call(), randarc.call()])
	
	idle_path = PathStyle.new(randf()).follow_path(idle_pathway).speed(2).align_y_to_origin().set_origin(position).use_absolute()
	attack_direct_path = PathStyle.new(randf()).towards_player(4, 6).speed(2).use_physics()
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	var water_para := GlobalData.magic_book.spell_with_name("parabola", {"h":"4", "s":"4"})
	water_para.element = Spell.Element.WATER
	var water_line := GlobalData.magic_book.spell_with_name("linear", {"s":"15", "d":"1"})
	water_line.element = Spell.Element.WATER
	
	default_pattern = AttackPatterns.new(
		[
			water_line,
			water_para,
		],
		[ 7, 3 ],
		false,
		0.25
	)
	
	sequence_pattern = AttackPatterns.new(
		[
			Spell.new(false, "u * t * 5 + u * 2", "v * t * 5 + v * 2 + 2", "w * t * 5 + w * 2", "1", 50, 5, Spell.Element.FIRE, 1),
			Spell.new(false, "u * t * 5 + u * 2", "v * t * 5 + v * 2 + 2", "w * t * 5 + w * 2", "1", 50, 5, Spell.Element.WATER, 1),
			Spell.new(false, "u * t * 5 + u * 2", "v * t * 5 + v * 2 + 2", "w * t * 5 + w * 2", "1", 50, 5, Spell.Element.ROCK, 1),
		],
		[ 2, 5, 3 ],
		true
	)
	
	animation_map["attack"] = "Bite_Front"
	
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if current_path == attack_direct_path:
		jump_timer += 1

func __default_pattern() -> AttackPatterns:
	var water_para := GlobalData.magic_book.spell_with_name("parabola", {"height":"4", "speed":"4"})
	water_para.element = Spell.Element.WATER
	var water_line := GlobalData.magic_book.spell_with_name("linear", {"speed":"15", "offset":"1"})
	water_line.element = Spell.Element.WATER
	
	default_pattern.spells = [
		water_line,
		water_para,
	]
	return default_pattern

func attack_state() -> AttackPatterns:
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


func update_behaviour():
	if current_path == idle_path and sqrt(player.position.distance_squared_to(position)) < vitals.perception.value:
		current_path = attack_direct_path		
	elif current_path == attack_direct_path:
		if sqrt(player.position.distance_squared_to(position)) > vitals.perception.value * 2:
			current_path = idle_path
		elif jump_timer > 60 * 5 and attack_direct_path.stored_loops > 0:
			create_attack_jump_path()
			attack_direct_path.stored_loops = 0
			current_path = attack_jump_path
	elif current_path == attack_jump_path and attack_jump_path.stored_loops > 0:
		attack_jump_path.stored_loops = 0
		jump_timer = 0
		current_path = attack_direct_path
			

func create_attack_jump_path():
	var start := position - player.position
	var mid: Vector3 = lerp(position, player.position, 2.5) + Vector3(0, 25, 0) - player.position
	var end: Vector3 = lerp(position, player.position, 5.0) - player.position
	var attack_jump_pathway = PathStyle.Pathway.new()
	attack_jump_pathway.append([PathStyle.Segment.quad(start, end, mid)])
	DebugDraw3D.draw_sphere(start, 0.5, Color(1, 0, 0), 5)
	DebugDraw3D.draw_sphere(mid, 0.5, Color(0, 1, 0), 5)
	DebugDraw3D.draw_sphere(end, 0.5, Color(0, 0, 1), 5)
	attack_jump_path = PathStyle.new(0.0).follow_path(attack_jump_pathway).speed(8).set_use_player_as_origin().align_y_to_origin().look_at_player()

func death_box() -> Vector3:
	return Vector3(0.7, 1.9, 0.3)

func drop_artifact() -> Artifact:
	var t := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(10, 30))
	var r := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(10, 30))
	var b := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(10, 30))
	var l := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(10, 30))
	return Artifact.new(Time.get_datetime_string_from_system(), t, r, b, l)
