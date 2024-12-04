class_name Frog
extends Enemy

var none_pattern: AttackPatterns
var attack_pattern1: AttackPatterns
var attack_pattern2: AttackPatterns

var idle_path: PathStyle
var attack_path: PathStyle

var water_flurry1 := GlobalData.magic_book.copy_spell("linear-flurry")
var water_flurry2 := GlobalData.magic_book.copy_spell("linear-flurry")
var water_flurry3 := GlobalData.magic_book.copy_spell("linear-flurry")
var water_attack1 := GlobalData.magic_book.copy_spell("linear")
var water_attack2 := GlobalData.magic_book.copy_spell("linear")
var water_attack3 := GlobalData.magic_book.copy_spell("linear")
	
func setup(seedling: int, biome: World.Biome) -> void:
	vitals = Vitals.enemy(hp(13), mana(12), mana_regen(8), percep(1,2), atk(7), def(6), {Artifact.Element.WATER: res(15, 5)})
	
	var idle_pathway := Pathway.new() \
		.move_to(Vector3(0, 0, 0)) \
		.quad_to(Vector3(20, 0, 0), Vector3(10, 20, 0), runs(10), Easing.out_quart) \
		.quad_to(Vector3(0, 0, 20), Vector3(10, 20, 10), runs(10), Easing.out_quart) \
		.quad_to(Vector3(20, 0, 20), Vector3(10, 20, 20), runs(10), Easing.out_quart) \
		.quad_to(Vector3(0, 0, 0), Vector3(10, 20, 10), runs(10), Easing.out_quart)
		
	idle_path = PathStyle.new(seedling, position).follow_path(idle_pathway).align_y_to_ground_and_air() \
		.initial_position_can_update_on_ground()
	
	attack_path = PathStyle.new(seedling).follow_path(idle_pathway)\
		.align_y_to_ground_and_air()\
		.origin_is_player() \
		.player_vision_is_body_rotation(0, 0, 10.0)\
		.look_at_player_xz() \
		.initial_position_can_update_on_ground()
	
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	water_flurry1.configure({"s":atks(1,10), "R":fits(PI*0.2, PI*0.5)}, Spell.Element.WATER, fit(5,10), power(7), radius(4), fiti(3,20), 10, 100, fit(50,75))
	water_flurry2.configure({"s":atks(2,10), "R":fits(PI*0.2, PI*0.5)}, Spell.Element.WATER, fit(5,10), power(4), radius(3), fiti(3,15), 10, 200, fit(50,75))
	water_flurry3.configure({"s":atks(3,10), "R":fits(PI*0.1, PI*0.2)}, Spell.Element.WATER, fit(5,10), power(2), radius(2), fiti(3,10), 10, 300, fit(50,75))
	water_attack1.configure({"s":atks(1,10)}, Spell.Element.WATER, fit(3,15), power(7), radius(4), 1, 10, 100, fit(50,75))
	water_attack2.configure({"s":atks(2,10)}, Spell.Element.WATER, fit(3,15), power(4), radius(3), 1, 10, 200, fit(50,75))
	water_attack3.configure({"s":atks(3,10)}, Spell.Element.WATER, fit(3,15), power(2), radius(2), 1, 10, 300, fit(50,75))
	
	spell_drop_probs = {
		water_flurry1: spell_drop(7),
		water_flurry2: spell_drop(8),
		water_flurry3: spell_drop(9),
		water_attack1: spell_drop(1),
		water_attack2: spell_drop(2),
		water_attack3: spell_drop(3),
	}
	
	attack_pattern1 = AttackPatterns.new(
		[
			water_flurry1,
			water_attack1,
			water_attack2,
			water_attack1,
			water_flurry1,
		],
		AttackPatterns.choose_in_sequence([ fit(5,2), fit(4,1), fit(5,2), fit(4,1), fit(5,2) ], -1)
	)
	
	attack_pattern2 = AttackPatterns.new(
		[
			water_flurry1,
			water_flurry2,
			water_flurry3,
			water_attack1,
			water_attack3,
		],
		AttackPatterns.choose_from_distribution(fit(5,2), [ 5, 4, 3, 1 ], -1)
	)
	
	
	animation_map["attack"] = "Weapon"
	kind = World.Enemy.FROG
	super.setup(seedling, biome)


func update_behaviour() -> void:
	super.update_behaviour()
	if is_idle:
		set_path_and_attack(idle_path, none_pattern)
	elif vitals.health.percentage() > 0.1:
		set_path_and_attack(attack_path, attack_pattern1)
	else:
		set_path_and_attack(attack_path, attack_pattern2)
			

func drop_artifact() -> Artifact:
	var t := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	var r := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	var b := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	var l := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	var new_name := player.name_generator.french_names.generate(8, 2)
	return Artifact.new(new_name, t, r, b, l)
