class_name UpgradeSettings

enum PurchaseError {
	NONE, NOT_ENOUGH_CURRENCY, UPGRADE_IS_OVER_LIMIT
}

signal max_velocity_updated(value: float)
signal max_radius_updated(value: float)
signal upgrade_was_purchased(settings: UpgradeSettings, payload: Dictionary)
signal upgrade_slot_progress(settings: UpgradeSettings, message: String)

var currency := 500

const HAS_VOID := 1 << 0
const HAS_FIRE := 1 << 1
const HAS_WATER := 1 << 2
const HAS_ROCK := 1 << 3
const HAS_AIR := 1 << 4
const HAS_ICE := 1 << 5
const HAS_ELECTRIC := 1 << 6
var has_spell_element := HAS_VOID | HAS_FIRE # Start with fire and void
var cost_spell_element := 100
func purchase_spell_element(el: Spell.Element) -> PurchaseError:
	if currency < cost_spell_element:
		return PurchaseError.NOT_ENOUGH_CURRENCY
		
	if check_if_has_spell_element(el):
		return PurchaseError.UPGRADE_IS_OVER_LIMIT
		
	has_spell_element |= (1 << el)
	currency -= cost_spell_element
	emit_upgrade_purchase({"element": el})
	return PurchaseError.NONE
	
func check_if_has_spell_element(el: Spell.Element) -> bool:
	return has_spell_element & (1 << el) != 0
	
func upgrade_description_spell_element(el: Spell.Element, size: int) -> String: 
	match el:
		Spell.Element.VOID: return "[img=l,%dx%d, color=#FFFFFF]res://GUI/Images/void.svg[/img] Void" % [size, size]
		Spell.Element.FIRE: return "[img=l,%dx%d, color=#FF0000]res://GUI/Images/fire.svg[/img] Fire" % [size, size]
		Spell.Element.ROCK: return "[img=l,%dx%d, color=#FF8000]res://GUI/Images/rock.svg[/img] Rock" % [size, size]
		Spell.Element.ELECTRIC: return "[img=l,%dx%d, color=#FF0080]res://GUI/Images/electric.svg[/img] Electric" % [size, size]
		Spell.Element.WATER: return "[img=l,%dx%d, color=#0080FF]res://GUI/Images/water.svg[/img] Water" % [size, size]
		Spell.Element.AIR: return "[img=l,%dx%d, color=#00FF80]res://GUI/Images/wind.svg[/img] Air" % [size, size]
		Spell.Element.ICE: return "[img=l,%dx%d, color=#00FFFF]res://GUI/Images/ice.svg[/img] Ice" % [size, size]
	return ""
	

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
	emit_upgrade_purchase({"chain": cm})
	return PurchaseError.NONE

func check_if_has_chain_method(el: Spell.ChainCastKind) -> bool:
	return has_chain_method & (1 << el) != 0
	
func upgrade_description_chain_method(el: Spell.ChainCastKind) -> String: 
	match el:
		Spell.ChainCastKind.START: return "Cast At Start"
		Spell.ChainCastKind.END: return "Cast At End"
		Spell.ChainCastKind.HIT: return "Cast On Hit"
	return ""
	
var upgrade_kind: Array[UpgradeKind]
var upgrade_cond: Array[UpgradeCondition]
var upgrade_prog_cur: Array[float]
var upgrade_prog_max: Array[float]
var upgrade_cond_info: Array[int]

# upgrade_* is the amount the upgrade is increased each level increase
# max_* is the current value
# cost_* is the amount required to perform upgrade
# buff_* is a temporary upgrade gained from artifacts
# LIMIT_* is the maximum amount allowed


var level_r := 1:
	set(value):
		level_r = clampi(value, 1, level_max_r)
		max_radius_updated.emit(max_r())
var level_max_r := 2 if GlobalData.is_demo else 20
func max_r(x: int = level_r) -> float: return x * 0.25
func upgrade_r() -> float: return max_r(level_r + 1) - max_r(level_r)
func cost_r() -> int: return (level_r ** 2) * 10
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
func upgrade_description_r(size: int) -> String: return "[img=l,%dx%d, color=#7700FF]res://GUI/Images/radius.svg[/img]" % [size, size]

var level_T := 1:
	set(value):
		level_T = clampi(value, 1, level_max_T)
var level_max_T := 3 if GlobalData.is_demo else 25
func max_T(x: int = level_T) -> float: return x + 1
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
func upgrade_description_T(size: int) -> String: return "[img=l,%dx%d, color=#00FF08]res://GUI/Images/time.svg[/img]" % [size, size]

var level_N := 1:
	set(value):
		level_N = clampi(value, 1, level_max_N)
var level_max_N := 3 if GlobalData.is_demo else 25
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
func upgrade_description_N(size: int) -> String: return "[img=l,%dx%d, color=#F700FF]res://GUI/Images/count.svg[/img]" % [size, size]

var level_D := 1:
	set(value):
		level_D = clampi(value, 1, level_max_D)
var level_max_D := 2 if GlobalData.is_demo else 10
func max_D(x: int = level_D) -> float: return roundf((x - 1) / 36.0 * 100.0)
func upgrade_D() -> float: return max_D(level_D + 1) - max_D(level_D)
func cost_D() -> int: return level_D * 25
var buff_D := 0.0
const LIMIT_D := 25.0
func purchase_D() -> PurchaseError:
	if currency < cost_D():
		return PurchaseError.NOT_ENOUGH_CURRENCY
		
	if level_D >= level_max_D:
		return PurchaseError.UPGRADE_IS_OVER_LIMIT
		
	currency -= cost_D()
	level_D += 1
	emit_upgrade_purchase()
	return PurchaseError.NONE
func upgrade_description_D() -> String: return "D"

var level_P := 1:
	set(value):
		level_P = clampi(value, 1, level_max_P)
var level_max_P := 3 if GlobalData.is_demo else 10
func max_P(x: int = level_P) -> int: return x * 10
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
func upgrade_description_P(size: int) -> String: return "[img=l,%dx%d, color=#0008FF]res://GUI/Images/power.svg[/img]" % [size, size]

# max spell velocity should be some multiple of player running speed. 
# Since max player speed is 10 we arbitrarily decide to limit spell speed to [10]*4=40
var level_v := 1:
	set(value):
		level_v = clampi(value, 1, level_max_v)
		max_velocity_updated.emit(max_v())
var level_max_v := 5 if GlobalData.is_demo else 20
func max_v(x: int = level_v) -> float: return 8 + x + floorf(x/20.0*12.0)
func upgrade_v() -> float: return max_v(level_v + 1) - max_v(level_v)
func cost_v() -> int: return level_v * 175
var buff_v := 0.0
const LIMIT_v := 40.0
func purchase_v() -> PurchaseError:
	if currency < cost_v():
		return PurchaseError.NOT_ENOUGH_CURRENCY
		
	if level_v >= level_max_v:
		return PurchaseError.UPGRADE_IS_OVER_LIMIT
		
	currency -= cost_v()
	level_v += 1
	emit_upgrade_purchase()
	return PurchaseError.NONE
func upgrade_description_v(size: int) -> String: return "[img=l,%dx%d, color=#77FF00]res://GUI/Images/velocity.svg[/img]" % [size, size]

var level_mana := 1:
	set(value):
		level_mana = clampi(value, 1, level_max_mana)
var level_max_mana := 2 if GlobalData.is_demo else 20
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
	var upgrade_amount := upgrade_mana()
	level_mana += 1
	emit_upgrade_purchase({"mana": upgrade_amount})
	return PurchaseError.NONE
func upgrade_description_mana(size: int) -> String: return "[img=l,%dx%d, color=#AA00AA]res://GUI/Images/mana.svg[/img]" % [size, size]

var level_health := 1:
	set(value):
		level_health = clampi(value, 1, level_max_health)
var level_max_health := 2 if GlobalData.is_demo else 20
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
	var upgrade_amount := upgrade_health()
	level_health += 1
	emit_upgrade_purchase({"health": upgrade_amount})
	return PurchaseError.NONE
func upgrade_description_health(size: int) -> String: return "[img=l,%dx%d, color=#00AA00]res://GUI/Images/health.svg[/img]" % [size, size]

var level_attack := 1:
	set(value):
		level_attack = clampi(value, 1, level_max_attack)
var level_max_attack := 1 if GlobalData.is_demo else 10
func max_attack(x: int = level_attack) -> float: return x * 10.0
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
func upgrade_description_attack(size: int) -> String: return "[img=l,%dx%d, color=#AA0000]res://GUI/Images/sword.svg[/img]" % [size, size]

var level_crit_rate := 1:
	set(value):
		level_crit_rate = clampi(value, 1, level_max_crit_rate)
var level_max_crit_rate := 1 if GlobalData.is_demo else 10
func max_crit_rate(x: int = level_crit_rate) -> float: return x * 10.0
func upgrade_crit_rate() -> float: return max_crit_rate(level_crit_rate + 1) - max_crit_rate(level_crit_rate)
func cost_crit_rate() -> int: return level_crit_rate * 250
var buff_crit_rate := 0.0
const LIMIT_CRIT_RATE := 100
func purchase_crit_rate() -> PurchaseError:
	if currency < cost_crit_rate():
		return PurchaseError.NOT_ENOUGH_CURRENCY
		
	if level_crit_rate >= level_max_crit_rate:
		return PurchaseError.UPGRADE_IS_OVER_LIMIT
		
	currency -= cost_crit_rate()
	level_crit_rate += 1
	emit_upgrade_purchase()
	return PurchaseError.NONE
func upgrade_description_crit_rate(size: int) -> String: return "[img=l,%dx%d, color=#0000AA]res://GUI/Images/cubes.svg[/img]" % [size, size]
	
var level_crit_dmg := 1:
	set(value):
		level_crit_dmg = clampi(value, 1, level_max_crit_dmg)
var level_max_crit_dmg := 1 if GlobalData.is_demo else 10
func max_crit_dmg(x: int = level_crit_dmg) -> float: return x * 50.0
func upgrade_crit_dmg() -> float: return max_crit_dmg(level_crit_dmg + 1) - max_crit_dmg(level_crit_dmg)
func cost_crit_dmg() -> int: return level_crit_dmg * 250
var buff_crit_dmg := 0.0
const LIMIT_CRIT_DMG := 500
func purchase_crit_dmg() -> PurchaseError:
	if currency < cost_crit_dmg():
		return PurchaseError.NOT_ENOUGH_CURRENCY
		
	if level_crit_dmg >= level_max_crit_dmg:
		return PurchaseError.UPGRADE_IS_OVER_LIMIT
		
	currency -= cost_crit_dmg()
	level_crit_dmg += 1
	emit_upgrade_purchase()
	return PurchaseError.NONE
func upgrade_description_crit_dmg(size: int) -> String: return "[img=l,%dx%d, color=#AAAA00]res://GUI/Images/hypersonic.svg[/img]" % [size, size]

var level_defence := 1:
	set(value):
		level_defence = clampi(value, 1, level_max_defence)
var level_max_defence := 1 if GlobalData.is_demo else 10
func max_defence(x: int = level_defence) -> float: return x * 10.0
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
func upgrade_description_defence(size: int) -> String: return "[img=l,%dx%d, color=#00AAAA]res://GUI/Images/shield.svg[/img]" % [size, size]

var level_spells_in_book := 1:
	set(value):
		level_spells_in_book = clampi(value, 1, level_max_spells_in_book)
var level_max_spells_in_book := 2 if GlobalData.is_demo else 50
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
func upgrade_description_spells_in_book() -> String: return "Active Spells"

var level_running_speed := 1:
	set(value):
		level_running_speed = clampi(value, 1, level_max_running_speed)
var level_max_running_speed := 1 if GlobalData.is_demo else 10
func max_running_speed(x: int = level_running_speed) -> float: return (x * 0.5) + 5.0
func upgrade_running_speed() -> float: return max_running_speed(level_running_speed + 1) - max_running_speed(level_running_speed)
func cost_running_speed() -> int: return level_running_speed * 500
var buff_running_speed := 0.0
const LIMIT_RUNNING_SPEED := 10.0
func purchase_running_speed() -> PurchaseError:
	if currency < cost_running_speed():
		return PurchaseError.NOT_ENOUGH_CURRENCY
		
	if level_running_speed >= level_max_running_speed:
		return PurchaseError.UPGRADE_IS_OVER_LIMIT
		
	currency -= cost_running_speed()
	level_running_speed += 1
	emit_upgrade_purchase()
	return PurchaseError.NONE
func upgrade_description_running_speed(size: int) -> String: return "[img=l,%dx%d, color=#F6FF00]res://GUI/Images/running.svg[/img]" % [size, size]

var level_mana_regen := 1:
	set(value):
		level_mana_regen = clampi(value, 1, level_max_mana_regen)
var level_max_mana_regen := 1 if GlobalData.is_demo else 10
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
func upgrade_description_mana_regen(size: int) -> String: return "[img=l,%dx%d, color=#AA00AA]res://GUI/Images/mana-outline.svg[/img]" % [size, size]
	
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
	has_chain_method = 1
	currency = 0
	upgrade_kind = [UpgradeKind.NONE, UpgradeKind.NONE, UpgradeKind.NONE, UpgradeKind.NONE]
	upgrade_cond = [UpgradeCondition.DEAL_FIRE, UpgradeCondition.DEAL_FIRE, UpgradeCondition.DEAL_FIRE, UpgradeCondition.DEAL_FIRE]
	upgrade_prog_cur = [0.0, 0.0, 0.0, 0.0]
	upgrade_prog_max = [0.0, 0.0, 0.0, 0.0]
	upgrade_cond_info = [0, 0, 0, 0]
	
func reset_all_stats_to_max_values() -> void:
	level_health = level_max_health
	level_mana = level_max_mana
	level_attack = level_max_attack
	level_defence = level_max_defence
	level_D = level_max_D
	level_N = level_max_N
	level_P = level_max_P
	level_r = level_max_r
	level_spells_in_book = level_max_spells_in_book
	level_running_speed = level_max_running_speed
	level_v = level_max_v
	level_T = level_max_T
	level_mana_regen = level_max_mana_regen
	has_spell_element = 0b1111_111
	has_chain_method = 0b111
	currency = 9_999_999
	upgrade_kind = [UpgradeKind.NONE, UpgradeKind.NONE, UpgradeKind.NONE, UpgradeKind.NONE]
	upgrade_cond = [UpgradeCondition.DEAL_FIRE, UpgradeCondition.DEAL_FIRE, UpgradeCondition.DEAL_FIRE, UpgradeCondition.DEAL_FIRE]
	upgrade_prog_cur = [0.0, 0.0, 0.0, 0.0]
	upgrade_prog_max = [0.0, 0.0, 0.0, 0.0]
	upgrade_cond_info = [0, 0, 0, 0]

func emit_upgrade_purchase(payload: Dictionary = {}) -> void:
	upgrade_was_purchased.emit(self, payload)

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
		
		"upgrade_kind": upgrade_kind, "upgrade_cond": upgrade_cond, "upgrade_prog_cur": upgrade_prog_cur, "upgrade_prog_max": upgrade_prog_max, "upgrade_cond_info": upgrade_cond_info,
	}

func load_dict(data: Dictionary) -> void:
	has_spell_element = data.get("has_spell_element", 0b1)
	has_chain_method = data.get("has_chain_method", 1)
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
	
	upgrade_kind.assign(data.get("upgrade_kind", [0, 0, 0, 0]) as Array)
	upgrade_cond.assign(data.get("upgrade_cond", [0, 0, 0, 0]) as Array)
	upgrade_prog_cur.assign(data.get("upgrade_prog_cur", [0.0, 0.0, 0.0, 0.0]) as Array)
	upgrade_prog_max.assign(data.get("upgrade_prog_max", [0.0, 0.0, 0.0, 0.0]) as Array)
	upgrade_cond_info.assign(data.get("upgrade_cond_info", [0, 0, 0, 0]) as Array)

func default_starter_spell() -> Spell:
	var blast_element := Spell.Element.FIRE
	if check_if_has_spell_element(Spell.Element.FIRE):
		blast_element = Spell.Element.FIRE
	elif check_if_has_spell_element(Spell.Element.ROCK):
		blast_element = Spell.Element.ROCK
	elif check_if_has_spell_element(Spell.Element.ELECTRIC):
		blast_element = Spell.Element.ELECTRIC
	elif check_if_has_spell_element(Spell.Element.WATER):
		blast_element = Spell.Element.WATER
	elif check_if_has_spell_element(Spell.Element.AIR):
		blast_element = Spell.Element.AIR
	elif check_if_has_spell_element(Spell.Element.ICE):
		blast_element = Spell.Element.ICE
	var blast := Spell.new(false, "u * speed * t + u * offset", "v * speed * t + u * offset", "w * speed * t + w * offset", "0.1", 5, 2.0, blast_element)
	blast.name = "Blast"
	blast.mana_cost = 1
	blast.expression_strings = {
		"speed": "9",
		"offset": "1",
	}
	blast.description = "fires a projectile in the direction of the camera"
	blast.build_expressions()
	
	return blast

enum UpgradeKind {
	NONE,
	VOID, FIRE, ROCK, ELECTRIC, WATER, AIR, ICE, CAST_START, CAST_END, CAST_HIT,
	UP_r, UP_T, UP_N, UP_P, UP_V, UP_ATK, UP_DEF, UP_RATE, UP_DMG, UP_SPEED, 
	UP_MANA_REGEN, UP_MANA, UP_HEALTH, UP_ACTIVE
}

enum UpgradeCondition {
	DEAL_FIRE, DEAL_ROCK, DEAL_ELECTRIC, DEAL_WATER, DEAL_AIR, DEAL_ICE,
	RECEIVE_FIRE, RECEIVE_ROCK, RECEIVE_ELECTRIC, RECEIVE_WATER, RECEIVE_AIR, RECEIVE_ICE,
	TRAVEL, MANA_BACK, DEFEAT_ENEMY, BURNING, WETNESS, SHOCK, FREEZE, FEATHER,
	VAPE, MELT, OVERLOAD
}

func random_upgrade_kind() -> UpgradeKind:
	var options := {}
	var element_odds := float(Spell.Element.size() - GDNavigator.popcnt(has_spell_element))
	var elements := Spell.Element.values()
	elements.shuffle()
	for element: Spell.Element in elements:
		if not check_if_has_spell_element(element):
			match element:
				Spell.Element.VOID: options[UpgradeKind.VOID] = element_odds
				Spell.Element.FIRE: options[UpgradeKind.FIRE] = element_odds
				Spell.Element.ROCK: options[UpgradeKind.ROCK] = element_odds
				Spell.Element.ELECTRIC: options[UpgradeKind.ELECTRIC] = element_odds
				Spell.Element.WATER: options[UpgradeKind.WATER] = element_odds
				Spell.Element.AIR: options[UpgradeKind.AIR] = element_odds
				Spell.Element.ICE: options[UpgradeKind.ICE] = element_odds
			element_odds *= 0.5
	
	if not check_if_has_chain_method(Spell.ChainCastKind.START): options[UpgradeKind.CAST_START] = 2
	if not check_if_has_chain_method(Spell.ChainCastKind.END): options[UpgradeKind.CAST_END] = 2
	if not check_if_has_chain_method(Spell.ChainCastKind.HIT): options[UpgradeKind.CAST_HIT] = 0.2
	
	if level_P < level_max_P: options[UpgradeKind.UP_P] = 3
	if level_spells_in_book < level_max_spells_in_book: options[UpgradeKind.UP_ACTIVE] = 1
	if level_running_speed < level_max_running_speed: options[UpgradeKind.UP_SPEED] = 0.5
	if level_v < level_max_v: options[UpgradeKind.UP_V] = 1
	if level_T < level_max_T: options[UpgradeKind.UP_T] = 1
	if level_N < level_max_N: options[UpgradeKind.UP_N] = 1
	if level_health < level_max_health: options[UpgradeKind.UP_HEALTH] = 3
	if level_mana < level_max_mana: options[UpgradeKind.UP_MANA] = 3
	if level_r < level_max_r: options[UpgradeKind.UP_r] = 1
	if level_attack < level_max_attack: options[UpgradeKind.UP_ATK] = 2
	if level_defence < level_max_defence: options[UpgradeKind.UP_DEF] = 2
	if level_mana_regen < level_max_mana_regen: options[UpgradeKind.UP_MANA_REGEN] = 1
	if level_crit_rate < level_max_crit_rate: options[UpgradeKind.UP_RATE] = 1
	if level_crit_dmg < level_max_crit_dmg: options[UpgradeKind.UP_DMG] = 1
	
	if options.is_empty():
		return UpgradeKind.NONE
	return Rand.entity_from_distribution(randf(), options, UpgradeKind.NONE)
	
func description_for_upgrade_kind(kind: UpgradeKind) -> String:
	match kind:
		UpgradeKind.VOID: return "Unlock " + upgrade_description_spell_element(Spell.Element.VOID, 12)
		UpgradeKind.FIRE: return "Unlock " + upgrade_description_spell_element(Spell.Element.FIRE, 12) 
		UpgradeKind.ROCK: return "Unlock " + upgrade_description_spell_element(Spell.Element.ROCK, 12) 
		UpgradeKind.ELECTRIC: return "Unlock " + upgrade_description_spell_element(Spell.Element.ELECTRIC, 12) 
		UpgradeKind.WATER: return "Unlock " + upgrade_description_spell_element(Spell.Element.WATER, 12) 
		UpgradeKind.AIR: return "Unlock " + upgrade_description_spell_element(Spell.Element.AIR, 12) 
		UpgradeKind.ICE: return "Unlock " + upgrade_description_spell_element(Spell.Element.ICE, 12) 
		UpgradeKind.CAST_START: return "Unlock " + upgrade_description_chain_method(Spell.ChainCastKind.START) 
		UpgradeKind.CAST_END: return "Unlock " + upgrade_description_chain_method(Spell.ChainCastKind.END)
		UpgradeKind.CAST_HIT: return "Unlock " + upgrade_description_chain_method(Spell.ChainCastKind.HIT)
		UpgradeKind.UP_r: return upgrade_description_r(12) + "r +" + str(upgrade_r()) + "m"
		UpgradeKind.UP_T: return upgrade_description_T(12) + "T +" + str(upgrade_T()) + "s" 
		UpgradeKind.UP_N: return upgrade_description_N(12) + "N +" + str(upgrade_N()) 
		UpgradeKind.UP_P: return upgrade_description_P(12) + "P +" + str(upgrade_P()) 
		UpgradeKind.UP_V: return upgrade_description_v(12) + "v +" + str(upgrade_v()) + "m/s" 
		UpgradeKind.UP_ATK: return upgrade_description_attack(12) + "ATK +" + str(upgrade_attack()) 
		UpgradeKind.UP_DEF: return upgrade_description_defence(12) + "DEF +" + str(upgrade_defence()) 
		UpgradeKind.UP_RATE: return upgrade_description_crit_rate(12) + "Rate +" + str(upgrade_crit_rate()) + "%" 
		UpgradeKind.UP_DMG: return upgrade_description_crit_dmg(12) + "Dmg +" + str(upgrade_crit_dmg()) 
		UpgradeKind.UP_SPEED: return upgrade_description_running_speed(12) + "Speed +" + str(upgrade_running_speed()) + "m/s"
		UpgradeKind.UP_MANA_REGEN: return upgrade_description_mana_regen(12) + "Regen +" + str(upgrade_mana_regen()) 
		UpgradeKind.UP_MANA: return upgrade_description_mana(12) + "Mana +" + str(upgrade_mana()) 
		UpgradeKind.UP_HEALTH: return upgrade_description_health(12) + " +" + str(upgrade_health()) 
		UpgradeKind.UP_ACTIVE: return upgrade_description_spells_in_book() + " +" + str(upgrade_spells_in_book())
	return ""
	
func message_for_upgrade_kind(kind: UpgradeKind) -> String:
	var result := ""
	match kind:
		UpgradeKind.VOID: result = upgrade_description_spell_element(Spell.Element.VOID, 21) + " Unlocked"
		UpgradeKind.FIRE: result = upgrade_description_spell_element(Spell.Element.FIRE, 21) + " Unlocked" 
		UpgradeKind.ROCK: result = upgrade_description_spell_element(Spell.Element.ROCK, 21) + " Unlocked" 
		UpgradeKind.ELECTRIC: result = upgrade_description_spell_element(Spell.Element.ELECTRIC, 21) + " Unlocked"
		UpgradeKind.WATER: result = upgrade_description_spell_element(Spell.Element.WATER, 21) + " Unlocked"
		UpgradeKind.AIR: result = upgrade_description_spell_element(Spell.Element.AIR, 21) + " Unlocked"
		UpgradeKind.ICE: result = upgrade_description_spell_element(Spell.Element.ICE, 21) + " Unlocked"
		UpgradeKind.CAST_START: result = upgrade_description_chain_method(Spell.ChainCastKind.START) + " Unlocked"
		UpgradeKind.CAST_END: result = upgrade_description_chain_method(Spell.ChainCastKind.END) + " Unlocked"
		UpgradeKind.CAST_HIT: result = upgrade_description_chain_method(Spell.ChainCastKind.HIT) + " Unlocked"
		UpgradeKind.UP_r: result = "Max " + upgrade_description_r(21) + "r " + str(max_r()) + "m"
		UpgradeKind.UP_T: result = "Max " + upgrade_description_T(21) + "T " + str(max_T()) + "s" 
		UpgradeKind.UP_N: result = "Max " + upgrade_description_N(21) + "N " + str(max_N()) 
		UpgradeKind.UP_P: result = "Max " + upgrade_description_P(21) + "P " + str(max_P()) 
		UpgradeKind.UP_V: result = "Max " + upgrade_description_v(21) + " Velocity " + str(max_v()) + "m/s" 
		UpgradeKind.UP_ATK: result = upgrade_description_attack(21) + "Attack " + str(max_attack())
		UpgradeKind.UP_DEF: result = upgrade_description_defence(21) + "Defence " + str(max_defence()) 
		UpgradeKind.UP_RATE: result = "Max " + upgrade_description_crit_rate(21) + "Crit Rate " + str(max_crit_rate()) + "%" 
		UpgradeKind.UP_DMG: result = "Max " + upgrade_description_crit_dmg(21) + "Crit Dmg " + str(upgrade_crit_dmg()) 
		UpgradeKind.UP_SPEED: result = "Max " + upgrade_description_running_speed(21) + "Speed " + str(upgrade_running_speed()) + "m/s"
		UpgradeKind.UP_MANA_REGEN: result = "Auto " + upgrade_description_mana_regen(21) + "Mana Regen " + str(upgrade_mana_regen()) 
		UpgradeKind.UP_MANA: result = "Max " + upgrade_description_mana(21) + "Mana " + str(upgrade_mana()) 
		UpgradeKind.UP_HEALTH: result = "Max " + upgrade_description_health(21) + "Health " + str(upgrade_health()) 
		UpgradeKind.UP_ACTIVE: result = "Max " + upgrade_description_spells_in_book() + " " + str(upgrade_spells_in_book())
	return "[center][font_size=21]" + result + "[/font_size][/center]"

func purchase_upgrade_kind(kind: UpgradeKind) -> void:
	currency = 9999999
	match kind:
		UpgradeKind.VOID: purchase_spell_element(Spell.Element.VOID)
		UpgradeKind.FIRE: purchase_spell_element(Spell.Element.FIRE) 
		UpgradeKind.ROCK: purchase_spell_element(Spell.Element.ROCK) 
		UpgradeKind.ELECTRIC: purchase_spell_element(Spell.Element.ELECTRIC) 
		UpgradeKind.WATER: purchase_spell_element(Spell.Element.WATER) 
		UpgradeKind.AIR: purchase_spell_element(Spell.Element.AIR) 
		UpgradeKind.ICE: purchase_spell_element(Spell.Element.ICE) 
		UpgradeKind.CAST_START: purchase_chain_method(Spell.ChainCastKind.START) 
		UpgradeKind.CAST_END: purchase_chain_method(Spell.ChainCastKind.END)
		UpgradeKind.CAST_HIT: purchase_chain_method(Spell.ChainCastKind.HIT)
		UpgradeKind.UP_r: purchase_r()
		UpgradeKind.UP_T: purchase_T()
		UpgradeKind.UP_N: purchase_N()
		UpgradeKind.UP_P: purchase_P()
		UpgradeKind.UP_V: purchase_v()
		UpgradeKind.UP_ATK: purchase_attack()
		UpgradeKind.UP_DEF: purchase_defence()
		UpgradeKind.UP_RATE: purchase_crit_rate()
		UpgradeKind.UP_DMG: purchase_crit_dmg()
		UpgradeKind.UP_SPEED: purchase_running_speed()
		UpgradeKind.UP_MANA_REGEN: purchase_mana_regen()
		UpgradeKind.UP_MANA: purchase_mana()
		UpgradeKind.UP_HEALTH: purchase_health()
		UpgradeKind.UP_ACTIVE: purchase_spells_in_book()

func cost_of_upgrade_kind(kind: UpgradeKind) -> int:
	match kind:
		UpgradeKind.VOID: return cost_spell_element
		UpgradeKind.FIRE: return cost_spell_element
		UpgradeKind.ROCK: return cost_spell_element
		UpgradeKind.ELECTRIC: return cost_spell_element
		UpgradeKind.WATER: return cost_spell_element
		UpgradeKind.AIR: return cost_spell_element
		UpgradeKind.ICE: return cost_spell_element
		UpgradeKind.CAST_START: return cost_chain_method(Spell.ChainCastKind.START)
		UpgradeKind.CAST_END: return cost_chain_method(Spell.ChainCastKind.END)
		UpgradeKind.CAST_HIT: return cost_chain_method(Spell.ChainCastKind.HIT)
		UpgradeKind.UP_r: return cost_r()
		UpgradeKind.UP_T: return cost_T()
		UpgradeKind.UP_N: return cost_N()
		UpgradeKind.UP_P: return cost_P()
		UpgradeKind.UP_V: return cost_v()
		UpgradeKind.UP_ATK: return cost_attack()
		UpgradeKind.UP_DEF: return cost_defence()
		UpgradeKind.UP_RATE: return cost_crit_rate()
		UpgradeKind.UP_DMG: return cost_crit_dmg()
		UpgradeKind.UP_SPEED: return cost_running_speed()
		UpgradeKind.UP_MANA_REGEN: return cost_mana_regen()
		UpgradeKind.UP_MANA: return cost_mana()
		UpgradeKind.UP_HEALTH: return cost_health()
		UpgradeKind.UP_ACTIVE: return cost_spells_in_book()
	return 0
	
func random_upgrade_condition() -> UpgradeCondition:
	var options := {
		UpgradeCondition.RECEIVE_FIRE: 0.5,
		UpgradeCondition.RECEIVE_ROCK: 0.25, 
		UpgradeCondition.RECEIVE_ELECTRIC: 0.25, 
		UpgradeCondition.RECEIVE_WATER: 0.5, 
		UpgradeCondition.RECEIVE_AIR: 0.25, 
		UpgradeCondition.RECEIVE_ICE: 0.5,
		UpgradeCondition.TRAVEL: 0.2,
		UpgradeCondition.MANA_BACK: 0.2,
		UpgradeCondition.DEFEAT_ENEMY: 1.0,
	}
	if check_if_has_spell_element(Spell.Element.FIRE):
		options[UpgradeCondition.DEAL_FIRE] = 1.0
		options[UpgradeCondition.BURNING] = 1.0
		options[UpgradeCondition.VAPE] = 0.5
		options[UpgradeCondition.MELT] = 0.5
	if check_if_has_spell_element(Spell.Element.ROCK):
		options[UpgradeCondition.DEAL_ROCK] = 2.0
	if check_if_has_spell_element(Spell.Element.ELECTRIC):
		options[UpgradeCondition.DEAL_ELECTRIC] = 1.5
		options[UpgradeCondition.SHOCK] = 0.75
		options[UpgradeCondition.OVERLOAD] = 0.5
	if check_if_has_spell_element(Spell.Element.WATER):
		options[UpgradeCondition.DEAL_WATER] = 1.0
		options[UpgradeCondition.WETNESS] = 1.0
	if check_if_has_spell_element(Spell.Element.AIR):
		options[UpgradeCondition.DEAL_AIR] = 2.0
		options[UpgradeCondition.FEATHER] = 0.5
	if check_if_has_spell_element(Spell.Element.ICE):
		options[UpgradeCondition.DEAL_ICE] = 1.75
		options[UpgradeCondition.FREEZE] = 1.0
		
	return Rand.entity_from_distribution(randf(), options, UpgradeCondition.TRAVEL)

func description_upgrade_condition(condition: UpgradeCondition, info: int) -> String:
	match condition:
		UpgradeCondition.DEAL_FIRE: return "Deal [img=l,12x12, color=#FF0000]res://GUI/Images/fire.svg[/img] Damage"
		UpgradeCondition.DEAL_ROCK: return "Deal [img=l,12x12, color=#FF8000]res://GUI/Images/rock.svg[/img] Damage"
		UpgradeCondition.DEAL_ELECTRIC: return "Deal [img=l,12x12, color=#FF0080]res://GUI/Images/electric.svg[/img] Damage"
		UpgradeCondition.DEAL_WATER: return "Deal [img=l,12x12, color=#0080FF]res://GUI/Images/water.svg[/img] Damage"
		UpgradeCondition.DEAL_AIR: return "Deal [img=l,12x12, color=#00FF80]res://GUI/Images/wind.svg[/img] Damage"
		UpgradeCondition.DEAL_ICE: return "Deal [img=l,12x12, color=#00FFFF]res://GUI/Images/ice.svg[/img] Damage"
		UpgradeCondition.RECEIVE_FIRE: return "Receive [img=l,12x12, color=#FF0000]res://GUI/Images/fire.svg[/img] Damage"
		UpgradeCondition.RECEIVE_ROCK: return "Receive [img=l,12x12, color=#FF8000]res://GUI/Images/rock.svg[/img] Damage"
		UpgradeCondition.RECEIVE_ELECTRIC: return "Receive [img=l,12x12, color=#FF0080]res://GUI/Images/electric.svg[/img] Damage"
		UpgradeCondition.RECEIVE_WATER: return "Receive [img=l,12x12, color=#0080FF]res://GUI/Images/water.svg[/img] Damage"
		UpgradeCondition.RECEIVE_AIR: return "Receive [img=l,12x12, color=#00FF80]res://GUI/Images/wind.svg[/img] Damage"
		UpgradeCondition.RECEIVE_ICE: return "Receive [img=l,12x12, color=#00FFFF]res://GUI/Images/ice.svg[/img] Damage"
		UpgradeCondition.TRAVEL: return "Travel"
		UpgradeCondition.MANA_BACK: return "Gain Mana Back"
		UpgradeCondition.DEFEAT_ENEMY: return "Defeat " + World.Enemy.keys()[info] # TODO: format enemy names
		UpgradeCondition.BURNING: return "Apply [img=l,12x12, color=#FF0000]res://GUI/Images/fire.svg[/img] Burning"
		UpgradeCondition.WETNESS: return "Apply [img=l,12x12, color=#0080FF]res://GUI/Images/water.svg[/img] Wetness"
		UpgradeCondition.FREEZE: return "Apply [img=l,12x12, color=#00FFFF]res://GUI/Images/ice.svg[/img] Freeze"
		UpgradeCondition.SHOCK: return "Apply [img=l,12x12, color=#FF0080]res://GUI/Images/electric.svg[/img] Shock"
		UpgradeCondition.FEATHER: return "Apply [img=l,12x12, color=#00FF80]res://GUI/Images/wind.svg[/img] Feather"
		UpgradeCondition.VAPE: return "[img=l,12x12, color=#FF0000]res://GUI/Images/fire.svg[/img] -> [img=l,12x12, color=#0080FF]res://GUI/Images/water.svg[/img]"
		UpgradeCondition.MELT: return "[img=l,12x12, color=#FF0000]res://GUI/Images/fire.svg[/img] -> [img=l,12x12, color=#00FFFF]res://GUI/Images/ice.svg[/img]"
		UpgradeCondition.OVERLOAD: return "[img=l,12x12, color=#FF0000]res://GUI/Images/fire.svg[/img] -> [img=l,12x12, color=#FF0080]res://GUI/Images/electric.svg[/img]"
		
	return ""
	
func fill_upgrade_slots(emit_changes: bool) -> void:
	for i in 4:
		upgrade_kind[i] = random_upgrade_kind()
		upgrade_cond[i] = random_upgrade_condition()
		upgrade_prog_cur[i] = 0.0
		upgrade_prog_max[i] = upgrade_cond_max(upgrade_kind[i], upgrade_cond[i])
		if upgrade_cond[i] == UpgradeCondition.DEFEAT_ENEMY:
			upgrade_cond_info[i] = World.Enemy.values().pick_random()
	if emit_changes:
		emit_upgrade_purchase()

func upgrade_cond_max(kind: UpgradeKind, cond: UpgradeCondition) -> float:
	var cost := cost_of_upgrade_kind(kind) / 5000.0 # 5000 is roughly the most expensive upgrade
	match cond:
		UpgradeCondition.DEAL_FIRE, UpgradeCondition.DEAL_ROCK, UpgradeCondition.DEAL_ELECTRIC, UpgradeCondition.DEAL_WATER, UpgradeCondition.DEAL_AIR, UpgradeCondition.DEAL_ICE: 
			return (cost ** 1.2) * 5000
		UpgradeCondition.RECEIVE_FIRE, UpgradeCondition.RECEIVE_ROCK, UpgradeCondition.RECEIVE_ELECTRIC, UpgradeCondition.RECEIVE_WATER, UpgradeCondition.RECEIVE_AIR, UpgradeCondition.RECEIVE_ICE: 
			return (cost ** 1.2) * 1000
		UpgradeCondition.TRAVEL:
			return (cost ** 1.2) * 10000
		UpgradeCondition.MANA_BACK: 
			return (cost ** 1.2) * 500
		UpgradeCondition.DEFEAT_ENEMY: 
			return (cost ** 1.5) * 1000
		UpgradeCondition.BURNING:
			return (cost ** 2) * 10
		UpgradeCondition.WETNESS:
			return (cost ** 2) * 10
		UpgradeCondition.FREEZE:
			return (cost ** 2) * 8
		UpgradeCondition.SHOCK:
			return (cost ** 2) * 7
		UpgradeCondition.FEATHER:
			return (cost ** 2) * 8
		UpgradeCondition.VAPE:
			return (cost ** 2) * 10
		UpgradeCondition.MELT:
			return (cost ** 2) * 15
		UpgradeCondition.OVERLOAD:
			return (cost ** 2) * 15
	return 0.0
	
func progress_damage_deal(info: Dictionary) -> void:
	var amount := info["dmg"] as float
	var application := info["app"] as float
	var element := info["el"] as Spell.Element
	match element:
		Spell.Element.FIRE:
			for i in 4: 
				if upgrade_cond[i] == UpgradeCondition.DEAL_FIRE: 
					upgrade_prog_cur[i] += amount
				elif upgrade_cond[i] == UpgradeCondition.BURNING:
					upgrade_prog_cur[i] += application
		Spell.Element.ROCK:
			for i in 4: if upgrade_cond[i] == UpgradeCondition.DEAL_ROCK: upgrade_prog_cur[i] += amount
		Spell.Element.ELECTRIC:
			for i in 4: 
				if upgrade_cond[i] == UpgradeCondition.DEAL_ELECTRIC: 
					upgrade_prog_cur[i] += amount
				elif upgrade_cond[i] == UpgradeCondition.SHOCK:
					upgrade_prog_cur[i] += application
		Spell.Element.WATER:
			for i in 4: 
				if upgrade_cond[i] == UpgradeCondition.DEAL_WATER: 
					upgrade_prog_cur[i] += amount
				elif upgrade_cond[i] == UpgradeCondition.WETNESS:
					upgrade_prog_cur[i] += application
		Spell.Element.AIR:
			for i in 4: 
				if upgrade_cond[i] == UpgradeCondition.DEAL_AIR: 
					upgrade_prog_cur[i] += amount
				elif upgrade_prog_cur[i] == UpgradeCondition.FEATHER:
					upgrade_prog_cur[i] += application
		Spell.Element.ICE:
			for i in 4: 
				if upgrade_cond[i] == UpgradeCondition.DEAL_ICE: 
					upgrade_prog_cur[i] += amount
				elif upgrade_prog_cur[i] == UpgradeCondition.FREEZE:
					upgrade_prog_cur[i] += application
	var vape := info["vape"] as float
	var melt := info["melt"] as float
	var overload := info["overload"] as float
	if vape > 0.0:
		for i in 4: if upgrade_cond[i] == UpgradeCondition.VAPE: upgrade_prog_cur[i] += vape
	if melt > 0.0:
		for i in 4: if upgrade_cond[i] == UpgradeCondition.MELT: upgrade_prog_cur[i] += melt
	if overload > 0.0:
		for i in 4: if upgrade_cond[i] == UpgradeCondition.OVERLOAD: upgrade_prog_cur[i] += overload
	
	update_upgrade_progress()
	
func progress_damage_receive(amount: float, element: Spell.Element) -> void:
	match element:
		Spell.Element.FIRE:
			for i in 4: if upgrade_cond[i] == UpgradeCondition.RECEIVE_FIRE: upgrade_prog_cur[i] += amount
		Spell.Element.ROCK:
			for i in 4: if upgrade_cond[i] == UpgradeCondition.RECEIVE_ROCK: upgrade_prog_cur[i] += amount
		Spell.Element.ELECTRIC:
			for i in 4: if upgrade_cond[i] == UpgradeCondition.RECEIVE_ELECTRIC: upgrade_prog_cur[i] += amount
		Spell.Element.WATER:
			for i in 4: if upgrade_cond[i] == UpgradeCondition.RECEIVE_WATER: upgrade_prog_cur[i] += amount
		Spell.Element.AIR:
			for i in 4: if upgrade_cond[i] == UpgradeCondition.RECEIVE_AIR: upgrade_prog_cur[i] += amount
		Spell.Element.ICE:
			for i in 4: if upgrade_cond[i] == UpgradeCondition.RECEIVE_ICE: upgrade_prog_cur[i] += amount
	update_upgrade_progress()
	
func progress_travel(amount: float) -> void:
	for i in 4: if upgrade_cond[i] == UpgradeCondition.TRAVEL: upgrade_prog_cur[i] += amount
	update_upgrade_progress()
	
func progress_mana_back(amount: float) -> void:
	for i in 4: if upgrade_cond[i] == UpgradeCondition.MANA_BACK: upgrade_prog_cur[i] += amount
	update_upgrade_progress()
	
func progress_defeat_enemy(enemy: World.Enemy, lvl: int) -> void:
	for i in 4:
		if upgrade_cond[i] == UpgradeCondition.DEFEAT_ENEMY and enemy == upgrade_cond_info[i]:
			upgrade_prog_cur[i] += maxi(lvl % 101, 1)
	update_upgrade_progress()

func update_upgrade_progress() -> void:
	var message := ""
	for i in 4:
		if upgrade_prog_cur[i] >= upgrade_prog_max[i]:
			purchase_upgrade_kind(upgrade_kind[i])
			message = message_for_upgrade_kind(upgrade_kind[i])
			fill_upgrade_slots(true)
			UIAudioPlayer.upgrade()
			break
	upgrade_slot_progress.emit(self, message)
