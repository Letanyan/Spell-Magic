class_name Wizard
extends Enemy

var none_pattern: AttackPatterns
var random_pattern: AttackPatterns

var idle_path: PathStyle
var attack_path: PathStyle

var fire1 := GlobalData.magic_book.copy_spell("linear")
var water1 := GlobalData.magic_book.copy_spell("linear")
var elec1 := GlobalData.magic_book.copy_spell("linear")
var ice1 := GlobalData.magic_book.copy_spell("linear")
	
func setup(seedling: int) -> void:
	vitals = Vitals.enemy(hp(15), mana(10), mana_regen(10), percep(1,4), atk(10), def(10), {Artifact.Element.FIRE: res(-10, 0), Artifact.Element.WATER: res(10, 0)})
	
	var circle_path := PathStyle.Pathway.new().random_points_in_disc(1, 0, 2, 0, 3)
	idle_path = PathStyle.new(0, position).follow_path(circle_path).align_y_to_ground()
	
	attack_path = PathStyle.new(randi(), position).towards_player(fit(1,10), 1, 2).align_y_to_ground().look_at_player()
	
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	fire1.configure({"s": atks(1,20), "d": "2"}, Spell.Element.FIRE, 10.0, power(18), radius(5), 1, 50, 150, 75)
	water1.configure({"s": atks(1,20), "d": "2"}, Spell.Element.WATER, 8.0, power(18), radius(5), 1, 50, 150, 75)
	elec1.configure({"s": atks(1,20), "d": "2"}, Spell.Element.ELECTRIC, 6.0, power(18), radius(5), 1, 50, 150, 75)
	ice1.configure({"s": atks(1,20), "d": "2"}, Spell.Element.ICE, 6.0, power(18), radius(5), 1, 50, 150, 75)
	
	random_pattern = AttackPatterns.new(
		[
			fire1,
			water1,
			elec1,
			ice1,
		],
		AttackPatterns.choose_from_distribution(fit(5, 0.5), [ 5, 5, 5, 5 ], -1)
	)
	
	animation_map["attack"] = "Bite_Front"
	kind = World.Enemy.WIZARD
	

func attack_state() -> AttackPatterns:
	if is_idle:
		return none_pattern
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
	var new_name := player.name_generator.constellations.generate(8, 2)
	return Artifact.new(new_name, t, r, b, l)
