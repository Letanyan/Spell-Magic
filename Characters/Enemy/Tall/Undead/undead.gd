class_name Undead
extends Enemy

var none_pattern: AttackPatterns
var random_pattern: AttackPatterns
var sequence_pattern: AttackPatterns

var idle_path: PathStyle
var attack_path: PathStyle
	
func setup(seedling: int) -> void:
	vitals = Vitals.enemy(500*fl, 100*fl, 10*fl, 10, 40*fl, 10*fl, {Artifact.Element.ROCK: Vector2(0.1*fl, 5+20*fl)})
	
	idle_path = PathStyle.new(seedling).random_points_in_circle(2, 20, bounds.y / 2.0, 10).set_origin(position + Vector3(0, bounds.y / 2.0, 0)).align_y_to_ground()
	attack_path = PathStyle.new(0, position + Vector3(0, bounds.y / 2.0, 0)).towards_player(2, 1, 2).use_absolute().look_at_player_xz() #.use_physics()
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	var rock_attack_small := GlobalData.magic_book.copy_spell("linear", {"d": "Br", "s": "5"}, Spell.Element.ROCK, 2+fl*6, fl*25, 0.1+fl*0.4, 1, 0, 0, 0)
	var rock_attack_medium := GlobalData.magic_book.copy_spell("linear", {"d": "Br*2", "s": "3", "h": "Br/2+0.5"}, Spell.Element.ROCK, 2+fl*6, fl*25, 0.2+fl*0.8, 1, 0, 0, 0)
	var rock_attack_large := GlobalData.magic_book.copy_spell("linear", {"d": "Br*2.5", "s": "1", "h": "Br/2+1.0"}, Spell.Element.ROCK, 2+fl*6, fl*25, 0.5+fl, 1, 0, 0, 0)
	
	#var water_attack := GlobalData.magic_book.copy_spell("linear", {"d": "Br*2.5", "s": "3", "h": "Br/2+1.0"}, Spell.Element.WATER, 2+fl*8, fl*50, 0.2+fl*0.8, 1, 0, 0, 30)
	#var fire_attack := GlobalData.magic_book.copy_spell("linear", {"d": "Br*2.5", "s": "3", "h": "Br/2+1.0"}, Spell.Element.FIRE, 2+fl*8, fl*50, 0.2+fl*0.8, 1, 0, 0, 30)
	#var electric_attack := GlobalData.magic_book.copy_spell("linear", {"d": "Br*2.5", "s": "3", "h": "Br/2+1.0"}, Spell.Element.ELECTRIC, 2+fl*8, fl*50, 0.2+fl*0.8, 1, 0, 0, 30)
	
	random_pattern = AttackPatterns.new(
		[
			rock_attack_small,
			rock_attack_medium,
			rock_attack_large,
		],
		AttackPatterns.choose_from_distribution(0.25, [ 10, 3, 1 ], -1)
	)
	
	sequence_pattern = AttackPatterns.new(
		[
			rock_attack_small,
			rock_attack_medium,
			rock_attack_small,
			rock_attack_large,
			rock_attack_small,
		],
		AttackPatterns.choose_in_sequence([ 2, 5, 2, 4, 2 ], -1)
	)
	
	#sequence_pattern = AttackPatterns.new(
		#[
			#AttackPatterns.new(
				#[
					#rock_attack_large,
					#water_attack,
				#],
				#[2, 2],
			#),
			#AttackPatterns.new(
				#[
					#fire_attack,
					#electric_attack,
				#],
				#[2, 2],
			#),
		#],
		#[3, 3],
		#0.5
	#)
	
	animation_map["attack"] = "Weapon"
	kind = World.Enemy.UNDEAD

func attack_state() -> AttackPatterns:
	if is_idle:
		return none_pattern
	elif vitals.health.percentage() >= 0.5:
		return sequence_pattern
	else:
		return random_pattern

func entity_info() -> EntityInfo:
	return EntityInfo.new(EntityInfo.Kind.UNDEAD, position)

func update_entity_info(info: EntityInfo) -> bool:
	info.position = position
	return true


func update_behaviour() -> void:
	super.update_behaviour()
	if is_idle:
		sequence_pattern.reset()
		random_pattern.reset()
		current_path = idle_path
	else:
		current_path = attack_path

func death_box() -> Vector3:
	return Vector3(0.7, 1.9, 0.3)

func drop_artifact() -> Artifact:
	var t := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	var r := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	var b := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	var l := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	var new_name := player.name_generator.dutch_names.generate(7, 2)
	return Artifact.new(new_name, t, r, b, l)
