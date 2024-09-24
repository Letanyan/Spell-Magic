class_name Rabbit
extends Enemy

var none_pattern: AttackPatterns
var attack_pattern1: AttackPatterns
var attack_pattern2: AttackPatterns
var attack_pattern3: AttackPatterns

var idle_path: PathStyle
var attack_path: PathStyle


func _ready() -> void:
	super._ready()
	
	velocity_movement = VelocityMovement.new()
	
func setup(seedling: int) -> void:
	vitals = Vitals.enemy(hp(12), mana(10), mana_regen(8), 15, atk(12), def(12), {Artifact.Element.AIR: res(5, 2)})
	
	var idle_pathway: PathStyle.Pathway = PathStyle.Pathway.new() \
		.move_to(Vector3(0, 0, 0)) \
		.quad_to(Vector3(20, 0, 0), Vector3(10, 20, 0), 2, PathStyle.Easing.out_quart) \
		.quad_to(Vector3(0, 0, 20), Vector3(10, 20, 10), 2, PathStyle.Easing.out_quart) \
		.quad_to(Vector3(20, 0, 20), Vector3(10, 20, 20), 2, PathStyle.Easing.out_quart) \
		.quad_to(Vector3(0, 0, 0), Vector3(10, 20, 10), 2, PathStyle.Easing.out_quart)
	idle_path = PathStyle.new(0, position).follow_path(idle_pathway).align_y_to_ground_and_jump() \
		.set_initial_position_can_update(PathStyle.InitialPositionCanUpdate.ON_GROUND)
	
	attack_path = PathStyle.new().follow_path(idle_pathway)\
		.align_y_to_ground_and_jump()\
		.set_use_player_as_origin() \
		.set_player_body_rotation_as_vision_angle(0, 0, 10.0)\
		.look_at_player_xz() \
		.set_initial_position_can_update(PathStyle.InitialPositionCanUpdate.ON_GROUND)
	
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	var air_spell := GlobalData.magic_book.copy_spell("linear", {}, Spell.Element.AIR, 5, power(19), radius(8), 1, 25, 150, 50)
	var air_mine := GlobalData.magic_book.copy_spell("bomb-disc-scatter", {"d":"1", "Rmin":"4", "Rmax":"8", "arc":"2*pi", "S":"0", "s":"0"}, Spell.Element.AIR, fit(5,15), power(5), radius(3), fiti(5,25), 5, 300, fit(25, 75))
	air_mine.y = air_mine.y + " + t*0.0001"
	air_mine.y_expr = Expr.new(air_mine.y)
	
	var air_fast := air_spell.duplicate({"s":fits(5,25), "d":"Br*2+r"})
	air_fast.power = power(14)
	var air_small_fast := air_fast.duplicate()
	air_small_fast.radius = 1
	var air_med_fast := air_fast.duplicate()
	air_med_fast.radius = 2
	var air_large_fast := air_fast.duplicate()
	air_large_fast.radius = 5
	
	var air_med := air_spell.duplicate({"s":fits(3,15), "d":"Br*2+r"})
	air_med.power = power(17)
	var air_small_med := air_med.duplicate()
	air_small_med.radius = 1
	var air_med_med := air_med.duplicate()
	air_med_med.radius = 2
	var air_large_med := air_med.duplicate()
	air_large_med.radius = 5
	
	var air_slow := air_spell.duplicate({"s":fits(2,10), "d":"Br*2+r"})
	air_slow.power = power(20)
	var air_small_slow := air_slow.duplicate()
	air_small_slow.radius = 1
	var air_med_slow := air_slow.duplicate()
	air_med_slow.radius = 2
	var air_large_slow := air_slow.duplicate()
	air_large_slow.radius = 5
	
	
	
	attack_pattern1 = AttackPatterns.new(
		[
			air_small_fast,
			air_small_med,
			air_small_slow,
		],
		AttackPatterns.choose_from_distribution(10.0, [ 5, 5, 7 ], -1)
	)
	
	attack_pattern2 = AttackPatterns.new(
		[
			air_small_fast,
			air_small_med,
			air_small_slow,
			air_med_fast,
			air_med_med,
			air_med_slow,
			air_mine,
		],
		AttackPatterns.choose_from_distribution(7.0, [ 8, 8, 12, 20, 20, 28, 1 ], -1)
	)
	
	attack_pattern3 = AttackPatterns.new(
		[
			AttackPatterns.new(
				[air_small_slow, air_small_fast, air_mine],
				AttackPatterns.choose_in_sequence([ 2, 1, 1 ], 1)
			),
			AttackPatterns.new(
				[air_med_slow, air_med_fast, air_mine],
				AttackPatterns.choose_in_sequence([ 3, 3, 1 ], 1)
			),
			AttackPatterns.new(
				[air_large_slow, air_large_fast, air_mine],
				AttackPatterns.choose_in_sequence([ 5, 5, 1 ], 1)
			),
		],
		AttackPatterns.choose_from_distribution(1, [ 2, 3, 5 ], -1)
	)
	
	animation_map["attack"] = "Weapon"
	kind = World.Enemy.BIRDMAN

func attack_state() -> AttackPatterns:
	if is_idle:
		return none_pattern
	elif vitals.health.percentage() > 0.5:
		return attack_pattern1
	elif vitals.health.percentage() > 0.25:
		return attack_pattern2
	else:
		return attack_pattern3


func update_behaviour() -> void:
	super.update_behaviour()
	if is_idle:
		current_path = idle_path
	else:
		current_path = attack_path
			

func drop_artifact() -> Artifact:
	var t := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	var r := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	var b := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	var l := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	return Artifact.new(Time.get_datetime_string_from_system(), t, r, b, l)

func drop_spell() -> Spell:
	var new_name := player.name_generator.latin_names.generate(6, 2)
	var water_para := GlobalData.magic_book.copy_spell("loop-shot", {"H":"4", "speed":"4"}, Spell.Element.AIR, 3, 5, 0.1, 1, 0, 0, 0).bake(new_name)
	return water_para
