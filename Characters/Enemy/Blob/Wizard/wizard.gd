class_name Wizard
extends Enemy

var none_pattern: AttackPatterns
var random_pattern1: AttackPatterns
var random_pattern2: AttackPatterns

var idle_path: PathStyle
var attack_path: PathStyle

var fire1 := GlobalData.magic_book.copy_spell("linear")
var water1 := GlobalData.magic_book.copy_spell("linear")
var elec1 := GlobalData.magic_book.copy_spell("linear")
var ice1 := GlobalData.magic_book.copy_spell("linear")

var fire_circle := GlobalData.magic_book.copy_spell("circle")
var fire_circle_line := GlobalData.magic_book.copy_spell("line")
var water_circle := GlobalData.magic_book.copy_spell("circle")
var water_circle_line := GlobalData.magic_book.copy_spell("line")
var elec_circle := GlobalData.magic_book.copy_spell("circle")
var elec_circle_line := GlobalData.magic_book.copy_spell("line")
var ice_circle := GlobalData.magic_book.copy_spell("circle")
var ice_circle_line := GlobalData.magic_book.copy_spell("line")
	
func setup(seedling: int) -> void:
	vitals = Vitals.enemy(hp(5), mana(20), mana_regen(10), percep(1,4), atk(20), def(2), {Artifact.Element.FIRE: res(-10, 0), Artifact.Element.WATER: res(10, 0)})
	
	var circle_path := PathStyle.Pathway.new().random_points_in_disc(1, 0, 2, 0, 3)
	idle_path = PathStyle.new(0, position).follow_path(circle_path).align_y_to_ground()
	
	attack_path = PathStyle.new(randi(), position).towards_player(fit(1,10), 1, 2).align_y_to_ground().look_at_player()
	
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	fire1.configure({"s": atks(1,20), "d": "2"}, Spell.Element.FIRE, 10.0, power(18), radius(5), 1, 50, 150, 75)
	water1.configure({"s": atks(1,20), "d": "2"}, Spell.Element.WATER, 8.0, power(18), radius(5), 1, 50, 150, 75)
	elec1.configure({"s": atks(1,20), "d": "2"}, Spell.Element.ELECTRIC, 6.0, power(18), radius(5), 1, 50, 150, 75)
	ice1.configure({"s": atks(1,20), "d": "2"}, Spell.Element.ICE, 6.0, power(18), radius(5), 1, 50, 150, 75)
	
	fire_circle.configure({"cx":"C*u","cy":"C*v","cz":"C*w","ux":"0","uy":"1","uz":"0","rots":fits(2,10),"R":fits(3,10)}, Spell.Element.FIRE, fit(4,15), power(1), radius(2), 1, 5, 100, 0, fire_circle_line)
	fire_circle_line.configure({"sx":"0","sy":"0","sz":"0","ex":"C*u","ey":"C*v","ez":"C*w"}, Spell.Element.FIRE, fit(5,2), power(18), radius(7), fiti(3,15), 70, 150, 75)
	fire_circle_line.set_delay("n*"+fits(2,0.5))
	
	water_circle.configure({"cx":"C*u","cy":"C*v","cz":"C*w","ux":"0","uy":"1","uz":"0","rots":fits(2,10),"R":fits(3,10)}, Spell.Element.WATER, fit(4,15), power(1), radius(2), 1, 5, 100, 0, fire_circle_line)
	water_circle_line.configure({"sx":"0","sy":"0","sz":"0","ex":"C*u","ey":"C*v","ez":"C*w"}, Spell.Element.WATER, fit(5,2), power(18), radius(7), fiti(3,15), 70, 150, 75)
	water_circle_line.set_delay("n*"+fits(2,0.5))
	
	elec_circle.configure({"cx":"C*u","cy":"C*v","cz":"C*w","ux":"0","uy":"1","uz":"0","rots":fits(2,10),"R":fits(3,10)}, Spell.Element.ELECTRIC, fit(4,15), power(1), radius(2), 1, 5, 100, 0, fire_circle_line)
	elec_circle_line.configure({"sx":"0","sy":"0","sz":"0","ex":"C*u","ey":"C*v","ez":"C*w"}, Spell.Element.ELECTRIC, fit(5,2), power(18), radius(7), fiti(3,15), 70, 150, 75)
	elec_circle_line.set_delay("n*"+fits(2,0.5))
	
	ice_circle.configure({"cx":"C*u","cy":"C*v","cz":"C*w","ux":"0","uy":"1","uz":"0","rots":fits(2,10),"R":fits(3,10)}, Spell.Element.ICE, fit(4,15), power(1), radius(2), 1, 5, 100, 0, fire_circle_line)
	ice_circle_line.configure({"sx":"0","sy":"0","sz":"0","ex":"C*u","ey":"C*v","ez":"C*w"}, Spell.Element.ICE, fit(5,2), power(18), radius(7), fiti(3,15), 70, 150, 75)
	ice_circle_line.set_delay("n*"+fits(2,0.5))
	
	random_pattern1 = AttackPatterns.new(
		[
			fire1,
			water1,
			elec1,
			ice1,
		],
		AttackPatterns.choose_from_distribution(fit(5, 0.5), [ 5, 5, 5, 5 ], -1)
	)
	
	random_pattern2 = AttackPatterns.new(
		[
			AttackPatterns.new(
				[
					fire_circle,
					water_circle,
					elec_circle,
					ice_circle,
				],
				AttackPatterns.choose_from_distribution(fit(5, 0.5), [ 5, 5, 5, 5 ], 1)
			),
			AttackPatterns.new(
				[
					fire1,
					water1,
					elec1,
					ice1,
				],
				AttackPatterns.choose_from_distribution(fit(5, 0.5), [ 5, 5, 5, 5 ], 5)
			)
		],
		AttackPatterns.choose_in_sequence(fitas(0.1, [3, 25]))
	)
	
	animation_map["attack"] = "Bite_Front"
	kind = World.Enemy.WIZARD
	super.setup(seedling)
	

func attack_state() -> AttackPatterns:
	if is_idle:
		return none_pattern
	elif vitals.health.percentage() > 0.7:
		return random_pattern1
	else:
		return random_pattern2


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
