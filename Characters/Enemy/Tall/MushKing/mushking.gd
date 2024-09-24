class_name Mushking
extends Enemy

var none_pattern: AttackPatterns
var basic_pattern: AttackPatterns

var idle_path: PathStyle
var basic_path: PathStyle
var angry_sequence: AttackSequence

func _ready() -> void:
	super._ready()
	
	velocity_movement = VelocityMovement.new()
	
func setup(seedling: int) -> void:
	vitals = Vitals.enemy(hp(17), mana(16), mana_regen(16), 40, atk(14), def(8), {Artifact.Element.WATER: res(16, 0), Artifact.Element.ROCK: res(16,0)})
	
	idle_path = PathStyle.new(0, position).follow_path(PathStyle.Pathway.empty(1))
	basic_path = PathStyle.new(0, position).towards_player(1, 3, 4).look_at_player_xz().align_y_to_ground()
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	var water_para1 := GlobalData.magic_book.copy_spell("loop-shot", {"H":"5"}, Spell.Element.WATER, invfit(2, 8), power(15), radius(2), 1, 50, 100, 25)
	var water_para2 := GlobalData.magic_book.copy_spell("loop-shot", {"H":"7.5"}, Spell.Element.WATER, invfit(2, 6), power(14), radius(3), 1, 50, 100, 50)
	var water_para3 := GlobalData.magic_book.copy_spell("loop-shot", {"H":"10"}, Spell.Element.WATER, invfit(2, 4), power(13), radius(4), 1, 50, 100, 75)
	var water_line1 := GlobalData.magic_book.copy_spell("linear", {"s":fits(2,10), "d":"Br*2"}, Spell.Element.WATER, fit(2, 8), power(10), radius(3), 1, 10, 200, 50)
	var water_line2 := GlobalData.magic_book.copy_spell("linear", {"s":fits(3,15), "d":"Br*2"}, Spell.Element.WATER, fit(2, 8), power(10), radius(3), 1, 10, 200, 50)
	var water_line3 := GlobalData.magic_book.copy_spell("linear", {"s":fits(4,20), "d":"Br*2"}, Spell.Element.WATER, fit(2, 8), power(10), radius(3), 1, 10, 200, 50)
	var water_flurry1 := GlobalData.magic_book.copy_spell("linear-flurry", {"s":fits(3,15), "R":fits(PI*0.2, PI*0.5)}, Spell.Element.WATER, fit(5,10), power(7), radius(4), fiti(3,20), 10, 100, fit(50,75))
	var water_flurry2 := GlobalData.magic_book.copy_spell("linear-flurry", {"s":fits(6,15), "R":fits(PI*0.2, PI*0.5)}, Spell.Element.WATER, fit(5,10), power(4), radius(3), fiti(3,15), 10, 200, fit(50,75))
	var water_flurry3 := GlobalData.magic_book.copy_spell("linear-flurry", {"s":fits(9,15), "R":fits(PI*0.1, PI*0.2)}, Spell.Element.WATER, fit(5,10), power(2), radius(2), fiti(3,10), 10, 300, fit(50,75))
	
	
	var water_shower1 := GlobalData.magic_book.copy_spell("linear", {"s":fits(3,8), "d":"Br*2", "rv": "rv+pi/8"}, Spell.Element.WATER, 5.0, power(5), radius(2), 1, 60.0, 80.0, 0.0)
	water_shower1.chain = GlobalData.magic_book.copy_spell("linear-flurry", {"s":fits(2,6), "d": "C", "dx":"0", "dy":"-1", "dz":"0", "oy": "u*d*10", "r": "fl * 6 + 4"}, Spell.Element.WATER, 20.0, power(6), radius(2), fiti(5, 20), 30.0, 50.0, 60.0)
	
	basic_pattern = AttackPatterns.new(
		[
			water_line1,
			water_line2,
			water_line3,
			water_para1,
			water_para2,
			water_para3,
			water_flurry1,
			water_flurry2,
			water_flurry3,
		],
		AttackPatterns.choose_from_distribution(6, [ 20, 18, 16,  14, 12, 10,  8, 6, 4 ], -1)
	)
	
	var basic_pattern_sequence := AttackPatterns.new(
		[
			water_line1,
			water_line2,
			water_line3,
			water_para1,
			water_para2,
			water_para3,
			water_flurry1,
			water_flurry2,
			water_flurry3,
		],
		AttackPatterns.choose_from_distribution(3, [ 20, 18, 16,  14, 12, 10,  8, 6, 4 ], 2)
	)
	
	var Z := Vector3.ZERO
	var U := -bounds.y * 2.5
	var up_pathway := PathStyle.Pathway.new() \
		.move_to(Vector3(0, U, 0)).line_to(Z, 3, PathStyle.Easing.linear)
	var down_pathway := PathStyle.Pathway.new() \
		.move_to(Z).line_to(Vector3(0, U, 0), 3, PathStyle.Easing.linear).wait(6)
	angry_sequence = AttackSequence.new(true, [
		PathStyle.new().follow_path(down_pathway).set_use_me_as_origin().look_at_player_xz().align_y_to_ground_and_dirt(),
		PathStyle.new().follow_path(PathStyle.Pathway.empty(5)).set_player_body_rotation_as_vision_angle(0, 2, 1, 1).align_y_to_origin(),
		PathStyle.new().follow_path(up_pathway).set_use_me_as_origin().look_at_player_xz().align_y_to_ground_and_dirt(),
		basic_pattern_sequence,
	])
	
	animation_map["attack"] = "Weapon"
	kind = World.Enemy.MUSHKING

func attack_state() -> AttackPatterns:
	if is_idle:
		return none_pattern
	elif vitals.health.percentage() > 0.75:
		return basic_pattern
	else:
		return none_pattern


func update_behaviour() -> void:
	super.update_behaviour()
	if is_idle:
		current_path = idle_path
		attack_sequence = null
	elif vitals.health.percentage() >= 0.75:
		current_path = basic_path
		attack_sequence = null
	else:
		attack_sequence = angry_sequence
			

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
