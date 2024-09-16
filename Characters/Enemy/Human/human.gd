class_name Human
extends Enemy

var none_pattern: AttackPatterns
var default_pattern: AttackPatterns

var idle_path: PathStyle
var attack_path: PathStyle
var water_path: PathStyle
var water_source: Vector3
	
func setup(seedling: int) -> void:
	vitals = Vitals.new(Vitals.Stat.new(100, 0, 100), Vitals.Stat.new(50, 0, 5, 1))
	vitals.perception.value = 10
	
	idle_path = PathStyle.new(seedling, position).random_points_in_circle(2, 10, 0, 10).align_y_to_ground().use_absolute()
	attack_path = PathStyle.new().towards_player(3, 3, 5).use_physics()
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	var fire_blast := GlobalData.magic_book.copy_spell("linear", {"d":"1", "s":"4"}, Spell.Element.FIRE)
	var water_blast := GlobalData.magic_book.copy_spell("linear", {"s":"5", "d":"1"}, Spell.Element.WATER)
	var rock_blast := GlobalData.magic_book.copy_spell("linear", {"d":"1", "s":"4"}, Spell.Element.ROCK)
	var ice_blast := GlobalData.magic_book.copy_spell("linear", {"s":"5", "d":"1"}, Spell.Element.ICE)
	var electric_blast := GlobalData.magic_book.copy_spell("linear", {"d":"1", "s":"4"}, Spell.Element.ELECTRIC)
	
	default_pattern = AttackPatterns.new(
		[
			fire_blast,
			water_blast,
			rock_blast,
			ice_blast,
			electric_blast,
		],
		AttackPatterns.choose_from_distribution(0.5, [ 5, 5, 5, 5, 5 ], -1)
	)
	kind = World.Enemy.HUMAN

func attack_state() -> AttackPatterns:
	health_bar.visible = not current_path == idle_path
	if current_path == idle_path:
		return none_pattern
	else:
		return default_pattern
		
func update_behaviour() -> void:
	if vitals.health.value < vitals.health.max_value:
		if current_path == idle_path and sqrt(player.position.distance_squared_to(position)) < vitals.perception.value:
			default_pattern.reset()
			current_path = attack_path
		elif current_path == attack_path and sqrt(player.position.distance_squared_to(position)) > vitals.perception.value * 2:
			current_path = idle_path
	else:
		current_path = idle_path

func entity_info() -> EntityInfo:
	return EntityInfo.new(EntityInfo.Kind.HUMAN, position)

func update_entity_info(info: EntityInfo) -> bool:
	info.position = position
	return true


func death_box() -> Vector3:
	return Vector3(0.7, 1.9, 0.3)
	
