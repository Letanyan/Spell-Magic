class_name AttackSequence
	
enum Reset { PATH, ATTACK }

var actions: Array # [](Reset, PathStyle, AttackPatterns, ASLabel, ASCondition)
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
	index = 0

func add(action: Variant) -> void:
	actions.append(action)
	
func reset() -> void:
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
	
	var did_update_index := false
		
	var current_action: Variant = actions[index]
	
	if current_action is Reset:
		if current_action == Reset.ATTACK:
			last_attack = null
		elif current_action == Reset.PATH:
			last_path = null
		index += 1
		did_update_index = true
		is_done.data = true
	elif current_action is PathStyle:
		last_path = current_action
		var next_movement := last_path.next_position(delta, me, player, is_done)
		next_movement_speed = next_movement.w
		next_position = Vector3(next_movement.x, next_movement.y, next_movement.z)
		if is_done.data:
			# we can set stored_loops to -x to have last_path repeat x times
			if last_path.stored_loops >= 0:
				did_update_index = true
				index += 1
	elif current_action is AttackPatterns:
		last_attack = current_action
		if last_attack.is_complete:
			did_update_index = true
			index += 1
			is_done.data = true
	elif current_action is ASLabel:
		index += 1
		did_update_index = true
		is_done.data = true
	elif current_action is ASCondition:
		var new_label := (current_action as ASCondition).condition.call() as String
		if new_label.is_empty():
			index += 1
			did_update_index = true
			is_done.data = true
		else:
			var new_index := -1
			for action: Variant in actions:
				new_index += 1
				if action is ASLabel:
					if (action as ASLabel).label == new_label:
						break
			if new_index > -1:
				index = new_index
			else:
				index += 1
			did_update_index = true
			is_done.data = true
			
	return did_update_index


class ASLabel:
	var label: String
	func _init(lbl: String) -> void:
		label = lbl
		
class ASCondition:
	var condition: Callable
	func _init(cond: Callable) -> void:
		condition = cond
		
	static func probability_jump(map: Dictionary) -> ASCondition:
		return ASCondition.new(func() -> String: return Population.random_entity_from_distribution(randf(), map, ""))
