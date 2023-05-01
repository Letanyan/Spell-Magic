class_name Vitals

var health: float
var mana: float

var burning: float
var wetness: float
var freeze: float

var burn_res: float
var wet_res: float
var freeze_res: float

func _init(_health: float, _mana: float, _burning: float = 0.0, _wetness: float = 0.0, _freeze: float = 0.0):
	health = _health
	mana = _mana
	burning = _burning
	wetness = _wetness
	freeze = _freeze

func handle_damage(kind: Spell.Element, power: float):
	match kind:
		Spell.Element.FIRE:
			var amount = (1 - burn_res) * power
			if wetness <= 0:
				burning += amount
				burning = clamp(burning, 0, 1)
			else:
				power = power * 0.5
			wetness -= amount
			wetness = clamp(wetness, 0, 1)
		Spell.Element.WATER:
			var amount = (1 - wet_res) * power
			if burning <= 0:
				wetness += amount
				wetness = clamp(wetness, 0, 1)
			else:
				power = power * 0.5
			burning -= amount
			burning = clamp(burning, 0, 1)
		Spell.Element.ICE:
			var amount = (1 - freeze_res) * wetness * power
			if wetness > 0:
				freeze += amount
				freeze = clamp(freeze, 0, 1)	
				wetness -= amount
				wetness = clamp(wetness, 0, 1)
			if burning > 0:
				power = power * 0.5
			burning -= amount
			burning = clamp(burning, 0, 1)
			
	health -= power
	print("health: ", health, ", burning: ", burning, ", wetness: ", wetness, ", freeze: ", freeze)
	print("element: ", Spell.name_from_element(kind))
