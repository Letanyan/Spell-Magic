class_name Human
extends Enemy

var none_pattern: AttackPatterns

var idle_path: PathStyle
var attack_path: PathStyle

enum HumanState {
	STANDING, DRINKING, WALKING
}
var house_location: Vector3
var state: HumanState = HumanState.STANDING 
var drinking_source: EntityInfo = null

func _ready():
	super._ready()
	
	animator = $Male_Casual/AnimationPlayer
	
	animation_map["idle"] = "Man_Idle"
	animation_map["walk"] = "Man_Walk"
	animation_map["run"] = "Man_Run"
	
	velocity_movement = VelocityMovement.new()
	
	vitals = Vitals.new(Vitals.Stat.new(100, 0, 100), Vitals.Stat.new(50, 0, 5, 1))
	vitals.thirst = Vitals.Stat.new(1, 0, 1, -0.1, 0.0005)
	vitals.perception.value = 10
	
	idle_path = PathStyle.new(randf()).random_points_in_circle(10, 10).speed(2).set_origin(position)
	attack_path = PathStyle.new(randf()).towards_player(0, 1).speed(2).use_physics()
	current_path = idle_path
	house_location = position
	
	knowledge = Knowledge.new({EntityInfo.Kind.PLAYER: true, EntityInfo.Kind.UNDEAD: true, EntityInfo.Kind.BUILDING: true}, false)
	
	none_pattern = AttackPatterns.none()
	
	update_stored_entity_knowledge()

func attack_state() -> AttackPatterns:
	return none_pattern

func entity_info() -> EntityInfo:
	return EntityInfo.new(EntityInfo.Kind.HUMAN, position)

func update_entity_info(info: EntityInfo):
	info.position = position


func update_behaviour():
	match state:
		HumanState.STANDING:
			if vitals.thirst.value < 0.5:
				for k in knowledge.entries:
					var e: EntityInfo = knowledge.entries[k]
					if e.liquid == EntityInfo.Liquid.WATER and e.liquid_amount > 0:
						state = HumanState.DRINKING
						drinking_source = e
						current_path = PathStyle.new(randf()).towards(drinking_source.position, 0, 0).speed(2).use_physics()
						break
			elif vitals.thirst.value >= 0.75:
				state = HumanState.WALKING
				current_path = PathStyle.new(randf()).random_points_in_circle(10, 10).speed(2).set_origin(house_location)
		HumanState.WALKING:
			if vitals.thirst.value < 0.75:
				state = HumanState.STANDING
				current_path = PathStyle.new(randf()).towards(position, 0, 0)
		HumanState.DRINKING:
			if drinking_source != null and drinking_source.position.distance_to(position) <= drinking_source.bounds.shape.radius * 2:
				vitals.thirst.apply(drinking_source.liquid_amount)
			if vitals.thirst.value >= 1.0:
				state = HumanState.WALKING
				current_path = PathStyle.new(randf()).random_points_in_circle(10, 10).speed(2).set_origin(house_location)

func death_box() -> Vector3:
	return Vector3(0.7, 1.9, 0.3)
	
