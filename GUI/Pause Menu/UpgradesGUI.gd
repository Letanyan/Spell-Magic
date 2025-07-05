class_name UpgradesGUI
extends Control

var settings: WorldSettings:
	set(value):
		settings = value
		update_state(UpgradeSettings.PurchaseError.NONE)

@onready var max_P_current: Label = $container/max_P/current
@onready var max_P_upgrade: Button = $container/max_P/upgrade
@onready var max_P_cost: RichTextLabel = $container/max_P/cost

@onready var max_v_current: Label = $container/max_v/current
@onready var max_v_upgrade: Button = $container/max_v/upgrade
@onready var max_v_cost: RichTextLabel = $container/max_v/cost

@onready var max_cd_current: Label = $container/crit_dmg/current
@onready var max_cd_upgrade: Button = $container/crit_dmg/upgrade
@onready var max_cd_cost: RichTextLabel = $container/crit_dmg/cost

@onready var max_cr_current: Label = $container/crit_rate/current
@onready var max_cr_upgrade: Button = $container/crit_rate/upgrade
@onready var max_cr_cost: RichTextLabel = $container/crit_rate/cost

@onready var max_N_current: Label = $container/max_N/current
@onready var max_N_upgrade: Button = $container/max_N/upgrade
@onready var max_N_cost: RichTextLabel = $container/max_N/cost

@onready var max_M_current: Label = $container/max_M/current
@onready var max_M_upgrade: Button = $container/max_M/upgrade
@onready var max_M_cost: RichTextLabel = $container/max_M/cost

@onready var max_r_current: Label = $container/max_r/current
@onready var max_r_upgrade: Button = $container/max_r/upgrade
@onready var max_r_cost: RichTextLabel = $container/max_r/cost

@onready var max_T_current: Label = $container/max_T/current
@onready var max_T_upgrade: Button = $container/max_T/upgrade
@onready var max_T_cost: RichTextLabel = $container/max_T/cost

@onready var max_H_current: Label = $container/max_H/current
@onready var max_H_upgrade: Button = $container/max_H/upgrade
@onready var max_H_cost: RichTextLabel = $container/max_H/cost

@onready var max_spell_count_current: Label = $container/max_spell_count/current
@onready var max_spell_count_upgrade: Button = $container/max_spell_count/upgrade
@onready var max_spell_count_cost: RichTextLabel = $container/max_spell_count/cost

@onready var max_running_speed_current: Label = $container/running_speed/current
@onready var max_running_speed_upgrade: Button = $container/running_speed/upgrade
@onready var max_running_speed_cost: RichTextLabel = $container/running_speed/cost

@onready var attack_current: Label = $container/attack/current
@onready var attack_upgrade: Button = $container/attack/upgrade
@onready var attack_cost: RichTextLabel = $container/attack/cost

@onready var defence_current: Label = $container/defence/current
@onready var defence_upgrade: Button = $container/defence/upgrade
@onready var defence_cost: RichTextLabel = $container/defence/cost

@onready var mana_regen_current: Label = $container/mana_regen/current
@onready var mana_regen_upgrade: Button = $container/mana_regen/upgrade
@onready var mana_regen_cost: RichTextLabel = $container/mana_regen/cost

@onready var element_void: VBoxContainer = $container/elements/Void
@onready var element_void_upgrade: Button = $container/elements/Void/upgrade
@onready var element_void_cost: RichTextLabel = $container/elements/Void/cost
@onready var element_fire: VBoxContainer = $container/elements/Fire
@onready var element_fire_upgrade: Button = $container/elements/Fire/upgrade
@onready var element_fire_cost: RichTextLabel = $container/elements/Fire/cost
@onready var element_water: VBoxContainer = $container/elements/Water
@onready var element_water_upgrade: Button = $container/elements/Water/upgrade
@onready var element_water_cost: RichTextLabel = $container/elements/Water/cost
@onready var element_air: VBoxContainer = $container/elements/Air
@onready var element_air_upgrade: Button = $container/elements/Air/upgrade
@onready var element_air_cost: RichTextLabel = $container/elements/Air/cost
@onready var element_rock: VBoxContainer = $container/elements/Rock
@onready var element_rock_upgrade: Button = $container/elements/Rock/upgrade
@onready var element_rock_cost: RichTextLabel = $container/elements/Rock/cost
@onready var element_ice: VBoxContainer = $container/elements/Ice
@onready var element_ice_upgrade: Button = $container/elements/Ice/upgrade
@onready var element_ice_cost: RichTextLabel = $container/elements/Ice/cost
@onready var element_electric: VBoxContainer = $container/elements/Electric
@onready var element_electric_upgrade: Button = $container/elements/Electric/upgrade
@onready var element_electric_cost: RichTextLabel = $container/elements/Electric/cost

@onready var chain_at_start: VBoxContainer = $container/chain_methods/AtStart
@onready var chain_at_start_upgrade: Button = $container/chain_methods/AtStart/upgrade
@onready var chain_at_start_cost: RichTextLabel = $container/chain_methods/AtStart/cost
@onready var chain_at_end: VBoxContainer = $container/chain_methods/AtEnd
@onready var chain_at_end_upgrade: Button = $container/chain_methods/AtEnd/upgrade
@onready var chain_at_end_cost: RichTextLabel = $container/chain_methods/AtEnd/cost
@onready var chain_on_hit: VBoxContainer = $container/chain_methods/OnHit
@onready var chain_on_hit_upgrade: Button = $container/chain_methods/OnHit/upgrade
@onready var chain_on_hit_cost: RichTextLabel = $container/chain_methods/OnHit/cost

@onready var currency: RichTextLabel = $container/Currency

func update_state(purchase_error: UpgradeSettings.PurchaseError) -> void:
	if purchase_error != UpgradeSettings.PurchaseError.NONE:
		var message := ""
		if purchase_error == UpgradeSettings.PurchaseError.NOT_ENOUGH_CURRENCY:
			message = "Not enough coins to make purchase. Defeat enemies to gain coins."
		elif purchase_error == UpgradeSettings.PurchaseError.UPGRADE_IS_OVER_LIMIT:
			message = "Max level reached. Can not upgrade furthur."
		var popup := PopupDialog.display(message, "Okay", "")
		popup.cancelled.connect(func() -> void: UIAudioPlayer.click())
		popup.confirmed.connect(func() -> void: UIAudioPlayer.click())
		popup.show_in_root(self)
		return
		
	const coin_suffix := " [img color=#ffc000]res://GUI/Images/coins.svg[/img][/center]"
	currency.text = "[right]" + str(settings.upgrade_settings.currency) + " [img color=#ffc000]res://GUI/Images/coins.svg[/img][/right]"
	
	if not settings.game_mode_settings.has_flag(GameModeSettings.SHOP_FOR_UPGRADES) and not settings.is_editing_level:
		element_void.visible = settings.upgrade_settings.check_if_has_spell_element(Spell.Element.VOID)
		element_fire.visible = settings.upgrade_settings.check_if_has_spell_element(Spell.Element.FIRE)
		element_water.visible = settings.upgrade_settings.check_if_has_spell_element(Spell.Element.WATER)
		element_air.visible = settings.upgrade_settings.check_if_has_spell_element(Spell.Element.AIR)
		element_rock.visible = settings.upgrade_settings.check_if_has_spell_element(Spell.Element.ROCK)
		element_ice.visible = settings.upgrade_settings.check_if_has_spell_element(Spell.Element.ICE)
		element_electric.visible = settings.upgrade_settings.check_if_has_spell_element(Spell.Element.ELECTRIC)
		chain_at_start.visible = settings.upgrade_settings.check_if_has_chain_method(Spell.ChainCastKind.START)
		chain_at_end.visible = settings.upgrade_settings.check_if_has_chain_method(Spell.ChainCastKind.END)
		chain_on_hit.visible = settings.upgrade_settings.check_if_has_chain_method(Spell.ChainCastKind.HIT)
	else:
		element_void.visible = true
		element_fire.visible = true
		element_water.visible = true
		element_air.visible = true
		element_rock.visible = true
		element_ice.visible = true
		element_electric.visible = true
		chain_at_start.visible = true
		chain_at_end.visible = true
		chain_on_hit.visible = true
	
	element_void_upgrade.disabled = settings.upgrade_settings.check_if_has_spell_element(Spell.Element.VOID) or (settings.upgrade_settings.currency < settings.upgrade_settings.cost_spell_element and not settings.is_editing_level)
	element_fire_upgrade.disabled = settings.upgrade_settings.check_if_has_spell_element(Spell.Element.FIRE) or (settings.upgrade_settings.currency < settings.upgrade_settings.cost_spell_element and not settings.is_editing_level)
	element_water_upgrade.disabled = settings.upgrade_settings.check_if_has_spell_element(Spell.Element.WATER) or (settings.upgrade_settings.currency < settings.upgrade_settings.cost_spell_element and not settings.is_editing_level)
	element_air_upgrade.disabled = settings.upgrade_settings.check_if_has_spell_element(Spell.Element.AIR) or (settings.upgrade_settings.currency < settings.upgrade_settings.cost_spell_element and not settings.is_editing_level)
	element_rock_upgrade.disabled = settings.upgrade_settings.check_if_has_spell_element(Spell.Element.ROCK) or (settings.upgrade_settings.currency < settings.upgrade_settings.cost_spell_element and not settings.is_editing_level)
	element_ice_upgrade.disabled = settings.upgrade_settings.check_if_has_spell_element(Spell.Element.ICE) or (settings.upgrade_settings.currency < settings.upgrade_settings.cost_spell_element and not settings.is_editing_level)
	element_electric_upgrade.disabled = settings.upgrade_settings.check_if_has_spell_element(Spell.Element.ELECTRIC) or (settings.upgrade_settings.currency < settings.upgrade_settings.cost_spell_element and not settings.is_editing_level)
	chain_at_start_upgrade.disabled = settings.upgrade_settings.check_if_has_chain_method(Spell.ChainCastKind.START) or (settings.upgrade_settings.currency < settings.upgrade_settings.cost_chain_method(Spell.ChainCastKind.START) and not settings.is_editing_level)
	chain_at_end_upgrade.disabled = settings.upgrade_settings.check_if_has_chain_method(Spell.ChainCastKind.END) or (settings.upgrade_settings.currency < settings.upgrade_settings.cost_chain_method(Spell.ChainCastKind.END) and not settings.is_editing_level)
	chain_on_hit_upgrade.disabled = settings.upgrade_settings.check_if_has_chain_method(Spell.ChainCastKind.HIT) or (settings.upgrade_settings.currency < settings.upgrade_settings.cost_chain_method(Spell.ChainCastKind.HIT) and not settings.is_editing_level)
	element_void_cost.text = ("[center]" + str(settings.upgrade_settings.cost_spell_element) + coin_suffix if settings.game_mode_settings.has_flag(GameModeSettings.SHOP_FOR_UPGRADES) else "") if not settings.upgrade_settings.check_if_has_spell_element(Spell.Element.VOID) else "[center][font_size=11]UNLOCKED[/font_size][/center]"
	element_fire_cost.text = ("[center]" + str(settings.upgrade_settings.cost_spell_element) + coin_suffix if settings.game_mode_settings.has_flag(GameModeSettings.SHOP_FOR_UPGRADES) else "") if not settings.upgrade_settings.check_if_has_spell_element(Spell.Element.FIRE) else "[center][font_size=11]UNLOCKED[/font_size][/center]"
	element_water_cost.text = ("[center]" + str(settings.upgrade_settings.cost_spell_element) + coin_suffix if settings.game_mode_settings.has_flag(GameModeSettings.SHOP_FOR_UPGRADES) else "") if not settings.upgrade_settings.check_if_has_spell_element(Spell.Element.WATER) else "[center][font_size=11]UNLOCKED[/font_size][/center]"
	element_air_cost.text = ("[center]" + str(settings.upgrade_settings.cost_spell_element) + coin_suffix if settings.game_mode_settings.has_flag(GameModeSettings.SHOP_FOR_UPGRADES) else "") if not settings.upgrade_settings.check_if_has_spell_element(Spell.Element.AIR) else "[center][font_size=11]UNLOCKED[/font_size][/center]"
	element_rock_cost.text = ("[center]" + str(settings.upgrade_settings.cost_spell_element) + coin_suffix if settings.game_mode_settings.has_flag(GameModeSettings.SHOP_FOR_UPGRADES) else "") if not settings.upgrade_settings.check_if_has_spell_element(Spell.Element.ROCK) else "[center][font_size=11]UNLOCKED[/font_size][/center]"
	element_ice_cost.text = ("[center]" + str(settings.upgrade_settings.cost_spell_element) + coin_suffix if settings.game_mode_settings.has_flag(GameModeSettings.SHOP_FOR_UPGRADES) else "") if not settings.upgrade_settings.check_if_has_spell_element(Spell.Element.ICE) else "[center][font_size=11]UNLOCKED[/font_size][/center]"
	element_electric_cost.text = ("[center]" + str(settings.upgrade_settings.cost_spell_element) + coin_suffix if settings.game_mode_settings.has_flag(GameModeSettings.SHOP_FOR_UPGRADES) else "") if not settings.upgrade_settings.check_if_has_spell_element(Spell.Element.ELECTRIC) else "[center][font_size=11]UNLOCKED[/font_size][/center]"
	chain_at_start_cost.text = ("[center]" + str(settings.upgrade_settings.cost_chain_method(Spell.ChainCastKind.START)) + coin_suffix if settings.game_mode_settings.has_flag(GameModeSettings.SHOP_FOR_UPGRADES) else "") if not settings.upgrade_settings.check_if_has_chain_method(Spell.ChainCastKind.START) else "[center][font_size=11]UNLOCKED[/font_size][/center]"
	chain_at_end_cost.text = ("[center]" + str(settings.upgrade_settings.cost_chain_method(Spell.ChainCastKind.END)) + coin_suffix if settings.game_mode_settings.has_flag(GameModeSettings.SHOP_FOR_UPGRADES) else "") if not settings.upgrade_settings.check_if_has_chain_method(Spell.ChainCastKind.END) else "[center][font_size=11]UNLOCKED[/font_size][/center]"
	chain_on_hit_cost.text = ("[center]" + str(settings.upgrade_settings.cost_chain_method(Spell.ChainCastKind.HIT)) + coin_suffix if settings.game_mode_settings.has_flag(GameModeSettings.SHOP_FOR_UPGRADES) else "") if not settings.upgrade_settings.check_if_has_chain_method(Spell.ChainCastKind.HIT) else "[center][font_size=11]UNLOCKED[/font_size][/center]"
	
	max_spell_count_current.text = str(settings.upgrade_settings.max_spells_in_book())
	max_running_speed_current.text = str(settings.upgrade_settings.max_running_speed()) + "m/s"
	max_P_current.text = str(settings.upgrade_settings.max_P())
	max_v_current.text = str(settings.upgrade_settings.max_v()) + "m/s"
	max_N_current.text = str(settings.upgrade_settings.max_N())
	max_T_current.text = str(settings.upgrade_settings.max_T()) + "s"
	max_M_current.text = str(settings.upgrade_settings.max_mana())
	max_r_current.text = str(settings.upgrade_settings.max_r()) + "m"
	max_H_current.text = str(settings.upgrade_settings.max_health())
	attack_current.text = str(settings.upgrade_settings.max_attack())
	defence_current.text = str(settings.upgrade_settings.max_defence())
	mana_regen_current.text = str(settings.upgrade_settings.max_mana_regen())
	max_cr_current.text = str(settings.upgrade_settings.max_crit_rate()) + "%"
	max_cd_current.text = str(settings.upgrade_settings.max_crit_dmg())
	max_spell_count_upgrade.disabled = settings.upgrade_settings.level_spells_in_book >= settings.upgrade_settings.level_max_spells_in_book or (settings.upgrade_settings.currency < settings.upgrade_settings.cost_spells_in_book() and not settings.is_editing_level)
	max_running_speed_upgrade.disabled = settings.upgrade_settings.level_running_speed >= settings.upgrade_settings.level_max_running_speed or (settings.upgrade_settings.currency < settings.upgrade_settings.cost_running_speed() and not settings.is_editing_level)
	max_P_upgrade.disabled = settings.upgrade_settings.level_P >= settings.upgrade_settings.level_max_P or (settings.upgrade_settings.currency < settings.upgrade_settings.cost_P() and not settings.is_editing_level)
	max_v_upgrade.disabled = settings.upgrade_settings.level_v >= settings.upgrade_settings.level_max_v or (settings.upgrade_settings.currency < settings.upgrade_settings.cost_v() and not settings.is_editing_level)
	max_T_upgrade.disabled = settings.upgrade_settings.level_T >= settings.upgrade_settings.level_max_T or (settings.upgrade_settings.currency < settings.upgrade_settings.cost_T() and not settings.is_editing_level)
	max_N_upgrade.disabled = settings.upgrade_settings.level_N >= settings.upgrade_settings.level_max_N or (settings.upgrade_settings.currency < settings.upgrade_settings.cost_N() and not settings.is_editing_level)
	max_H_upgrade.disabled = settings.upgrade_settings.level_health >= settings.upgrade_settings.level_max_health or (settings.upgrade_settings.currency < settings.upgrade_settings.cost_health() and not settings.is_editing_level)
	max_M_upgrade.disabled = settings.upgrade_settings.level_mana >= settings.upgrade_settings.level_max_mana or (settings.upgrade_settings.currency < settings.upgrade_settings.cost_mana() and not settings.is_editing_level)
	max_r_upgrade.disabled = settings.upgrade_settings.level_r >= settings.upgrade_settings.level_max_r or (settings.upgrade_settings.currency < settings.upgrade_settings.cost_r() and not settings.is_editing_level)
	attack_upgrade.disabled = settings.upgrade_settings.level_attack >= settings.upgrade_settings.level_max_attack or (settings.upgrade_settings.currency < settings.upgrade_settings.cost_attack() and not settings.is_editing_level)
	defence_upgrade.disabled = settings.upgrade_settings.level_defence >= settings.upgrade_settings.level_max_defence or (settings.upgrade_settings.currency < settings.upgrade_settings.cost_defence() and not settings.is_editing_level)
	mana_regen_upgrade.disabled = settings.upgrade_settings.level_mana_regen >= settings.upgrade_settings.level_max_mana_regen or (settings.upgrade_settings.currency < settings.upgrade_settings.cost_mana_regen() and not settings.is_editing_level)
	max_cr_upgrade.disabled = settings.upgrade_settings.level_crit_rate >= settings.upgrade_settings.level_max_crit_rate or (settings.upgrade_settings.currency < settings.upgrade_settings.cost_crit_rate() and not settings.is_editing_level)
	max_cd_upgrade.disabled = settings.upgrade_settings.level_crit_dmg >= settings.upgrade_settings.level_max_crit_dmg or (settings.upgrade_settings.currency < settings.upgrade_settings.cost_crit_dmg() and not settings.is_editing_level)
	max_spell_count_upgrade.text = "+ " + str(settings.upgrade_settings.upgrade_spells_in_book()) if settings.upgrade_settings.level_spells_in_book < settings.upgrade_settings.level_max_spells_in_book else "MAXED"
	max_running_speed_upgrade.text = "+ " + str(settings.upgrade_settings.upgrade_running_speed()) + "m/s" if settings.upgrade_settings.level_running_speed < settings.upgrade_settings.level_max_running_speed else "MAXED"
	max_P_upgrade.text = "+ " + str(settings.upgrade_settings.upgrade_P()) if settings.upgrade_settings.level_P < settings.upgrade_settings.level_max_P else "MAXED"
	max_v_upgrade.text = "+ " + str(settings.upgrade_settings.upgrade_v()) + "m/s" if settings.upgrade_settings.level_v < settings.upgrade_settings.level_max_v else "MAXED"
	max_T_upgrade.text = "+ " + str(settings.upgrade_settings.upgrade_T()) + "s" if settings.upgrade_settings.level_T < settings.upgrade_settings.level_max_T else "MAXED"
	max_N_upgrade.text = "+ " + str(settings.upgrade_settings.upgrade_N()) if settings.upgrade_settings.level_N < settings.upgrade_settings.level_max_N else "MAXED"
	max_H_upgrade.text = "+ " + str(settings.upgrade_settings.upgrade_health()) if settings.upgrade_settings.level_health < settings.upgrade_settings.level_max_health else "MAXED"
	max_M_upgrade.text = "+ " + str(settings.upgrade_settings.upgrade_mana()) if settings.upgrade_settings.level_mana < settings.upgrade_settings.level_max_mana else "MAXED"
	max_r_upgrade.text = "+ " + str(settings.upgrade_settings.upgrade_r()) + "m" if settings.upgrade_settings.level_r < settings.upgrade_settings.level_max_r else "MAXED"
	attack_upgrade.text = "+ " + str(settings.upgrade_settings.upgrade_attack()) if settings.upgrade_settings.level_attack < settings.upgrade_settings.level_max_attack else "MAXED"
	defence_upgrade.text = "+ " + str(settings.upgrade_settings.upgrade_defence()) if settings.upgrade_settings.level_defence < settings.upgrade_settings.level_max_defence else "MAXED"
	mana_regen_upgrade.text = "+ " + str(settings.upgrade_settings.upgrade_mana_regen()) if settings.upgrade_settings.level_mana_regen < settings.upgrade_settings.level_max_mana_regen else "MAXED"
	max_cr_upgrade.text = "+ " + str(settings.upgrade_settings.upgrade_crit_rate()) + "%" if settings.upgrade_settings.level_crit_rate < settings.upgrade_settings.level_max_crit_rate else "MAXED"
	max_cd_upgrade.text = "+ " + str(settings.upgrade_settings.upgrade_crit_dmg()) if settings.upgrade_settings.level_crit_dmg < settings.upgrade_settings.level_max_crit_dmg else "MAXED"
	max_spell_count_cost.text = "[center]" + str(settings.upgrade_settings.cost_spells_in_book()) + coin_suffix if settings.upgrade_settings.level_spells_in_book < settings.upgrade_settings.level_max_spells_in_book else ""
	max_running_speed_cost.text = "[center]" + str(settings.upgrade_settings.cost_running_speed()) + coin_suffix if settings.upgrade_settings.level_running_speed < settings.upgrade_settings.level_max_running_speed else ""
	max_P_cost.text = "[center]" + str(settings.upgrade_settings.cost_P()) + coin_suffix if settings.upgrade_settings.level_P < settings.upgrade_settings.level_max_P else ""
	max_v_cost.text = "[center]" + str(settings.upgrade_settings.cost_v()) + coin_suffix if settings.upgrade_settings.level_v < settings.upgrade_settings.level_max_v else ""
	max_N_cost.text = "[center]" + str(settings.upgrade_settings.cost_N()) + coin_suffix if settings.upgrade_settings.level_T < settings.upgrade_settings.level_max_T else ""
	max_T_cost.text = "[center]" + str(settings.upgrade_settings.cost_T()) + coin_suffix if settings.upgrade_settings.level_N < settings.upgrade_settings.level_max_N else ""
	max_M_cost.text = "[center]" + str(settings.upgrade_settings.cost_mana()) + coin_suffix if settings.upgrade_settings.level_health < settings.upgrade_settings.level_max_health else ""
	max_r_cost.text = "[center]" + str(settings.upgrade_settings.cost_r()) + coin_suffix if settings.upgrade_settings.level_mana < settings.upgrade_settings.level_max_mana else ""
	max_H_cost.text = "[center]" + str(settings.upgrade_settings.cost_health()) + coin_suffix if settings.upgrade_settings.level_r < settings.upgrade_settings.level_max_r else ""
	attack_cost.text = "[center]" + str(settings.upgrade_settings.cost_attack()) + coin_suffix if settings.upgrade_settings.level_attack < settings.upgrade_settings.level_max_attack else ""
	defence_cost.text = "[center]" + str(settings.upgrade_settings.cost_defence()) + coin_suffix if settings.upgrade_settings.level_defence < settings.upgrade_settings.level_max_defence else ""
	mana_regen_cost.text = "[center]" + str(settings.upgrade_settings.cost_mana_regen()) + coin_suffix if settings.upgrade_settings.level_mana_regen < settings.upgrade_settings.level_max_mana_regen else ""
	max_cr_cost.text = "[center]" + str(settings.upgrade_settings.cost_crit_rate()) + coin_suffix if settings.upgrade_settings.level_crit_rate < settings.upgrade_settings.level_max_crit_rate else ""
	max_cd_cost.text = "[center]" + str(settings.upgrade_settings.cost_crit_dmg()) + coin_suffix if settings.upgrade_settings.level_crit_dmg < settings.upgrade_settings.level_max_crit_dmg else ""

func make_display_only(is_demo: bool) -> void:
	currency.visible = not is_demo
	max_spell_count_upgrade.visible = not is_demo
	max_running_speed_upgrade.visible = not is_demo
	max_P_upgrade.visible = not is_demo
	max_v_upgrade.visible = not is_demo
	max_T_upgrade.visible = not is_demo
	max_N_upgrade.visible = not is_demo
	max_H_upgrade.visible = not is_demo
	max_M_upgrade.visible = not is_demo
	max_r_upgrade.visible = not is_demo
	attack_upgrade.visible = not is_demo
	defence_upgrade.visible = not is_demo
	mana_regen_upgrade.visible = not is_demo
	max_cr_upgrade.visible = not is_demo
	max_cd_upgrade.visible = not is_demo
	max_spell_count_cost.visible = not is_demo
	max_running_speed_cost.visible = not is_demo
	max_P_cost.visible = not is_demo
	max_v_cost.visible = not is_demo
	max_N_cost.visible = not is_demo
	max_T_cost.visible = not is_demo
	max_M_cost.visible = not is_demo
	max_r_cost.visible = not is_demo
	max_H_cost.visible = not is_demo
	attack_cost.visible = not is_demo
	defence_cost.visible = not is_demo
	mana_regen_cost.visible = not is_demo
	max_cr_cost.visible = not is_demo
	max_cd_cost.visible = not is_demo

func _on_max_spell_count_upgrade_pressed() -> void:
	var err := settings.upgrade_settings.purchase_spells_in_book(settings.is_editing_level)
	UIAudioPlayer.click()
	update_state(err)
	
func _on_max_running_speed_upgrade_pressed() -> void:
	var err := settings.upgrade_settings.purchase_running_speed(settings.is_editing_level)
	update_state(err)
	
func _on_void_upgrade_pressed() -> void:
	var err := settings.upgrade_settings.purchase_spell_element(Spell.Element.VOID, settings.is_editing_level)
	UIAudioPlayer.click()
	update_state(err)

func _on_fire_upgrade_pressed() -> void:
	var err := settings.upgrade_settings.purchase_spell_element(Spell.Element.FIRE, settings.is_editing_level)
	UIAudioPlayer.click()
	update_state(err)

func _on_water_upgrade_pressed() -> void:
	var err := settings.upgrade_settings.purchase_spell_element(Spell.Element.WATER, settings.is_editing_level)
	UIAudioPlayer.click()
	update_state(err)
	
func _on_air_upgrade_pressed() -> void:
	var err := settings.upgrade_settings.purchase_spell_element(Spell.Element.AIR, settings.is_editing_level)
	UIAudioPlayer.click()
	update_state(err)

func _on_rock_upgrade_pressed() -> void:
	var err := settings.upgrade_settings.purchase_spell_element(Spell.Element.ROCK, settings.is_editing_level)
	UIAudioPlayer.click()
	update_state(err)

func _on_ice_upgrade_pressed() -> void:
	var err := settings.upgrade_settings.purchase_spell_element(Spell.Element.ICE, settings.is_editing_level)
	UIAudioPlayer.click()
	update_state(err)

func _on_electric_upgrade_pressed() -> void:
	var err := settings.upgrade_settings.purchase_spell_element(Spell.Element.ELECTRIC, settings.is_editing_level)
	UIAudioPlayer.click()
	update_state(err)

func _on_max_P_upgrade_pressed() -> void:
	var err := settings.upgrade_settings.purchase_P(settings.is_editing_level)
	UIAudioPlayer.click()
	update_state(err)
	
func _on_max_v_upgrade_pressed() -> void:
	var err := settings.upgrade_settings.purchase_v(settings.is_editing_level)
	UIAudioPlayer.click()
	update_state(err)

func _on_max_T_upgrade_pressed() -> void:
	var err := settings.upgrade_settings.purchase_T(settings.is_editing_level)
	UIAudioPlayer.click()
	update_state(err)

func _on_max_N_upgrade_pressed() -> void:
	var err := settings.upgrade_settings.purchase_N(settings.is_editing_level)
	UIAudioPlayer.click()
	update_state(err)

func _on_max_M_upgrade_pressed() -> void:
	var err := settings.upgrade_settings.purchase_mana(settings.is_editing_level)
	UIAudioPlayer.click()
	update_state(err)
	
func _on_max_R_upgrade_pressed() -> void:
	var err := settings.upgrade_settings.purchase_r(settings.is_editing_level)
	UIAudioPlayer.click()
	update_state(err)

func _on_at_start_upgrade_pressed() -> void:
	var err := settings.upgrade_settings.purchase_chain_method(Spell.ChainCastKind.START, settings.is_editing_level)
	UIAudioPlayer.click()
	update_state(err)

func _on_at_end_upgrade_pressed() -> void:
	var err := settings.upgrade_settings.purchase_chain_method(Spell.ChainCastKind.END, settings.is_editing_level)
	UIAudioPlayer.click()
	update_state(err)

func _on_on_hit_upgrade_pressed() -> void:
	var err := settings.upgrade_settings.purchase_chain_method(Spell.ChainCastKind.HIT, settings.is_editing_level)
	UIAudioPlayer.click()
	update_state(err)

func _on_max_H_upgrade_pressed() -> void:
	var err := settings.upgrade_settings.purchase_health(settings.is_editing_level)
	UIAudioPlayer.click()
	update_state(err)
	
func _on_attack_upgrade_pressed() -> void:
	var err := settings.upgrade_settings.purchase_attack(settings.is_editing_level)
	UIAudioPlayer.click()
	update_state(err)

func _on_defence_upgrade_pressed() -> void:
	var err := settings.upgrade_settings.purchase_defence(settings.is_editing_level)
	UIAudioPlayer.click()
	update_state(err)
	
func _on_mana_regen_upgrade_pressed() -> void:
	var err := settings.upgrade_settings.purchase_mana_regen(settings.is_editing_level)
	UIAudioPlayer.click()
	update_state(err)


func _on_crit_rate_upgrade_pressed() -> void:
	var err := settings.upgrade_settings.purchase_crit_rate(settings.is_editing_level)
	UIAudioPlayer.click()
	update_state(err)

func _on_crit_dmg_upgrade_pressed() -> void:
	var err := settings.upgrade_settings.purchase_crit_dmg(settings.is_editing_level)
	UIAudioPlayer.click()
	update_state(err)
