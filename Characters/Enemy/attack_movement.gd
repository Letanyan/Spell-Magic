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
	
func reset_state():
	if before == null and during == null and after == null:
		state = AMState.DONE
	else:
		state = AMState.BEFORE
	
func next_state():
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

func next_position(me: Enemy, player: Player) -> Vector3:
	var is_done := Globals.Ref.new(false)
	match state:
		AMState.IDLE: return Vector3.ZERO
		AMState.BEFORE:
			if before:
				var result := before.next_position(me, player, is_done) 
				if is_done.data:
					state = AMState.DURING
				return result
		AMState.DURING:
			if during:
				var result := during.next_position(me, player, is_done) 
				if is_done.data:
					state = AMState.AFTER
				return result
		AMState.AFTER:
			if after:
				var result := after.next_position(me, player, is_done) 
				if is_done.data:
					state = AMState.DONE
				return result
		AMState.DONE: 
			return Vector3.ZERO
	return Vector3.ZERO
