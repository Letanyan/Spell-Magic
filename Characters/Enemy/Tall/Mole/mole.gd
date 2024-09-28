class_name Mole
extends Enemy

var none_pattern: AttackPatterns
var random_pattern: AttackPatterns

var idle_path: PathStyle
var attack_path: PathStyle

var hide_and_attack: AttackSequence

var elec1 := GlobalData.magic_book.copy_spell("linear")
var elec2 := GlobalData.magic_book.copy_spell("linear")
var elec3 := GlobalData.magic_book.copy_spell("linear")
	
func setup(seedling: int) -> void:
	kind = World.Enemy.NONE # set to zero while we setup stuff
	vitals = Vitals.enemy(hp(16), mana(14), mana_regen(10), percep(2,4), atk(15), def(15), {Artifact.Element.ROCK: res(8, 0), Artifact.Element.ELECTRIC: res(7, 1)})
	
	var circle_path := PathStyle.Pathway.new().move_to(Vector3.ZERO).circle_with_speed(5, 0, 7)
	current_path = PathStyle.new(0, position).follow_path(circle_path).align_y_to_ground()
	idle_path = current_path
	
	var R := 25.0
	var U := -bounds.y * 2.5
		
	var underground := func() -> Vector3:
		var p: Vector3 = Vector3(randf() * 2.0 - 1.0, 0, randf() * 2.0 - 1.0).normalized() * R + Vector3(0, U, 0)
		return p
	
	var a: Vector3 = underground.call()
	var b: Vector3 = underground.call()
	var c: Vector3 = underground.call()
	var d: Vector3 = underground.call()
	var e: Vector3 = underground.call()
	var p := PathStyle.Pathway.new() \
		.move_to(a) \
		.line_to(b, 8, PathStyle.Easing.linear) \
		.line_to(c, 8, PathStyle.Easing.linear) \
		.line_to(d, 8, PathStyle.Easing.linear) \
		.line_to(e, 8, PathStyle.Easing.linear) \
		.line_to(a, 8, PathStyle.Easing.linear)
	
	attack_path = PathStyle.new().follow_path(p).set_use_player_as_origin().align_y_to_ground().look_at_player()
	
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
	
	elec1.configure({"s": atks(3,15), "d": "5"}, Spell.Element.ELECTRIC, fit(7,14), power(7), radius(3), 1, 25, 150, 30)
	elec2.configure({"s": atks(2,10), "d": "5"}, Spell.Element.ELECTRIC, fit(6,12), power(10), radius(4), 1, 25, 150, 40)
	elec3.configure({"s": atks(1,5), "d": "5"}, Spell.Element.ELECTRIC, fit(5,10), power(13), radius(5), 1, 25, 150, 50)
	
	random_pattern = AttackPatterns.new(
		[
			elec1,
			elec2,
			elec3,
		],
		AttackPatterns.choose_from_distribution(fit(2.0, 0.5), [ 5, 3, 2 ], -1)
	)
	
	hide_and_attack = AttackSequence.new(true, [
		PathStyle.new().follow_path(down_pathway).set_use_me_as_origin().look_at_player().align_y_to_ground_and_dirt(),
		PathStyle.new().follow_path(
			PathStyle.Pathway.new().move_to(a).line_to(b, 8, PathStyle.Easing.linear)
		).set_use_player_as_origin().look_at_player().align_y_to_origin(),
		PathStyle.new().follow_path(up_pathway).set_use_me_as_origin().look_at_player().align_y_to_ground_and_dirt(),
		random_pattern,
		
		PathStyle.new().follow_path(down_pathway).set_use_me_as_origin().look_at_player().align_y_to_ground_and_dirt(),
		PathStyle.new().follow_path(
			PathStyle.Pathway.new().move_to(b).line_to(c, 8, PathStyle.Easing.linear)
		).set_use_player_as_origin().look_at_player().align_y_to_origin(),
		PathStyle.new().follow_path(up_pathway).set_use_me_as_origin().look_at_player().align_y_to_ground_and_dirt(),
		random_pattern,
		
		PathStyle.new().follow_path(down_pathway).set_use_me_as_origin().look_at_player().align_y_to_ground_and_dirt(),
		PathStyle.new().follow_path(
			PathStyle.Pathway.new().move_to(c).line_to(d, 8, PathStyle.Easing.linear)
		).set_use_player_as_origin().look_at_player().align_y_to_origin(),
		PathStyle.new().follow_path(up_pathway).set_use_me_as_origin().look_at_player().align_y_to_ground_and_dirt(),
		random_pattern,
		
		PathStyle.new().follow_path(down_pathway).set_use_me_as_origin().look_at_player().align_y_to_ground_and_dirt(),
		PathStyle.new().follow_path(
			PathStyle.Pathway.new().move_to(d).line_to(e, 8, PathStyle.Easing.linear)
		).set_use_player_as_origin().look_at_player().align_y_to_origin(),
		PathStyle.new().follow_path(up_pathway).set_use_me_as_origin().look_at_player().align_y_to_ground_and_dirt(),
		random_pattern,
		
		PathStyle.new().follow_path(down_pathway).set_use_me_as_origin().look_at_player().align_y_to_ground_and_dirt(),
		PathStyle.new().follow_path(
			PathStyle.Pathway.new().move_to(e).line_to(a, 8, PathStyle.Easing.linear)
		).set_use_player_as_origin().look_at_player().align_y_to_origin(),
		PathStyle.new().follow_path(up_pathway).set_use_me_as_origin().look_at_player().align_y_to_ground_and_dirt(),
		random_pattern,
	])
	
	animation_map["attack"] = "Weapon"
	kind = World.Enemy.MOLE

func attack_state() -> AttackPatterns:
	if is_idle:
		return none_pattern
	elif vitals.health.percentage() >= 0.5:
		return random_pattern
	else:
		return none_pattern


func update_behaviour() -> void:
	super.update_behaviour()
	if is_idle:
		current_path = idle_path
		attack_sequence = null
	elif vitals.health.percentage() >= 0.5:
		attack_sequence = null
		current_path = attack_path
	else:
		attack_sequence = hide_and_attack
