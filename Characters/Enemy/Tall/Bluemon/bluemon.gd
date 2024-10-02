class_name Bluemon
extends Enemy

var none_pattern: AttackPatterns
var attack_pattern1: AttackPatterns
var attack_pattern2: AttackPatterns
var attack_pattern3: AttackPatterns

var idle_path: PathStyle
var attack_path: PathStyle

var water_attack1 := GlobalData.magic_book.copy_spell("linear-arc")
var water_attack2 := GlobalData.magic_book.copy_spell("linear-arc")
var water_attack3 := GlobalData.magic_book.copy_spell("linear-arc")
var fire_attack1 := GlobalData.magic_book.copy_spell("linear-arc")
var fire_attack2 := GlobalData.magic_book.copy_spell("linear-arc")
var fire_attack3 := GlobalData.magic_book.copy_spell("linear-arc")


func _ready() -> void:
	super._ready()
	
	velocity_movement = VelocityMovement.new()
	
func setup(seedling: int) -> void:
	vitals = Vitals.enemy(hp(19), mana(18), mana_regen(15), percep(1,4), atk(17), def(16), {Artifact.Element.WATER: res(8, 4), Artifact.Element.FIRE: res(8, 4)})
	
	var circle_path := PathStyle.Pathway.new().move_to(Vector3.ZERO).circle_with_speed(fit(10,15), 0, fit(3,1))
	idle_path = PathStyle.new(0, position).follow_path(circle_path).align_y_to_ground()
	attack_path = PathStyle.new(0, Vector3.ZERO).follow_path(circle_path).align_y_to_ground().look_at_player_xz().set_use_player_as_origin()
	
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	water_attack1.configure({"R":"pi*0.5", "s":atks(2,10)}, Spell.Element.WATER, fit(5,15), power(15), radius(5), fiti(3,16), 70, 130, fit(30,60))
	water_attack2.configure({"R":"pi*0.75", "s":atks(3,12)}, Spell.Element.WATER, fit(6,18), power(17), radius(4), fiti(4,16), 60, 140, fit(40,60))
	water_attack3.configure({"R":"pi", "s":atks(4,15)}, Spell.Element.WATER, fit(7,21), power(19), radius(3), fiti(5,16), 50, 150, fit(50,60))
	fire_attack1.configure({"R":"pi*0.5", "s":atks(2,10)}, Spell.Element.FIRE, fit(5,15), power(15), radius(5), fiti(3,16), 70, 130, fit(30,60))
	fire_attack2.configure({"R":"pi*0.75", "s":atks(3,12)}, Spell.Element.FIRE, fit(6,18), power(17), radius(4), fiti(4,16), 60, 140, fit(40,60))
	fire_attack3.configure({"R":"pi", "s":atks(4,15)}, Spell.Element.FIRE, fit(7,21), power(19), radius(3), fiti(5,16), 50, 150, fit(50,60))
	
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
		AttackPatterns.choose_from_distribution(fit(8,2), [ 15, 10, 5, 15, 10, 5 ], -1)
	)
	
	
	animation_map["attack"] = "Weapon"
	kind = World.Enemy.BLUEMON

func attack_state() -> AttackPatterns:
	if is_idle:
		return none_pattern
	elif vitals.health.percentage() > 0.75:
		return attack_pattern1
	elif vitals.health.percentage() > 0.5:
		return attack_pattern2
	else:
		return attack_pattern3


func update_behaviour() -> void:
	super.update_behaviour()
	if is_idle:
		current_path = idle_path
	else:
		current_path = attack_path
		

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
