class_name WalkerHead
extends Enemy

var none_pattern: AttackPatterns
var default_pattern: AttackPatterns
var sequence_pattern: AttackPatterns
var defence_pattern: AttackPatterns

var idle_path: PathStyle
var attack_path: PathStyle

var ice_wall_duration := 10.0
var ice_wall_timer := 0.0

var water_small := GlobalData.magic_book.copy_spell("linear")
var water_medium := GlobalData.magic_book.copy_spell("linear")
var water_large := GlobalData.magic_book.copy_spell("linear")
var ice_small := GlobalData.magic_book.copy_spell("linear")
var ice_medium := GlobalData.magic_book.copy_spell("linear")
var ice_large := GlobalData.magic_book.copy_spell("linear")
var ice_wall := GlobalData.magic_book.copy_spell("wall")
	
func setup(seedling: int, biome: World.Biome) -> void:
	vitals = Vitals.enemy(hp(14), mana(2), mana_regen(10), percep(1,4), atk(5), def(12), {Artifact.Element.WATER: res(5, 1), Artifact.Element.ICE: res(7, 2)})
	class_level = 14
	
	var circle_path := Pathway.new().random_points_in_disc(2, 0, 10, 0, 10)
	idle_path = PathStyle.new(seedling, position).follow_path(circle_path).align_y_to_ground()
	attack_path = PathStyle.new().follow_path(Pathway.empty(fit(3,8))).player_vision_is_body_rotation(2, 0, 10).look_at_player().align_y_to_ground()
	current_path = idle_path
	
	water_small.configure({"d": "Br", "s": atks(4,15)}, Spell.Element.WATER, fit(2,10), power(12), radius(2), 1, 80, 80, fl*50)
	water_medium.configure({"d": "Br*2", "s": atks(3,11)}, Spell.Element.WATER, fit(5,15), power(10), radius(3), 1, 80, 80, fl*60)
	water_large.configure({"d": "Br*3", "s": atks(2,11)}, Spell.Element.WATER, fit(10,20), power(10), radius(4), 1, 80, 80, fl*75)
	ice_small.configure({"d": "Br", "s": atks(4,15)}, Spell.Element.ICE, fit(2,10), power(12), radius(2), 1, 80, 80, fl*50)
	ice_medium.configure({"d": "Br*2", "s": atks(3,11)}, Spell.Element.ICE, fit(5,15), power(10), radius(3), 1, 80, 80, fl*60)
	ice_large.configure({"d": "Br*3", "s": atks(2,11)}, Spell.Element.ICE, fit(10,20), power(10), radius(4), 1, 80, 80, fl*75)
	ice_wall.configure({"size":"vec(0.495, 0.495, 0.01)"}, Spell.Element.ICE, ice_wall_duration, 0, 1, 4, 0, 0, 0)
	ice_wall.follow = true
	
	spell_drop_probs = {
		water_small: spell_drop(1),
		water_medium: spell_drop(2),
		water_large: spell_drop(3),
		ice_small: spell_drop(5),
		ice_medium: spell_drop(6),
		ice_large: spell_drop(7),
		ice_wall: spell_drop(10),
	}
	
	
	none_pattern = AttackPatterns.none()
	
	default_pattern = AttackPatterns.new(
		[
			water_small,
			water_medium,
			water_large,
			ice_small,
			ice_medium,
			ice_large,
		],
		AttackPatterns.choose_from_distribution(fit(5,2), [ 10, 4, 2, 10, 4, 2 ], -1)
	)
	
	sequence_pattern = AttackPatterns.new(
		[
			water_small,
			ice_small,
			water_small,
			ice_small,
			water_large,
			ice_large,
			water_large,
			ice_large,
			water_medium,
			ice_medium,
			water_medium,
			ice_medium,
		],
		AttackPatterns.choose_in_sequence(fitas(0.7, [ 2, 2, 2, 2, 6, 6, 6, 6, 4, 4, 4 ]), -1)
	)
	
	ice_wall_timer = ice_wall_duration
	defence_pattern = AttackPatterns.new(
		[ice_wall],
		AttackPatterns.choose_in_sequence([ 0 ], -1)
	)
	
	artifact_drop_probs = {
		"NS": {
			"is_effect": 0.5,
			"event": { Artifact.Event.DEAL: 5, Artifact.Event.RECEIVE: 5 },
			"effect": { Artifact.Effect.RESISTANCE_FLAT: 20, Artifact.Effect.RESISTANCE_PERCENTAGE: 15, Artifact.Effect.BOOST_PERCENTAGE: 10, Artifact.Effect.BOOST_FLAT: 5 },
			"ev_element": { Artifact.Element.WATER: 10, Artifact.Element.ICE: 10 },
			"ef_element": { Artifact.Element.WATER: 10, Artifact.Element.ICE: 10, Artifact.Element.CRIT_RATE: 5, Artifact.Element.CRIT_DMG: 5 },
			"pattern": { Artifact.Pattern.SQUARE: 4, Artifact.Pattern.CIRCLE: 4 },
			"tier": artier(10),
		},
		"W": {
			"is_effect": 0.75,
			"event": { Artifact.Event.DEAL: 5 },
			"effect": { Artifact.Effect.RESISTANCE_FLAT: 20, Artifact.Effect.RESISTANCE_PERCENTAGE: 15 },
			"ev_element": { Artifact.Element.WATER: 10 },
			"ef_element": { Artifact.Element.WATER: 10, Artifact.Element.CRIT_RATE: 5 },
			"pattern": { Artifact.Pattern.SQUARE: 4 },
			"tier": artier(10),
		},
		"E": {
			"is_effect": 0.25,
			"event": { Artifact.Event.RECEIVE: 5 },
			"effect": { Artifact.Effect.BOOST_PERCENTAGE: 10, Artifact.Effect.BOOST_FLAT: 5 },
			"ev_element": { Artifact.Element.ICE: 10 },
			"ef_element": { Artifact.Element.ICE: 10, Artifact.Element.CRIT_RATE: 5, Artifact.Element.CRIT_DMG: 5 },
			"pattern": { Artifact.Pattern.CIRCLE: 4 },
			"tier": artier(10),
		}
	}
	
	animation_map["attack"] = "Weapon"
	kind = World.Enemy.WALKER_HEAD
	super.setup(seedling, biome)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if current_path != idle_path:
		ice_wall_timer += delta


func update_behaviour() -> void:
	super.update_behaviour()
	if is_idle:
		set_path_and_attack(idle_path, none_pattern)
	else:
		if ice_wall_timer == 0 or ice_wall_timer > 60 * 10:
			set_path_and_attack(attack_path, defence_pattern)
		elif vitals.health.percentage() >= 0.5:
			set_path_and_attack(attack_path, default_pattern)
		else:
			set_path_and_attack(attack_path, sequence_pattern)

func spell_was_cast_impl(spell: Spell) -> void:
	if spell.name == "wall":
		ice_wall_timer = 0.0001
