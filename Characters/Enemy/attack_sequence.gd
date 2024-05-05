class_name AttackSequence
	
enum Reset { PATH, ATTACK }

var actions: Array # [](Reset, PathStyle, AttackPatterns)
var time: float
var index: int
var should_loop: bool

var last_path: PathStyle
var last_attack: AttackPatterns

var next_position: Vector3
var next_movement_speed: float
var next_spell: Spell

func _init(_should_loop: bool, _actions: Array = []) -> void:
	actions = _actions
	should_loop = _should_loop
	time = 0.0
	index = 0

func add(action: Variant) -> void:
	actions.append(action)
	
func reset() -> void:
	time = 0.0
	index = 0
	last_path = null
	last_attack = null
	
func update(delta: float, me: Enemy, player: Player, is_done: Globals.Ref) -> bool:
	if actions.is_empty():
		return false
		
	if index >= actions.size():
		if should_loop:
			index = 0
		else:
			return false
	
	time += delta
	var did_update_index := false
		
	var current_action: Variant = actions[index]
	
	if current_action is Reset:
		if current_action == Reset.ATTACK:
			last_attack = null
		elif current_action == Reset.PATH:
			last_path = null
		index += 1
		did_update_index = true
		time = 0.0
		is_done.data = true
	elif current_action is PathStyle:
		last_path = current_action
		next_position = (current_action as PathStyle).next_position(me, player, is_done, time)
		next_movement_speed = (current_action as PathStyle).movement_speed(time)
		if time > last_path.path.total_duration:
			did_update_index = true
			index += 1
			time = 0.0
	elif current_action is AttackPatterns:
		last_attack = current_action
		did_update_index = true
		index += 1
		time = 0.0
		is_done.data = true
		
	return did_update_index
