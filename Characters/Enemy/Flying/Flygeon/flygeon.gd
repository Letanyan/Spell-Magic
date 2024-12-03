class_name Flygeon
extends Enemy

var none_pattern: AttackPatterns
var random_pattern: AttackPatterns
var sequence_pattern: AttackPatterns

var idle_path: PathStyle
var attack_path: PathStyle

var air_small_fast := GlobalData.magic_book.copy_spell("linear")
var air_med_med := GlobalData.magic_book.copy_spell("linear")
var air_large_slow := GlobalData.magic_book.copy_spell("linear")
var air_ring := GlobalData.magic_book.copy_spell("plane-slice")
var air_flurry := GlobalData.magic_book.copy_spell("plane-linear")
	
func setup(seedling: int, biome: World.Biome) -> void:
	vitals = Vitals.enemy(hp(8), mana(18), mana_regen(20), percep(4,7), atk(11), def(12), {Artifact.Element.AIR: res(15, 5)})
	
	var idle_pathway := Pathway.new().random_points_in_sphere(runs(12), 3, 8, 5, Easing.in_out_quad).apply_transform(T.translated(Vec3.y(10)))
	idle_path = PathStyle.new(seedling, position).follow_path(idle_pathway).align_y_to_air()
	
	var attack_pathway := Pathway.new()
	var attack_pathway_min_radius := fit(3, 7)
	var attack_pathway_max_radius := fit(7, 14)
	var starting_point := Rand.point_in_hemisphere_shell(attack_pathway_min_radius, attack_pathway_max_radius)
	attack_pathway.move_to(starting_point)
	var last_point := starting_point
	for i in fiti(3, 4):
		var np := Rand.point_in_hemisphere_shell(attack_pathway_min_radius, attack_pathway_max_radius)
		var mid := Globals.midpoint_tangent1(last_point, np)
		var easing := Easing.rising if np.y > last_point.y else Easing.falling
		attack_pathway.line_to(mid, runs(16), easing)
		attack_pathway.line_to(np, runs(16), easing)
		last_point = np
	var easing := Easing.rising if starting_point.y > last_point.y else Easing.falling
	var mid := Globals.midpoint_tangent1(last_point, starting_point)
	attack_pathway.line_to(mid, runs(16), easing)
	attack_pathway.line_to(starting_point, runs(16), easing)
	
	attack_path = PathStyle.new().follow_path(attack_pathway)\
		.align_y_to_air()\
		.origin_is_player()\
		.player_vision_is_camera(0, 0.0, 1.0, 2.0)\
		.look_at_player()
	
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	air_small_fast.configure({"s":atks(5,15), "d":"Br*2"}, Spell.Element.AIR, 5, power(4), radius(2), 1, 25, 100, ea(8))
	air_med_med.configure({"s":atks(3,10), "d":"Br*2"}, Spell.Element.AIR, 5, power(7), radius(3), 1, 25, 100, ea(10))
	air_large_slow.configure({"s":atks(1,5), "d":"Br*2"}, Spell.Element.AIR, 5, power(10), radius(4), 1, 25, 100, ea(15))
	air_flurry.configure({"s":atks(5,17), "d":"C", "c":"vec(0,0,0)", "R":fits(1,5)+"*rn0+rn1", "off":"vec(u, lerp(0.5, v, 1), w)", "dir":"vec(0,-1,0)", "a":"rn0*2*pi"}, Spell.Element.AIR, fit(3,6), power(12), radius(7), fiti(2, 10), 40, 60, ea(12), null, "n*"+fits(3, 0.3))
	air_ring.configure({"s":atks(2, 6), "d":"Br*2+"+fits(2,8), "c":"vec(0,0,0)", "R":fits(2,8), "off": "uvw", "dir":"uvw", "a":"(n/N*2*pi)+t"}, Spell.Element.AIR, fit(5,10), power(15), radius(5), fiti(4, 12), 30, 90, ea(14))
	
	random_pattern = AttackPatterns.new(
		[
			air_flurry,
			air_ring,
			air_small_fast,
		],
		AttackPatterns.choose_from_distribution(atkd(5), [ 10, 5, 2 ], -1)
	)
	
	sequence_pattern = AttackPatterns.new(
		[
			air_flurry,
			air_med_med,
			air_large_slow,
			air_small_fast,
			air_ring,
			air_small_fast,
			air_large_slow,
			air_med_med,
			air_flurry,
		],
		AttackPatterns.choose_in_sequence(atkds([5, 12, 17, 12, 5, 12, 17, 12, 5]), -1)
	)
	
	animation_map["attack"] = "Headbutt"
	kind = World.Enemy.FLYGEON
	super.setup(seedling, biome)
	

func update_behaviour() -> void:
	super.update_behaviour()
	if is_idle:
		set_path_and_attack(idle_path, none_pattern)
	elif vitals.health.percentage() >= 0.5:
		set_path_and_attack(attack_path, sequence_pattern)
	else:
		set_path_and_attack(attack_path, random_pattern)

func drop_artifact() -> Artifact:
	var t := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	var r := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	var b := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	var l := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	var new_name := player.name_generator.chinese_names.generate(8, 2)
	return Artifact.new(new_name, t, r, b, l)
