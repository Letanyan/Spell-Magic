class_name Mole
extends Enemy

var none_pattern: AttackPatterns
var random_pattern: AttackPatterns
var sequence_pattern: AttackPatterns

var idle_path: PathStyle
var attack_path: PathStyle

var hide_and_attack: AttackSequence

func _ready() -> void:
	super._ready()
	
	velocity_movement = VelocityMovement.new()
	
	vitals = Vitals.new(Vitals.Stat.new(100, 0, 100), Vitals.Stat.new(50, 0, 5, 1))
	vitals.perception.value = 25
	
	idle_path = PathStyle.new(randf()).circle(position, 7, 5, 0).use_absolute().align_y_to_ground()
	
	var R := 25.0
	var U := -5.0
		
	var underground := func() -> Vector3:
		var p: Vector3 = Vector3(randf() * 2.0 - 1.0, 0, randf() * 2.0 - 1.0).normalized() * R + Vector3(0, U, 0)
		return p
	
	var p := PathStyle.Pathway.new()
	var a: Vector3 = underground.call()
	var b: Vector3 = underground.call()
	var c: Vector3 = underground.call()
	var d: Vector3 = underground.call()
	var e: Vector3 = underground.call()

	p.append_with_speed([
		PathStyle.Segment.linear(a, b), PathStyle.Segment.linear(b, c),
		PathStyle.Segment.linear(c, d), PathStyle.Segment.linear(d, e),
		PathStyle.Segment.linear(e, a),
	], [5, 5, 5, 5, 5],
	[PathStyle.Easing.linear, PathStyle.Easing.linear, PathStyle.Easing.linear,
	PathStyle.Easing.linear, PathStyle.Easing.linear]
	)
	
	attack_path = PathStyle.new(0.0).follow_path(p).set_use_player_as_origin().align_y_to_origin().look_at_player().set_is_done_uses_path_segments()
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	var Z := Vector3.ZERO
	var up_pathway := PathStyle.Pathway.new(
		[PathStyle.Segment.linear(Vector3(0, U, 0), Z), PathStyle.Segment.point(Z, 1)],
		[3, 3],
		[PathStyle.Easing.linear, PathStyle.Easing.linear]
	)
	var down_pathway := PathStyle.Pathway.new(
		[PathStyle.Segment.linear(Z, Vector3(0, U, 0))],
		[1],
		[PathStyle.Easing.linear]
	)
	
	
	random_pattern = AttackPatterns.new(
		[
			Spell.new(false, "u * t * 15 + u * 5", "v * t * 15 + v * 5", "w * t * 15 + w * 5", 1, 0.1, 1, Spell.Element.ELECTRIC, 1),
			Spell.new(false, "u * t * 5 + u * 5", "v * t * 5 + v * 5", "w * t * 5 + w * 5", 1, 0.1, 2, Spell.Element.ELECTRIC, 1),
			Spell.new(false, "u * t * 15 + u * 5", "v * t * 15 + v * 5", "w * t * 15 + w * 5", 1, 0.1, 3, Spell.Element.ELECTRIC, 1),
		],
		AttackPatterns.choose_from_distribution(1.0, [ 5, 3, 2 ])
	)
	
	sequence_pattern = AttackPatterns.new(
		[
			Spell.new(false, "u * t * 5", "v * t * 5 + 4", "w * t * 5", 1, 0.1, 5, Spell.Element.ELECTRIC, 1),
			Spell.new(false, "u * t * 5", "v * t * 5 + 4", "w * t * 5", 1, 0.1, 5, Spell.Element.FIRE, 1),
			Spell.new(false, "u * t * 5", "v * t * 5 + 4", "w * t * 5", 1, 0.1, 5, Spell.Element.ELECTRIC, 1),
		],
		AttackPatterns.choose_in_sequence([ 1, 2, 1 ])
	)
	
	hide_and_attack = AttackSequence.new(true, [
		PathStyle.new(0.0).follow_path(down_pathway).set_use_me_as_origin().look_at_player().align_y_to_ground_and_dirt(),
		PathStyle.new(0.0).follow_path(
			PathStyle.Pathway.init_with_speed([PathStyle.Segment.linear(a, b)], [8], [PathStyle.Easing.linear])
		).set_use_player_as_origin().look_at_player().align_y_to_origin(),
		PathStyle.new(0.0).follow_path(up_pathway).set_use_me_as_origin().look_at_player().align_y_to_ground_and_dirt(),
		random_pattern,
		
		PathStyle.new(0.0).follow_path(down_pathway).set_use_me_as_origin().look_at_player().align_y_to_ground_and_dirt(),
		PathStyle.new(0.0).follow_path(
			PathStyle.Pathway.init_with_speed([PathStyle.Segment.linear(b, c)], [8], [PathStyle.Easing.linear])
		).set_use_player_as_origin().look_at_player().align_y_to_origin(),
		PathStyle.new(0.0).follow_path(up_pathway).set_use_me_as_origin().look_at_player().align_y_to_ground_and_dirt(),
		random_pattern,
		
		PathStyle.new(0.0).follow_path(down_pathway).set_use_me_as_origin().look_at_player().align_y_to_ground_and_dirt(),
		PathStyle.new(0.0).follow_path(
			PathStyle.Pathway.init_with_speed([PathStyle.Segment.linear(c, d)], [8], [PathStyle.Easing.linear])
		).set_use_player_as_origin().look_at_player().align_y_to_origin(),
		PathStyle.new(0.0).follow_path(up_pathway).set_use_me_as_origin().look_at_player().align_y_to_ground_and_dirt(),
		random_pattern,
		
		PathStyle.new(0.0).follow_path(down_pathway).set_use_me_as_origin().look_at_player().align_y_to_ground_and_dirt(),
		PathStyle.new(0.0).follow_path(
			PathStyle.Pathway.init_with_speed([PathStyle.Segment.linear(d, e)], [8], [PathStyle.Easing.linear])
		).set_use_player_as_origin().look_at_player().align_y_to_origin(),
		PathStyle.new(0.0).follow_path(up_pathway).set_use_me_as_origin().look_at_player().align_y_to_ground_and_dirt(),
		random_pattern,
		
		PathStyle.new(0.0).follow_path(down_pathway).set_use_me_as_origin().look_at_player().align_y_to_ground_and_dirt(),
		PathStyle.new(0.0).follow_path(
			PathStyle.Pathway.init_with_speed([PathStyle.Segment.linear(e, a)], [8], [PathStyle.Easing.linear])
		).set_use_player_as_origin().look_at_player().align_y_to_origin(),
		PathStyle.new(0.0).follow_path(up_pathway).set_use_me_as_origin().look_at_player().align_y_to_ground_and_dirt(),
		random_pattern,
	])
	
	animation_map["attack"] = "Weapon"

func attack_state() -> AttackPatterns:
	health_bar.visible = not current_path == idle_path
	if current_path == idle_path:
		return none_pattern
	elif vitals.health.value >= 50:
		return random_pattern
	else:
		return sequence_pattern

func entity_info() -> EntityInfo:
	return EntityInfo.new(EntityInfo.Kind.BAT, position)

func update_entity_info(info: EntityInfo) -> bool:
	info.position = position
	return true


func update_behaviour() -> void:
	if current_path == idle_path and sqrt(player.position.distance_squared_to(position)) < vitals.perception.value:
		#current_path = attack_path
		random_pattern.reset()
		sequence_pattern.reset()
		attack_sequence = hide_and_attack
	elif current_path == attack_path and sqrt(player.position.distance_squared_to(position)) > vitals.perception.value * 2:
		current_path = idle_path
		attack_sequence = null
