class_name Mole
extends Enemy

var none_pattern: AttackPatterns
var random_pattern: AttackPatterns
var sequence_pattern: AttackPatterns

var idle_path: PathStyle
var attack_path: PathStyle

var hide_and_attack: AttackSequence
	
func setup(seedling: int) -> void:
	kind = World.Enemy.NONE # set to zero while we setup stuff
	vitals = Vitals.enemy(hp(16), mana(14), mana_regen(10), 25, atk(15), def(15), {Artifact.Element.ROCK: res(8, 0), Artifact.Element.ELECTRIC: res(7, 1)})
	
	current_path = PathStyle.new(0, position).circle(7, 5, bounds.y / 2.0).use_absolute().align_y_to_ground()
	idle_path = current_path
	
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
	
	attack_path = PathStyle.new().follow_path(p).set_use_player_as_origin().align_y_to_origin().look_at_player().set_is_done_uses_path_segments()
	
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
	
	var elec1 := GlobalData.magic_book.copy_spell("linear", {"s": "15", "d": "5"}, Spell.Element.ELECTRIC, 1+fl*5, 5+fl*45, 0.1+fl*0.25, 1, 25, 50, 0)
	var elec2 := GlobalData.magic_book.copy_spell("linear", {"s": "10", "d": "5"}, Spell.Element.ELECTRIC, 3+fl*5, 15+fl*45, 0.2+fl*0.25, 1, 25, 50, 0)
	var elec3 := GlobalData.magic_book.copy_spell("linear", {"s": "5", "d": "5"}, Spell.Element.ELECTRIC, 5+fl*5, 25+fl*45, 0.3+fl*0.25, 1, 25, 50, 0)
	
	
	random_pattern = AttackPatterns.new(
		[
			elec1,
			elec2,
			elec3,
		],
		AttackPatterns.choose_from_distribution(1.0, [ 5, 3, 2 ], 1)
	)
	
	sequence_pattern = AttackPatterns.new(
		[
			elec1,
			elec2,
			elec3,
		],
		AttackPatterns.choose_in_sequence([ 1, 2, 1 ], -1)
	)
	
	hide_and_attack = AttackSequence.new(true, [
		PathStyle.new().follow_path(down_pathway).set_use_me_as_origin().look_at_player().align_y_to_ground_and_dirt(),
		PathStyle.new().follow_path(
			PathStyle.Pathway.init_with_speed([PathStyle.Segment.linear(a, b)], [8], [PathStyle.Easing.linear])
		).set_use_player_as_origin().look_at_player().align_y_to_origin(),
		PathStyle.new().follow_path(up_pathway).set_use_me_as_origin().look_at_player().align_y_to_ground_and_dirt(),
		random_pattern,
		
		PathStyle.new().follow_path(down_pathway).set_use_me_as_origin().look_at_player().align_y_to_ground_and_dirt(),
		PathStyle.new().follow_path(
			PathStyle.Pathway.init_with_speed([PathStyle.Segment.linear(b, c)], [8], [PathStyle.Easing.linear])
		).set_use_player_as_origin().look_at_player().align_y_to_origin(),
		PathStyle.new().follow_path(up_pathway).set_use_me_as_origin().look_at_player().align_y_to_ground_and_dirt(),
		random_pattern,
		
		PathStyle.new().follow_path(down_pathway).set_use_me_as_origin().look_at_player().align_y_to_ground_and_dirt(),
		PathStyle.new().follow_path(
			PathStyle.Pathway.init_with_speed([PathStyle.Segment.linear(c, d)], [8], [PathStyle.Easing.linear])
		).set_use_player_as_origin().look_at_player().align_y_to_origin(),
		PathStyle.new().follow_path(up_pathway).set_use_me_as_origin().look_at_player().align_y_to_ground_and_dirt(),
		random_pattern,
		
		PathStyle.new().follow_path(down_pathway).set_use_me_as_origin().look_at_player().align_y_to_ground_and_dirt(),
		PathStyle.new().follow_path(
			PathStyle.Pathway.init_with_speed([PathStyle.Segment.linear(d, e)], [8], [PathStyle.Easing.linear])
		).set_use_player_as_origin().look_at_player().align_y_to_origin(),
		PathStyle.new().follow_path(up_pathway).set_use_me_as_origin().look_at_player().align_y_to_ground_and_dirt(),
		random_pattern,
		
		PathStyle.new().follow_path(down_pathway).set_use_me_as_origin().look_at_player().align_y_to_ground_and_dirt(),
		PathStyle.new().follow_path(
			PathStyle.Pathway.init_with_speed([PathStyle.Segment.linear(e, a)], [8], [PathStyle.Easing.linear])
		).set_use_player_as_origin().look_at_player().align_y_to_origin(),
		PathStyle.new().follow_path(up_pathway).set_use_me_as_origin().look_at_player().align_y_to_ground_and_dirt(),
		random_pattern,
	])
	
	animation_map["attack"] = "Weapon"
	kind = World.Enemy.MOLE

func attack_state() -> AttackPatterns:
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
	super.update_behaviour()
	if is_idle:
		current_path = idle_path
		attack_sequence = null
	else:
		random_pattern.reset()
		sequence_pattern.reset()
		attack_sequence = hide_and_attack
