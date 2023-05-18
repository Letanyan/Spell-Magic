class_name AttackPatterns

var spells: Array
var spell_weight: Array
var is_sequence: bool = false
var start_time: float
var current_sequence_index: int

func _init(_spells: Array, _spell_weight: Array, _is_sequence: bool):
	spells = _spells
	spell_weight = _spell_weight
	start_time = 0
	current_sequence_index = 0
	is_sequence = _is_sequence
	if not _is_sequence:
		var total: float = 0.0 
		for s in spell_weight:
			total += s
		for i in range(spell_weight.size()):
			spell_weight[i] = spell_weight[i] / total
	
func choose_spell_from_distribution(vitals: Vitals, behaviour: Behaviour) -> Spell:
	if not randf() < behaviour.aggression * 0.25:
		return null
		
	var range_start = 0.0
	var range_end = 0.0
	
	var p = randf()
	for i in range(spell_weight.size()):
		range_end += spell_weight[i]
		if range_start <= p and p <= range_end:
			return spells[i]
		range_start = range_end
		
	return spells.pick_random()

func choose_spell_from_sequence(vitals: Vitals, behaviour: Behaviour) -> Spell:
	if current_sequence_index >= spells.size():
		current_sequence_index = 0
		
	var s = spells[current_sequence_index]
	var t = spell_weight[current_sequence_index]
	
	var ct = Time.get_unix_time_from_system()
	if ct - start_time >= t:
		start_time = Time.get_unix_time_from_system()
		current_sequence_index += 1
		return s
	else:
		return null

func choose_spell(vitals: Vitals, behaviour: Behaviour) -> Spell:
	return choose_spell_from_sequence(vitals, behaviour) if is_sequence else choose_spell_from_distribution(vitals, behaviour)
