class_name AttackSequence
	
enum ASOptions { 
	RESET_PATH, # immediatly null Path 
	RESET_ATTACK, # immediatly null Attack
	PERSIST_PATH, # ignore Path is_done and keep going with Path
	PERSIST_ATTACK, # ignore Attack is_done and keep going with Attack
	AUTO_RESET_PATH, # null Path when is_done
	AUTO_RESET_ATTACK # null Attack when is_done
}
enum Persist { PATH = 1 << 0, ATTACK = 1 << 1 }

var actions: Array # [](ASOptions, PathStyle, AttackPatterns, ASLabel, ASCondition)
var index: int
var should_loop: bool
var persist: int = 0 #Persist.ATTACK

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
	
func update(delta: float, me: Node3D, player: Variant, is_done: Globals.Ref) -> bool:
	if actions.is_empty():
		return false
		
	if index >= actions.size():
		if should_loop:
			index = 0
		else:
			return false
	
	var did_update_index := false
		
	var current_action: Variant = actions[index]
	const DEBUG = false
	if current_action is ASOptions:
		if current_action == ASOptions.RESET_ATTACK:
			if DEBUG: print(index, " RESET: ATTACK")
			last_attack = null
		elif current_action == ASOptions.RESET_PATH:
			if DEBUG: print(index, " RESET: PATH")			
			last_path = null
		elif current_action == ASOptions.PERSIST_ATTACK:
			if DEBUG: print(index, " PERSIST: ATTACK")	
			persist |= Persist.ATTACK
		elif current_action == ASOptions.PERSIST_PATH:
			if DEBUG: print(index, " PERSIST: PATH")	
			persist |= Persist.PATH
		elif current_action == ASOptions.AUTO_RESET_ATTACK:
			if DEBUG: print(index, " AUTO RESET: ATTACK")	
			persist &= ~Persist.ATTACK
		elif current_action == ASOptions.AUTO_RESET_PATH:
			if DEBUG: print(index, " AUTO RESET: PATH")	
			persist &= ~Persist.PATH
		index += 1
		did_update_index = true
		is_done.data = true
	elif current_action is PathStyle:
		if DEBUG: print(index, " PathStyle")
		if last_path != current_action:
			last_path = current_action
			last_path.time = NAN
		var next_movement := last_path.next_position(delta, me, player, is_done)
		next_movement_speed = next_movement.w
		next_position = Vector3(next_movement.x, next_movement.y, next_movement.z)
		if is_done.data:
			# we can set loop_count_start to -x to have last_path repeat x times
			if last_path.stored_loops >= 0:
				did_update_index = true
				index += 1
				if (persist & Persist.PATH) == 0:
					last_path.reset()
					last_path = null
	elif current_action is AttackPatterns:
		if DEBUG: print(index, " AttackPatterns")
		last_attack = current_action
		if last_attack.is_complete:
			last_attack.reset()
			last_attack.is_complete = false
			did_update_index = true
			index += 1
			is_done.data = true
			if (persist & Persist.ATTACK) == 0:
				last_attack = null
	elif current_action is ASLabel:
		if DEBUG: print(index, " ASLabel")		
		index += 1
		did_update_index = true
		is_done.data = true
	elif current_action is ASCondition:
		if DEBUG: print(index, " ASCondition")	
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

func is_complete() -> bool:
	return index >= actions.size()

class ASLabel:
	var label: String
	func _init(lbl: String) -> void:
		label = lbl
		
class ASCondition:
	var condition: Callable
	func _init(cond: Callable) -> void:
		condition = cond
		
	static func probability_jump(map: Dictionary) -> ASCondition:
		return ASCondition.new(func() -> String: return Rand.entity_from_distribution(randf(), map, ""))
