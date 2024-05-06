class_name AttackPatterns

var spells: Array # [](Spell, AttackPatterns)
var waiting_for_pattern: AttackPatterns
var is_complete: bool = false
var time: float = 0.0
var last_time: float = 0.0
var predicate: Callable

func _init(_spells: Array, _predicate: Callable) -> void:
	spells = _spells
	waiting_for_pattern = null
	time = 0.0
	last_time = Time.get_unix_time_from_system()
	predicate = _predicate
	
func reset() -> void:
	time = 0.0
	last_time = Time.get_unix_time_from_system()
	
static func none() -> AttackPatterns:
	return AttackPatterns.new([], func() -> void: return)

func choose_spell(vitals: Vitals) -> Spell:
	if spells.is_empty():
		return null
	if waiting_for_pattern:
		if waiting_for_pattern.is_complete:
			waiting_for_pattern = null
		else:
			return waiting_for_pattern.choose_spell(vitals)
			
	var now_time := Time.get_unix_time_from_system()
	time += now_time - last_time
	last_time = now_time
	var is_done := Globals.Ref.new(false)
	var index: int = predicate.call(time, is_done)
	if is_done.data:
		is_complete = true
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

static func choose_from_distribution(agro: float, weights: Array[int]) -> Callable:
	var total: float = 0.0
	var probs: Array[float] = []
	for s in weights:
		total += s
		probs.append(0.0)
	for i in range(weights.size()):
		probs[i] = weights[i] / total
	
	return func(t: float, is_done: Globals.Ref) -> int:
		if randf() > agro:
			return -1
		
		is_done.data = true
		var range_end := 0.0
		var p := randf()
		for i in range(probs.size()):
			range_end += probs[i]
			var pass_prob := p <= range_end
			if not pass_prob:
				continue
			return i
		return -1
		
static func choose_in_sequence(intervals: Array[float]) -> Callable:
	var starting_points: Array[float] = []
	var completed: Array[bool] = []
	var total := 0.0
	for s in intervals:
		total += s
		starting_points.append(total)
		completed.append(false)
	
	return func(t: float, is_done: Globals.Ref) -> int:
		var end_index := starting_points.size() - 1
		if t >= starting_points[end_index] and not completed[end_index]:
			is_done.data = true
			for i in completed.size():
				completed[i] = false
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
