class_name UpgradeSettings

enum PurchaseError {
	NONE, NOT_ENOUGH_CURRENCY, UPGRADE_IS_OVER_LIMIT
}

signal max_velocity_updated(value: float)
signal max_radius_updated(value: float)
signal upgrade_was_purchased(settings: UpgradeSettings)

var currency := 1000


const HAS_VOID := 1 << 0
const HAS_FIRE := 1 << 1
const HAS_WATER := 1 << 2
const HAS_ROCK := 1 << 3
const HAS_AIR := 1 << 4
const HAS_ICE := 1 << 5
const HAS_ELECTRIC := 1 << 6
var has_spell_element := 0b11 # Start with fire and void
var cost_spell_element := 100
func purchase_spell_element(el: Spell.Element) -> PurchaseError:
	if currency < cost_spell_element:
		return PurchaseError.NOT_ENOUGH_CURRENCY
		
	if check_if_has_spell_element(el):
		return PurchaseError.UPGRADE_IS_OVER_LIMIT
		
	has_spell_element |= (1 << el)
	currency -= cost_spell_element
	emit_upgrade_purchase()
	return PurchaseError.NONE
	
func check_if_has_spell_element(el: Spell.Element) -> bool:
	return has_spell_element & (1 << el) != 0

const HAS_CHAIN_ON_START := 1 << 1
const HAS_CHAIN_ON_END := 1 << 2
const HAS_CHAIN_ON_HIT := 1 << 3
var has_chain_method := 1
func cost_chain_method(method: Spell.ChainCastKind) -> int:
	if method == Spell.ChainCastKind.START or method == Spell.ChainCastKind.END:
		return 200
	elif method == Spell.ChainCastKind.HIT:
		return 1000
	else:
		return 0
		
func purchase_chain_method(cm: Spell.ChainCastKind) -> PurchaseError:
	if currency < cost_spell_element:
		return PurchaseError.NOT_ENOUGH_CURRENCY
		
	if check_if_has_chain_method(cm):
		return PurchaseError.UPGRADE_IS_OVER_LIMIT
		
	has_chain_method |= (1 << cm)
	currency -= cost_chain_method(cm)
	emit_upgrade_purchase()
	return PurchaseError.NONE

func check_if_has_chain_method(el: Spell.ChainCastKind) -> bool:
	return has_chain_method & (1 << el) != 0
	

# upgrade_* is the amount the upgrade is increased each level increase
# max_* is the current value
# cost_* is the amount required to perform upgrade
# buff_* is a temporary upgrade gained from artifacts
# LIMIT_* is the maximum amount allowed


var level_r := 1:
	set(value):
		level_r = clampi(value, 1, level_max_r)
		max_radius_updated.emit(max_r())
const level_max_r := 50
func max_r(x: int = level_r) -> float: return x * 0.1
func upgrade_r() -> float: return max_r(level_r + 1) - max_r(level_r)
func cost_r() -> int: return level_r * 50
var buff_r := 0.0
const LIMIT_r := 5.0
func purchase_r() -> PurchaseError:
	if currency < cost_r():
		return PurchaseError.NOT_ENOUGH_CURRENCY
		
	if level_r >= level_max_r:
		return PurchaseError.UPGRADE_IS_OVER_LIMIT
		
	currency -= cost_r()
	level_r += 1
	emit_upgrade_purchase()
	return PurchaseError.NONE


var level_T := 1:
	set(value):
		level_T = clampi(value, 1, level_max_T)
const level_max_T := 25
func max_T(x: int = level_T) -> float: return x
func upgrade_T() -> float: return max_T(level_T + 1) - max_T(level_T)
func cost_T() -> int: return ceili(level_T ** 1.5 * 10)
var buff_T := 0.0
const LIMIT_T := 25.0
func purchase_T() -> PurchaseError:
	if currency < cost_T():
		return PurchaseError.NOT_ENOUGH_CURRENCY
		
	if level_T >= level_max_T:
		return PurchaseError.UPGRADE_IS_OVER_LIMIT
		
	currency -= cost_T()
	level_T += 1
	emit_upgrade_purchase()
	return PurchaseError.NONE


var level_N := 1:
	set(value):
		level_N = clampi(value, 1, level_max_N)
const level_max_N := 25
func max_N(x: int = level_N) -> int: return x
func upgrade_N() -> int: return max_N(level_N + 1) - max_N(level_N)
func cost_N() -> int: return level_N * 150
var buff_N := 0.0
const LIMIT_N := 25
func purchase_N() -> PurchaseError:
	if currency < cost_N():
		return PurchaseError.NOT_ENOUGH_CURRENCY
		
	if level_N >= level_max_N:
		return PurchaseError.UPGRADE_IS_OVER_LIMIT
		
	currency -= cost_N()
	level_N += 1
	emit_upgrade_purchase()
	return PurchaseError.NONE


var level_D := 1:
	set(value):
		level_D = clampi(value, 1, level_max_D)
const level_max_D := 26
func max_D(x: int = level_D) -> float: return (x - 1.0)
func upgrade_D() -> float: return max_D(level_D + 1) - max_D(level_D)
func cost_D() -> int: return level_D * 25
var buff_D := 0.0
const LIMIT_D := 30.0
func purchase_D() -> PurchaseError:
	if currency < cost_D():
		return PurchaseError.NOT_ENOUGH_CURRENCY
		
	if level_D >= level_max_D:
		return PurchaseError.UPGRADE_IS_OVER_LIMIT
		
	currency -= cost_D()
	level_D += 1
	emit_upgrade_purchase()
	return PurchaseError.NONE


var level_P := 1:
	set(value):
		level_P = clampi(value, 1, level_max_P)
const level_max_P := 20
func max_P(x: int = level_P) -> int: return x * 5
func upgrade_P() -> int: return max_P(level_P + 1) - max_P(level_P)
func cost_P() -> int: return level_P * 200
var buff_P := 0.0
const LIMIT_P := 100
func purchase_P() -> PurchaseError:
	if currency < cost_P():
		return PurchaseError.NOT_ENOUGH_CURRENCY
		
	if level_P >= level_max_P:
		return PurchaseError.UPGRADE_IS_OVER_LIMIT
		
	currency -= cost_P()
	level_P += 1
	emit_upgrade_purchase()
	return PurchaseError.NONE

# max spell velocity should be some multiple of player running speed. 
# Since max player speed is 8 we arbitrarily decide to limit spell speed to [8]*4=32
var level_v := 1:
	set(value):
		level_v = clampi(value, 1, level_max_v)
		max_velocity_updated.emit(max_v())
const level_max_v := 25
func max_v(x: int = level_v) -> float: return 4 + x + floorf(x/25.0*3.0)
func upgrade_v() -> float: return max_v(level_v + 1) - max_v(level_v)
func cost_v() -> int: return level_v * 175
var buff_v := 0.0
const LIMIT_v := 32.0
func purchase_v() -> PurchaseError:
	if currency < cost_v():
		return PurchaseError.NOT_ENOUGH_CURRENCY
		
	if level_v >= level_max_v:
		return PurchaseError.UPGRADE_IS_OVER_LIMIT
		
	currency -= cost_v()
	level_v += 1
	emit_upgrade_purchase()
	return PurchaseError.NONE


var level_mana := 1:
	set(value):
		level_mana = clampi(value, 1, level_max_mana)
const level_max_mana := 20
func max_mana(x: int = level_mana) -> float: return x * 50.0
func upgrade_mana() -> float: return max_mana(level_mana + 1) - max_mana(level_mana)
func cost_mana() -> int: return level_mana * 50
var buff_mana := 0.0
const LIMIT_MANA := 1000
func purchase_mana() -> PurchaseError:
	if currency < cost_mana():
		return PurchaseError.NOT_ENOUGH_CURRENCY
		
	if level_mana >= level_max_mana:
		return PurchaseError.UPGRADE_IS_OVER_LIMIT
		
	currency -= cost_mana()
	level_mana += 1
	emit_upgrade_purchase()
	return PurchaseError.NONE


var level_health := 1:
	set(value):
		level_health = clampi(value, 1, level_max_health)
const level_max_health := 20
func max_health(x: int = level_health) -> float: return x * 50.0
func upgrade_health() -> float: return max_health(level_health + 1) - max_health(level_health)
func cost_health() -> int: return level_health * 50
var buff_health := 0.0
const LIMIT_HEALTH := 1000.0
func purchase_health() -> PurchaseError:
	if currency < cost_health():
		return PurchaseError.NOT_ENOUGH_CURRENCY
		
	if level_health >= level_max_health:
		return PurchaseError.UPGRADE_IS_OVER_LIMIT
		
	currency -= cost_health()
	level_health += 1
	emit_upgrade_purchase()
	return PurchaseError.NONE


var level_attack := 1:
	set(value):
		level_attack = clampi(value, 1, level_max_attack)
const level_max_attack := 20
func max_attack(x: int = level_attack) -> float: return x * 5.0
func upgrade_attack() -> float: return max_attack(level_attack + 1) - max_attack(level_attack)
func cost_attack() -> int: return level_attack * 180
var buff_attack := 0.0
const LIMIT_ATTACK := 100
func purchase_attack() -> PurchaseError:
	if currency < cost_attack():
		return PurchaseError.NOT_ENOUGH_CURRENCY
		
	if level_attack >= level_max_attack:
		return PurchaseError.UPGRADE_IS_OVER_LIMIT
		
	currency -= cost_attack()
	level_attack += 1
	emit_upgrade_purchase()
	return PurchaseError.NONE


var level_defence := 1:
	set(value):
		level_defence = clampi(value, 1, level_max_defence)
const level_max_defence := 20
func max_defence(x: int = level_defence) -> float: return x * 5.0
func upgrade_defence() -> float: return max_defence(level_defence + 1) - max_defence(level_defence) 
func cost_defence() -> int: return level_defence * 140
var buff_defence := 0.0
const LIMIT_DEFENCE := 100
func purchase_defence() -> PurchaseError:
	if currency < cost_defence():
		return PurchaseError.NOT_ENOUGH_CURRENCY
		
	if level_defence >= level_max_defence:
		return PurchaseError.UPGRADE_IS_OVER_LIMIT
		
	currency -= cost_defence()
	level_defence += 1
	emit_upgrade_purchase()
	return PurchaseError.NONE


var level_spells_in_book := 1:
	set(value):
		level_spells_in_book = clampi(value, 1, level_max_spells_in_book)
const level_max_spells_in_book := 50
func max_spells_in_book(x: int = level_spells_in_book) -> int: return x * 4
func upgrade_spells_in_book() -> int: return max_spells_in_book(level_spells_in_book + 1) - max_spells_in_book(level_spells_in_book)
func cost_spells_in_book() -> int: return 15
const LIMIT_SPELLS_IN_BOOK := 200
func purchase_spells_in_book() -> PurchaseError:
	if currency < cost_spells_in_book():
		return PurchaseError.NOT_ENOUGH_CURRENCY
		
	if level_spells_in_book >= level_max_spells_in_book:
		return PurchaseError.UPGRADE_IS_OVER_LIMIT
		
	currency -= cost_spells_in_book()
	level_spells_in_book += 1
	emit_upgrade_purchase()
	return PurchaseError.NONE


var level_running_speed := 1:
	set(value):
		level_running_speed = clampi(value, 1, level_max_running_speed)
const level_max_running_speed := 25
func max_running_speed(x: int = level_running_speed) -> float: return 50 # ((x - 1) * 0.25) + 2.0
func upgrade_running_speed() -> float: return max_running_speed(level_running_speed + 1) - max_running_speed(level_running_speed)
func cost_running_speed() -> int: return level_running_speed * 500
var buff_running_speed := 0.0
const LIMIT_RUNNING_SPEED := 8.0
func purchase_running_speed() -> PurchaseError:
	if currency < cost_running_speed():
		return PurchaseError.NOT_ENOUGH_CURRENCY
		
	if level_running_speed >= level_max_running_speed:
		return PurchaseError.UPGRADE_IS_OVER_LIMIT
		
	currency -= cost_running_speed()
	level_running_speed += 1
	emit_upgrade_purchase()
	return PurchaseError.NONE


var level_mana_regen := 1:
	set(value):
		level_mana_regen = clampi(value, 1, level_max_mana_regen)
const level_max_mana_regen := 10
func max_mana_regen(x: int = level_mana_regen) -> float: return x * 0.5
func upgrade_mana_regen() -> float: return max_mana_regen(level_mana_regen + 1) - max_mana_regen(level_mana_regen)
func cost_mana_regen() -> int: return level_mana_regen * 300
const LIMIT_MANA_REGEN := 5
func purchase_mana_regen() -> PurchaseError:
	if currency < cost_mana_regen():
		return PurchaseError.NOT_ENOUGH_CURRENCY
		
	if level_mana_regen >= level_max_mana_regen:
		return PurchaseError.UPGRADE_IS_OVER_LIMIT
		
	currency -= cost_mana_regen()
	level_mana_regen += 1
	emit_upgrade_purchase()
	return PurchaseError.NONE

	
func reset_all_stats_to_default_values() -> void:
	level_r = 1
	level_T = 1
	level_N = 1
	level_D = 1
	level_P = 1
	level_v = 1
	level_mana = 1
	level_health = 1
	level_spells_in_book = 1
	level_running_speed = 1
	level_attack = 1
	level_defence = 1
	level_mana_regen = 1
	has_spell_element = 0b11
	has_chain_method = 0
	currency = 0
	
func reset_all_stats_to_max_values() -> void:
	level_health = 999
	level_mana = 999
	level_attack = 999
	level_defence = 999
	level_D = 999
	level_N = 999
	level_P = 999
	level_r = 999
	level_spells_in_book = 999
	level_running_speed = 999
	level_v = 999
	level_T = 999
	level_mana_regen = 999
	has_spell_element = 0b1111_111
	has_chain_method = 0b111
	currency = 9_999_999

func emit_upgrade_purchase() -> void:
	upgrade_was_purchased.emit(self)

func save_dict() -> Dictionary:
	return {
		"has_spell_element": has_spell_element, "has_chain_method": has_chain_method,
		"cost_spell_element": cost_spell_element,
		
		"level_r": level_r,
		"level_T": level_T, 
		"level_N": level_N, 
		"level_D": level_D, 
		"level_P": level_P, 
		"level_v": level_v,
		"level_mana": level_mana, 
		"level_health": level_health, 
		"level_spells_in_book": level_spells_in_book,
		"level_attack": level_attack, 
		"level_defence": level_defence, 
		"level_running_speed": level_running_speed,
		"level_mana_regen": level_mana_regen,
		
		"currency": currency,
	}

func load_dict(data: Dictionary) -> void:
	has_spell_element = data.get("has_spell_element", 0b1)
	has_chain_method = data.get("has_chain_method", 0)
	cost_spell_element = data.get("cost_spell_element", 100)
	
	level_r = data.get("level_r", 1)
	level_T = data.get("level_T", 1)
	level_N = data.get("level_N", 1)
	level_D = data.get("level_D", 1)
	level_P = data.get("level_P", 1)
	level_v = data.get("level_v", 1)
	level_mana = data.get("level_mana", 1)
	level_health = data.get("level_health", 1)
	level_spells_in_book = data.get("level_spells_in_book", 1)
	level_running_speed = data.get("level_running_speed", 1)
	level_attack = data.get("level_attack", 1)
	level_defence = data.get("level_defence", 1)
	level_mana_regen = data.get("level_mana_regen", 1)
	
	currency = data.get("currency", 0)
