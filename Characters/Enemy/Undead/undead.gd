class_name Undead
extends Enemy

var none_pattern: AttackPatterns
var random_pattern: AttackPatterns
var sequence_pattern: AttackPatterns

var idle_path: PathStyle
var attack_path: PathStyle

static var artifact_name_generator := WordGenerator.new(WordGenerator.SourcePath.dutch_names)

func _ready() -> void:
	super._ready()
	
	velocity_movement = VelocityMovement.new()
	
	vitals = Vitals.new(Vitals.Stat.new(100, 0, 100), Vitals.Stat.new(50, 0, 5, 1))
	vitals.perception.value = 10 * 4
	
	idle_path = PathStyle.new(randf()).random_points_in_circle(2, 2, 10).set_origin(position)
	attack_path = PathStyle.new(randf()).towards_player(2, 1, 2).use_physics()
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	var rock_attack_small := GlobalData.magic_book.copy_spell("linear", {"d": "Br", "s": "5"})
	rock_attack_small.element = Spell.Element.ROCK
	var rock_attack_medium := GlobalData.magic_book.copy_spell("linear", {"d": "Br*2", "s": "3", "h": "Br/2+0.5"})
	rock_attack_medium.radius = 1
	rock_attack_medium.element = Spell.Element.ROCK
	var rock_attack_large := GlobalData.magic_book.copy_spell("linear", {"d": "Br*2.5", "s": "1", "h": "Br/2+1.0"})
	rock_attack_large.element = Spell.Element.ROCK
	rock_attack_large.radius = 2
	
	var water_attack := GlobalData.magic_book.copy_spell("linear", {"d": "Br*2.5", "s": "3", "h": "Br/2+1.0"})
	water_attack.element = Spell.Element.WATER
	water_attack.radius = 1
	
	var fire_attack := GlobalData.magic_book.copy_spell("linear", {"d": "Br*2.5", "s": "3", "h": "Br/2+1.0"})
	fire_attack.element = Spell.Element.FIRE
	fire_attack.radius = 1
	
	var electric_attack := GlobalData.magic_book.copy_spell("linear", {"d": "Br*2.5", "s": "3", "h": "Br/2+1.0"})
	electric_attack.element = Spell.Element.ELECTRIC
	electric_attack.radius = 1
	
	random_pattern = AttackPatterns.new(
		[
			rock_attack_small,
			rock_attack_medium,
			rock_attack_large,
		],
		AttackPatterns.choose_from_distribution(0.25, [ 10, 3, 1 ])
	)
	
	sequence_pattern = AttackPatterns.new(
		[
			rock_attack_small,
			rock_attack_medium,
			rock_attack_small,
			rock_attack_large,
			rock_attack_small,
		],
		AttackPatterns.choose_in_sequence([ 2, 5, 2, 4, 2 ])
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

func attack_state() -> AttackPatterns:
	health_bar.visible = not current_path == idle_path
	if current_path == idle_path:
		return none_pattern
	elif vitals.health.value >= 50:
		return sequence_pattern
	else:
		return random_pattern

func entity_info() -> EntityInfo:
	return EntityInfo.new(EntityInfo.Kind.UNDEAD, position)

func update_entity_info(info: EntityInfo) -> bool:
	info.position = position
	return true


func update_behaviour() -> void:
	if current_path == idle_path and sqrt(player.position.distance_squared_to(position)) < vitals.perception.value:
		sequence_pattern.reset()
		random_pattern.reset()
		current_path = attack_path
	elif current_path == attack_path and sqrt(player.position.distance_squared_to(position)) > vitals.perception.value * 2:
		current_path = idle_path

func death_box() -> Vector3:
	return Vector3(0.7, 1.9, 0.3)

func drop_artifact() -> Artifact:
	var t := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(10, 30))
	var r := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(10, 30))
	var b := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(10, 30))
	var l := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(10, 30))
	return Artifact.new(artifact_name_generator.generate(7, 2), t, r, b, l)
