class_name Vitals

class Stat:
	var min_value: float
	var max_value: float
	var value: float
	var change_per_tick: float
	var resistance: float
	
	func _init(v: float, min_v: float, max_v: float, change: float = 0, res: float = 0):
		value = v
		min_value = min_v
		max_value = max_v
		change_per_tick = change
		resistance = res
		
	func amount_of_change(p: float) -> float:
		return (1 - resistance) * p
		
	func apply_ignoring_resistance(amount: float):
		value = clamp(value + amount, min_value, max_value)
		
	func update_per_tick():
		apply_ignoring_resistance(change_per_tick)
		

var health: Stat
var mana: Stat

var burning: Stat
var wetness: Stat
var freeze: Stat

var hunger: Stat
var thirst: Stat
var perception: Stat


func _init(_health: Stat, _mana: Stat, _burning := Stat.new(0, 0, 1, -0.05), _wetness := Stat.new(0, 0, 1, -0.001), _freeze := Stat.new(0, 0, 1, -0.01)):
	health = _health
	mana = _mana
	burning = _burning
	wetness = _wetness
	freeze = _freeze
	hunger = Stat.new(0, 0, 0)
	thirst = Stat.new(0, 0, 0)
	perception = Stat.new(50, 0, 100)

func handle_damage(kind: Spell.Element, power: float):
	match kind:
		Spell.Element.FIRE:
			var amount = burning.amount_of_change(power)
			if wetness.value <= 0 and freeze.value <= 0:
				burning.apply_ignoring_resistance(amount)
			else:
				power = power * 0.5
			wetness.apply_ignoring_resistance(-amount)
			freeze.apply_ignoring_resistance(-amount * 1.5)
		Spell.Element.WATER:
			var amount = wetness.amount_of_change(power)
			if burning.value <= 0:
				wetness.apply_ignoring_resistance(amount)
			else:
				power = power * 0.5
			burning.apply_ignoring_resistance(-amount)
			freeze.apply_ignoring_resistance(amount * freeze.value)
		Spell.Element.ICE:
			var amount = freeze.amount_of_change(wetness.value * power)
			if wetness.value > 0:
				freeze.apply_ignoring_resistance(amount)
				wetness.apply_ignoring_resistance(-amount)
			if burning.value > 0:
				power = power * 0.25
			burning.apply_ignoring_resistance(-amount)
			
	health.apply_ignoring_resistance(-power)
	print("health: ", health.value, ", burning: ", burning.value, ", wetness: ", wetness.value, ", freeze: ", freeze.value)
	print("element: ", Spell.name_from_element(kind))
	print(wetness_scale())

func update_vitals():
	freeze.update_per_tick()
	wetness.update_per_tick()
	burning.update_per_tick()
	health.update_per_tick()
	mana.update_per_tick()
	if burning.value > 0:
		health.apply_ignoring_resistance(-burning.value * health.value / 100.0)

func wetness_scale():
	return 1 + wetness.value
