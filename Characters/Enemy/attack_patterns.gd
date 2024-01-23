class_name AttackPatterns

class SpellMovement:
	var spell: Spell
	var movement: AttackMovement
	
	func _init(s: Spell, m: AttackMovement) -> void:
		spell = s
		movement = m

var spells: Array
var movements: Array[AttackMovement]
var spell_weight: Array[float]
var is_sequence: bool = false
var start_time: float
var last_use: Dictionary # [String: Unix.Time]
var current_sequence_index: int
var aggression: float
var waiting_for_pattern: AttackPatterns
var is_complete: bool = false


func _init(_spells: Array, _spell_weight: Array[float], _is_sequence: bool, _aggression: float = 0.0, _movements: Array[AttackMovement] = []):
	assert(_spells.size() == _spell_weight.size(), "spells array must be same size as spell weight")
	assert(_movements == [] or _movements.size() == _spells.size(), "movements array must be same size as spells array or it must be an empty array")
	
	spells = _spells
	spell_weight = _spell_weight
	if _movements.is_empty():
		movements = []
		for i in range(spells.size()):
			movements.append(AttackMovement.new())
	else:
		movements = _movements
	start_time = 0
	last_use = {}
	current_sequence_index = 0
	is_sequence = _is_sequence
	waiting_for_pattern = null
	aggression = _aggression
	if not _is_sequence:
		var total: float = 0.0 
		for s in spell_weight:
			total += s
		for i in range(spell_weight.size()):
			spell_weight[i] = spell_weight[i] / total
	
static func none() -> AttackPatterns:
	return AttackPatterns.new([], [], false, 0.0, [])
	
func choose_spell_from_distribution(vitals: Vitals, behaviour: Behaviour) -> SpellMovement:
	if randf() > aggression:
		return null
		
	is_complete = true
	var range_start := 0.0
	var range_end := 0.0
	
	var p := randf()
	for i in range(spell_weight.size()):
		range_end += spell_weight[i]
		var s = spells[i]
		var pass_prob = range_start <= p and p <= range_end
		if not pass_prob:
			continue
			
		if s is AttackPatterns:
			waiting_for_pattern = s as AttackPatterns
			waiting_for_pattern.is_complete = false
			return waiting_for_pattern.choose_spell(vitals, behaviour)
		else:
			var pass_cool : bool = Time.get_unix_time_from_system() - last_use.get(s.name, 0) >= s.cooldown
			var pass_mana : bool = vitals.mana.value > s.actual_mana_cost()
			if pass_cool and pass_mana:
				last_use[s.name] = Time.get_unix_time_from_system()
				return SpellMovement.new(s, movements[i])
		range_start = range_end
		
	return null

func choose_spell_from_sequence(vitals: Vitals, behaviour: Behaviour) -> SpellMovement:
	if current_sequence_index >= spells.size():
		is_complete = true
		current_sequence_index = 0
		
	var s = spells[current_sequence_index]
	var t: float = spell_weight[current_sequence_index]
	var m: AttackMovement = movements[current_sequence_index]
	
	var ct := Time.get_unix_time_from_system()
	if ct - start_time >= t:
		start_time = Time.get_unix_time_from_system()
		current_sequence_index += 1
		if s is AttackPatterns:
			waiting_for_pattern = s as AttackPatterns
			waiting_for_pattern.is_complete = false
			return waiting_for_pattern.choose_spell(vitals, behaviour)
		else:
			return SpellMovement.new(s, m)
	else:
		return null

func choose_spell(vitals: Vitals, behaviour: Behaviour) -> SpellMovement:
	if spells.is_empty():
		return null
	if waiting_for_pattern:
		if waiting_for_pattern.is_complete:
			waiting_for_pattern = null
		else:
			return waiting_for_pattern.choose_spell(vitals, behaviour)
	return choose_spell_from_sequence(vitals, behaviour) if is_sequence else choose_spell_from_distribution(vitals, behaviour)
