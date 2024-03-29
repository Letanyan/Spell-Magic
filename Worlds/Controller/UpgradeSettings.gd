class_name UpgradeSettings

enum PurchaseError {
	NONE, NOT_ENOUGH_CURRENCY, UPGRADE_IS_OVER_LIMIT
}

const HAS_VOID := 1 << 0
const HAS_FIRE := 1 << 1
const HAS_WATER := 1 << 2
const HAS_ROCK := 1 << 3
const HAS_AIR := 1 << 4
const HAS_ICE := 1 << 5
const HAS_ELECTRIC := 1 << 6
var has_spell_element := 0b11 # Start with fire and void
var cost_spell_element := 100

const HAS_CHAIN_ON_START := 1 << 0
const HAS_CHAIN_ON_END := 1 << 1
const HAS_CHAIN_ON_HIT := 1 << 2
var has_chain_method := 0
var cost_chain_method := 100

var upgrade_r := 0.1
var max_r := 0.1:
	set(value):
		max_r = value
		max_radius_updated.emit(value)
var cost_r := 10
var buff_r := 0.0
const LIMIT_r := 5.0
var upgrade_T := 1.0
var max_T := 1.0
var cost_T := 10
var buff_T := 0.0
const LIMIT_T := 25.0
var upgrade_N := 1
var max_N := 1
var cost_N := 10
var buff_N := 0.0
const LIMIT_N := 25
var upgrade_D := 1.0
var max_D := 0.0
var cost_D := 10
var buff_D := 0.0
const LIMIT_D := 30.0
var upgrade_P := 5
var max_P := 10
var cost_P := 10
var buff_P := 0.0
const LIMIT_P := 100
var upgrade_v := 2.5
var max_v := 2.5:
	set(value):
		max_v = value
		max_velocity_updated.emit(value)
var cost_v := 10
var buff_v := 0.0
const LIMIT_v := 100.0

var upgrade_mana := 10.0
var max_mana := 100.0
var cost_mana := 10
var buff_mana := 0.0
const LIMIT_MANA := 1000 
var upgrade_health := 10.0
var max_health := 100.0
var cost_health := 10
const LIMIT_HEALTH := 1000.0

var upgrade_attack := 5.0
var max_attack := 10.0
var cost_attack := 10
var buff_attack := 0.0
const LIMIT_ATTACK := 100
var upgrade_defence := 5.0
var max_defence := 10.0
var cost_defence := 10
var buff_defence := 0.0
const LIMIT_DEFENCE := 100

var upgrade_spells_in_book := 2
var max_spells_in_book := 4
var cost_spells_in_book := 25
const LIMIT_SPELLS_IN_BOOK := 200

var upgrade_running_speed := 0.25
var max_running_speed := 2.0
var cost_running_speed := 50
var buff_running_speed := 0.0
const LIMIT_RUNNING_SPEED := 15.0

var currency := 1000

signal max_velocity_updated(value: float)
signal max_radius_updated(value: float)

func check_if_has_spell_element(el: Spell.Element) -> bool:
	return has_spell_element & (1 << el) != 0

func check_if_has_chain_method(el: Spell.ChainCastKind) -> bool:
	return has_chain_method & (1 << el) != 0

func reset_all_stats_to_default_values():
	max_r = 0.1
	max_T = 1.0
	max_N = 1
	max_D = 0.0
	max_P = 1
	max_v = 2.5
	max_mana = 100.0
	max_health = 100.0
	max_spells_in_book = 4
	max_running_speed = 2.0
	max_attack = 10.0
	max_defence = 10.0
	has_spell_element = 0b11
	has_chain_method = 0
	
func reset_all_stats_to_max_values():
	max_health = UpgradeSettings.LIMIT_HEALTH
	max_mana = UpgradeSettings.LIMIT_MANA
	max_attack = UpgradeSettings.LIMIT_ATTACK
	max_defence = UpgradeSettings.LIMIT_DEFENCE
	max_D = UpgradeSettings.LIMIT_D
	max_N = UpgradeSettings.LIMIT_N
	max_P = UpgradeSettings.LIMIT_P
	max_r = UpgradeSettings.LIMIT_r
	max_spells_in_book = UpgradeSettings.LIMIT_SPELLS_IN_BOOK
	max_running_speed = UpgradeSettings.LIMIT_RUNNING_SPEED
	max_v = UpgradeSettings.LIMIT_v
	max_T = UpgradeSettings.LIMIT_T
	has_spell_element = 0b1111_111
	has_chain_method = 0b111

func purchase_spells_in_book() -> PurchaseError:
	if currency < cost_spells_in_book:
		return PurchaseError.NOT_ENOUGH_CURRENCY
		
	if max_spells_in_book + upgrade_spells_in_book > LIMIT_SPELLS_IN_BOOK:
		return PurchaseError.UPGRADE_IS_OVER_LIMIT
		
	max_spells_in_book += upgrade_spells_in_book
	currency -= cost_spells_in_book
	return PurchaseError.NONE
	
func purchase_running_speed() -> PurchaseError:
	if currency < cost_running_speed:
		return PurchaseError.NOT_ENOUGH_CURRENCY
		
	if max_running_speed + upgrade_running_speed > LIMIT_RUNNING_SPEED:
		return PurchaseError.UPGRADE_IS_OVER_LIMIT
		
	max_running_speed += upgrade_running_speed
	currency -= cost_running_speed
	return PurchaseError.NONE
	
func purchase_health() -> PurchaseError:
	if currency < cost_health:
		return PurchaseError.NOT_ENOUGH_CURRENCY
		
	if max_health + upgrade_health > LIMIT_HEALTH:
		return PurchaseError.UPGRADE_IS_OVER_LIMIT
		
	max_health += upgrade_health
	currency -= cost_health
	return PurchaseError.NONE

func purchase_mana() -> PurchaseError:
	if currency < cost_mana:
		return PurchaseError.NOT_ENOUGH_CURRENCY
		
	if max_mana + upgrade_mana > LIMIT_MANA:
		return PurchaseError.UPGRADE_IS_OVER_LIMIT
		
	max_mana += upgrade_mana
	currency -= cost_mana
	return PurchaseError.NONE
	
func purchase_attack() -> PurchaseError:
	if currency < cost_attack:
		return PurchaseError.NOT_ENOUGH_CURRENCY
		
	if max_attack + upgrade_attack > LIMIT_ATTACK:
		return PurchaseError.UPGRADE_IS_OVER_LIMIT
		
	max_attack += upgrade_attack
	currency -= cost_attack
	return PurchaseError.NONE

func purchase_defence() -> PurchaseError:
	if currency < cost_defence:
		return PurchaseError.NOT_ENOUGH_CURRENCY
		
	if max_defence + upgrade_defence > LIMIT_DEFENCE:
		return PurchaseError.UPGRADE_IS_OVER_LIMIT
		
	max_defence += upgrade_defence
	currency -= cost_defence
	return PurchaseError.NONE
	
	
func purchase_v() -> PurchaseError:
	if currency < cost_v:
		return PurchaseError.NOT_ENOUGH_CURRENCY
		
	if max_v + upgrade_v > LIMIT_v:
		return PurchaseError.UPGRADE_IS_OVER_LIMIT
		
	max_v += upgrade_v
	currency -= cost_v
	return PurchaseError.NONE

func purchase_P() -> PurchaseError:
	if currency < cost_P:
		return PurchaseError.NOT_ENOUGH_CURRENCY
		
	if max_P + upgrade_P > LIMIT_P:
		return PurchaseError.UPGRADE_IS_OVER_LIMIT
		
	max_P += upgrade_P
	currency -= cost_P
	return PurchaseError.NONE

func purchase_D() -> PurchaseError:
	if currency < cost_D:
		return PurchaseError.NOT_ENOUGH_CURRENCY
		
	if max_D + upgrade_D > LIMIT_D:
		return PurchaseError.UPGRADE_IS_OVER_LIMIT
		
	max_D += upgrade_D
	currency -= cost_D
	return PurchaseError.NONE
	
func purchase_N() -> PurchaseError:
	if currency < cost_N:
		return PurchaseError.NOT_ENOUGH_CURRENCY
		
	if max_N + upgrade_N > LIMIT_N:
		return PurchaseError.UPGRADE_IS_OVER_LIMIT
		
	max_N += upgrade_N
	currency -= cost_N
	return PurchaseError.NONE
	
func purchase_T() -> PurchaseError:
	if currency < cost_T:
		return PurchaseError.NOT_ENOUGH_CURRENCY
		
	if max_T + upgrade_T > LIMIT_T:
		return PurchaseError.UPGRADE_IS_OVER_LIMIT
		
	max_T += upgrade_T
	currency -= cost_T
	return PurchaseError.NONE

func purchase_r() -> PurchaseError:
	if currency < cost_r:
		return PurchaseError.NOT_ENOUGH_CURRENCY
		
	if max_r + upgrade_r > LIMIT_r:
		return PurchaseError.UPGRADE_IS_OVER_LIMIT
		
	max_r += upgrade_r
	currency -= cost_r
	return PurchaseError.NONE
	
func purchase_spell_element(el: Spell.Element) -> PurchaseError:
	if currency < cost_spell_element:
		return PurchaseError.NOT_ENOUGH_CURRENCY
		
	if check_if_has_spell_element(el):
		return PurchaseError.UPGRADE_IS_OVER_LIMIT
		
	has_spell_element |= (1 << el)
	currency -= cost_spell_element
	return PurchaseError.NONE
	
func purchase_chain_method(cm: Spell.ChainCastKind) -> PurchaseError:
	if currency < cost_spell_element:
		return PurchaseError.NOT_ENOUGH_CURRENCY
		
	if check_if_has_chain_method(cm):
		return PurchaseError.UPGRADE_IS_OVER_LIMIT
		
	has_chain_method |= (1 << cm)
	currency -= cost_chain_method
	return PurchaseError.NONE

func save_dict():
	return {
		"has_spell_element": has_spell_element, "has_chain_method": has_chain_method,
		"max_r": max_r, "max_T": max_T, "max_N": max_N, "max_D": max_D, "max_P": max_P, "max_v": max_v,
		"max_mana": max_mana, "max_health": max_health, "max_spells_in_book": max_spells_in_book,
		"max_attack": max_attack, "max_defence": max_defence, "max_running_speed": max_running_speed,
				
		"cost_spell_element": cost_spell_element, "cost_chain_method": cost_chain_method,
		"cost_r": cost_r, "cost_T": cost_T, "cost_N": cost_N, "cost_D": cost_D, "cost_P": cost_P, "cost_v": cost_v,
		"cost_mana": cost_mana, "cost_health": cost_health, "cost_spells_in_book": cost_spells_in_book,
		"cost_attack": cost_attack, "cost_defence": cost_defence, "cost_running_speed": cost_running_speed,
		
		"upgrade_r": upgrade_r, "upgrade_T": upgrade_T, "upgrade_N": upgrade_N, "upgrade_D": upgrade_D, "upgrade_P": upgrade_P, "upgrade_v": upgrade_v,
		"upgrade_mana": upgrade_mana, "upgrade_health": upgrade_health, "upgrade_spells_in_book": upgrade_spells_in_book,
		"upgrade_attack": upgrade_attack, "upgrade_defence": upgrade_defence, "upgrade_running_speed": upgrade_running_speed,
		
		"currency": currency,
	}

func load_dict(data: Dictionary):
	has_spell_element = data.get("has_spell_element", 0b1)
	has_chain_method = data.get("has_chain_method", 0)
	max_r = data.get("max_r", 1)
	max_T = data.get("max_T", 1.0)
	max_N = data.get("max_N", 1)
	max_D = data.get("max_D", 0.0)
	max_P = data.get("max_P", 1.0)
	max_v = data.get("max_v", 2.5)
	max_mana = data.get("max_mana", 100.0)
	max_health = data.get("max_health", 100.0)
	max_spells_in_book = data.get("max_spells_in_book", 4)
	max_running_speed = data.get("max_running_speed", 2.0)
	max_attack = data.get("max_attack", 100.0)
	max_defence = data.get("max_defence", 100.0)
	
	cost_spell_element = data.get("cost_spell_element", 100)
	cost_chain_method = data.get("cost_chain_method", 100)
	cost_r = data.get("cost_r", 10)
	cost_T = data.get("cost_T", 10)
	cost_N = data.get("cost_N", 10)
	cost_D = data.get("cost_D", 10)
	cost_P = data.get("cost_P", 10)
	cost_v = data.get("cost_v", 10)
	cost_mana = data.get("cost_mana", 10)
	cost_health = data.get("cost_health", 10)
	cost_spells_in_book = data.get("cost_spells_in_book", 25)
	cost_running_speed = data.get("cost_running_speed", 50)
	cost_attack = data.get("cost_attack", 10)
	cost_defence = data.get("cost_defence", 10)
	
	upgrade_r = data.get("upgrade_r", 0.1)
	upgrade_T = data.get("upgrade_T", 1.0)
	upgrade_N = data.get("upgrade_N", 1)
	upgrade_D = data.get("upgrade_D", 1.0)
	upgrade_P = data.get("upgrade_P", 5)
	upgrade_v = data.get("upgrade_v", 2.5)
	upgrade_mana = data.get("upgrade_mana", 10.0)
	upgrade_health = data.get("upgrade_health", 10.0)
	upgrade_spells_in_book = data.get("upgrade_spells_in_book", 2)
	upgrade_running_speed = data.get("upgrade_running_speed", 0.25)
	upgrade_attack = data.get("upgrade_attack", 10)
	upgrade_defence = data.get("upgrade_defence", 10)
	
	currency = data.get("currency", 0)
