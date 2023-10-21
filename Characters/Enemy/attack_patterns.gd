class_name AttackPatterns

var spells: Array[Spell]
var spell_weight: Array[float]
var is_sequence: bool = false
var start_time: float
var last_use: Dictionary # [String: Unix.Time]
var current_sequence_index: int
var aggression: float

func _init(_spells: Array[Spell], _spell_weight: Array[float], _is_sequence: bool, _aggression: float = 0.0):
	spells = _spells
	spell_weight = _spell_weight
	start_time = 0
	last_use = {}
	current_sequence_index = 0
	is_sequence = _is_sequence
	aggression = _aggression
	if not _is_sequence:
		var total: float = 0.0 
		for s in spell_weight:
			total += s
		for i in range(spell_weight.size()):
			spell_weight[i] = spell_weight[i] / total
	
static func none() -> AttackPatterns:
	return AttackPatterns.new([], [], false, 0.0)
	
func choose_spell_from_distribution(vitals: Vitals, behaviour: Behaviour) -> Spell:
	if randf() > aggression:
		return null
		
	var range_start := 0.0
	var range_end := 0.0
	
	var p := randf()
	for i in range(spell_weight.size()):
		range_end += spell_weight[i]
		var s = spells[i]
		var pass_prob = range_start <= p and p <= range_end
		var pass_cool = Time.get_unix_time_from_system() - last_use.get(s.name, 0) >= s.cooldown
		var pass_mana = vitals.mana.value > s.actual_mana_cost()
		if pass_prob and pass_cool and pass_mana:
			last_use[s.name] = Time.get_unix_time_from_system()
			return s
		range_start = range_end
		
	return null

func choose_spell_from_sequence(vitals: Vitals, behaviour: Behaviour) -> Spell:
	if current_sequence_index >= spells.size():
		current_sequence_index = 0
		
	var s: Spell = spells[current_sequence_index]
	var t: float = spell_weight[current_sequence_index]
	
	var ct := Time.get_unix_time_from_system()
	if ct - start_time >= t:
		start_time = Time.get_unix_time_from_system()
		current_sequence_index += 1
		return s
	else:
		return null

func choose_spell(vitals: Vitals, behaviour: Behaviour) -> Spell:
	if spells.is_empty():
		return null
	return choose_spell_from_sequence(vitals, behaviour) if is_sequence else choose_spell_from_distribution(vitals, behaviour)
