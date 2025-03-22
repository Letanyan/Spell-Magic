class_name Rabbit
extends Enemy

var none_pattern: AttackPatterns
var attack_pattern1: AttackPatterns
var attack_pattern2: AttackPatterns
var attack_pattern3: AttackPatterns

var idle_path: PathStyle
var attack_path: PathStyle

var air_small_fast := GlobalData.magic_book.copy_spell("swipe")
var air_med_fast := GlobalData.magic_book.copy_spell("swipe")
var air_large_fast := GlobalData.magic_book.copy_spell("swipe")
var air_small_med := GlobalData.magic_book.copy_spell("swipe")
var air_med_med := GlobalData.magic_book.copy_spell("swipe")
var air_large_med := GlobalData.magic_book.copy_spell("swipe")
var air_small_slow := GlobalData.magic_book.copy_spell("swipe")
var air_med_slow := GlobalData.magic_book.copy_spell("swipe")
var air_large_slow := GlobalData.magic_book.copy_spell("swipe")

var air_mine := GlobalData.magic_book.copy_spell("bomb-disc-scatter")
	
func setup(seedling: int, biome: World.Biome) -> void:
	vitals = Vitals.enemy(hp(12), mana(10), mana_regen(8), percep(1,3), atk(12), def(12), {Artifact.Element.AIR: res(5, 2)})
	class_level = 14
	
	var idle_pathway := Pathway.new() \
		.move_to(Vector3(-10, 0, -10)) \
		.quad_to(Vector3(10, 0, -10), Vector3(0, 20, -10), runs(17), Easing.out_box) \
		.quad_to(Vector3(-10, 0, 10), Vector3(0, 20, 0), runs(17), Easing.out_box) \
		.quad_to(Vector3(10, 0, 10), Vector3(0, 20, 10), runs(17), Easing.out_box) \
		.quad_to(Vector3(-10, 0, -10), Vector3(0, 20, 0), runs(17), Easing.out_box)
	idle_path = PathStyle.new(seedling, position).follow_path(idle_pathway).align_y_to_ground_and_air() \
		.initial_position_can_update_on_ground()

	attack_path = PathStyle.new(seedling).follow_path(idle_pathway)\
		.align_y_to_ground_and_air()\
		.origin_is_me() \
		.look_at_player_xz() \
		.initial_position_can_update_on_ground()
	
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	air_mine.configure({"d":"1", "Rmin":"4", "Rmax":"8", "arc":"2*pi", "S":"0", "s":"0.00001"}, Spell.Element.AIR, fit(5,15), power(5), radius(3), fiti(5,25), 5, 300, fit(25, 75))
	air_mine.set_y(air_mine.y + " + t*0.0001")
	
	air_small_fast.configure({"Rx":fits(PI/8,PI/2)+"*if(eq(mod(n,2),0),-1,1)", "Ry":fits(PI/8,PI/2), "Dn":fits(10,2), "dz":fits(1,2), "d":"Br*2+C-dz*N/2"}, Spell.Element.AIR, fit(10,2), power(14), radius(1), fiti(1,10), 25, 100, 50)
	air_med_fast.configure({"Rx":fits(PI/8,PI/2)+"*if(eq(mod(n,2),0),-1,1)", "Ry":fits(PI/8,PI/2), "Dn":fits(10,2), "dz":fits(1,2), "d":"Br*2+C-dz*N/2"}, Spell.Element.AIR, fit(10,2), power(14), radius(1), fiti(1,10), 25, 100, 50)
	air_large_fast.configure({"Rx":fits(PI/8,PI/2)+"*if(eq(mod(n,2),0),-1,1)", "Ry":fits(PI/8,PI/2), "Dn":fits(10,2), "dz":fits(1,2), "d":"Br*2+C-dz*N/2"}, Spell.Element.AIR, fit(10,2), power(14), radius(1), fiti(1,10), 25, 100, 50)
	air_small_med.configure({"Rx":fits(PI/8,PI/2)+"*if(eq(mod(n,2),0),-1,1)", "Ry":fits(PI/8,PI/2), "Dn":fits(10,2), "dz":fits(1,2), "d":"Br*2+C-dz*N/2"}, Spell.Element.AIR, fit(15,4), power(17), radius(2), fiti(1,10), 25, 100, 50)
	air_med_med.configure({"Rx":fits(PI/8,PI/2)+"*if(eq(mod(n,2),0),-1,1)", "Ry":fits(PI/8,PI/2), "Dn":fits(10,2), "dz":fits(1,2), "d":"Br*2+C-dz*N/2"}, Spell.Element.AIR, fit(15,4), power(17), radius(2), fiti(1,10), 25, 100, 50)
	air_large_med.configure({"Rx":fits(PI/8,PI/2)+"*if(eq(mod(n,2),0),-1,1)", "Ry":fits(PI/8,PI/2), "Dn":fits(10,2), "dz":fits(1,2), "d":"Br*2+C-dz*N/2"}, Spell.Element.AIR, fit(15,4), power(17), radius(2), fiti(1,10), 25, 100, 50)
	air_small_slow.configure({"Rx":fits(PI/8,PI/2)+"*if(eq(mod(n,2),0),-1,1)", "Ry":fits(PI/8,PI/2), "Dn":fits(10,2), "dz":fits(1,2), "d":"Br*2+C-dz*N/2"}, Spell.Element.AIR, fit(20,6), power(20), radius(5), fiti(1,10), 25, 100, 50)
	air_med_slow.configure({"Rx":fits(PI/8,PI/2)+"*if(eq(mod(n,2),0),-1,1)", "Ry":fits(PI/8,PI/2), "Dn":fits(10,2), "dz":fits(1,2), "d":"Br*2+C-dz*N/2"}, Spell.Element.AIR, fit(20,6), power(20), radius(5), fiti(1,10), 25, 100, 50)
	air_large_slow.configure({"Rx":fits(PI/8,PI/2)+"*if(eq(mod(n,2),0),-1,1)", "Ry":fits(PI/8,PI/2), "Dn":fits(10,2), "dz":fits(1,2), "d":"Br*2+C-dz*N/2"}, Spell.Element.AIR, fit(20,6), power(20), radius(5), fiti(1,10), 25, 100, 50)
	
	spell_drop_probs = {
		air_small_slow: spell_drop(1),
		air_med_slow: spell_drop(2),
		air_large_slow: spell_drop(3),		
		air_small_med: spell_drop(4),
		air_med_med: spell_drop(5),
		air_large_med: spell_drop(6),
		air_small_fast: spell_drop(7),
		air_med_fast: spell_drop(8),
		air_large_fast: spell_drop(9),
	}
	
	attack_pattern1 = AttackPatterns.new(
		[
			air_small_fast,
			air_small_med,
			air_small_slow,
		],
		AttackPatterns.choose_from_distribution(fit(10, 2), [ 5, 5, 7 ], -1)
	)
	
	attack_pattern2 = AttackPatterns.new(
		[
			air_small_fast,
			air_small_med,
			air_small_slow,
			air_med_fast,
			air_med_med,
			air_med_slow,
			air_mine,
		],
		AttackPatterns.choose_from_distribution(fit(7, 1), [ 8, 8, 12, 20, 20, 28, 1 ], -1)
	)
	
	attack_pattern3 = AttackPatterns.new(
		[
			AttackPatterns.new(
				[air_small_slow, air_small_fast, air_mine],
				AttackPatterns.choose_in_sequence(fitas(0.75, [ 2, 1, 1 ]), 1)
			),
			AttackPatterns.new(
				[air_med_slow, air_med_fast, air_mine],
				AttackPatterns.choose_in_sequence(fitas(0.5, [ 3, 3, 1 ]), 1)
			),
			AttackPatterns.new(
				[air_large_slow, air_large_fast, air_mine],
				AttackPatterns.choose_in_sequence(fitas(0.25, [ 5, 5, 1 ]), 1)
			),
		],
		AttackPatterns.choose_from_distribution(1, [ 2, 3, 5 ], -1)
	)
	
	artifact_drop_probs = {
		"NS": {
			"event": { Artifact.Event.RECEIVE: 2, Artifact.Event.DEAL: 10 },
			"element": { Artifact.Element.AIR: 10, },
			"pattern": { Artifact.Pattern.TRIANGLE: 5, Artifact.Pattern.CIRCLE: 8 },
			"tier": artier(16),
		},
		"WE": {
			"event": { Artifact.Event.RECEIVE: 10, Artifact.Event.DEAL: 2 },
			"element": { Artifact.Element.AIR: 10, },
			"pattern": { Artifact.Pattern.TRIANGLE: 5, Artifact.Pattern.CIRCLE: 8 },
			"tier": artier(16),
		}
	}
	
	animation_map["attack"] = "Weapon"
	kind = World.Enemy.RABBIT
	super.setup(seedling, biome)


func update_behaviour() -> void:
	super.update_behaviour()
	if is_idle:
		set_path_and_attack(idle_path, none_pattern)
	elif vitals.health.percentage() > 0.5:
		set_path_and_attack(attack_path, attack_pattern1)
	elif vitals.health.percentage() > 0.25:
		set_path_and_attack(attack_path, attack_pattern2)
	else:
		set_path_and_attack(attack_path, attack_pattern3)
			
