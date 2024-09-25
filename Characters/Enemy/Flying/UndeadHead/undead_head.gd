class_name UndeadHead
extends Enemy

var none_pattern: AttackPatterns
var random_pattern: AttackPatterns
var sequence_pattern: AttackPatterns

var idle_path: PathStyle
var attack_path: PathStyle
	
func setup(seedling: int) -> void:
	vitals = Vitals.enemy(hp(4), mana(1), mana_regen(1), 5, atk(4), def(2), {Artifact.Element.ROCK: res(0, 1)})
	
	idle_path = PathStyle.new(seedling, position).random_points_in_circle(2, 20, 0, 10).align_y_to_ground()
	attack_path = PathStyle.new(0, position).towards_player(2, 1, 2).look_at_player_xz().align_y_to_ground()
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	var rock_attack_small := GlobalData.magic_book.copy_spell("linear", {"d": "Br", "s": "5"}, Spell.Element.ROCK, fit(2,3), power(5), radius(2), 1, 0, 0, 0)
	var rock_attack_medium := GlobalData.magic_book.copy_spell("linear", {"d": "Br*2", "s": "3"}, Spell.Element.ROCK, fit(2,4), power(6), radius(2), 1, 0, 0, 0)
	var rock_attack_large := GlobalData.magic_book.copy_spell("linear", {"d": "Br*2.5", "s": "1"}, Spell.Element.ROCK, fit(2,5), power(7), radius(2), 1, 0, 0, 0)
	
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
		AttackPatterns.choose_in_sequence(timings(2.0, [ 2, 5, 2, 4, 2 ]), -1)
	)
	
	animation_map["attack"] = "Headbutt"
	kind = World.Enemy.UNDEAD_HEAD

func attack_state() -> AttackPatterns:
	if is_idle:
		return none_pattern
	elif vitals.health.percentage() >= 0.5:
		return random_pattern
	else:
		return sequence_pattern


func update_behaviour() -> void:
	super.update_behaviour()
	if is_idle:
		current_path = idle_path
	else:
		current_path = attack_path

func drop_artifact() -> Artifact:
	var t := Artifact.Option.make_random()
	var l := Artifact.Option.make_random()
	var b := Artifact.Option.make_random()
	var r := Artifact.Option.make_random()
	return Artifact.new(player.name_generator.irish_names.generate(5, 3), t, l, b, r)
	
func drop_spell() -> Spell:
	var new_name := player.name_generator.latin_names.generate(6, 2)
	var spell := GlobalData.magic_book.copy_spell("arc", {"s": "5"}, Spell.Element.ELECTRIC, 1, 5, 0.2, 4, 50, 50, NAN).bake(new_name)
	return spell
