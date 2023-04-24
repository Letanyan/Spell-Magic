class_name AttackPatterns

var spells: Array
var spell_prob: Array

func _init(_spells: Array, _spell_prob: Array):
	spells = _spells
	spell_prob = _spell_prob
	var total: float = 0.0 
	for s in spell_prob:
		total += s
	for i in range(spell_prob.size()):
		spell_prob[i] = spell_prob[i] / total
	
func choose_spell(aggression: float) -> Spell:
	if not randf() < aggression * 0.25:
		return null
		
	var range_start = 0.0
	var range_end = 0.0
	
	var p = randf()
	for i in range(spell_prob.size()):
		range_end += spell_prob[i]
		if range_start <= p and p <= range_end:
			return spells[i]
		range_start = range_end
		
	return spells.pick_random()
