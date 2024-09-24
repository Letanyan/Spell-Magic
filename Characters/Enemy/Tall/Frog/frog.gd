class_name Frog
extends Enemy

var none_pattern: AttackPatterns
var attack_pattern1: AttackPatterns
var attack_pattern2: AttackPatterns

var idle_path: PathStyle
var attack_path: PathStyle


func _ready() -> void:
	super._ready()
	
	velocity_movement = VelocityMovement.new()
	
func setup(seedling: int) -> void:
	vitals = Vitals.enemy(hp(13), mana(12), mana_regen(8), 15, atk(7), def(6), {Artifact.Element.WATER: res(15, 5)})
	
	var idle_pathway: PathStyle.Pathway = PathStyle.Pathway.new() \
		.move_to(Vector3(0, 0, 0)) \
		.quad_to(Vector3(20, 0, 0), Vector3(10, 20, 0), 2, PathStyle.Easing.out_quart) \
		.quad_to(Vector3(0, 0, 20), Vector3(10, 20, 10), 2, PathStyle.Easing.out_quart) \
		.quad_to(Vector3(20, 0, 20), Vector3(10, 20, 20), 2, PathStyle.Easing.out_quart) \
		.quad_to(Vector3(0, 0, 0), Vector3(10, 20, 10), 2, PathStyle.Easing.out_quart)
		
	idle_path = PathStyle.new(0, position).follow_path(idle_pathway).align_y_to_ground_and_jump() \
		.set_initial_position_can_update(PathStyle.InitialPositionCanUpdate.ON_GROUND)
	
	attack_path = PathStyle.new().follow_path(idle_pathway)\
		.align_y_to_ground_and_jump()\
		.set_use_player_as_origin() \
		.set_player_body_rotation_as_vision_angle(0, 0, 10.0)\
		.look_at_player_xz() \
		.set_initial_position_can_update(PathStyle.InitialPositionCanUpdate.ON_GROUND)
	
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	var water_flurry1 := GlobalData.magic_book.copy_spell("linear-flurry", {"s":fits(3,15), "R":fits(PI*0.2, PI*0.5)}, Spell.Element.WATER, fit(5,10), power(7), radius(4), fiti(3,20), 10, 100, fit(50,75))
	var water_flurry2 := GlobalData.magic_book.copy_spell("linear-flurry", {"s":fits(6,15), "R":fits(PI*0.2, PI*0.5)}, Spell.Element.WATER, fit(5,10), power(4), radius(3), fiti(3,15), 10, 200, fit(50,75))
	var water_flurry3 := GlobalData.magic_book.copy_spell("linear-flurry", {"s":fits(9,15), "R":fits(PI*0.1, PI*0.2)}, Spell.Element.WATER, fit(5,10), power(2), radius(2), fiti(3,10), 10, 300, fit(50,75))
	
	var water_attack1 := GlobalData.magic_book.copy_spell("linear", {"s":fits(3,15)}, Spell.Element.WATER, fit(3,15), power(7), radius(4), 1, 10, 100, fit(50,75))
	var water_attack2 := GlobalData.magic_book.copy_spell("linear", {"s":fits(6,15)}, Spell.Element.WATER, fit(3,15), power(4), radius(3), 1, 10, 200, fit(50,75))
	var water_attack3 := GlobalData.magic_book.copy_spell("linear", {"s":fits(9,15)}, Spell.Element.WATER, fit(3,15), power(2), radius(2), 1, 10, 300, fit(50,75))
	
	attack_pattern1 = AttackPatterns.new(
		[
			water_flurry1,
			water_attack1,
			water_attack2,
			water_attack1,
			water_flurry1,
		],
		AttackPatterns.choose_in_sequence([ fit(5,2), fit(4,1), fit(5,2), fit(4,1), fit(5,2) ], -1)
	)
	
	attack_pattern2 = AttackPatterns.new(
		[
			water_flurry1,
			water_flurry2,
			water_flurry3,
			water_attack1,
		],
		AttackPatterns.choose_from_distribution(fit(5,2), [ 5, 4, 3, 1 ], -1)
	)
	
	
	animation_map["attack"] = "Weapon"
	kind = World.Enemy.FROG

func attack_state() -> AttackPatterns:
	if is_idle:
		return none_pattern
	elif vitals.health.percentage() > 0.1:
		return attack_pattern1
	else:
		return attack_pattern2


func update_behaviour() -> void:
	super.update_behaviour()
	if is_idle:
		current_path = idle_path
	elif vitals.health.percentage() > 0.1:
		current_path = attack_path
	else:
		current_path = attack_path
			

func drop_artifact() -> Artifact:
	var t := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	var r := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	var b := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	var l := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	return Artifact.new(Time.get_datetime_string_from_system(), t, r, b, l)

func drop_spell() -> Spell:
	var new_name := player.name_generator.latin_names.generate(6, 2)
	var water_para := GlobalData.magic_book.copy_spell("loop-shot", {"H":"4", "speed":"4"}, Spell.Element.AIR, 3, 5, 0.1, 1, 0, 0, 0).bake(new_name)
	return water_para
