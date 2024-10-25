class_name CharacterBody
extends IKCC

var invunerable := 0.0
var velocity_movement := VelocityMovement.new()
var vitals: Vitals = Vitals.new(Vitals.Stat.new(100, 0, 100), Vitals.Stat.new(50, 0, 50, 0.55))
var bounds: Vector3 = Vector3(0, 0, 0)

func feet_position() -> float:
	return position.y - bounds.y / 2.0
	
func set_feet_position(y: float) -> void:
	position.y = y + bounds.y / 2.0

func add_impulse(impulse: Vector3) -> void:
	velocity_movement.impulse += impulse
