class_name Human
extends Enemy

var none_pattern: AttackPatterns

var idle_path: PathStyle
var attack_path: PathStyle
var water_path: PathStyle
var water_source: Vector3

func _ready():
	super._ready()
	
	animator = $Male_Casual/AnimationPlayer
	
	velocity_movement = VelocityMovement.new()
	
	vitals = Vitals.new(Vitals.Stat.new(100, 0, 100), Vitals.Stat.new(50, 0, 5, 1))
	vitals.thirst = Vitals.Stat.new(1, 0, 1, -0.0002, 0.1)
	vitals.perception.value = 10
	
	idle_path = PathStyle.new(randf()).random_points_in_circle(10, 10).speed(2).set_origin(position)
	attack_path = PathStyle.new(randf()).towards_player(0, 1).speed(2).use_physics()
	current_path = idle_path
	
	none_pattern = AttackPatterns.none()

func attack_state() -> AttackPatterns:
	return none_pattern

func entity_info() -> EntityInfo:
	return EntityInfo.new(EntityInfo.Kind.HUMAN, position)

func update_entity_info(info: EntityInfo) -> bool:
	info.position = position
	return true


func death_box() -> Vector3:
	return Vector3(0.7, 1.9, 0.3)
	
