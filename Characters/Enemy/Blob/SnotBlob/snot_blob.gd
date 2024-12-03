class_name SnotBlob
extends Enemy

var none_pattern: AttackPatterns
var random_pattern: AttackPatterns
var sequence_pattern: AttackPatterns

var idle_path: PathStyle
var attack_path: PathStyle

var water_spout1 := GlobalData.magic_book.copy_spell("plane-slice")
var water_spout2 := GlobalData.magic_book.copy_spell("plane-slice")
var water_spout3 := GlobalData.magic_book.copy_spell("plane-slice")
var water_down1 := GlobalData.magic_book.copy_spell("plane-linear")
var water_down2 := GlobalData.magic_book.copy_spell("plane-linear")
var water_down3 := GlobalData.magic_book.copy_spell("plane-linear")
var water_spiral1 := GlobalData.magic_book.copy_spell("plane-slice")
var water_spiral2 := GlobalData.magic_book.copy_spell("plane-slice")
var water_spiral3 := GlobalData.magic_book.copy_spell("plane-slice")
	
func setup(seedling: int, biome: World.Biome) -> void:
	vitals = Vitals.enemy(hp(15), mana(5), mana_regen(10), percep(1,3), atk(10), def(10), {Artifact.Element.FIRE: res(-10, 0), Artifact.Element.WATER: res(10, 0)})
	
	var circle_path := Pathway.new().random_points_in_disc(1, 0, 2, 0, 3)
	idle_path = PathStyle.new(seedling, position).follow_path(circle_path).align_y_to_ground()
	
	attack_path = PathStyle.new(seedling, position).towards_player(fit(5,20), 1, 2).origin_is_player().align_y_to_ground().look_at_player()
	
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	water_spout1.configure({
		"d":"Br*2", "s":"0", "R":"1+t/T*"+fits(3,9), "off":"vec(0,0,0)", "dir":"vec(1,0,0)", "a":"n/N*2*pi", "c": "vec(0,0,0)"
	}, Spell.Element.WATER, fit(8,16), power(10), radius(3), fiti(3, 15), 33, 99, ea(10))
	water_spout1.follow = true
	water_spout2.configure({
		"d":"Br*2", "s":"0", "R":"1+t/T*"+fits(3,9), "off":"vec(0,0,0)", "dir":"vec(1,0,0)", "a":"n/N*2*pi", "c": "vec(0,1,0)"
	}, Spell.Element.WATER, fit(8,16), power(12), radius(3), fiti(3, 15), 66, 66, ea(12), water_spout1)
	water_spout2.follow = true
	water_spout2.chain_cast_kind = Spell.ChainCastKind.START
	water_spout3.configure({
		"d":"Br*2", "s":"0", "R":"1+t/T*"+fits(3,9), "off":"vec(0,0,0)", "dir":"vec(1,0,0)", "a":"n/N*2*pi", "c": "vec(0,2,0)"
	}, Spell.Element.WATER, fit(8,16), power(14), radius(3), fiti(3, 15), 99, 33, ea(14), water_spout2)
	water_spout3.follow = true
	water_spout3.chain_cast_kind = Spell.ChainCastKind.START
	
	water_down1.configure({
		"d": "8", "s":atks(4,10), "R":fits(6,12), "off":"vec(0,1,0)", "dir":"vec(0,-1,0)", "a":"n/N*2*pi", "c":"vec(0,0,0)"
	}, Spell.Element.WATER, fit(4,8), power(10), radius(3), fiti(3,15), 40, 80, ea(11))
	water_down1.follow = true
	water_down2.configure({
		"d": "8", "s":atks(4,10), "R":fits(5,10), "off":"vec(0,1,0)", "dir":"vec(0,-1,0)", "a":"n/N*2*pi", "c":"vec(0,0,0)"
	}, Spell.Element.WATER, fit(4,8), power(12), radius(3), fiti(3,12), 60, 100, ea(13), water_down1)
	water_down2.follow = true
	water_down2.chain_cast_kind = Spell.ChainCastKind.END
	water_down3.configure({
		"d": "8", "s":atks(4,10), "R":fits(4,8), "off":"vec(0,1,0)", "dir":"vec(0,-1,0)", "a":"n/N*2*pi", "c":"vec(0,0,0)"
	}, Spell.Element.WATER, fit(4,8), power(14), radius(3), fiti(3,9), 80, 120, ea(15), water_down2)
	water_down3.follow = true
	water_down3.chain_cast_kind = Spell.ChainCastKind.END
	
	water_spiral1.configure({
		"d": "Br*2", "s": "0", "R":fits(6,12), "off":"vec(0,0,0)", "dir":"vec(1,0,0)", "a":"n/N*2*pi+t/T*2*pi*"+atks(4,10), "c": "vec(0,0,0)" 
	}, Spell.Element.WATER, fit(6, 12), power(12), radius(4), fiti(3,15), 33, 99, ea(12))
	water_spiral1.follow = true
	water_spiral2.configure({
		"d": "Br*2", "s": "0", "R":fits(6,12), "off":"vec(0,0,0)", "dir":"vec(1,0,0)", "a":"n/N*2*pi+t/T*2*pi*"+atks(4,10), "c": "vec(0,0,0)" 
	}, Spell.Element.WATER, fit(6, 12), power(12), radius(4), fiti(3,15), 66, 122, ea(14), water_spiral1)
	water_spiral2.follow = true
	water_spiral2.chain_cast_kind = Spell.ChainCastKind.START
	water_spiral3.configure({
		"d": "Br*2", "s": "0", "R":fits(6,12), "off":"vec(0,0,0)", "dir":"vec(1,0,0)", "a":"n/N*2*pi+t/T*2*pi*"+atks(4,10), "c": "vec(0,0,0)" 
	}, Spell.Element.WATER, fit(6, 12), power(12), radius(4), fiti(3,15), 99, 155, ea(16), water_spiral2)
	water_spiral3.follow = true
	water_spiral3.chain_cast_kind = Spell.ChainCastKind.START
	
	random_pattern = AttackPatterns.new(
		[
			water_spout1,
			water_spout2,
			water_spout3,
			water_down1,
			water_down2,
			water_down3,
		],
		AttackPatterns.choose_from_distribution(fit(6,10), [ 12, 10, 8, 3, 2, 1 ], -1)
	)
	
	sequence_pattern = AttackPatterns.new(
		[
			water_spiral1,
			water_down1,
			water_spiral2,
			water_down2,
			water_spiral3,
			water_down3,
		],
		AttackPatterns.choose_in_sequence(fita([6, 4, 6, 4, 6, 4], [10, 8, 10, 8, 10, 8]), -1)
	)
	
	animation_map["attack"] = "Bite_Front"
	kind = World.Enemy.SNOT_BLOB
	super.setup(seedling, biome)


func update_behaviour() -> void:
	super.update_behaviour()
	if is_idle:
		set_path_and_attack(idle_path, none_pattern)
	elif vitals.health.percentage() > 0.5:
		set_path_and_attack(attack_path, sequence_pattern)
	else:
		set_path_and_attack(attack_path, random_pattern)

func drop_artifact() -> Artifact:
	var t := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	var r := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	var b := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	var l := Artifact.Option.make_random(0.5, {Artifact.Effect.BOOST_FLAT: 0.5, Artifact.Effect.BOOST_PERCENTAGE: 0.5}, {Artifact.Event.DEAL: 0.5}, {Artifact.Element.ROCK: 0.5, Artifact.Element.WATER: 0.2}, Vector2i(1, 3))
	var new_name := player.name_generator.spanish_names.generate(8, 2)
	return Artifact.new(new_name, t, r, b, l)
