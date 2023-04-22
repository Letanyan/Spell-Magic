class_name StateManager

var passive: PathStyle
var aggresive: PathStyle

var current: PathStyle

func _init(_passive: PathStyle, _aggresive: PathStyle):
	passive = _passive
	aggresive = _aggresive 
	current = passive

func next_position(player: Player) -> Vector3:
	return current.next_position(player)

func update_state(me: Enemy, player: Player):
	if sqrt(player.position.distance_squared_to(me.position)) < 10:
		current = aggresive
	elif current == aggresive and sqrt(player.position.distance_squared_to(me.position)) > 50:
		current = passive
