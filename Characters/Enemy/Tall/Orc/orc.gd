class_name Orc
extends Enemy

var none_pattern: AttackPatterns
var random_pattern: AttackPatterns
var sequence_pattern: AttackPatterns

var idle_path: PathStyle
var attack_path: PathStyle

var electric_attack_small := GlobalData.magic_book.copy_spell("linear")
var electric_attack_medium := GlobalData.magic_book.copy_spell("linear")
var electric_attack_large := GlobalData.magic_book.copy_spell("linear")
var electric_boomerang := GlobalData.magic_book.copy_spell("plane-slice")
var electric_boomerang_wave := GlobalData.magic_book.copy_spell("plane-slice")
	
func setup(seedling: int, biome: World.Biome) -> void:
	vitals = Vitals.enemy(hp(8), mana(1), mana_regen(1), percep(1,2), atk(7), def(3), {Artifact.Element.ROCK: res(1, 0)})
	
	var circle_path := Pathway.new().random_points_in_disc(2, 0, 20, 0, 10)
	idle_path = PathStyle.new(seedling).follow_path(circle_path).align_y_to_ground()
	attack_path = PathStyle.new(seedling).towards_player(fit(5,9), 3, 5).look_at_player_xz().align_y_to_ground()
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	electric_attack_small.configure({"d": "Br", "s": atks(1,12)}, Spell.Element.ELECTRIC, fit(2,3), power(5), radius(2), 1, 0, 0, ea(5))
	electric_attack_medium.configure({"d": "Br*2", "s": atks(1,13)}, Spell.Element.ELECTRIC, fit(2,4), power(6), radius(2), 1, 0, 0, ea(9))
	electric_attack_large.configure({"d": "Br*2.5", "s": atks(1,14)}, Spell.Element.ELECTRIC, fit(2,5), power(7), radius(2), 1, 0, 0, ea(13))
	electric_boomerang.configure({
		"d": "Br", "s": atks(5,10), "R":fits(5, 15),
		"off": "uvw", "dir": "uvw",
		"a": "n/N*pi+t*"+fits(1, 5), "c": "vec(0, 0, 0)",
	}, Spell.Element.ELECTRIC, fit(4,9), power(7), radius(4), fiti(3, 14), 0, 0, ea(8))
	electric_boomerang_wave.configure({
		"d": "Br", "s": atks(5,10), "R":fits(5, 15),
		"off": "uvw", "dir": "uvw",
		"a": "n/N*pi+t*"+fits(1, 5), "c": "vec(0, (sin(t*%s)*0.5+0.5)*%s, 0)" % [fits(1,4), fits(0,3)],
	}, Spell.Element.ELECTRIC, fit(4,9), power(7), radius(4), fiti(3, 14), 0, 0, ea(8))
	
	spell_drop_probs = {
		electric_attack_small: spell_drop(2),
		electric_attack_medium: spell_drop(3),
		electric_attack_large: spell_drop(4),
		electric_boomerang: spell_drop(6),
		electric_boomerang_wave: spell_drop(7),
	}
	
	random_pattern = AttackPatterns.new(
		[
			electric_attack_small,
			electric_attack_medium,
			electric_attack_large,
			electric_boomerang,
		],
		AttackPatterns.choose_from_distribution(atkd(10), [ 30, 24, 20, 1 ], -1)
	)
	
	sequence_pattern = AttackPatterns.new(
		[
			electric_boomerang,
			electric_attack_small,
			electric_attack_medium,
			electric_attack_large,
			electric_boomerang_wave,
			electric_attack_medium,
			electric_attack_small,
			electric_attack_large,
		],
		AttackPatterns.choose_in_sequence(atkds([9, 15, 12, 20, 9, 12, 15, 20]), -1)
	)
	
	artifact_drop_probs = {
		"SEW": {
			"is_effect": 0.1,
			"event": { Artifact.Event.RECEIVE: 5, Artifact.Event.DEAL: 15 },
			"effect": { Artifact.Effect.BOOST_PERCENTAGE: 5, Artifact.Effect.BOOST_FLAT: 10 },
			"ev_element": { Artifact.Element.ELECTRIC: 10, },
			"ef_element": { Artifact.Element.ELECTRIC: 10, Artifact.Element.ATTACK: 5, Artifact.Element.CRIT_DMG: 2, Artifact.Element.POWER: 2, },
			"pattern": { Artifact.Pattern.TRIANGLE: 2, Artifact.Pattern.CIRCLE: 2 },
			"tier": artier(14),
		},
		"N": {
			"is_effect": 0.1,
			"event": { Artifact.Event.RECEIVE: 5, Artifact.Event.DEAL: 15 },
			"effect": { Artifact.Effect.BOOST_PERCENTAGE: 5, Artifact.Effect.BOOST_FLAT: 10 },
			"ev_element": { Artifact.Element.ELECTRIC: 10, },
			"ef_element": { Artifact.Element.ELECTRIC: 10, Artifact.Element.ATTACK: 5, Artifact.Element.CRIT_DMG: 2, Artifact.Element.POWER: 2, },
			"pattern": { Artifact.Pattern.TRIANGLE: 2, Artifact.Pattern.CIRCLE: 2 },
			"tier": artier(14),
		}
	}
	
	animation_map["attack"] = "Weapon"
	kind = World.Enemy.ORC
	super.setup(seedling, biome)


func update_behaviour() -> void:
	super.update_behaviour()
	if is_idle:
		set_path_and_attack(idle_path, none_pattern)
	elif vitals.health.percentage() >= 0.5:
		set_path_and_attack(attack_path, random_pattern)
	else:
		set_path_and_attack(attack_path, sequence_pattern)


func drop_health() -> float:
	return health_drop(1)
