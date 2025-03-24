class_name Bluemon
extends Enemy

var none_pattern: AttackPatterns
var attack_pattern1: AttackPatterns
var attack_pattern2: AttackPatterns
var attack_pattern3: AttackPatterns
var cover_and_attack_sequence: AttackSequence

var idle_path: PathStyle
var attack_path: PathStyle

var water_bomb_small := GlobalData.magic_book.copy_spell("plane-slice")
var water_bomb_medium := GlobalData.magic_book.copy_spell("plane-slice")
var water_bomb_large := GlobalData.magic_book.copy_spell("plane-slice")
var water_attack1 := GlobalData.magic_book.copy_spell("linear-arc")
var water_attack2 := GlobalData.magic_book.copy_spell("linear-arc")
var water_attack3 := GlobalData.magic_book.copy_spell("linear-arc")
var ice_attack1 := GlobalData.magic_book.copy_spell("linear-arc")
var ice_attack2 := GlobalData.magic_book.copy_spell("linear-arc")
var ice_attack3 := GlobalData.magic_book.copy_spell("linear-arc")
var rock_wall := GlobalData.magic_book.copy_spell("bomb")
	
func setup(seedling: int, biome: World.Biome) -> void:
	vitals = Vitals.enemy(hp(19), mana(18), mana_regen(15), percep(1,4), atk(17), def(16), {Artifact.Element.WATER: res(8, 4), Artifact.Element.FIRE: res(8, 4)})
	class_level = 20
	
	var circle_path := Pathway.new().move_to(Vector3.ZERO).circle(fit(10,15), 0, runs(19))
	idle_path = PathStyle.new(seedling, position).follow_path(circle_path).align_y_to_ground()
	attack_path = PathStyle.new(seedling).follow_path(circle_path).align_y_to_ground().look_at_player_xz().origin_is_player()
	
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	water_bomb_small.configure({
		"d": "C", "s": "0", "R": "rn0*%s+lerp(t/T, %s, %s)" % [fits(6,2), fits(8,4), fits(4,2)],
		"off": "uvw", "dir": "uvw", "a": "n/N*pi*2",
	}, Spell.Element.WATER, fit(7,14), power(5), radius(2), fiti(8,16), 5, 100, ea(10), null, fits(4,2)+"+n*"+fits(1.5, 0.25))
	water_bomb_medium.configure({
		"d": "C", "s": "0", "R": "rn0*%s+lerp(t/T, %s, %s)" % [fits(8,4), fits(10,5), fits(6,3)],
		"off": "uvw", "dir": "uvw", "a": "n/N*pi*2",
	}, Spell.Element.WATER, fit(5,10), power(6), radius(4), fiti(7,14), 3, 200, ea(13), null, fits(4,2)+"+n*"+fits(1.5, 0.25))
	water_bomb_large.configure({
		"d": "C", "s": "0", "R": "rn0*%s+lerp(t/T, %s, %s)" % [fits(10,5), fits(12,6), fits(8,4)],
		"off": "uvw", "dir": "uvw", "a": "n/N*pi*2",
	}, Spell.Element.WATER, fit(3,6), power(7), radius(6), fiti(6,12), 1, 300, ea(16), null, fits(4,2)+"+n*"+fits(1.5, 0.25))
	water_attack1.configure({"R":"pi*0.5", "s":atks(2,10)}, Spell.Element.WATER, fit(5,15), power(15), radius(5), fiti(3,16), 70, 130, fit(30,60))
	water_attack2.configure({"R":"pi*0.75", "s":atks(3,12)}, Spell.Element.WATER, fit(6,18), power(17), radius(4), fiti(4,16), 60, 140, fit(40,60))
	water_attack3.configure({"R":"pi", "s":atks(4,15)}, Spell.Element.WATER, fit(7,21), power(19), radius(3), fiti(5,16), 50, 150, fit(50,60))
	ice_attack1.configure({"R":"pi*0.5", "s":atks(2,10)}, Spell.Element.ICE, fit(5,15), power(15), radius(5), fiti(3,16), 70, 130, fit(30,60))
	ice_attack2.configure({"R":"pi*0.75", "s":atks(3,12)}, Spell.Element.ICE, fit(6,18), power(17), radius(4), fiti(4,16), 60, 140, fit(40,60))
	ice_attack3.configure({"R":"pi", "s":atks(4,15)}, Spell.Element.ICE, fit(7,21), power(19), radius(3), fiti(5,16), 50, 150, fit(50,60))
	rock_wall.configure({"d": "0.1","S":"0","s":"0.0","size":"vec(5, 5, 0.1)","spinrate":"0"}, Spell.Element.ROCK, fit(10,20), power(0), 1.5, 1, 0, 0, 0)
	
	spell_drop_probs = {
		water_bomb_small: spell_drop(5),
		water_bomb_medium: spell_drop(6),
		water_bomb_large: spell_drop(7),
		water_attack1: spell_drop(1),
		water_attack2: spell_drop(2),
		water_attack3: spell_drop(3),
		ice_attack1: spell_drop(1),
		ice_attack2: spell_drop(2),
		ice_attack3: spell_drop(3),
		rock_wall: spell_drop(10),
	}
	
	attack_pattern1 = AttackPatterns.new(
		[
			water_bomb_small,
			water_bomb_medium,
			water_bomb_large,
		],
		AttackPatterns.choose_from_distribution(atkd(9), [ 15, 10, 5 ], -1)
	)
	
	attack_pattern2 = AttackPatterns.new(
		[
			ice_attack1,
			ice_attack2,
			ice_attack3,
			water_attack1,
			water_attack2,
			water_attack3,
		],
		AttackPatterns.choose_from_distribution(atkd(12), [ 15, 10, 5, 3, 5, 10 ], -1)
	)
	
	attack_pattern3 = AttackPatterns.new(
		[
			ice_attack1,
			ice_attack2,
			ice_attack3,
			water_attack1,
			water_attack2,
			water_attack3,
		],
		AttackPatterns.choose_from_distribution(atkd(16), [ 15, 10, 5, 15, 10, 5 ], 1)
	)
	
	var cover_and_attack_path := PathStyle.new(seedling).follow_path(
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
	
	artifact_drop_probs = {
		"NS": {
			"is_effect": 0.5,
			"event": { Artifact.Event.RECEIVE: 2, Artifact.Event.DEAL: 10 },
			"effect": { Artifact.Effect.BOOST_PERCENTAGE: 10, Artifact.Effect.BOOST_FLAT: 10 },
			"ev_element": { Artifact.Element.WATER: 10, Artifact.Element.ICE: 10 },
			"ef_element": { Artifact.Element.WATER: 10, Artifact.Element.ICE: 10, Artifact.Element.CRIT_RATE: 5, Artifact.Element.ATTACK: 5, },
			"pattern": { Artifact.Pattern.TRIANGLE: 4, Artifact.Pattern.CIRCLE: 2 },
			"tier": artier(17),
		},
		"WE": {
			"is_effect": 0.5,
			"event": { Artifact.Event.RECEIVE: 10, Artifact.Event.DEAL: 2 },
			"effect": { Artifact.Effect.BOOST_PERCENTAGE: 10, Artifact.Effect.BOOST_FLAT: 10 },
			"ev_element": { Artifact.Element.WATER: 10, Artifact.Element.ICE: 10 },
			"ef_element": { Artifact.Element.WATER: 10, Artifact.Element.ICE: 10, Artifact.Element.CRIT_RATE: 5, Artifact.Element.ATTACK: 5, },
			"pattern": { Artifact.Pattern.TRIANGLE: 4, Artifact.Pattern.CIRCLE: 2 },
			"tier": artier(17),
		}
	}
	
	
	animation_map["attack"] = "Weapon"
	kind = World.Enemy.BLUEMON
	super.setup(seedling, biome)


func update_behaviour() -> void:
	super.update_behaviour()
	if is_idle:
		set_path_and_attack(idle_path, none_pattern)
	elif vitals.health.percentage() > 0.7:
		set_path_and_attack(attack_path, attack_pattern1)
	elif vitals.health.percentage() > 0.4:
		set_path_and_attack(attack_path, attack_pattern2)
	else:
		set_attack_sequence(cover_and_attack_sequence)
		
