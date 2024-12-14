class_name OrcDead
extends Enemy

var none_pattern: AttackPatterns
var random_pattern: AttackPatterns
var sequence_pattern: AttackPatterns

var idle_path: PathStyle
var attack_path: PathStyle

var electric_attack_small := GlobalData.magic_book.copy_spell("plane-slice")
var electric_attack_medium := GlobalData.magic_book.copy_spell("plane-slice")
var electric_attack_large := GlobalData.magic_book.copy_spell("plane-slice")
var electric_attack_lines := GlobalData.magic_book.copy_spell("bomb-linear")
	
func setup(seedling: int, biome: World.Biome) -> void:
	vitals = Vitals.enemy(hp(18), mana(16), mana_regen(10), percep(4,6), atk(14), def(13), {Artifact.Element.ELECTRIC: res(3, 1)})
	class_level = 17
	
	var circle_path := Pathway.new().random_points_in_disc(2, 0, 20, 0, 10)
	idle_path = PathStyle.new(seedling, position).follow_path(circle_path).align_y_to_ground()
	attack_path = PathStyle.new(seedling, position).towards_player(fit(5,10), 6, 12).look_at_player_xz().align_y_to_ground()
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	electric_attack_small.configure({
		"d": "C", "s": "0", "R": fits(6, 2)+"+rn0*"+fits(5, 8),
		"off": "uvw", "dir": "uvw", "a": "n/N*pi*2",
	}, Spell.Element.ELECTRIC, fit(7,14), power(5), radius(2), fiti(8,16), 5, 100, ea(10), null, fits(4,2)+"+n*"+fits(1.5, 0.25))
	electric_attack_medium.configure({
		"d": "C", "s": "0", "R": fits(8, 4)+"+rn0*"+fits(6, 12),
		"off": "uvw", "dir": "uvw", "a": "n/N*pi*2",
	}, Spell.Element.ELECTRIC, fit(5,10), power(6), radius(4), fiti(7,14), 3, 200, ea(13), null, fits(4,2)+"+n*"+fits(1.5, 0.25))
	electric_attack_large.configure({
		"d": "C", "s": "0", "R": fits(10, 5)+"+rn0*"+fits(9, 18),
		"off": "uvw", "dir": "uvw", "a": "n/N*pi*2",
	}, Spell.Element.ELECTRIC, fit(3,6), power(7), radius(6), fiti(6,12), 1, 300, ea(16), null, fits(4,2)+"+n*"+fits(1.5, 0.25))
	electric_attack_lines.configure({
		"d": "1", "a": "0", "R": "0.5", "S": fits(5,1), "s":fits(2, 0.5),
		"LC": "2", "LR": "pi*0.5"
	}, Spell.Element.ELECTRIC, fit(2, 10), power(5), radius(3), fiti(4,10), 10, 50, ea(10))
	
	spell_drop_probs = {
		electric_attack_small: spell_drop(1),
		electric_attack_medium: spell_drop(2),
		electric_attack_large: spell_drop(3),
		electric_attack_lines: spell_drop(6),
	}
	
	random_pattern = AttackPatterns.new(
		[
			electric_attack_lines,
			electric_attack_small,
			electric_attack_medium,
			electric_attack_large,
		],
		AttackPatterns.choose_from_distribution(atkd(8), [ 10, 3, 1 ], -1)
	)
	
	sequence_pattern = AttackPatterns.new(
		[
			electric_attack_lines,
			electric_attack_small,
			electric_attack_medium,
			electric_attack_large,
		],
		AttackPatterns.choose_from_distribution(atkd(14), [2, 5, 4, 3], -1)
	)
	
	artifact_drop_probs = {
		"NEW": {
			"is_effect": 0.9,
			"event": { Artifact.Event.RECEIVE: 5, Artifact.Event.DEAL: 15 },
			"effect": { Artifact.Effect.BOOST_PERCENTAGE: 5, Artifact.Effect.BOOST_FLAT: 10 },
			"ev_element": { Artifact.Element.ELECTRIC: 10, },
			"ef_element": { Artifact.Element.ELECTRIC: 10, Artifact.Element.ATTACK: 5, Artifact.Element.CRIT_DMG: 2, Artifact.Element.POWER: 2, },
			"pattern": { Artifact.Pattern.TRIANGLE: 2, Artifact.Pattern.CIRCLE: 2 },
			"tier": artier(17),
		},
		"S": {
			"is_effect": 0.9,
			"event": { Artifact.Event.RECEIVE: 5, Artifact.Event.DEAL: 15 },
			"effect": { Artifact.Effect.BOOST_PERCENTAGE: 5, Artifact.Effect.BOOST_FLAT: 10 },
			"ev_element": { Artifact.Element.ELECTRIC: 10, },
			"ef_element": { Artifact.Element.ELECTRIC: 10, Artifact.Element.ATTACK: 5, Artifact.Element.CRIT_DMG: 2, Artifact.Element.POWER: 2, },
			"pattern": { Artifact.Pattern.TRIANGLE: 2, Artifact.Pattern.CIRCLE: 2 },
			"tier": artier(17),
		}
	}
	
	animation_map["attack"] = "Weapon"
	kind = World.Enemy.ORC_DEAD
	super.setup(seedling, biome)


func update_behaviour() -> void:
	super.update_behaviour()
	if is_idle:
		set_path_and_attack(idle_path, none_pattern)
	elif vitals.health.percentage() >= 0.5:
		set_path_and_attack(attack_path, random_pattern)
	else:
		set_path_and_attack(attack_path, sequence_pattern)
