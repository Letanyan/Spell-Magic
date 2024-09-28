class_name Fungi
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
var water_down1 := GlobalData.magic_book.copy_spell("top-down")
var water_down2 := GlobalData.magic_book.copy_spell("top-down")
var water_down3 := GlobalData.magic_book.copy_spell("top-down")
var water_shower1 := GlobalData.magic_book.copy_spell("linear")
var water_shower1_chain := GlobalData.magic_book.copy_spell("linear-flurry")
	
func setup(seedling: int) -> void:
	vitals = Vitals.enemy(hp(13), mana(13), mana_regen(13), percep(1,4), atk(8), def(4), {Artifact.Element.WATER: res(12, 0)})
	
	idle_path = PathStyle.new(0, position).follow_path(PathStyle.Pathway.empty(1))
	basic_path = PathStyle.new(0, position).follow_path(PathStyle.Pathway.empty(1)).look_at_player_xz()
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	water_para1.configure({"H":"5"}, Spell.Element.WATER, fit(8, 2), power(15), radius(2), 1, 50, 100, 25)
	water_para2.configure({"H":"7.5"}, Spell.Element.WATER, fit(6, 2), power(14), radius(3), 1, 50, 100, 50)
	water_para3.configure({"H":"10"}, Spell.Element.WATER, fit(4, 2), power(13), radius(4), 1, 50, 100, 75)
	water_line1.configure({"s":atks(2,10), "d":"Br*2"}, Spell.Element.WATER, fit(2, 8), power(10), radius(3), 1, 10, 200, 50)
	water_line2.configure({"s":atks(3,12), "d":"Br*2"}, Spell.Element.WATER, fit(2, 8), power(10), radius(3), 1, 10, 200, 50)
	water_line3.configure({"s":atks(4,14), "d":"Br*2"}, Spell.Element.WATER, fit(2, 8), power(10), radius(3), 1, 10, 200, 50)
	water_down1.configure({"H": "10"}, Spell.Element.WATER, fit(10,3), power(8), radius(3), 1, 75, 25, 55)
	water_down2.configure({"H": "20"}, Spell.Element.WATER, fit(8,4), power(10), radius(3), 1, 75, 50, 65)
	water_down3.configure({"H": "30"}, Spell.Element.WATER, fit(6,5), power(12), radius(3), 1, 75, 75, 75)
	# FIXME: [1]
	water_shower1.configure({"s":fits(3,8), "d":"Br*2", "rv": "rv+pi/8"}, Spell.Element.WATER, 5.0, power(5), radius(2), 1, 60.0, 80.0, 0.0, water_shower1_chain)
	water_shower1_chain.configure({"s":fits(2,6), "d": "C", "dx":"0", "dy":"-1", "dz":"0", "oy": "u*d*10", "r": "fl * 6 + 4"}, Spell.Element.WATER, 20.0, power(6), radius(2), fiti(5, 20), 30.0, 50.0, 60.0)
		
	
	basic_pattern = AttackPatterns.new(
		[
			water_line1,
			water_line2,
			water_line3,
			water_para1,
			water_para2,
			water_para3,
			water_down1,
			water_down2,
			water_down3,
		],
		AttackPatterns.choose_from_distribution(fit(6,2), [ 20, 18, 16,  14, 12, 10,  8, 6, 4 ], -1)
	)
	
	var basic_pattern_sequence := AttackPatterns.new(
		[
			water_line1,
			water_line2,
			water_line3,
			water_para1,
			water_para2,
			water_para3,
			water_down1,
			water_down2,
			water_down3,
		],
		AttackPatterns.choose_from_distribution(fit(3,1), [ 20, 18, 16,  14, 12, 10,  8, 6, 4 ], 2)
	)
	
	var Z := Vector3.ZERO
	var U := -bounds.y * 2.5
	var up_pathway := PathStyle.Pathway.new() \
		.move_to(Vector3(0, U, 0)).line_to(Z, 3, PathStyle.Easing.linear)
	var down_pathway := PathStyle.Pathway.new() \
		.move_to(Z).line_to(Vector3(0, U, 0), 3, PathStyle.Easing.linear).wait(6)
	angry_sequence = AttackSequence.new(true, [
		PathStyle.new().follow_path(down_pathway).set_use_me_as_origin().look_at_player_xz().align_y_to_ground_and_dirt(),
		PathStyle.new().follow_path(up_pathway).set_use_me_as_origin().look_at_player_xz().align_y_to_ground_and_dirt(),
		basic_pattern_sequence,
	])
	
	animation_map["attack"] = "Bite_Front"
	kind = World.Enemy.FUNGI
	

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
