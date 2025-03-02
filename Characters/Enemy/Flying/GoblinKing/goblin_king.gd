class_name GoblinKing
extends Enemy

var none_pattern: AttackPatterns
var random_pattern: AttackPatterns
var sequence_pattern: AttackPatterns

var idle_path: PathStyle
var attack_path: PathStyle

var rock_attack_small := GlobalData.magic_book.copy_spell("plane-linear")
var rock_attack_medium := GlobalData.magic_book.copy_spell("plane-linear")
var rock_attack_large := GlobalData.magic_book.copy_spell("plane-linear")
	
func setup(seedling: int, biome: World.Biome) -> void:
	vitals = Vitals.enemy(hp(4), mana(1), mana_regen(1), percep(1,2), atk(4), def(2), {Artifact.Element.ROCK: res(0, 1)})
	class_level = 15
	
	var circle_path := Pathway.new().random_points_in_disc(2, 0, 20, 0, 10)
	idle_path = PathStyle.new(seedling, position).follow_path(circle_path).align_y_to_ground()
	var path := Pathway.new().grid(runs(8), 3, 3, fit(10, 20), fit(10, 20)).apply_transform(T.translated(Vec3.y(fit(4, 16))))
	attack_path = PathStyle.new(seedling).follow_path(path).origin_is_player().look_at_player_xz().align_y_to_air()
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	rock_attack_small.configure({"d": "Br", "s": atks(1,9), "R":"0", "off":"uvw", "dir":"uvw", "a":"0"}, Spell.Element.ROCK, fit(5,6), power(5), radius(2), 1, 40, 80, 0)
	rock_attack_medium.configure({"d": "Br", "s": atks(2,15), "R":fits(2,6), "off":"uvw", "dir":"uvw", "a":"sin(t/tau*%s)" % fits(0.2,2.2)}, Spell.Element.ROCK, fit(5,12), power(5), radius(2), fiti(1,4), 40, 80, 0)
	rock_attack_large.configure({"d": "Br", "s": atks(3,18), "R":fits(3,6), "off":"uvw", "dir":"uvw", "a":"sin(t/tau*%s)" % fits(0.6,2.4)}, Spell.Element.ROCK, fit(5,18), power(5), radius(2), fiti(1,6), 40, 80, 0)
	
	spell_drop_probs = {
		rock_attack_small: spell_drop(1),
		rock_attack_medium: spell_drop(2),
		rock_attack_large: spell_drop(3),
	}
	
	random_pattern = AttackPatterns.new(
		[
			rock_attack_small,
			rock_attack_medium,
			rock_attack_large,
		],
		AttackPatterns.choose_from_distribution(fit(4, 2), [ fit(10, 1), 6, fit(1, 10) ], -1)
	)
	
	sequence_pattern = AttackPatterns.new(
		[
			rock_attack_small,
			rock_attack_medium,
			rock_attack_small,
			rock_attack_large,
			rock_attack_small,
		],
		AttackPatterns.choose_in_sequence(fitas(0.6, [ 2, 5, 2, 4, 2 ]), -1)
	)
	
	artifact_drop_probs = {
		"NW": {
			"is_effect": 0.5,
			"event": {Artifact.Event.DEAL: 5, Artifact.Event.RECEIVE: 1, },
			"effect": { Artifact.Effect.BOOST_FLAT: 10, },
			"ef_element": { Artifact.Element.ROCK: 10, Artifact.Element.RUNNING_SPEED: 10,  },
			"ev_element": { Artifact.Element.ROCK: 10 },
			"pattern": { Artifact.Pattern.SQUARE: 2 },
			"tier": artier(12),
		},
		"SE": {
			"is_effect": 0.9,
			"event": {Artifact.Event.DEAL: 5, Artifact.Event.RECEIVE: 1, },
			"effect": { Artifact.Effect.BOOST_FLAT: 10, },
			"ef_element": { Artifact.Element.ROCK: 10, Artifact.Element.RUNNING_SPEED: 10,  },
			"ev_element": { Artifact.Element.ROCK: 10 },
			"pattern": { Artifact.Pattern.SQUARE: 2 },
			"tier": artier(12),
		},
	}
	
	animation_map["attack"] = "Headbutt"
	kind = World.Enemy.GOBLIN_KING
	super.setup(seedling, biome)


func update_behaviour() -> void:
	super.update_behaviour()
	if is_idle:
		set_path_and_attack(idle_path, none_pattern)
	elif vitals.health.percentage() >= 0.5:
		set_path_and_attack(attack_path, random_pattern)
	else:
		set_path_and_attack(attack_path, sequence_pattern)
