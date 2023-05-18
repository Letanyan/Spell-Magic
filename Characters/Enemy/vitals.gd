class_name Vitals

var health: float
var mana: float
var mana_growth: float
var _mana_limit: float

var burning: float
var wetness: float
var freeze: float

var burn_res: float
var wet_res: float
var freeze_res: float

func _init(_health: float, _mana: float, _burning: float = 0.0, _wetness: float = 0.0, _freeze: float = 0.0, _burn_res: float = 0.0, _wet_res: float = 0.0, _freeze_res: float = 0.0, _mana_growth: float = 0.0):
	health = _health
	mana = _mana
	mana_growth = _mana_growth
	_mana_limit = _mana
	burning = _burning
	wetness = _wetness
	freeze = _freeze
	burn_res = _burn_res
	wet_res = _wet_res
	freeze_res = _freeze_res

func handle_damage(kind: Spell.Element, power: float):
	match kind:
		Spell.Element.FIRE:
			var amount = (1 - burn_res) * power
			if wetness <= 0 and freeze <= 0:
				burning = clamp(burning + amount, 0, 1)
			else:
				power = power * 0.5
			wetness = clamp(wetness - amount, 0, 1)
			freeze = clamp(freeze - amount * 1.5, 0, 1)
		Spell.Element.WATER:
			var amount = (1 - wet_res) * power
			if burning <= 0:
				wetness = clamp(wetness + amount, 0, 1)
			else:
				power = power * 0.5
			burning = clamp(burning - amount, 0, 1)
			freeze = clamp(freeze + amount * freeze, 0, 1)
		Spell.Element.ICE:
			var amount = (1 - freeze_res) * wetness * power
			if wetness > 0:
				freeze = clamp(freeze + amount, 0, 1)
				wetness = clamp(wetness - amount, 0, 1)
			if burning > 0:
				power = power * 0.25
			burning = clamp(burning - amount, 0, 1)
			
	health = clamp(health - power, 0, 100000)
	print("health: ", health, ", burning: ", burning, ", wetness: ", wetness, ", freeze: ", freeze)
	print("element: ", Spell.name_from_element(kind))
	print(wetness_scale())

func update_vitals():
	if freeze > 0:
		freeze = clamp(freeze - (freeze_res + 0.01), 0, 1)
	if burning > 0:
		burning = clamp(burning - (burn_res + 0.05), 0, 1)
		health = clamp(health - burning * health / 100, 0, 1)
	if wetness > 0:
		wetness = clamp(wetness - (wet_res + 0.001), 0, 1)
	mana = clamp(mana + mana_growth, 0, _mana_limit)

func wetness_scale():
	return 1 + wetness
