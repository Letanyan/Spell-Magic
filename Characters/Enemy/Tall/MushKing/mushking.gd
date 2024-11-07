class_name Mushking
extends Enemy

var none_pattern: AttackPatterns
var basic_pattern: AttackPatterns

var idle_path: PathStyle
var basic_path: PathStyle
var angry_sequence: AttackSequence

var water_para1 := GlobalData.magic_book.copy_spell("loop-shot")
var water_para2 := GlobalData.magic_book.copy_spell("loop-shot")
var water_para3 := GlobalData.magic_book.copy_spell("loop-shot")
var water_line1 := GlobalData.magic_book.copy_spell("linear")
var water_line2 := GlobalData.magic_book.copy_spell("linear")
var water_line3 := GlobalData.magic_book.copy_spell("linear")
var water_flurry1 := GlobalData.magic_book.copy_spell("linear-flurry")
var water_flurry2 := GlobalData.magic_book.copy_spell("linear-flurry")
var water_flurry3 := GlobalData.magic_book.copy_spell("linear-flurry")

var water_shower1 := GlobalData.magic_book.copy_spell("line")
var water_shower1_chain := GlobalData.magic_book.copy_spell("linear-flurry")
	
func setup(seedling: int, biome: World.Biome) -> void:
	vitals = Vitals.enemy(hp(17), mana(16), mana_regen(16), percep(4,8), atk(14), def(8), {Artifact.Element.WATER: res(16, 0), Artifact.Element.ROCK: res(16,0)})
	
	idle_path = PathStyle.new(0, position).follow_path(Pathway.empty(1))
	basic_path = PathStyle.new(0, position).towards_player(1, 3, 4).player_vision_is_camera(PI, 0, 2, 3).look_at_player_xz().align_y_to_ground()
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	water_para1.configure({"H":"5"}, Spell.Element.WATER, fit(8, 2), power(15), radius(2), 1, 50, 100, 25)
	water_para2.configure({"H":"7.5"}, Spell.Element.WATER, fit(6, 2), power(14), radius(3), 1, 50, 100, 50)
	water_para3.configure({"H":"10"}, Spell.Element.WATER, fit(4, 2), power(13), radius(4), 1, 50, 100, 75)
	water_line1.configure({"s":atks(2,7), "d":"Br*2"}, Spell.Element.WATER, fit(2, 8), power(10), radius(3), 1, 10, 200, 50)
	water_line2.configure({"s":atks(3,8), "d":"Br*2"}, Spell.Element.WATER, fit(2, 8), power(10), radius(3), 1, 10, 200, 50)
	water_line3.configure({"s":atks(4,9), "d":"Br*2"}, Spell.Element.WATER, fit(2, 8), power(10), radius(3), 1, 10, 200, 50)
	water_flurry1.configure({"s":atks(1,15), "R":fits(PI*0.2, PI*0.5)}, Spell.Element.WATER, fit(5,10), power(7), radius(4), fiti(3,20), 10, 100, fit(50,75))
	water_flurry2.configure({"s":atks(2,15), "R":fits(PI*0.2, PI*0.5)}, Spell.Element.WATER, fit(5,10), power(4), radius(3), fiti(3,15), 10, 200, fit(50,75))
	water_flurry3.configure({"s":atks(3,15), "R":fits(PI*0.1, PI*0.2)}, Spell.Element.WATER, fit(5,10), power(2), radius(2), fiti(3,10), 10, 300, fit(50,75))
	water_shower1.configure({"sx":"u*Br","sy":"v*Br","sz":"w*Br","ex":"u*C","ey":"C*v","ez":"C*w"}, Spell.Element.WATER, 5.0, power(5), radius(2), 1, 60.0, 80.0, 0.0, water_shower1_chain)
	water_shower1_chain.configure({"s":fits(2,6), "d": "C", "dx":"0", "dy":"-1", "dz":"0", "oy": "u*d*10", "r": "fl * 6 + 4"}, Spell.Element.WATER, 20.0, power(6), radius(2), fiti(5, 20), 30.0, 50.0, 60.0)
	
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
		AttackPatterns.choose_from_distribution(fit(6,1), [ 20, 18, 16,  14, 12, 10,  8, 6, 4 ], -1)
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
		AttackPatterns.choose_from_distribution(fit(3,0.5), [ 20, 18, 16,  14, 12, 10,  8, 6, 4 ], 2)
	)
	
	var Z := Vector3.ZERO
	var U := -bounds.y * 2.5
	var up_pathway := Pathway.new() \
		.move_to(Vector3(0, U, 0)) \
		.line_to(Z, runs(12), Easing.linear) \
		.wait(fit(8,2))
	var down_pathway := Pathway.new() \
		.move_to(Z) \
		.line_to(Vector3(0, U, 0), runs(12), Easing.linear) \
		.wait(fit(2,8))
	angry_sequence = AttackSequence.new(true, [
		PathStyle.new().follow_path(down_pathway).origin_is_me().look_at_player_xz().align_y_to_ground_and_dirt(),
		PathStyle.new().follow_path(Pathway.empty(5)).player_vision_is_body_rotation(0, 2, 1, 1).align_y_to_ground_air_and_dirt(),
		PathStyle.new().follow_path(up_pathway).origin_is_me().look_at_player_xz().align_y_to_ground_and_dirt(),
		basic_pattern_sequence,
	])
	
	animation_map["attack"] = "Weapon"
	kind = World.Enemy.MUSHKING
	super.setup(seedling, biome)

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
	var new_name := player.name_generator.italian_names.generate(8, 2)
	return Artifact.new(new_name, t, r, b, l)

func drop_spell() -> Spell:
	var new_name := player.name_generator.latin_names.generate(6, 2)
	var water_para := GlobalData.magic_book.copy_and_configure_spell("loop-shot", {"H":"4", "speed":"4"}, Spell.Element.AIR, 3, 5, 0.1, 1, 0, 0, 0).bake(new_name)
	return water_para
