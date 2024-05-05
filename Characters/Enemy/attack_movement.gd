extends Node
class_name AttackMovement

enum AMState { IDLE, BEFORE, DURING, AFTER, DONE } 

var before: PathStyle = null
var during: PathStyle = null
var after: PathStyle = null

var state: AMState = AMState.IDLE

func _init(b: PathStyle = null, d: PathStyle = null, a: PathStyle = null) -> void:
	before = b
	during = d
	after = a
	if b == null and d == null and a == null:
		state = AMState.DONE
	else:
		state = AMState.BEFORE
	
func current_path() -> PathStyle:
	match state:
		AMState.IDLE: return null
		AMState.BEFORE: return before
		AMState.DURING: return during
		AMState.AFTER: return after
		AMState.DONE: return null
	return null
	
func reset_state() -> void:
	if before == null and during == null and after == null:
		state = AMState.DONE
	else:
		state = AMState.BEFORE
	
func next_state() -> void:
	if state == AMState.IDLE:
		state = AMState.BEFORE
	elif state == AMState.BEFORE:
		state = AMState.DURING
	elif state == AMState.DURING:
		state = AMState.AFTER
	elif state == AMState.AFTER:
		state = AMState.DONE
	elif state == AMState.DONE:
		state = AMState.DONE
