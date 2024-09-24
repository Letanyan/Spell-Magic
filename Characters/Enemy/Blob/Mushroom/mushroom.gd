class_name Mushroom
extends Enemy

var none_pattern: AttackPatterns
var basic_pattern: AttackPatterns

var idle_path: PathStyle
	
func setup(seedling: int) -> void:
	vitals = Vitals.enemy(hp(10), mana(10), mana_regen(5), 20, atk(5), def(4), {Artifact.Element.WATER: res(10, 0)})
	
	idle_path = PathStyle.still_path().align_y_to_ground()
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	var water_para1 := GlobalData.magic_book.copy_spell("loop-shot", {"H":"5"}, Spell.Element.WATER, invfit(2, 8), power(15), radius(2), 1, 50, 100, 25)
	var water_para2 := GlobalData.magic_book.copy_spell("loop-shot", {"H":"7.5"}, Spell.Element.WATER, invfit(2, 6), power(14), radius(3), 1, 50, 100, 50)
	var water_para3 := GlobalData.magic_book.copy_spell("loop-shot", {"H":"10"}, Spell.Element.WATER, invfit(2, 4), power(13), radius(4), 1, 50, 100, 75)
	var water_line1 := GlobalData.magic_book.copy_spell("linear", {"s":fits(2,10), "d":"Br*2"}, Spell.Element.WATER, fit(2, 8), power(10), radius(3), 1, 10, 200, 50)
	var water_line2 := GlobalData.magic_book.copy_spell("linear", {"s":fits(3,15), "d":"Br*2"}, Spell.Element.WATER, fit(2, 8), power(10), radius(3), 1, 10, 200, 50)
	var water_line3 := GlobalData.magic_book.copy_spell("linear", {"s":fits(4,20), "d":"Br*2"}, Spell.Element.WATER, fit(2, 8), power(10), radius(3), 1, 10, 200, 50)
	var water_down1 := GlobalData.magic_book.copy_spell("top-down", {"H": "10"}, Spell.Element.WATER, 10.0, power(8), radius(3), 1, 75, 25, 55)
	var water_down2 := GlobalData.magic_book.copy_spell("top-down", {"H": "20"}, Spell.Element.WATER, 8.0, power(10), radius(3), 1, 75, 50, 65)
	var water_down3 := GlobalData.magic_book.copy_spell("top-down", {"H": "30"}, Spell.Element.WATER, 6.0, power(12), radius(3), 1, 75, 75, 75)
	
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
			water_down1,
			water_down2,
			water_down3,
		],
		AttackPatterns.choose_from_distribution(6, [ 20, 18, 16,  14, 12, 10,  8, 6, 4 ], -1)
	)
	
	animation_map["attack"] = "Bite_Front"
	kind = World.Enemy.MUSHROOM
	

func attack_state() -> AttackPatterns:
	if is_idle:
		return none_pattern
	else:
		return basic_pattern


func update_behaviour() -> void:
	super.update_behaviour()
	current_path = idle_path

func death_box() -> Vector3:
	return Vector3(0.7, 1.9, 0.3)

func drop_artifact() -> Artifact:
	var t := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	var r := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	var b := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	var l := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	return Artifact.new(Time.get_datetime_string_from_system(), t, r, b, l)
