class_name Goblin
extends Enemy

var none_pattern: AttackPatterns
var random_pattern: AttackPatterns
var sequence_pattern: AttackPatterns

var idle_path: PathStyle
var attack_path: PathStyle

var rock_attack_small := GlobalData.magic_book.copy_spell("linear")
var rock_attack_medium := GlobalData.magic_book.copy_spell("linear")
var rock_attack_large := GlobalData.magic_book.copy_spell("linear")
	
func setup(seedling: int, biome: World.Biome) -> void:
	vitals = Vitals.enemy(hp(4), mana(1), mana_regen(1), percep(1,2), atk(4), def(2), {Artifact.Element.ROCK: res(0, 1)})
	
	var circle_path := Pathway.new().random_points_in_disc(2, 0, 20, 0, 10)
	idle_path = PathStyle.new(seedling, position).follow_path(circle_path).align_y_to_ground()
	attack_path = PathStyle.new(seedling, position).towards_player(fit(2,4), 1, 2).look_at_player_xz().align_y_to_ground()
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	rock_attack_small.configure({"d": "Br", "s": atks(1,3)}, Spell.Element.ROCK, fit(2,3), power(5), radius(2), 1, 0, 0, 0)
	rock_attack_medium.configure({"d": "Br*2", "s": atks(1,3)}, Spell.Element.ROCK, fit(2,4), power(6), radius(2), 1, 0, 0, 0)
	rock_attack_large.configure({"d": "Br*2.5", "s": atks(1,3)}, Spell.Element.ROCK, fit(2,5), power(7), radius(2), 1, 0, 0, 0)
	
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
		AttackPatterns.choose_from_distribution(fit(5,3), [ 10, 3, 1 ], -1)
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
	
	animation_map["attack"] = "Headbutt"
	kind = World.Enemy.GOBLIN
	super.setup(seedling, biome)


func update_behaviour() -> void:
	super.update_behaviour()
	if is_idle:
		set_path_and_attack(idle_path, none_pattern)
	elif vitals.health.percentage() >= 0.5:
		set_path_and_attack(attack_path, random_pattern)
	else:
		set_path_and_attack(attack_path, sequence_pattern)

func drop_artifact() -> Artifact:
	var t := Artifact.Option.make_random()
	var l := Artifact.Option.make_random()
	var b := Artifact.Option.make_random()
	var r := Artifact.Option.make_random()
	return Artifact.new(player.name_generator.irish_names.generate(5, 3), t, l, b, r)
