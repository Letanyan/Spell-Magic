class_name AttackPatterns

var spells: Array # [](Spell | AttackPatterns)
var waiting_for_pattern: AttackPatterns
var is_complete: bool = false
var time: float = 0.0
var last_time: float = 0.0
var predicate: Callable

func _init(_spells: Array, _predicate: Callable) -> void:
	spells = _spells
	waiting_for_pattern = null
	time = 0.0
	last_time = -1.0
	predicate = _predicate
	
func reset() -> void:
	time = 0.0
	last_time = Time.get_unix_time_from_system()
	
static func none() -> AttackPatterns:
	return AttackPatterns.new([], func() -> int: return -1)

func choose_spell(vitals: Vitals) -> Spell:
	if spells.is_empty():
		return null
	if waiting_for_pattern:
		if waiting_for_pattern.is_complete:
			waiting_for_pattern = null
		else:
			return waiting_for_pattern.choose_spell(vitals)
	if is_complete:
		return null
			
	if last_time <= 0.0:
		last_time = Time.get_unix_time_from_system()
	var now_time := Time.get_unix_time_from_system()
	time += now_time - last_time
	last_time = now_time
	var is_done := Globals.Ref.new(false)
	var should_reset := Globals.Ref.new(false)
	var index: int = predicate.call(time, is_done, should_reset)
	if is_done.data:
		is_complete = true
	if should_reset.data or is_done.data:
		reset()
	if index <= -1 or index >= spells.size():
		return null
		
	var s: Variant = spells[index]
	if s is AttackPatterns:
		waiting_for_pattern = s as AttackPatterns
		waiting_for_pattern.is_complete = false
		return waiting_for_pattern.choose_spell(vitals)
	else:
		return s as Spell

# use repeat < 0 for infinite
static func choose_from_distribution(interval: float, weights: Array[int], repeat: int = 1) -> Callable:
	var total: float = 0.0
	var probs: Array[float] = []
	var repeat_count := Globals.Ref.new(repeat)
	for s in weights:
		total += s
		probs.append(0.0)
	for i in range(weights.size()):
		probs[i] = weights[i] / total
	
	return func(t: float, is_done: Globals.Ref, should_reset: Globals.Ref) -> int:
		if t < interval or repeat_count.data == 0:
			return -1
		
		repeat_count.data -= 1
		if repeat_count.data == 0:
			is_done.data = true
		if repeat_count.data <= 0:
			should_reset.data = true
		var range_end := 0.0
		var p := randf()
		for i in range(probs.size()):
			range_end += probs[i]
			var pass_prob := p <= range_end
			if not pass_prob:
				continue
			return i
		return -1
		
# use repeat < 0 for infinite
static func choose_in_sequence(intervals: Array[float], repeat: int = 1) -> Callable:
	var starting_points: Array[float] = []
	var completed: Array[bool] = []
	var total := 0.0
	var repeat_count := Globals.Ref.new(repeat)
	for s in intervals:
		total += s
		starting_points.append(total)
		completed.append(false)
	
	return func(t: float, is_done: Globals.Ref, should_reset: Globals.Ref) -> int:
		if repeat_count.data == 0:
			return -1
		var end_index := starting_points.size() - 1
		if t >= starting_points[end_index] and not completed[end_index]:
			if repeat_count.data == 0:
				is_done.data = true
			else:
				repeat_count.data -= 1
				for i in completed.size():
					completed[i] = false
			if repeat_count.data <= 0:
				should_reset.data = true
			return end_index
			
		for i in range(end_index):
			if completed[i]:
				continue
			var range_start := starting_points[i]
			var range_end := starting_points[i + 1]
			var pass_starting_point := range_start <= t and t < range_end
			if not pass_starting_point:
				continue
			completed[i] = true
			return i
		return -1
