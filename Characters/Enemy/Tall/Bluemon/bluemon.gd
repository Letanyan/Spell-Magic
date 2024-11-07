class_name Bluemon
extends Enemy

var none_pattern: AttackPatterns
var attack_pattern1: AttackPatterns
var attack_pattern2: AttackPatterns
var attack_pattern3: AttackPatterns
var cover_and_attack_sequence: AttackSequence

var idle_path: PathStyle
var attack_path: PathStyle

var water_attack1 := GlobalData.magic_book.copy_spell("linear-arc")
var water_attack2 := GlobalData.magic_book.copy_spell("linear-arc")
var water_attack3 := GlobalData.magic_book.copy_spell("linear-arc")
var fire_attack1 := GlobalData.magic_book.copy_spell("linear-arc")
var fire_attack2 := GlobalData.magic_book.copy_spell("linear-arc")
var fire_attack3 := GlobalData.magic_book.copy_spell("linear-arc")
var rock_wall := GlobalData.magic_book.copy_spell("bomb")
	
func setup(seedling: int, biome: World.Biome) -> void:
	vitals = Vitals.enemy(hp(19), mana(18), mana_regen(15), percep(1,4), atk(17), def(16), {Artifact.Element.WATER: res(8, 4), Artifact.Element.FIRE: res(8, 4)})
	
	var circle_path := Pathway.new().move_to(Vector3.ZERO).circle(fit(10,15), 0, runs(19))
	idle_path = PathStyle.new(0, position).follow_path(circle_path).align_y_to_ground()
	attack_path = PathStyle.new(0, Vector3.ZERO).follow_path(circle_path).align_y_to_ground().look_at_player_xz().origin_is_player()
	
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	water_attack1.configure({"R":"pi*0.5", "s":atks(2,10)}, Spell.Element.WATER, fit(5,15), power(15), radius(5), fiti(3,16), 70, 130, fit(30,60))
	water_attack2.configure({"R":"pi*0.75", "s":atks(3,12)}, Spell.Element.WATER, fit(6,18), power(17), radius(4), fiti(4,16), 60, 140, fit(40,60))
	water_attack3.configure({"R":"pi", "s":atks(4,15)}, Spell.Element.WATER, fit(7,21), power(19), radius(3), fiti(5,16), 50, 150, fit(50,60))
	fire_attack1.configure({"R":"pi*0.5", "s":atks(2,10)}, Spell.Element.FIRE, fit(5,15), power(15), radius(5), fiti(3,16), 70, 130, fit(30,60))
	fire_attack2.configure({"R":"pi*0.75", "s":atks(3,12)}, Spell.Element.FIRE, fit(6,18), power(17), radius(4), fiti(4,16), 60, 140, fit(40,60))
	fire_attack3.configure({"R":"pi", "s":atks(4,15)}, Spell.Element.FIRE, fit(7,21), power(19), radius(3), fiti(5,16), 50, 150, fit(50,60))
	rock_wall.configure({"d": "0.2","S":"0","s":"0","rx":"5","ry":"5","rz":"0.1","ra":"0"}, Spell.Element.ROCK, fit(10,20), power(0), 1.5, 1, 0, 0, 0)
	
	attack_pattern1 = AttackPatterns.new(
		[
			water_attack1,
			water_attack2,
			water_attack3,
		],
		AttackPatterns.choose_from_distribution(fit(7,3), [ 15, 10, 5 ], -1)
	)
	
	attack_pattern2 = AttackPatterns.new(
		[
			fire_attack1,
			fire_attack2,
			fire_attack3,
		],
		AttackPatterns.choose_from_distribution(fit(7,3), [ 15, 10, 5 ], -1)
	)
	
	attack_pattern3 = AttackPatterns.new(
		[
			fire_attack1,
			fire_attack2,
			fire_attack3,
			water_attack1,
			water_attack2,
			water_attack3,
		],
		AttackPatterns.choose_from_distribution(0.5, [ 15, 10, 5, 15, 10, 5 ], 1)
	)
	
	var cover_and_attack_path := PathStyle.new().follow_path(
		Pathway.new() \
			.move_to(Vector3(0, 0, 0))
			.line_to(Vector3(5, 0, 0), runs(15)) \
			.line_to(Vector3(-5, 0, 0), runs(15)) \
			.line_to(Vector3(0, 0, 0), runs(15))
	).align_y_to_ground().look_at_player_xz().player_vision_is_line_of_sight(0, 10).initial_position_can_update_when_loop()
	
	cover_and_attack_sequence = AttackSequence.new(true, [
		AttackSequence.ASOptions.PATH_SEGMENT_IS_DONE,
		AttackPatterns.new([rock_wall], AttackPatterns.choose_from_distribution(0, [1])),
		cover_and_attack_path,
		attack_pattern3,
		AttackPatterns.new([rock_wall], AttackPatterns.choose_from_distribution(0, [1])),
		cover_and_attack_path,
		attack_pattern3,
		cover_and_attack_path,	
	])
	
	
	animation_map["attack"] = "Weapon"
	kind = World.Enemy.BLUEMON
	super.setup(seedling, biome)

func attack_state() -> AttackPatterns:
	if is_idle:
		return none_pattern
	elif vitals.health.percentage() > 0.75:
		return none_pattern
	elif vitals.health.percentage() > 0.5:
		return attack_pattern2
	else:
		return none_pattern


func update_behaviour() -> void:
	super.update_behaviour()
	if is_idle:
		current_path = idle_path
	elif vitals.health.percentage() > 0.5:
		#current_path = attack_path
		attack_sequence = cover_and_attack_sequence
	else:
		attack_sequence = cover_and_attack_sequence
		

func drop_artifact() -> Artifact:
	var t := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	var r := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	var b := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	var l := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	var new_name := player.name_generator.indian_names.generate(8, 2)
	return Artifact.new(new_name, t, r, b, l)

func drop_spell() -> Spell:
	var new_name := player.name_generator.latin_names.generate(6, 2)
	var water_para := water_attack1.duplicate().bake(new_name)
	return water_para
