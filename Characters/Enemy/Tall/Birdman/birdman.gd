class_name Birdman
extends Enemy

var none_pattern: AttackPatterns
var attack_pattern1: AttackPatterns
var attack_pattern2: AttackPatterns
var attack_pattern3: AttackPatterns

var idle_path: PathStyle
var attack_path: PathStyle

var air_small_fast := GlobalData.magic_book.copy_spell("linear")
var air_med_fast := GlobalData.magic_book.copy_spell("linear")
var air_large_fast := GlobalData.magic_book.copy_spell("linear")
var air_small_med := GlobalData.magic_book.copy_spell("linear")
var air_med_med := GlobalData.magic_book.copy_spell("linear")
var air_large_med := GlobalData.magic_book.copy_spell("linear")
var air_small_slow := GlobalData.magic_book.copy_spell("linear")
var air_med_slow := GlobalData.magic_book.copy_spell("linear")
var air_large_slow := GlobalData.magic_book.copy_spell("linear")

var air_mine := GlobalData.magic_book.copy_spell("bomb-disc-scatter")


func _ready() -> void:
	super._ready()
	
	velocity_movement = VelocityMovement.new()
	
func setup(seedling: int) -> void:
	vitals = Vitals.enemy(hp(17), mana(16), mana_regen(10), percep(4,6), atk(17), def(8), {Artifact.Element.AIR: res(5, 2)})
	
	var idle_pathway: PathStyle.Pathway = PathStyle.Pathway.new() \
		.move_to(Vector3(0, -4, 0)) \
		.line_to(Vector3(0, 20, 0), 5, PathStyle.Easing.out_quart) \
		.line_to(Vector3(0, -4, 0), 2, PathStyle.Easing.out_quart)
	idle_path = PathStyle.new(0, position).follow_path(idle_pathway).align_y_to_ground_and_air()
	
	var attack_pathway := PathStyle.Pathway.new() \
		.move_to(Vector3(10, 0, 0)) \
		.line_to(Vector3(10, fit(15,450), 0), fit(5,15), PathStyle.Easing.out_quart) \
		.wait(fit(10,5)) \
		.line_to(Vector3(10, 0, 0), 2, PathStyle.Easing.out_quart) \
		.wait(fit(4,8))
	attack_path = PathStyle.new().follow_path(attack_pathway)\
		.align_y_to_ground_and_air()\
		.set_use_player_as_origin()\
		.set_player_body_rotation_as_vision_angle(0, 0, 10.0)\
		.look_at_player_xz()
	
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	air_mine.configure({"d":"1", "Rmin":"4", "Rmax":"8", "arc":"2*pi", "S":"0", "s":"0"}, Spell.Element.AIR, fit(5,15), power(5), radius(3), fiti(5,25), 5, 300, fit(25, 75))
	air_mine.y = air_mine.y + " + t*0.0001"
	air_mine.y_expr = Expr.new(air_mine.y)
	
	air_small_fast.configure({"s":atks(5,15), "d":"Br*2+r"}, Spell.Element.AIR, 5, power(14), radius(1), 1, 25, 100, 50)
	air_med_fast.configure({"s":atks(5,15), "d":"Br*2+r"}, Spell.Element.AIR, 5, power(14), radius(2), 1, 25, 100, 50)
	air_large_fast.configure({"s":atks(5,15), "d":"Br*2+r"}, Spell.Element.AIR, 5, power(14), radius(5), 1, 25, 100, 50)
	air_small_med.configure({"s":atks(3,10), "d":"Br*2+r"}, Spell.Element.AIR, 5, power(17), radius(1), 1, 25, 100, 50)
	air_med_med.configure({"s":atks(3,10), "d":"Br*2+r"}, Spell.Element.AIR, 5, power(17), radius(2), 1, 25, 100, 50)
	air_large_med.configure({"s":atks(3,10), "d":"Br*2+r"}, Spell.Element.AIR, 5, power(17), radius(5), 1, 25, 100, 50)
	air_small_slow.configure({"s":atks(1,5), "d":"Br*2+r"}, Spell.Element.AIR, 5, power(20), radius(1), 1, 25, 100, 50)
	air_med_slow.configure({"s":atks(1,5), "d":"Br*2+r"}, Spell.Element.AIR, 5, power(20), radius(2), 1, 25, 100, 50)
	air_large_slow.configure({"s":atks(1,5), "d":"Br*2+r"}, Spell.Element.AIR, 5, power(20), radius(5), 1, 25, 100, 50)
	
	attack_pattern1 = AttackPatterns.new(
		[
			air_small_fast,
			air_small_med,
			air_small_slow,
		],
		AttackPatterns.choose_from_distribution(fit(10, 2), [ 5, 5, 7 ], -1)
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
		AttackPatterns.choose_from_distribution(fit(7, 2), [ 8, 8, 12, 20, 20, 28, 1 ], -1)
	)
	
	attack_pattern3 = AttackPatterns.new(
		[
			AttackPatterns.new(
				[air_small_slow, air_small_fast, air_mine],
				AttackPatterns.choose_in_sequence(fitas(0.75, [ 2, 1, 1 ]), 1)
			),
			AttackPatterns.new(
				[air_med_slow, air_med_fast, air_mine],
				AttackPatterns.choose_in_sequence(fitas(0.5, [ 3, 3, 1 ]), 1)
			),
			AttackPatterns.new(
				[air_large_slow, air_large_fast, air_mine],
				AttackPatterns.choose_in_sequence(fitas(0.25, [ 5, 5, 1 ]), 1)
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
		attack_pattern1.reset()
		attack_pattern2.reset()
		attack_pattern3.reset()
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
	var water_para := air_large_med.duplicate().bake(new_name)
	return water_para
