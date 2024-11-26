class_name Mole
extends Enemy

var none_pattern: AttackPatterns
var random_pattern: AttackPatterns

var idle_path: PathStyle
var attack_path: PathStyle

var hide_and_attack: AttackSequence

var elec1 := GlobalData.magic_book.copy_spell("linear")
var elec2 := GlobalData.magic_book.copy_spell("linear")
var elec3 := GlobalData.magic_book.copy_spell("linear")
	
func setup(seedling: int, biome: World.Biome) -> void:
	vitals = Vitals.enemy(hp(16), mana(14), mana_regen(10), percep(2,4), atk(8), def(12), {Artifact.Element.ROCK: res(8, 0), Artifact.Element.ELECTRIC: res(7, 1)})
	
	var circle_path := Pathway.new().move_to(Vector3.ZERO).circle(5, 0, runs(7))
	current_path = PathStyle.new(0, position).follow_path(circle_path).align_y_to_ground()
	idle_path = current_path
	
	var R := 25.0
	var U := -bounds.y * 2.5
		
	var underground := func() -> Vector3:
		var p: Vector3 = Vector3(randf() * 2.0 - 1.0, 0, randf() * 2.0 - 1.0).normalized() * R + Vector3(0, U, 0)
		return p
	
	var a: Vector3 = underground.call()
	var b: Vector3 = underground.call()
	var c: Vector3 = underground.call()
	var d: Vector3 = underground.call()
	var e: Vector3 = underground.call()
	var p := Pathway.new() \
		.move_to(a) \
		.line_to(b, runs(8), Easing.linear) \
		.line_to(c, runs(8), Easing.linear) \
		.line_to(d, runs(8), Easing.linear) \
		.line_to(e, runs(8), Easing.linear) \
		.line_to(a, runs(8), Easing.linear)
	
	attack_path = PathStyle.new().follow_path(p).origin_is_player().align_y_to_ground().look_at_player()
	
	none_pattern = AttackPatterns.none()
	
	var Z := Vector3.ZERO
	var up_pathway := Pathway.new() \
		.move_to(Vector3(0, U, 0)) \
		.line_to(Z, runs(4), Easing.linear) \
		.wait(fit(10,2))
	var down_pathway := Pathway.new() \
		.move_to(Z) \
		.line_to(Vector3(0, U, 0), runs(3), Easing.linear)
	
	elec1.configure({"s": atks(3,15), "d": "5"}, Spell.Element.ELECTRIC, fit(7,14), power(7), radius(3), 1, 25, 150, 30)
	elec2.configure({"s": atks(2,10), "d": "5"}, Spell.Element.ELECTRIC, fit(6,12), power(10), radius(4), 1, 25, 150, 40)
	elec3.configure({"s": atks(1,5), "d": "5"}, Spell.Element.ELECTRIC, fit(5,10), power(13), radius(5), 1, 25, 150, 50)
	
	random_pattern = AttackPatterns.new(
		[
			elec1,
			elec2,
			elec3,
		],
		AttackPatterns.choose_from_distribution(fit(2.0, 0.5), [ 5, 3, 2 ], -1)
	)
	
	hide_and_attack = AttackSequence.new(true, [
		PathStyle.new().follow_path(down_pathway).origin_is_me().look_at_player().align_y_to_ground_and_dirt(),
		PathStyle.new().follow_path(
			Pathway.new().move_to(a).line_to(b, runs(8), Easing.linear)
		).origin_is_player().look_at_player().align_y_to_ground_air_and_dirt(),
		PathStyle.new().follow_path(up_pathway).origin_is_me().look_at_player().align_y_to_ground_and_dirt(),
		random_pattern,
		
		PathStyle.new().follow_path(down_pathway).origin_is_me().look_at_player().align_y_to_ground_and_dirt(),
		PathStyle.new().follow_path(
			Pathway.new().move_to(b).line_to(c, runs(8), Easing.linear)
		).origin_is_player().look_at_player().align_y_to_ground_air_and_dirt(),
		PathStyle.new().follow_path(up_pathway).origin_is_me().look_at_player().align_y_to_ground_and_dirt(),
		random_pattern,
		
		PathStyle.new().follow_path(down_pathway).origin_is_me().look_at_player().align_y_to_ground_and_dirt(),
		PathStyle.new().follow_path(
			Pathway.new().move_to(c).line_to(d, runs(8), Easing.linear)
		).origin_is_player().look_at_player().align_y_to_ground_air_and_dirt(),
		PathStyle.new().follow_path(up_pathway).origin_is_me().look_at_player().align_y_to_ground_and_dirt(),
		random_pattern,
		
		PathStyle.new().follow_path(down_pathway).origin_is_me().look_at_player().align_y_to_ground_and_dirt(),
		PathStyle.new().follow_path(
			Pathway.new().move_to(d).line_to(e, runs(8), Easing.linear)
		).origin_is_player().look_at_player().align_y_to_ground_air_and_dirt(),
		PathStyle.new().follow_path(up_pathway).origin_is_me().look_at_player().align_y_to_ground_and_dirt(),
		random_pattern,
		
		PathStyle.new().follow_path(down_pathway).origin_is_me().look_at_player().align_y_to_ground_and_dirt(),
		PathStyle.new().follow_path(
			Pathway.new().move_to(e).line_to(a, runs(8), Easing.linear)
		).origin_is_player().look_at_player().align_y_to_ground_air_and_dirt(),
		PathStyle.new().follow_path(up_pathway).origin_is_me().look_at_player().align_y_to_ground_and_dirt(),
		random_pattern,
	])
	
	animation_map["attack"] = "Weapon"
	kind = World.Enemy.MOLE
	super.setup(seedling, biome)


func update_behaviour() -> void:
	super.update_behaviour()
	if is_idle:
		set_path_and_attack(idle_path, none_pattern)
	elif vitals.health.percentage() >= 0.5:
		set_path_and_attack(attack_path, random_pattern)
	else:
		set_attack_sequence(hide_and_attack)
