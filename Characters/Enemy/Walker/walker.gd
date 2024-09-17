class_name Walker
extends Enemy

var none_pattern: AttackPatterns
var default_pattern: AttackPatterns
var sequence_pattern: AttackPatterns
var defence_pattern: AttackPatterns

var idle_path: PathStyle
var attack_path: PathStyle

var ice_wall_timer: int = 0
	
func setup(seedling: int) -> void:
	vitals = Vitals.enemy(1000*fl, 1000*fl, 20*fl, 25, 70*fl, 50*fl, {Artifact.Element.WATER: Vector2(0.25*fl, 0), Artifact.Element.ICE: Vector2(0.75*fl, 0), Artifact.Element.FIRE: Vector2(1.25*fl, fl*20)})
	
	idle_path = PathStyle.new().random_points_in_circle(2, 10, bounds.y / 2.0, 10).set_origin(position).align_y_to_ground()
	attack_path = PathStyle.new().set_use_player_as_origin().set_player_body_vision_as_origin(2, 0, 10).use_physics().look_at_player()
	current_path = idle_path
	
	var water_small := GlobalData.magic_book.copy_spell("linear", {"d": "Br", "s": "8"}, Spell.Element.WATER, 2+fl*8, 5+fl*70, 0.1+fl*0.4, 1, 80, 80, fl*50)
	var water_medium := GlobalData.magic_book.copy_spell("linear", {"d": "Br*2", "s": "4", "h": "Br/2+0.4"}, Spell.Element.WATER, 5+fl*10, 5+fl*80, 0.2+fl*0.8, 1, 80, 80, fl*60)
	var water_large := GlobalData.magic_book.copy_spell("linear", {"d": "Br*3", "s": "2", "h": "Br/2+0.6"}, Spell.Element.WATER, 10+fl*10, 5+fl*90, 0.5+fl, 1, 80, 80, fl*75)
	
	var ice_small := GlobalData.magic_book.copy_spell("linear", {"d": "Br", "s": "8", "h": "Br/2+0.4"}, Spell.Element.ICE, 2+fl*8, 5+fl*70, 0.1+fl*0.4, 1, 80, 80, fl*50)
	var ice_medium := GlobalData.magic_book.copy_spell("linear", {"d": "Br*2", "s": "4", "h": "Br/2+0.8"}, Spell.Element.ICE, 5+fl*10, 5+fl*80, 0.2+fl*0.8, 1, 80, 80, fl*60)
	var ice_large := GlobalData.magic_book.copy_spell("linear", {"d": "Br*3", "s": "2", "h": "Br/2+1.6"}, Spell.Element.ICE, 10+fl*10, 5+fl*90, 0.5+fl, 1, 80, 80, fl*75)
	
	var ice_wall := GlobalData.magic_book.copy_spell("wall", {}, Spell.Element.ICE, 10, 0, 6, 4, 0, 0, 0)
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
		AttackPatterns.choose_from_distribution(0.5, [ 10, 4, 2, 10, 4, 2 ], -1)
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
	health_bar.visible = not current_path == idle_path
	if current_path == idle_path:
		return none_pattern
	else:
		if ice_wall_timer == 0 or ice_wall_timer > 60 * 10:
			ice_wall_timer = 1
			return defence_pattern
		elif vitals.health.value >= 50:
			return default_pattern
		else:
			return sequence_pattern

func entity_info() -> EntityInfo:
	return EntityInfo.new(EntityInfo.Kind.UNDEAD, position)

func update_entity_info(info: EntityInfo) -> bool:
	info.position = position
	return true


func update_behaviour() -> void:
	if current_path == idle_path and sqrt(player.position.distance_squared_to(position)) < vitals.perception.value:
		player.watch_enemy(get_node(".") as Enemy)
		health_bar.visible = true
		default_pattern.reset()
		defence_pattern.reset()
		sequence_pattern.reset()
		current_path = attack_path
	elif current_path == attack_path and sqrt(player.position.distance_squared_to(position)) > vitals.perception.value * 2:
		player.ignore_enemy(get_node(".") as Enemy)
		health_bar.visible = false
		current_path = idle_path

func death_box() -> Vector3:
	return Vector3(0.7, 1.9, 0.3)
