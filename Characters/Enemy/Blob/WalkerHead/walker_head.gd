class_name WalkerHead
extends Enemy

var none_pattern: AttackPatterns
var default_pattern: AttackPatterns
var sequence_pattern: AttackPatterns
var defence_pattern: AttackPatterns

var idle_path: PathStyle
var attack_path: PathStyle

var ice_wall_timer: int = 0

var water_small := GlobalData.magic_book.copy_spell("linear")
var water_medium := GlobalData.magic_book.copy_spell("linear")
var water_large := GlobalData.magic_book.copy_spell("linear")
var ice_small := GlobalData.magic_book.copy_spell("linear")
var ice_medium := GlobalData.magic_book.copy_spell("linear")
var ice_large := GlobalData.magic_book.copy_spell("linear")
var ice_wall := GlobalData.magic_book.copy_spell("wall")
	
func setup(seedling: int) -> void:
	vitals = Vitals.enemy(hp(14), mana(12), mana_regen(10), 15, atk(11), def(9), {Artifact.Element.WATER: res(5, 1), Artifact.Element.ICE: res(7, 2)})
	
	idle_path = PathStyle.new().random_points_in_circle(2, 10, bounds.y / 2.0, 10).set_origin(position).align_y_to_ground()
	attack_path = PathStyle.new().set_use_player_as_origin().set_player_body_rotation_as_vision_angle(2, 0, 10).use_physics().look_at_player()
	current_path = idle_path
	
	water_small.configure({"d": "Br", "s": "8"}, Spell.Element.WATER, 2+fl*8, 5+fl*70, 0.1+fl*0.4, 1, 80, 80, fl*50)
	water_medium.configure({"d": "Br*2", "s": "4"}, Spell.Element.WATER, 5+fl*10, 5+fl*80, 0.2+fl*0.8, 1, 80, 80, fl*60)
	water_large.configure({"d": "Br*3", "s": "2"}, Spell.Element.WATER, 10+fl*10, 5+fl*90, 0.5+fl, 1, 80, 80, fl*75)
	ice_small.configure({"d": "Br", "s": "8"}, Spell.Element.ICE, 2+fl*8, 5+fl*70, 0.1+fl*0.4, 1, 80, 80, fl*50)
	ice_medium.configure({"d": "Br*2", "s": "4"}, Spell.Element.ICE, 5+fl*10, 5+fl*80, 0.2+fl*0.8, 1, 80, 80, fl*60)
	ice_large.configure({"d": "Br*3", "s": "2"}, Spell.Element.ICE, 10+fl*10, 5+fl*90, 0.5+fl, 1, 80, 80, fl*75)
	ice_wall.configure({}, Spell.Element.ICE, 10, 0, 6, 4, 0, 0, 0)
	ice_wall.follow = true
	
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
		AttackPatterns.choose_in_sequence([ 2, 2, 2, 2, 6, 6, 6, 6, 4, 4, 4 ], -1)
	)
	
	defence_pattern = AttackPatterns.new(
		[ice_wall],
		AttackPatterns.choose_in_sequence([ 0 ], -1)
	)
	
	animation_map["attack"] = "Weapon"
	kind = World.Enemy.WALKER

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if current_path != idle_path:
		ice_wall_timer += 1

func attack_state() -> AttackPatterns:
	if is_idle:
		return none_pattern
	else:
		if ice_wall_timer == 0 or ice_wall_timer > 60 * 10:
			ice_wall_timer = 1
			return defence_pattern
		elif vitals.health.percentage() >= 0.5:
			return default_pattern
		else:
			return sequence_pattern


func update_behaviour() -> void:
	super.update_behaviour()
	if is_idle:
		current_path = idle_path
	else:
		current_path = attack_path
