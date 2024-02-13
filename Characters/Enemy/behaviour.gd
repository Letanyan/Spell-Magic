class_name Behaviour

var passive: PathStyle
var aggresive: PathStyle

var aggression_radius: float = 30.0
var passive_radius: float = 90.0

var current: PathStyle
var aggression: float

func _init(_passive: PathStyle, _aggresive: PathStyle, _aggression: float):
	passive = _passive
	aggresive = _aggresive 
	current = passive
	aggression = _aggression

func movement_speed():
	return current.movement_speed()
	
func is_aggresive() -> bool:
	return current == aggresive

func next_position(me: Enemy, player: Player) -> Vector3:
	return current.next_position(me, player)

func update_state(me: Enemy, player: Player):
	if current == passive and sqrt(player.position.distance_squared_to(me.position)) < aggression_radius:
		print("aggro: ", sqrt(player.position.distance_squared_to(me.position)))
		current = aggresive
		aggression = 0.5
	elif current == aggresive and sqrt(player.position.distance_squared_to(me.position)) > passive_radius:
		print("passive: ", sqrt(player.position.distance_squared_to(me.position)))
		current = passive
		aggression = 0.0
