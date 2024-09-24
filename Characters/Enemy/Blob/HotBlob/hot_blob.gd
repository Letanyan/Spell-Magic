class_name HotBlob
extends Enemy

var none_pattern: AttackPatterns
var random_pattern: AttackPatterns
var sequence_pattern: AttackPatterns

var idle_path: PathStyle
var attack_path: PathStyle
	
func setup(seedling: int) -> void:
	vitals = Vitals.enemy(hp(10), mana(18), mana_regen(20), 30, atk(12), def(12), {Artifact.Element.FIRE: res(15, 5)})
	
	idle_path = PathStyle.new(0, position).random_points_in_circle(1, 2, 0, 3).align_y_to_ground()
	
	attack_path = PathStyle.new(randi(), position).towards_player(1, 1, 2).set_use_player_as_origin().align_y_to_ground().look_at_player()
	
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	var fire1 := GlobalData.magic_book.copy_spell("linear", {"s": "5", "d": "2"}, Spell.Element.FIRE, 10.0, power(10), radius(2), 1, 50, 50, 55)
	var fire2 := GlobalData.magic_book.copy_spell("linear", {"s": "5", "d": "2"}, Spell.Element.FIRE, 8.0, power(12), radius(2), 1, 50, 50, 65)
	var fire3 := GlobalData.magic_book.copy_spell("linear", {"s": "10", "d": "2"}, Spell.Element.FIRE, 6.0, power(18), radius(2), 1, 50, 50, 75)
	
	var fire_down1 := GlobalData.magic_book.copy_spell("top-down", {"H": "10"}, Spell.Element.FIRE, 10.0, power(8), radius(3), 1, 75, 25, 55)
	var fire_down2 := GlobalData.magic_book.copy_spell("top-down", {"H": "20"}, Spell.Element.FIRE, 8.0, power(10), radius(3), 1, 75, 50, 65)
	var fire_down3 := GlobalData.magic_book.copy_spell("top-down", {"H": "30"}, Spell.Element.FIRE, 6.0, power(12), radius(3), 1, 75, 75, 75)
	
	var fire_mine1 := GlobalData.magic_book.copy_spell("bomb-sphere-scatter", {"d": "1", "Rmin": "4", "Rmax": "8", "S":"1", "s":"0"}, Spell.Element.FIRE, 5.0, power(5), radius(5), fiti(4, 15), 33, 66, 25)
	var fire_mine2 := GlobalData.magic_book.copy_spell("bomb", {"d":"1", "S":"1", "s":"0.5"}, Spell.Element.FIRE, 7.0, power(9), radius(7), fiti(2, 8), 75, 120, 50)
	var fire_mine3 := GlobalData.magic_book.copy_spell("bomb-linear", {"d": "1", "R": "10", "S":"1.5-fl", "s":"lerp(fl, 2, 0.1)"}, Spell.Element.FIRE, 5.0, power(15), radius(3), fiti(5, 10), 70, 180, 60)
	
	random_pattern = AttackPatterns.new(
		[
			fire_mine1,
			fire_mine2,
			fire_mine3,
		],
		AttackPatterns.choose_from_distribution(5.0, [ 10, 5, 2 ], -1)
	)
	
	sequence_pattern = AttackPatterns.new(
		[
			fire1,
			fire2,
			fire3,
			fire_down1,
			fire3,
			fire2,
			fire1,
			fire_down2,
			fire2,
			fire1,
			fire3,
			fire_down3,
		],
		AttackPatterns.choose_in_sequence([ 1, 1, 1, 5, 1, 1, 1, 5, 1, 1, 1, 5  ], -1)
	)
	
	animation_map["attack"] = "Bite_Front"
	kind = World.Enemy.HOT_BLOB
	

func attack_state() -> AttackPatterns:
	if is_idle:
		return none_pattern
	elif vitals.health.percentage() > 0.5:
		return sequence_pattern
	else:
		return random_pattern


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
