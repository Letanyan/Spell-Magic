class_name Human
extends Enemy

var none_pattern: AttackPatterns
var default_pattern: AttackPatterns

var idle_path: PathStyle
var attack_path: PathStyle
var water_path: PathStyle
var water_source: Vector3

func _ready():
	super._ready()
	
	velocity_movement = VelocityMovement.new()
	
	vitals = Vitals.new(Vitals.Stat.new(100, 0, 100), Vitals.Stat.new(50, 0, 5, 1))
	vitals.perception.value = 10
	
	idle_path = PathStyle.new(randf()).speed(2).random_points_in_circle(10, 10).set_origin(position)
	attack_path = PathStyle.new(randf()).towards_player(3, 5).speed(3).use_physics()
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()
	
	var fire_blast := GlobalData.magic_book.spell_with_name("linear", {"d":"1", "s":"4"})
	fire_blast.element = Spell.Element.FIRE
	var water_blast := GlobalData.magic_book.spell_with_name("linear", {"s":"5", "d":"1"})
	water_blast.element = Spell.Element.WATER
	var rock_blast := GlobalData.magic_book.spell_with_name("linear", {"d":"1", "s":"4"})
	rock_blast.element = Spell.Element.ROCK
	var ice_blast := GlobalData.magic_book.spell_with_name("linear", {"s":"5", "d":"1"})
	ice_blast.element = Spell.Element.ICE
	var electric_blast := GlobalData.magic_book.spell_with_name("linear", {"d":"1", "s":"4"})
	electric_blast.element = Spell.Element.ELECTRIC
	
	default_pattern = AttackPatterns.new(
		[
			fire_blast,
			water_blast,
			rock_blast,
			ice_blast,
			electric_blast,
		],
		[ 5, 5, 5, 5, 5 ],
		0.5
	)

func attack_state() -> AttackPatterns:
	health_bar.visible = not current_path == idle_path
	if current_path == idle_path:
		return none_pattern
	else:
		return default_pattern
		
func update_behaviour():
	if vitals.health.value < vitals.health.max_value:
		if current_path == idle_path and sqrt(player.position.distance_squared_to(position)) < vitals.perception.value:
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
	
