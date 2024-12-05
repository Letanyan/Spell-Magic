class_name Dragoon
extends Enemy

var none_pattern: AttackPatterns
var random_pattern: AttackPatterns
var sequence_pattern: AttackPatterns

var idle_path: PathStyle
var attack_path: PathStyle

var fire2 := GlobalData.magic_book.copy_spell("linear")
var fire1 := GlobalData.magic_book.copy_spell("linear")
var fire3 := GlobalData.magic_book.copy_spell("linear")
var fire_down1 := GlobalData.magic_book.copy_spell("top-down")
var fire_down2 := GlobalData.magic_book.copy_spell("top-down")
var fire_down3 := GlobalData.magic_book.copy_spell("top-down")
var fire_mine1 := GlobalData.magic_book.copy_spell("bomb-sphere-scatter")
var fire_mine2 := GlobalData.magic_book.copy_spell("bomb")
var fire_mine3 := GlobalData.magic_book.copy_spell("bomb-linear")
	
func setup(seedling: int, biome: World.Biome) -> void:
	vitals = Vitals.enemy(hp(17), mana(19), mana_regen(20), percep(3,6), atk(17), def(17), {Artifact.Element.FIRE: res(12, 7)})
	
	var sphere_path := Pathway.new().move_to(Vector3(0, 10, 0)).random_points_in_sphere(4, 0, 10, 7)
	idle_path = PathStyle.new(seedling, position).follow_path(sphere_path).align_y_to_air()
	
	const x_size = 10
	const y_size = 10
	const z_size = 10
	var start_point := Rand.v3_abs(x_size, y_size, z_size)
	var cube_path := Pathway.new() \
		.move_to(start_point) \
		.line_to(Rand.v3_abs(x_size, y_size, z_size), runs(12), Easing.in_out_sine) \
		.line_to(Rand.v3_abs(x_size, y_size, z_size), runs(15), Easing.in_out_sine) \
		.line_to(Rand.v3_abs(x_size, y_size, z_size), runs(13), Easing.in_out_sine) \
		.line_to(Rand.v3_abs(x_size, y_size, z_size), runs(14), Easing.in_out_sine) \
		.line_to(start_point, runs(11), Easing.in_out_sine)
	
	attack_path = PathStyle.new(seedling).follow_path(cube_path).align_y_to_air().look_at_player() \
		.player_vision_is_body_rotation(0, 10, 3, 6)
	
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	fire1.configure({"s": atks(3,18), "d": "2"}, Spell.Element.FIRE, 10.0, power(12), radius(3), 1, 50, 50, 65)
	fire2.configure({"s": atks(4,19), "d": "2"}, Spell.Element.FIRE, 8.0, power(14), radius(3), 1, 50, 50, 70)
	fire3.configure({"s": atks(4,20), "d": "2"}, Spell.Element.FIRE, 6.0, power(19), radius(3), 1, 50, 50, 75)
	fire_down1.configure({"H": "10"}, Spell.Element.FIRE, fit(10, 5), power(10), radius(4), 1, 75, 25, 65)
	fire_down2.configure({"H": "20"}, Spell.Element.FIRE, fit(8, 4), power(12), radius(4), 1, 75, 50, 70)
	fire_down3.configure({"H": "30"}, Spell.Element.FIRE, fit(6, 3), power(14), radius(4), 1, 75, 75, 75)
	fire_mine1.configure({"d": "1", "Rmin": "4", "Rmax": "8", "S":"1", "s":"0"}, Spell.Element.FIRE, fit(3,9), power(7), radius(7), fiti(4, 15), 33, 66, 25)
	fire_mine2.configure({"d":"1", "S":"1", "s":"0.5"}, Spell.Element.FIRE, fit(4,14), power(11), radius(9), fiti(2, 8), 75, 120, 50)
	fire_mine3.configure({"d": "1", "R": "10", "S":"1.5-fl", "s":"lerp(fl, 2, 0.1)"}, Spell.Element.FIRE, fit(3,16), power(17), radius(5), fiti(5, 10), 70, 180, 60)
	
	spell_drop_probs = {
		fire1: spell_drop(1),
		fire2: spell_drop(2),
		fire3: spell_drop(3),
		fire_down1: spell_drop(6),
		fire_down2: spell_drop(7),
		fire_down3: spell_drop(8),
		fire_mine1: spell_drop(10),
		fire_mine2: spell_drop(11),
		fire_mine3: spell_drop(12),
	}
	
	random_pattern = AttackPatterns.new(
		[
			fire1,
			fire2,
			fire3,
			fire_down1,
			fire_down2,
			fire_down3,
		],
		AttackPatterns.choose_from_distribution(fit(3,1), [14, 10, 8, 6, 4, 2], -1)
	)
	
	sequence_pattern = AttackPatterns.new(
		[
			fire_mine1,
			fire_down1,
			fire_mine2,
			fire_down2,
			fire_mine3,	
			fire_down3,
		],
		AttackPatterns.choose_in_sequence(fitas(0.3, [ 2, 5, 2, 5, 2, 5 ]), -1)
	)
	
	artifact_drop_probs = {
		"NS": {
			"is_effect": 0.5,
			"event": { Artifact.Event.DEAL: 15, Artifact.Event.RECEIVE: 1 },
			"effect": { Artifact.Effect.BOOST_PERCENTAGE: 20, Artifact.Effect.BOOST_FLAT: 10 },
			"ev_element": { Artifact.Element.FIRE: 10, },
			"ef_element": { Artifact.Element.FIRE: 10, Artifact.Element.CRIT_RATE: 5, Artifact.Element.ATTACK: 5, },
			"pattern": { Artifact.Pattern.SQUARE: 4, Artifact.Pattern.TRIANGLE: 1 },
			"tier": artier(19),
		},
		"WE": {
			"is_effect": 0.5,
			"event": { Artifact.Event.DEAL: 1, Artifact.Event.RECEIVE: 5 },
			"effect": { Artifact.Effect.BOOST_PERCENTAGE: 20, Artifact.Effect.BOOST_FLAT: 5 },
			"ev_element": { Artifact.Element.FIRE: 10, },
			"ef_element": { Artifact.Element.FIRE: 10, Artifact.Element.CRIT_RATE: 10, Artifact.Element.ATTACK: 10, },
			"pattern": { Artifact.Pattern.SQUARE: 1, Artifact.Pattern.TRIANGLE: 4 },
			"tier": artier(17),
		},
	}
	
	animation_map["attack"] = "Headbutt"
	kind = World.Enemy.DRAGOON
	super.setup(seedling, biome)


func update_behaviour() -> void:
	super.update_behaviour()
	if is_idle:
		set_path_and_attack(idle_path, none_pattern)
	elif vitals.health.percentage() >= 0.1:
		set_path_and_attack(attack_path, random_pattern)
	else:
		set_path_and_attack(attack_path, sequence_pattern)
